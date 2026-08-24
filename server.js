'use strict';

const express = require('express');
const path = require('path');

const app = express();

/* =========================================================
   VINOM AI — Production Server
   Express 5.x / Node.js 20+
   ========================================================= */

// ---------------------------------------------------------
// Configuration
// ---------------------------------------------------------

const PORT = Number(process.env.PORT) || 3000;
const HOST = '0.0.0.0';

const PUBLIC_DIR = path.join(__dirname, 'public');
const INDEX_FILE = path.join(PUBLIC_DIR, 'index.html');

// ---------------------------------------------------------
// Security / Performance
// ---------------------------------------------------------

app.disable('x-powered-by');

app.set('trust proxy', 1);

// ---------------------------------------------------------
// Request parsers
// ---------------------------------------------------------

app.use(
  express.json({
    limit: '50mb'
  })
);

app.use(
  express.urlencoded({
    extended: true,
    limit: '50mb'
  })
);

// ---------------------------------------------------------
// Basic request logging
// ---------------------------------------------------------

app.use((req, res, next) => {
  const started = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - started;

    console.log(
      `${new Date().toISOString()} ${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`
    );
  });

  next();
});

// ---------------------------------------------------------
// Health check
// ---------------------------------------------------------

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'VINOM AI',
    environment: process.env.NODE_ENV || 'production',
    timestamp: new Date().toISOString()
  });
});

// ---------------------------------------------------------
// API status
// ---------------------------------------------------------

app.get('/api/status', (req, res) => {
  res.status(200).json({
    success: true,
    name: 'VINOM AI',
    version: '1.0.0',
    server: 'online',
    node: process.version
  });
});

// ---------------------------------------------------------
// Static files
// ---------------------------------------------------------

app.use(
  express.static(PUBLIC_DIR, {
    index: 'index.html',
    extensions: ['html'],

    maxAge:
      process.env.NODE_ENV === 'production'
        ? '1d'
        : 0,

    setHeaders: (res, filePath) => {
      // Prevent browsers from caching the main HTML too aggressively
      if (filePath.endsWith('index.html')) {
        res.setHeader(
          'Cache-Control',
          'no-cache, no-store, must-revalidate'
        );

        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
      }
    }
  })
);

// ---------------------------------------------------------
// SPA fallback
//
// IMPORTANT:
// Express 5 does NOT use:
// app.get('*', ...)
//
// Correct Express 5 syntax:
// app.get('/{*splat}', ...)
//
// This is one of the important fixes for the 503 problem.
// ---------------------------------------------------------

app.get('/{*splat}', (req, res, next) => {
  // Never redirect API requests to index.html
  if (req.path.startsWith('/api/')) {
    return next();
  }

  res.sendFile(INDEX_FILE, (error) => {
    if (error) {
      next(error);
    }
  });
});

// ---------------------------------------------------------
// 404 handler
// ---------------------------------------------------------

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Not Found',
    path: req.originalUrl
  });
});

// ---------------------------------------------------------
// Global error handler
// ---------------------------------------------------------

app.use((error, req, res, next) => {
  console.error('VINOM AI SERVER ERROR');
  console.error(error);

  if (res.headersSent) {
    return next(error);
  }

  res.status(error.status || 500).json({
    success: false,
    error:
      process.env.NODE_ENV === 'production'
        ? 'Internal Server Error'
        : error.message
  });
});

// ---------------------------------------------------------
// Start server
// ---------------------------------------------------------

const server = app.listen(PORT, HOST, () => {
  console.log('');
  console.log('==============================================');
  console.log('              VINOM AI SERVER');
  console.log('==============================================');
  console.log(`Environment : ${process.env.NODE_ENV || 'production'}`);
  console.log(`Node.js     : ${process.version}`);
  console.log(`Port        : ${PORT}`);
  console.log(`Host        : ${HOST}`);
  console.log(`Public      : ${PUBLIC_DIR}`);
  console.log('Status      : ONLINE');
  console.log('==============================================');
  console.log('');
});

// ---------------------------------------------------------
// Graceful shutdown
// ---------------------------------------------------------

function shutdown(signal) {
  console.log(`${signal} received. Shutting down...`);

  server.close(() => {
    console.log('VINOM AI server stopped.');
    process.exit(0);
  });

  setTimeout(() => {
    console.error('Forced shutdown.');
    process.exit(1);
  }, 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// ---------------------------------------------------------
// Prevent unexpected crashes from silently killing server
// ---------------------------------------------------------

process.on('uncaughtException', (error) => {
  console.error('UNCAUGHT EXCEPTION:');
  console.error(error);
});

process.on('unhandledRejection', (reason) => {
  console.error('UNHANDLED PROMISE REJECTION:');
  console.error(reason);
});
