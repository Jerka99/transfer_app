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
const MAX_STORAGE_BYTES =
  Number(process.env.MAX_STORAGE_GB || 50) * 1024 * 1024 * 1024;

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
  return 30;
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
    const { action, key, contentType, password, expiresIn, size } = event.queryStringParameters || {};

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
      if (!size || isNaN(size)) {
        return bad("Missing or invalid file size");
      }

      const fileSize = Number(size);

      const currentUsage = await getTotalBucketSize();

      if (currentUsage + fileSize > MAX_STORAGE_BYTES) {
        return bad("Storage limit exceeded (50GB)");
      }

      const command = new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: contentType });
      const url = await getSignedUrl(s3, command, { expiresIn: DEFAULT_EXPIRY });
      return ok({ url, expiresIn: expirySeconds });
    }

    // Delete
    if (action === "delete") {
      await s3.send(new DeleteObjectCommand({ Bucket: BUCKET, Key: key }));
      return ok({ deleted: true });
    }

    // List objects but treat folders as one element
    if (action === "list") {
      const result = await s3.send(new ListObjectsV2Command({ Bucket: BUCKET }));

      const itemsMap = {}; // key = top-level folder or file
      const filesAtRoot = [];

      (result.Contents || []).forEach(obj => {
        if (!obj.Key) return;
        const parts = obj.Key.split('/');

        if (parts.length > 1) {
          const folderName = parts[0];
          if (!itemsMap[folderName]) {
            itemsMap[folderName] = { key: folderName, isFolder: true, children: [] };
          }
          itemsMap[folderName].children.push({
            key: obj.Key,
            size: obj.Size,
            lastModified: obj.LastModified,
            isFolder: false
          });
        } else {
          filesAtRoot.push({
            key: obj.Key,
            size: obj.Size,
            lastModified: obj.LastModified,
            isFolder: false
          });
        }
      });

      let usedBytes = 0;

      (result.Contents || []).forEach(obj => {
        usedBytes += obj.Size || 0;
      });

      const list = [...Object.values(itemsMap), ...filesAtRoot];
      return ok({
        maxBytes: MAX_STORAGE_BYTES,
        usedBytes,
        items: list,
      });
    }


    // Generate signed URLs for all files in a folder
    if (action === "download-folder") {
      if (!key) return bad("Missing folder key");

      // List all objects under the folder prefix
      const result = await s3.send(new ListObjectsV2Command({ Bucket: BUCKET, Prefix: key.endsWith('/') ? key : key + '/' }));
      const urls = await Promise.all((result.Contents || []).map(async (obj) => {
        const command = new GetObjectCommand({ Bucket: BUCKET, Key: obj.Key });
        const url = await getSignedUrl(s3, command, { expiresIn: expirySeconds });
        return { key: obj.Key, url };
      }));

      return ok({ folder: key, urls });
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

async function getTotalBucketSize() {
  let continuationToken;
  let total = 0;

  do {
    const result = await s3.send(
      new ListObjectsV2Command({
        Bucket: BUCKET,
        ContinuationToken: continuationToken,
      })
    );

    for (const obj of result.Contents || []) {
      total += obj.Size || 0;
    }

    continuationToken = result.IsTruncated
      ? result.NextContinuationToken
      : undefined;
  } while (continuationToken);

  return total;
}
