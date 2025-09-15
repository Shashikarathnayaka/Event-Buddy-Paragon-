const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({maxInstances: 10});

// Cloud Function: Trigger when a new event is created
exports.sendEventCreatedNotification = onDocumentCreated(
    "events/{eventId}",
    async (event) => {
      const eventData = event.data;
      const eventId = event.params.eventId;
      const eventName = eventData.name || "New Event";

      // Get all user tokens
      const usersSnapshot = await db.collection("users").get();
      const tokens = [];

      usersSnapshot.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token) tokens.push(token);
      });

      if (tokens.length === 0) {
        console.log("No FCM tokens found");
        return;
      }

      // Notification payload
      const payload = {
        notification: {
          title: "🎉 New Event Created!",
          body: `Check out the new event: ${eventName}`,
        },
        data: {
          type: "event_created",
          eventId: eventId,
          eventName: eventName,
        },
      };

      try {
        const response = await admin.messaging().sendToDevice(tokens, payload);
        console.log("Notifications sent successfully:", response.successCount);
      } catch (error) {
        console.error("Error sending notifications:", error);
      }
    },
);
