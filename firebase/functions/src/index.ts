import * as functions from "firebase-functions";
import * as crypto from "crypto";
import admin = require("firebase-admin");
import {DocumentSnapshot} from "firebase-functions/lib/providers/firestore";
admin.initializeApp();
const _db = admin.firestore();

exports.getAppConfig = functions.https.onRequest(async (req, res) => {
  console.log("getAppConfig triggered");
  if (!req.headers.authorization ||
    !req.headers.authorization.startsWith("Bearer ")) {
    console.error(
        "No Firebase ID token was in the Authorization header.",
        "Authorize your request by providing the following HTTP header:",
        "Authorization: Bearer <GeneratedAuthMD5>");
    res.status(403).send("Unauthorized");
    return;
  }
  console.log("Found 'Authorization' header");
  // Read the ID Token from the Authorization header.
  const idToken: string = req.headers.authorization.split("Bearer ")[1];
  const obj: { [k: string]: string } = req.body;
  const orgID: string = obj["orgID"];
  const appID: string = obj["appID"];
  const appName: string = obj["appName"];
  const dateTimeString: string = obj["dateTime"];

  try {
    if (orgID === null || orgID === "") {
      throw new Error("Missing parameter 1");
    }
    if (appID === null || appID === "") {
      throw new Error("Missing parameter 2");
    }
    if (idToken === null || idToken === "") {
      throw new Error("Missing parameter 3");
    }
    if (appName === null|| appName === "") {
      throw new Error("Missing parameter 4");
    }
    if (dateTimeString == null || dateTimeString === "") {
      throw new Error("Missing parameter 5");
    }
    const currDate: string = new Date().toISOString();
    if (dateTimeString.substring(0, 9) !== currDate.substring(0, 9)) {
      throw new Error("Unauthorized - Date missmatch");
    }
    console.log("Retrieving the App secret from database");

    const doc: DocumentSnapshot = await _db
        .collection("Organizations")
        .doc(orgID.toString())
        .collection("Apps")
        .doc(appID.toString())
        .get();
    if (!doc.exists) {
      throw new Error("App does not exist");
    }
    if (doc.data()!["secret"] == null) {
      throw new Error("App does not exist");
    }
    const secret: string = doc.data()!["secret"];
    const dbAppName: string = doc.data()!["name"];
    console.log(dbAppName + " settings retrieved from the database " + secret);

    console.log("Generating auth token");
    const md5Hash: string = crypto
        .createHash("md5")
        .update(orgID.toString() +
          dbAppName.toString() +
          secret.toString() +
          currDate.substring(0, 9))
        .digest("hex")
        .toString()
        .toLowerCase();
    console.log("Validating auth token");
    if (md5Hash !== idToken) {
      throw Error("Authorization token verification failed");
    }
    console.log("Request was successfully authenticated");
    console.log("Retrieving App config");
    const appConfig: Map<string, any> = doc.data()!.appConfig;
    const appTheme: Map<string, any> = doc.data()!.appTheme;
    const docFire: DocumentSnapshot = await _db
        .collection("Organizations")
        .doc(orgID.toString())
        .collection("GeneralConfig")
        .doc("firestoreSettings")
        .get();
    let firabaseSettigs = {};
    if (docFire.exists) {
      firabaseSettigs = {
        "apiKey": docFire.data()!.apiKey,
        "appID": docFire.data()!.appID,
        "messagingSenderId": docFire.data()!.messagingSenderId,
        "projectId": docFire.data()!.projectId,
      };
    }
    const ret = {
      "appConfig": appConfig,
      "appTheme": appTheme,
      "firebaseSettings": firabaseSettigs,
    };

    res.status(200).send(JSON.stringify(ret));
    return;
  } catch (e) {
    console.error(e);
    res.status(403).send(e);
    return;
  }
});
