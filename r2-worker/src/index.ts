export interface Env {
	R2: R2Bucket;
	R2_BUCKET_NAME: string;
	ADMIN_PASSWORD: string;
	ADMIN_TOKEN: string;
	MAX_STORAGE_GB: string;
}

const CORS_HEADERS: HeadersInit = {
	"Access-Control-Allow-Origin": "*", // tighten in prod
	"Access-Control-Allow-Headers": "Authorization, Content-Type",
	"Access-Control-Allow-Methods": "GET, POST, PUT, OPTIONS",
};

export default {
	async fetch(req: Request, env: Env): Promise<Response> {
		if (!env.R2) {
			return new Response(
				JSON.stringify({ error: "R2 binding is not configured" }),
				{ status: 500, headers: CORS_HEADERS }
			);
		}

		// Preflight
		if (req.method === "OPTIONS") {
			return new Response(null, { status: 204, headers: CORS_HEADERS });
		}

		const url = new URL(req.url);
		const action = url.searchParams.get("action");
		const key = url.searchParams.get("key");
		const contentType =
			url.searchParams.get("contentType") || "application/octet-stream";
		const password = url.searchParams.get("password");
		const size = Number(url.searchParams.get("size") || 0);

		const MAX_STORAGE_BYTES =
			Number(env.MAX_STORAGE_GB || "50") * 1024 * 1024 * 1024;

		// ------------------------
		// helpers
		// ------------------------
		const ok = (body: unknown) =>
			new Response(JSON.stringify(body), {
				status: 200,
				headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
			});

		const bad = (msg: string) =>
			new Response(JSON.stringify({ error: msg }), {
				status: 400,
				headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
			});

		const unauthorized = (msg = "Unauthorized") =>
			new Response(JSON.stringify({ error: msg }), {
				status: 401,
				headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
			});

		const timingSafeEqual = async (a?: string, b?: string) => {
			if (!a || !b || a.length !== b.length) return false;
			const enc = new TextEncoder();
			return crypto.subtle.timingSafeEqual(enc.encode(a), enc.encode(b));
		};

		const isAdmin = () => {
			const auth = req.headers
				.get("Authorization")
				?.replace("Bearer ", "");
			return auth === env.ADMIN_TOKEN;
		};

		const getTotalBucketSize = async () => {
			let cursor: string | undefined;
			let total = 0;

			do {
				const list = await env.R2.list({ cursor });
				for (const obj of list.objects) total += obj.size || 0;
				cursor = list.truncated ? list.cursor : undefined;
			} while (cursor);

			return total;
		};

		try {
			// ------------------------
			// LOGIN
			// ------------------------
			if (action === "login") {
				const okPwd = await timingSafeEqual(
					password,
					env.ADMIN_PASSWORD
				);
				if (!okPwd) return unauthorized("Invalid password");

				return ok({
					token: env.ADMIN_TOKEN,
					message: "Login successful",
				});
			}

			// ------------------------
			// AUTH GUARD
			// ------------------------
			const protectedActions = ["upload", "delete", "list"];
			if (protectedActions.includes(action || "") && !isAdmin()) {
				return unauthorized();
			}

			// ------------------------
			// UPLOAD (PUT body)
			// ------------------------
			if (action === "upload") {
				if (!key) return bad("Missing key");
				if (!req.body) return bad("Missing body");

				if (!size || isNaN(size)) {
					return bad("Missing or invalid file size");
				}

				const used = await getTotalBucketSize();
				if (used + size > MAX_STORAGE_BYTES) {
					return bad("Storage limit exceeded");
				}

				await env.R2.put(key, req.body, {
					httpMetadata: { contentType },
				});

				return ok({ uploaded: true, key });
			}

			// ------------------------
			// DELETE
			// ------------------------
			if (action === "delete") {
				if (!key) return bad("Missing key");
				await env.R2.delete(key);
				return ok({ deleted: true });
			}

			// ------------------------
			// LIST (folders grouped)
			// ------------------------
			if (action === "list") {
				const list = await env.R2.list();
				const folders: Record<string, any> = {};
				const rootFiles: any[] = [];
				let usedBytes = 0;

				for (const obj of list.objects) {
					usedBytes += obj.size || 0;
					const parts = obj.key.split("/");

					if (parts.length > 1) {
						const folder = parts[0];
						folders[folder] ??= {
							key: folder,
							isFolder: true,
							children: [],
						};

						folders[folder].children.push({
							key: obj.key,
							size: obj.size,
							lastModified: obj.uploaded,
							isFolder: false,
						});
					} else {
						rootFiles.push({
							key: obj.key,
							size: obj.size,
							lastModified: obj.uploaded,
							isFolder: false,
						});
					}
				}

				return ok({
					maxBytes: MAX_STORAGE_BYTES,
					usedBytes,
					items: [...Object.values(folders), ...rootFiles],
				});
			}

			// ------------------------
			// DOWNLOAD (stream)
			// ------------------------
			if (action === "download") {
				if (!key) return bad("Missing key");

				const obj = await env.R2.get(key);
				if (!obj) return bad("File not found");

				return new Response(obj.body, {
					headers: {
						...CORS_HEADERS,
						"Content-Type":
							obj.httpMetadata?.contentType ||
							"application/octet-stream",
						"Content-Disposition": `attachment; filename="${key
							.split("/")
							.pop()}"`,
					},
				});
			}

			// ------------------------
			// DOWNLOAD FOLDER
			// ------------------------
			if (action === "download-folder") {
				if (!key) return bad("Missing folder key");

				const prefix = key.endsWith("/") ? key : key + "/";
				const list = await env.R2.list({ prefix });

				const files = await Promise.all(
					list.objects.map(async (o) => {
						const obj = await env.R2.get(o.key);
						return {
							key: o.key,
							size: o.size,
							data: obj ? await obj.arrayBuffer() : null,
						};
					})
				);

				return ok({ folder: key, files });
			}

			return bad("Invalid action");
		} catch (err: any) {
			console.error(err);
			return new Response(
				JSON.stringify({ error: err.message }),
				{ status: 500, headers: CORS_HEADERS }
			);
		}
	},
};
