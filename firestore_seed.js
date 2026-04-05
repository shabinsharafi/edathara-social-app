// firestore_seed.js
// Run with: node firestore_seed.js
// Make sure you have firebase-admin installed: npm install firebase-admin
// Place your serviceAccountKey.json in the same directory.

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function seed() {
  console.log('🌱 Seeding Firestore...');

  // ── Grounds ──────────────────────────────────────────────────────────────
  const grounds = [
    {
      id: 'cricket-ground',
      name: 'Cricket Ground',
      icon: '🏏',
      colorHex: '#1A5C3A',
      timeSlots: ['06:00','07:00','08:00','09:00','10:00','14:00','15:00','16:00','17:00','18:00'],
      blockedSlots: [],
      conflictIds: ['football-pitch-1', 'football-pitch-2'],
      description: 'Full-size cricket ground with pitch',
      isActive: true,
      capacity: 22,
    },
    {
      id: 'football-pitch-1',
      name: 'Football Pitch 1',
      icon: '⚽',
      colorHex: '#1A3A6C',
      timeSlots: ['06:00','07:00','08:00','09:00','10:00','14:00','15:00','16:00','17:00','18:00'],
      blockedSlots: [],
      conflictIds: ['cricket-ground'],
      description: 'Standard football pitch (north side)',
      isActive: true,
      capacity: 22,
    },
    {
      id: 'football-pitch-2',
      name: 'Football Pitch 2',
      icon: '⚽',
      colorHex: '#4A235A',
      timeSlots: ['06:00','07:00','08:00','09:00','10:00','14:00','15:00','16:00','17:00','18:00'],
      blockedSlots: [],
      conflictIds: ['cricket-ground'],
      description: 'Standard football pitch (south side)',
      isActive: true,
      capacity: 22,
    },
  ];

  for (const g of grounds) {
    const { id, ...data } = g;
    await db.collection('grounds').doc(id).set(data);
    console.log(`  ✅ Ground: ${g.name}`);
  }

  // ── Banners ───────────────────────────────────────────────────────────────
  const banners = [
    {
      title: 'Welcome to Edathara Samskarika Samithi',
      subtitle: 'Book your slot in seconds',
      colorHex: '#0D2B1F',
      imageUrl: null,
      sortOrder: 0,
    },
    {
      title: 'Annual Sports Meet 2025',
      subtitle: 'Register now — limited slots available',
      colorHex: '#1A3A6C',
      imageUrl: null,
      sortOrder: 1,
    },
    {
      title: 'New Pavilion Fund Drive',
      subtitle: 'Help us build something great',
      colorHex: '#6B2D2D',
      imageUrl: null,
      sortOrder: 2,
    },
  ];

  for (const b of banners) {
    await db.collection('banners').add(b);
    console.log(`  ✅ Banner: ${b.title}`);
  }

  // ── Contacts ──────────────────────────────────────────────────────────────
  const contacts = [
    { name: 'Ground Manager',  phone: '+91 98765 43210', role: 'Bookings & Ground', sortOrder: 0 },
    { name: 'Club Secretary',  phone: '+91 91234 56789', role: 'Memberships & Admin', sortOrder: 1 },
    { name: 'Treasurer',       phone: '+91 94567 12345', role: 'Finance & Donations', sortOrder: 2 },
    { name: 'Emergency',       phone: '112',             role: 'Security & Emergency', sortOrder: 3 },
  ];

  for (const c of contacts) {
    await db.collection('contacts').add(c);
    console.log(`  ✅ Contact: ${c.name}`);
  }

  // ── News ──────────────────────────────────────────────────────────────────
  const news = [
    {
      title: 'Welcome to Edathara Samskarika Samithi App!',
      body: 'We are thrilled to launch our official club app. You can now book grounds, stay updated with news, and connect with fellow members — all in one place.',
      authorId: 'admin',
      authorName: 'Admin',
      imageUrl: null,
      likedBy: [],
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      title: 'Monsoon maintenance complete',
      body: 'All grounds are now ready after the monsoon season. Drainage has been improved on Football Pitch 2. Happy playing!',
      authorId: 'admin',
      authorName: 'Admin',
      imageUrl: null,
      likedBy: [],
      createdAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
      ),
    },
  ];

  for (const n of news) {
    await db.collection('news').add(n);
    console.log(`  ✅ News: ${n.title}`);
  }

  // ── Fundraisers ───────────────────────────────────────────────────────────
  const fundraisers = [
    {
      title: 'New Pavilion Fund',
      description: 'Help us build a world-class pavilion with changing rooms, a lounge, and storage facilities for all members.',
      goalAmount: 500000,
      raisedAmount: 182000,
      deadline: 'Dec 2025',
      imageUrl: null,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      title: 'Ground Lighting Project',
      description: 'Install professional floodlights to enable evening and night play year-round. Benefit all members!',
      goalAmount: 200000,
      raisedAmount: 97000,
      deadline: 'Oct 2025',
      imageUrl: null,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now(),
    },
  ];

  for (const f of fundraisers) {
    await db.collection('fundraisers').add(f);
    console.log(`  ✅ Fundraiser: ${f.title}`);
  }

  console.log('\n🎉 Seeding complete!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
