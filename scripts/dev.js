#!/usr/bin/env node

const http = require('http');
const { spawn } = require('child_process');

function checkBackend(callback) {
  let called = false;
  const done = (val) => {
    if (!called) {
      called = true;
      callback(val);
    }
  };

  const req = http.get('http://127.0.0.1:8080/health', (res) => {
    done(res.statusCode === 200);
  });
  req.on('error', () => done(false));
  req.setTimeout(2500, () => {
    req.destroy();
    done(false);
  });
}

function startBackend(onStarted) {
  console.log('[Zenith] Starting backend server (dart run bin/zenith_server.dart)...');
  const backend = spawn('dart', ['run', 'bin/zenith_server.dart'], {
    stdio: 'inherit',
    env: process.env,
  });

  backend.on('error', (err) => {
    console.error('[Zenith] Failed to start backend:', err.message);
  });

  let attempts = 0;
  const poll = setInterval(() => {
    attempts++;
    checkBackend((healthy) => {
      if (healthy) {
        clearInterval(poll);
        console.log('[Zenith] Backend is healthy and ready on http://localhost:8080');
        onStarted(backend);
      } else if (attempts >= 25) {
        clearInterval(poll);
        console.warn('[Zenith] Backend start timed out. Starting Flutter frontend anyway...');
        onStarted(backend);
      }
    });
  }, 1000);
}

function startFrontend() {
  console.log('[Zenith] Launching Flutter Web in Chrome (port 8000)...');
  const flutter = spawn('flutter', ['run', '-d', 'chrome', '--web-port=8000'], {
    stdio: 'inherit',
    env: process.env,
  });

  flutter.on('exit', (code) => {
    process.exit(code ?? 0);
  });
}

checkBackend((alreadyRunning) => {
  if (alreadyRunning) {
    console.log('[Zenith] Backend server is already running on http://localhost:8080');
    startFrontend();
  } else {
    startBackend((backendProcess) => {
      startFrontend();
      process.on('SIGINT', () => {
        if (backendProcess) backendProcess.kill();
        process.exit(0);
      });
      process.on('SIGTERM', () => {
        if (backendProcess) backendProcess.kill();
        process.exit(0);
      });
    });
  }
});
