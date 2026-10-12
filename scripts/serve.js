#!/usr/bin/env node

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const PORT = process.env.PORT || 8000;
const WEB_DIR = path.resolve(__dirname, '..', 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

if (!fs.existsSync(WEB_DIR)) {
  console.error(`[Zenith] Error: Web build directory not found at ${WEB_DIR}`);
  console.error('[Zenith] Please run "npm run build" first to generate the web release.');
  process.exit(1);
}

const server = http.createServer((req, res) => {
  // Proxy API requests directly to Zenith Privacy Engine backend (default port 8080)
  if (
    req.url.startsWith('/api/') ||
    req.url.startsWith('/v1/') ||
    req.url === '/health'
  ) {
    const proxyReq = http.request(
      {
        hostname: '127.0.0.1',
        port: 8080,
        path: req.url,
        method: req.method,
        headers: req.headers,
      },
      (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res, { end: true });
      }
    );

    proxyReq.on('error', (err) => {
      res.writeHead(502, { 'Content-Type': 'application/problem+json' });
      res.end(
        JSON.stringify({
          type: 'https://zenith.privacy/errors/backend-unreachable',
          title: 'Zenith Engine Backend Offline',
          status: 502,
          detail:
            'The Zenith backend service on port 8080 is not reachable: ' +
            err.message +
            '. Start it via "npm run backend" or "dart run bin/zenith_server.dart".',
          instance: req.url,
        })
      );
    });

    req.pipe(proxyReq, { end: true });
    return;
  }

  // Normalize request URL
  let reqUrl = decodeURI(req.url.split('?')[0]);
  if (reqUrl.startsWith('/Zenith/')) {
    reqUrl = reqUrl.substring('/Zenith'.length);
  } else if (reqUrl === '/Zenith') {
    reqUrl = '/index.html';
  }
  if (reqUrl === '/' || reqUrl === '') {
    reqUrl = '/index.html';
  }

  let filePath = path.join(WEB_DIR, reqUrl);

  // Security check: ensure file path doesn't escape WEB_DIR
  if (!filePath.startsWith(WEB_DIR)) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('403 Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err) {
      // Fallback to index.html for SPA routing if file not found
      filePath = path.join(WEB_DIR, 'index.html');
    } else if (stats.isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (readErr, content) => {
      if (readErr) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404 Not Found');
        return;
      }

      res.writeHead(200, {
        'Content-Type': contentType,
        'Cache-Control': 'no-cache',
        'Cross-Origin-Embedder-Policy': 'credentialless',
        'Cross-Origin-Opener-Policy': 'same-origin',
      });
      res.end(content);
    });
  });
});

server.listen(PORT, () => {
  const url = `http://localhost:${PORT}`;
  console.log(`\n======================================================`);
  console.log(`  🛰️  PROJECT ZENITH — LOCALHOST WEB SERVER RUNNING`);
  console.log(`======================================================`);
  console.log(`  Target URL: ${url}`);
  console.log(`  Serving from: ${WEB_DIR}`);
  console.log(`  Press Ctrl+C to stop the server.\n`);

  // Automatically open browser on macOS
  if (process.platform === 'darwin') {
    exec(`open ${url}`);
  }
});
