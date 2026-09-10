const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Listen for new deposits
exports.sendDepositNotification = functions.firestore
  .document("deposits/{depositId}")
  .onCreate(async (snap, context) => {
    const newData = snap.data();
    const userId = newData.userId;
    const amount = newData.amount;

    // Get user fcmToken
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      console.log("No token for user", userId);
      return;
    }

    const payload = {
      notification: {
        title: "Deposit Received",
        body: `Your deposit of ৳${amount} has been received.`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "deposit",
        id: context.params.depositId,
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  });

// Listen for deposit status updates
exports.sendDepositStatusNotification = functions.firestore
  .document("deposits/{depositId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Only notify if status changed
    if (newData.status === oldData.status) return;

    const userId = newData.userId;
    const status = newData.status;

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) return;

    const payload = {
      notification: {
        title: "Deposit Update",
        body: `Your deposit is now ${status}.`,
      },
       data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "deposit",
        id: context.params.depositId,
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  });

// Listen for new loans (Approval/Creation)
exports.sendLoanNotification = functions.firestore
  .document("loans/{loanId}")
  .onCreate(async (snap, context) => {
    const newData = snap.data();
    const userId = newData.borrowerId;
    const amount = newData.loanAmount;

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) return;

    const payload = {
      notification: {
        title: "Loan Approved",
        body: `Your loan of ৳${amount} has been approved.`,
      },
       data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "loan",
        id: context.params.loanId,
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  });

// Listen for loan status updates
exports.sendLoanStatusNotification = functions.firestore
  .document("loans/{loanId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (newData.status === oldData.status) return;

    const userId = newData.borrowerId;
    const status = newData.status;

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) return;

    const payload = {
      notification: {
        title: "Loan Update",
        body: `Your loan status is now ${status}.`,
      },
       data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "loan",
        id: context.params.loanId,
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  });
