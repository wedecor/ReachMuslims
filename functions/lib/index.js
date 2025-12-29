"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onFollowUpAdded = exports.onLeadStatusChanged = exports.onLeadReassigned = exports.onLeadAssigned = exports.onUserCreated = exports.onUserApproved = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
/**
 * Set custom claims when user is approved or updated
 * This makes role/status available in Firestore rules via request.auth.token
 */
exports.onUserApproved = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;
    // Check if user was just approved or role/status/active changed
    const statusChanged = before.status !== after.status;
    const roleChanged = before.role !== after.role;
    const activeChanged = before.active !== after.active;
    if (statusChanged || roleChanged || activeChanged) {
        try {
            // Set custom claims
            const customClaims = {
                role: after.role || null,
                status: after.status || "pending",
                active: after.active || false,
                region: after.region || null,
            };
            await admin.auth().setCustomUserClaims(userId, customClaims);
            console.log(`Custom claims set for user ${userId}:`, customClaims);
        }
        catch (error) {
            console.error(`Error setting custom claims for user ${userId}:`, error);
        }
    }
});
/**
 * Set custom claims when user document is created
 */
exports.onUserCreated = functions.firestore
    .document("users/{userId}")
    .onCreate(async (snap, context) => {
    const userData = snap.data();
    const userId = context.params.userId;
    try {
        const customClaims = {
            role: userData.role || null,
            status: userData.status || "pending",
            active: userData.active || false,
            region: userData.region || null,
        };
        await admin.auth().setCustomUserClaims(userId, customClaims);
        console.log(`Custom claims set for new user ${userId}:`, customClaims);
    }
    catch (error) {
        console.error(`Error setting custom claims for new user ${userId}:`, error);
    }
});
/**
 * Helper function to check if user is active
 */
async function isUserActive(userId) {
    try {
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists)
            return false;
        const userData = userDoc.data();
        return userData.active === true;
    }
    catch (error) {
        console.error("Error checking user active status:", error);
        return false;
    }
}
/**
 * Helper function to get user FCM token
 */
async function getUserFCMToken(userId) {
    try {
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists)
            return null;
        // In a real app, FCM token would be stored in user document or a separate tokens collection
        // For now, we'll return null (notifications will only be in-app)
        return null;
    }
    catch (error) {
        console.error("Error getting FCM token:", error);
        return null;
    }
}
/**
 * Helper function to create notification
 */
async function createNotification(userId, leadId, type, title, body) {
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
    }
    catch (error) {
        console.error("Error creating notification:", error);
    }
}
/**
 * Triggered when a lead is assigned
 */
exports.onLeadAssigned = functions.firestore
    .document("leads/{leadId}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const leadId = context.params.leadId;
    // Check if assignment changed from unassigned to assigned
    if (!before.assignedTo && after.assignedTo) {
        const assignedUserId = after.assignedTo;
        // Verify user is in same region
        const userDoc = await db.collection("users").doc(assignedUserId).get();
        if (!userDoc.exists)
            return;
        const userData = userDoc.data();
        if (userData.region !== after.region) {
            console.log(`Skipping notification: user ${assignedUserId} is not in region ${after.region}`);
            return;
        }
        await createNotification(assignedUserId, leadId, "leadAssigned", "New Lead Assigned", `You have been assigned to lead: ${after.name}`);
    }
});
/**
 * Triggered when a lead is reassigned
 */
exports.onLeadReassigned = functions.firestore
    .document("leads/{leadId}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const leadId = context.params.leadId;
    // Check if assignment changed to a different user
    if (before.assignedTo &&
        after.assignedTo &&
        before.assignedTo !== after.assignedTo) {
        const newAssignedUserId = after.assignedTo;
        // Verify user is in same region
        const userDoc = await db.collection("users").doc(newAssignedUserId).get();
        if (!userDoc.exists)
            return;
        const userData = userDoc.data();
        if (userData.region !== after.region) {
            console.log(`Skipping notification: user ${newAssignedUserId} is not in region ${after.region}`);
            return;
        }
        await createNotification(newAssignedUserId, leadId, "leadReassigned", "Lead Reassigned", `Lead "${after.name}" has been reassigned to you`);
    }
});
/**
 * Triggered when lead status changes
 */
exports.onLeadStatusChanged = functions.firestore
    .document("leads/{leadId}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const leadId = context.params.leadId;
    // Check if status changed
    if (before.status !== after.status && after.assignedTo) {
        const assignedUserId = after.assignedTo;
        // Verify user is active and in same region
        const userDoc = await db.collection("users").doc(assignedUserId).get();
        if (!userDoc.exists)
            return;
        const userData = userDoc.data();
        if (userData.region !== after.region) {
            console.log(`Skipping notification: user ${assignedUserId} is not in region ${after.region}`);
            return;
        }
        await createNotification(assignedUserId, leadId, "leadStatusChanged", "Lead Status Updated", `Lead "${after.name}" status changed to ${after.status}`);
    }
});
/**
 * Triggered when a follow-up is added
 */
exports.onFollowUpAdded = functions.firestore
    .document("leads/{leadId}/followUps/{followUpId}")
    .onCreate(async (snap, context) => {
    const followUpData = snap.data();
    const leadId = context.params.leadId;
    const createdBy = followUpData.createdBy;
    // Get lead to find assigned user
    const leadDoc = await db.collection("leads").doc(leadId).get();
    if (!leadDoc.exists)
        return;
    const leadData = leadDoc.data();
    const assignedUserId = leadData.assignedTo;
    // Only notify if lead is assigned and not the person who created the follow-up
    if (assignedUserId && assignedUserId !== createdBy) {
        // Verify user is active and in same region
        const userDoc = await db.collection("users").doc(assignedUserId).get();
        if (!userDoc.exists)
            return;
        const userData = userDoc.data();
        if (userData.region !== leadData.region) {
            console.log(`Skipping notification: user ${assignedUserId} is not in region ${leadData.region}`);
            return;
        }
        await createNotification(assignedUserId, leadId, "followUpAdded", "New Follow-Up Added", `A new follow-up was added to lead "${leadData.name}"`);
    }
});
//# sourceMappingURL=index.js.map