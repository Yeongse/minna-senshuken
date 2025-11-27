import admin from 'firebase-admin';

let firebaseApp: admin.app.App | null = null;

export function initializeFirebase(): admin.app.App {
  if (firebaseApp) {
    return firebaseApp;
  }

  if (admin.apps.length > 0) {
    firebaseApp = admin.apps[0]!;
    return firebaseApp;
  }

  firebaseApp = admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: process.env.FIREBASE_PROJECT_ID,
  });

  return firebaseApp;
}

export function getAuth(): admin.auth.Auth {
  const app = initializeFirebase();
  return admin.auth(app);
}
