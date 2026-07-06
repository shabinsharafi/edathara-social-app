const { initializeApp, cert } = require('firebase-admin/app');
const { getStorage } = require('firebase-admin/storage');

// Run: node set_cors.js <path-to-service-account.json>
const serviceAccountPath = process.argv[2];
if (!serviceAccountPath) {
  console.error('Usage: node set_cors.js <service-account.json>');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
initializeApp({
  credential: cert(serviceAccount),
  storageBucket: `${serviceAccount.project_id}.appspot.com`,
});

const bucket = getStorage().bucket();
const corsConfig = [
  { origin: ['*'], method: ['GET'], maxAgeSeconds: 3600 },
];

bucket.setCorsConfiguration(corsConfig)
  .then(() => console.log('CORS set successfully'))
  .catch(err => console.error('Error:', err));
