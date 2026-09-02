import { serve } from "bun";
import { readFileSync, existsSync } from "fs";
import { join, extname } from "path";

const port = 8088;
const root = import.meta.dir;

const mimeTypes: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".pdf": "application/pdf",
  ".md": "text/markdown; charset=utf-8",
};

serve({
  port: port,
  hostname: "0.0.0.0",
  fetch(req) {
    const url = new URL(req.url);
    let pathname = url.pathname;
    if (pathname === "/" || pathname === "") {
      pathname = "/index.html";
    }

    const filePath = join(root, pathname.replace(/^\//, ""));

    if (existsSync(filePath)) {
      const fileBuffer = readFileSync(filePath);
      const ext = extname(filePath).toLowerCase();
      const contentType = mimeTypes[ext] || "application/octet-stream";

      return new Response(fileBuffer, {
        status: 200,
        headers: { "Content-Type": contentType },
      });
    }

    return new Response("404 Not Found", { status: 404 });
  },
});

console.log(`[Bun Web Server] Successfully listening on http://localhost:${port}`);
