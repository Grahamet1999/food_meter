const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

exports.suggestRecipes = require("./recipes").suggestRecipes;

exports.sendExpiringItemNotifications = functions.pubsub
  .schedule("every day 02:00") // Runs every day at 2:00 AM UTC
  .timeZone("Etc/UTC")
  .onRun(async () => {
    const db = admin.firestore();
    const today = admin.firestore.Timestamp.now().toDate();
    const oneDayMs = 24 * 60 * 60 * 1000;

    const usersSnapshot = await db.collection("users").get();

    await Promise.allSettled(usersSnapshot.docs.map(async (userDoc) => {
      const userId = userDoc.id;
      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return;

      const itemsSnapshot = await db
        .collection("users")
        .doc(userId)
        .collection("pantry_items")
        .get();

      for (const itemDoc of itemsSnapshot.docs) {
        const item = itemDoc.data();
        if (!item.expirationDate) continue;
        const expDate = item.expirationDate.toDate
          ? item.expirationDate.toDate()
          : new Date(item.expirationDate);
        const diff = expDate - today;
        let daysLeft = null;
        if (diff > 0 && diff <= oneDayMs) daysLeft = 1;
        else if (diff > oneDayMs && diff <= 5 * oneDayMs) daysLeft = 5;
        if (!daysLeft) continue;

        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "Expiring Item Reminder",
              body: `Your ${item.name} expires in ${daysLeft} day${daysLeft === 1 ? "" : "s"}!`,
            },
          });
        } catch (err) {
          // A single expired/invalid token shouldn't stop other users' items
          // from being processed.
          console.error(
            `Failed to send notification to user ${userId} for item ${itemDoc.id}:`,
            err,
          );
        }
      }
    }));

    return null;
  });
