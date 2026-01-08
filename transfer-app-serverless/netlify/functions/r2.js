const { S3Client, ListObjectsV2Command, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const s3 = new S3Client({
  region: "auto",
  endpoint: process.env.R2_ENDPOINT,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY,
    secretAccessKey: process.env.R2_SECRET_KEY
  }
});

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*", // todo fix
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const BUCKET = process.env.R2_BUCKET_NAME;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
const ADMIN_TOKEN = process.env.ADMIN_TOKEN;

function safeEqual(a, b) {
  return (
    a &&
    b &&
    a.length === b.length &&
    crypto.timingSafeEqual(Buffer.from(a), Buffer.from(b))
  );
}

function isAdmin(event) {
  const token = event.headers?.authorization?.replace("Bearer ", "");
  return token && token === process.env.ADMIN_TOKEN;
}

const ALLOWED_EXPIRIES = [
  60 * 60,
  60 * 60 * 24,
  60 * 60 * 24 * 7,
  60 * 60 * 24 * 30
];

const DEFAULT_EXPIRY = 60 * 60;

function resolveExpiry(raw) {
  console.log("raw", raw);
  const seconds = Number(raw);
  // if (!Number.isInteger(seconds)) return DEFAULT_EXPIRY;
  // if (!ALLOWED_EXPIRIES.includes(seconds)) return DEFAULT_EXPIRY;
  return seconds;
}

exports.handler = async function (event) {
  if (event.httpMethod === "OPTIONS") {
    return {
      statusCode: 204,
      headers: {
        "Content-Type": "application/json",
        ...CORS_HEADERS
      },
      body: "",
    };
  }
  try {
    const { action, key, contentType, password, expiresIn } = event.queryStringParameters || {};

    //  Login
    if (action === "login") {
      if (!safeEqual(password, ADMIN_PASSWORD)) {
        return unauthorized("Invalid password");
      }
      return ok({
        token: ADMIN_TOKEN,
        message: "Login successful"
      });

    }

    // Check admin for protected actions
    const protectedActions = ["upload", "delete", "list"];
    if (protectedActions.includes(action) && !isAdmin(event)) {
      return unauthorized();
    }
    console.log("expiresIn", expiresIn)
    const expirySeconds = resolveExpiry(expiresIn);

    //  Upload
    if (action === "upload") {
      const command = new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: contentType });
      const url = await getSignedUrl(s3, command, { expiresIn: DEFAULT_EXPIRY });
      return ok({ url, expiresIn: expirySeconds });
    }

    // Delete
    if (action === "delete") {
      await s3.send(new DeleteObjectCommand({ Bucket: BUCKET, Key: key }));
      return ok({ deleted: true });
    }

    //  List
    if (action === "list") {
      const result = await s3.send(new ListObjectsV2Command({ Bucket: BUCKET }));
      const files = (result.Contents || []).map(obj => ({
        key: obj.Key,
        size: obj.Size,
        lastModified: obj.LastModified
      }));
      return ok(files);
    }

    //  Download (publicly accessible via signed URL)
    if (action === "download") {
      const command = new GetObjectCommand({ Bucket: BUCKET, Key: key });
      const url = await getSignedUrl(s3, command, { expiresIn: expirySeconds });
      return ok({ url, expiresIn: expirySeconds });
    }

    return bad("Invalid action");
  } catch (err) {
    console.error(err);
    return error(err.message);
  }
};

// helpers
function ok(body) {
  return {
    statusCode: 200, headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS
    },

    body: JSON.stringify(body)
  };
}
function bad(msg) {
  return {
    statusCode: 400, headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS
    },

    body: JSON.stringify({ error: msg })
  };
}
function unauthorized(msg = "Unauthorized") {
  return {
    statusCode: 401, headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS
    },

    body: JSON.stringify({ error: msg })
  };
}
function error(msg) {
  return {
    statusCode: 500, headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS
    },
    body: JSON.stringify({ error: msg })
  };
}
