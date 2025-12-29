import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * One-time function to set custom claims for all existing users
 * Run this once after deploying the new rules
 */
export const setCustomClaimsForAllUsers = functions.https.onCall(async (data, context) => {
  // Only allow admins to call this
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError("permission-denied", "Only admins can call this function");
  }

  const db = admin.firestore();
  const usersSnapshot = await db.collection("users").get();
  let count = 0;

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data();
    const userId = userDoc.id;

    try {
      const customClaims: { [key: string]: string | boolean | null } = {
        role: userData.role || null,
        status: userData.status || "pending",
        active: userData.active || false,
        region: userData.region || null,
      };

      await admin.auth().setCustomUserClaims(userId, customClaims);
      count++;
      console.log(`Set custom claims for user ${userId}`);
    } catch (error) {
      console.error(`Error setting custom claims for user ${userId}:`, error);
    }
  }

  return { message: `Custom claims set for ${count} users` };
});


