import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

/**
 * Set custom claims when user is approved or updated
 * This makes role/status available in Firestore rules via request.auth.token
 */
export const onUserApproved = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() as User;
    const after = change.after.data() as User;
    const userId = context.params.userId;

    // Check if user was just approved or role/status/active changed
    const statusChanged = before.status !== after.status;
    const roleChanged = before.role !== after.role;
    const activeChanged = before.active !== after.active;

    if (statusChanged || roleChanged || activeChanged) {
      try {
        // Set custom claims
        const customClaims: { [key: string]: string | boolean | null } = {
          role: after.role || null,
          status: after.status || "pending",
          active: after.active || false,
          region: after.region || null,
        };

        await admin.auth().setCustomUserClaims(userId, customClaims);
        console.log(`Custom claims set for user ${userId}:`, customClaims);
      } catch (error) {
        console.error(`Error setting custom claims for user ${userId}:`, error);
      }
    }
  });

/**
 * Set custom claims when user document is created
 */
export const onUserCreated = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const userData = snap.data() as User;
    const userId = context.params.userId;

    try {
      const customClaims: { [key: string]: string | boolean | null } = {
        role: userData.role || null,
        status: userData.status || "pending",
        active: userData.active || false,
        region: userData.region || null,
      };

      await admin.auth().setCustomUserClaims(userId, customClaims);
      console.log(`Custom claims set for new user ${userId}:`, customClaims);
    } catch (error) {
      console.error(`Error setting custom claims for new user ${userId}:`, error);
    }
  });

interface User {
  uid?: string;
  name: string;
  email: string;
  role?: string;
  region?: string;
  active: boolean;
  status?: string;
}

interface Lead {
  assignedTo?: string;
  assignedToName?: string;
  region: string;
  name: string;
  status: string;
}

/**
 * Helper function to check if user is active
 */
async function isUserActive(userId: string): Promise<boolean> {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return false;
    const userData = userDoc.data() as User;
    return userData.active === true;
  } catch (error) {
    console.error("Error checking user active status:", error);
    return false;
  }
}

/**
 * Helper function to get user FCM token
 */
async function getUserFCMToken(userId: string): Promise<string | null> {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return null;
    // In a real app, FCM token would be stored in user document or a separate tokens collection
    // For now, we'll return null (notifications will only be in-app)
    return null;
  } catch (error) {
    console.error("Error getting FCM token:", error);
    return null;
  }
}

/**
 * Helper function to create notification
 */
async function createNotification(
  userId: string,
  leadId: string,
  type: string,
  title: string,
  body: string
): Promise<void> {
  try {
    // Check if user is active
    const isActive = await isUserActive(userId);
    if (!isActive) {
      console.log(`Skipping notification for inactive user: ${userId}`);
      return;
    }

    // Create notification document
    await db.collection("notifications").add({
      userId,
      leadId,
      type,
      title,
      body,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send push notification if FCM token exists
    const fcmToken = await getUserFCMToken(userId);
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: {
          leadId,
          type,
        },
      });
    }
  } catch (error) {
    console.error("Error creating notification:", error);
  }
}

/**
 * Triggered when a lead is assigned
 */
export const onLeadAssigned = functions.firestore
  .document("leads/{leadId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() as Lead;
    const after = change.after.data() as Lead;
    const leadId = context.params.leadId;

    // Check if assignment changed from unassigned to assigned
    if (!before.assignedTo && after.assignedTo) {
      const assignedUserId = after.assignedTo;
      
      // Verify user exists and is active (allow cross-region assignment)
      const userDoc = await db.collection("users").doc(assignedUserId).get();
      if (!userDoc.exists) return;
      
      const userData = userDoc.data() as User;
      if (!userData.active) {
        console.log(`Skipping notification: user ${assignedUserId} is not active`);
        return;
      }

      // Note: Region check removed to support cross-region assignment
      // (e.g., sales person handling both USA and India leads)

      await createNotification(
        assignedUserId,
        leadId,
        "leadAssigned",
        "New Lead Assigned",
        `You have been assigned to lead: ${after.name}`
      );
    }
  });

/**
 * Triggered when a lead is reassigned
 */
export const onLeadReassigned = functions.firestore
  .document("leads/{leadId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() as Lead;
    const after = change.after.data() as Lead;
    const leadId = context.params.leadId;

    // Check if assignment changed to a different user
    if (
      before.assignedTo &&
      after.assignedTo &&
      before.assignedTo !== after.assignedTo
    ) {
      const newAssignedUserId = after.assignedTo;
      
      // Verify user exists and is active (allow cross-region assignment)
      const userDoc = await db.collection("users").doc(newAssignedUserId).get();
      if (!userDoc.exists) return;
      
      const userData = userDoc.data() as User;
      if (!userData.active) {
        console.log(`Skipping notification: user ${newAssignedUserId} is not active`);
        return;
      }

      // Note: Region check removed to support cross-region assignment

      await createNotification(
        newAssignedUserId,
        leadId,
        "leadReassigned",
        "Lead Reassigned",
        `Lead "${after.name}" has been reassigned to you`
      );
    }
  });

/**
 * Triggered when lead status changes
 */
export const onLeadStatusChanged = functions.firestore
  .document("leads/{leadId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() as Lead;
    const after = change.after.data() as Lead;
    const leadId = context.params.leadId;

    // Check if status changed
    if (before.status !== after.status && after.assignedTo) {
      const assignedUserId = after.assignedTo;
      
      // Verify user exists and is active (allow cross-region assignment)
      const userDoc = await db.collection("users").doc(assignedUserId).get();
      if (!userDoc.exists) return;
      
      const userData = userDoc.data() as User;
      if (!userData.active) {
        console.log(`Skipping notification: user ${assignedUserId} is not active`);
        return;
      }

      // Note: Region check removed to support cross-region assignment

      await createNotification(
        assignedUserId,
        leadId,
        "leadStatusChanged",
        "Lead Status Updated",
        `Lead "${after.name}" status changed to ${after.status}`
      );
    }
  });

/**
 * Triggered when a follow-up is added
 */
export const onFollowUpAdded = functions.firestore
  .document("leads/{leadId}/followUps/{followUpId}")
  .onCreate(async (snap, context) => {
    const followUpData = snap.data();
    const leadId = context.params.leadId;
    const createdBy = followUpData.createdBy;

    // Get lead to find assigned user
    const leadDoc = await db.collection("leads").doc(leadId).get();
    if (!leadDoc.exists) return;

    const leadData = leadDoc.data() as Lead;
    const assignedUserId = leadData.assignedTo;

    // Only notify if lead is assigned and not the person who created the follow-up
    if (assignedUserId && assignedUserId !== createdBy) {
      // Verify user exists and is active (allow cross-region assignment)
      const userDoc = await db.collection("users").doc(assignedUserId).get();
      if (!userDoc.exists) return;
      
      const userData = userDoc.data() as User;
      if (!userData.active) {
        console.log(`Skipping notification: user ${assignedUserId} is not active`);
        return;
      }

      // Note: Region check removed to support cross-region assignment

      await createNotification(
        assignedUserId,
        leadId,
        "followUpAdded",
        "New Follow-Up Added",
        `A new follow-up was added to lead "${leadData.name}"`
      );
    }
  });

