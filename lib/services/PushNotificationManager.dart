import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as fireAuth;
import 'package:smith_base_app/services/db.dart';

class PushNotificationsManager {

  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance = PushNotificationsManager._();
  final fireAuth.FirebaseAuth auth = fireAuth.FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final _db = DatabaseService();
  bool _initialized = false;

  Future<void> init(Function(String) launchCallback, Function(String) resumeCallback) async {
    if (!_initialized) {
      // For iOS request permission first.
      //Example of the what is received from Firebase:
      //{notification: {title: Tesing ppush, body: ifludlydlydlydlyd}, data: {messageID: VAVVad9gmGZglz0sfIFG}}
      _firebaseMessaging.requestPermission();
      //RemoteMessage message = await _firebaseMessaging.getInitialMessage();
      // _firebaseMessaging.configure(
      //   onMessage: (Map<String, dynamic> message) async {
      //     print("onMessage: $message");
      //     Fluttertoast.showToast(
      //       msg: 'New message received on chat: ' + message['notification']['title'],
      //       backgroundColor: Colors.red,
      //       textColor: Colors.white,
      //       toastLength: Toast.LENGTH_LONG
      //     );
      //   },
      //   onLaunch: (Map<String, dynamic> message) async {
      //     print("onLaunch: $message");
      //     if(message['data']['messageID'] != null) {
      //       launchCallback(message['data']['messageID']);
      //     }
      //   },
      //   onResume: (Map<String, dynamic> message) async {
      //     print("onResume: $message");
      //     if(message['data']['messageID'] != null) {
      //       resumeCallback(message['data']['messageID']);
      //     }
      //   },
      //   onBackgroundMessage: (Map<String, dynamic> message) async {
      //     print("onMessage: $message");
      //     Fluttertoast.showToast(
      //       msg: 'New message received on chat: ' + message['notification']['title'],
      //       backgroundColor: Colors.red,
      //       textColor: Colors.white,
      //       toastLength: Toast.LENGTH_LONG
      //     );
      //   },
      // );

      // For testing purposes print the Firebase Messaging token
      String? token = await _firebaseMessaging.getToken();
      fireAuth.User? user = auth.currentUser;
      print("FirebaseMessaging token: $token");
      if(user != null) {
        await _db.saveUserDeviceToken(token, user.uid);
      }
      _initialized = true;
    }
  }

}