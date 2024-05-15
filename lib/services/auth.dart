import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fireAuth;
import 'package:firebase_core/firebase_core.dart';

abstract class BaseAuth {
  Future<String> signIn(String? email, String? password);

  Future<String> signUp(String email, String password);

  Future<fireAuth.User?> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();
}
class Auth implements BaseAuth  {
  final fireAuth.FirebaseAuth _firebaseAuth = fireAuth.FirebaseAuth.instance;
  final fireAuth.FirebaseAuth _secondaryAuth = fireAuth.FirebaseAuth.instanceFor(app: Firebase.app("Secondary"));

  Future<String> signIn(String? email, String? password) async {
    //final prefs =  await SharedPreferences.getInstance();
    await _secondaryAuth.signInWithEmailAndPassword(
        email: email!, password: password!);
    var result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    fireAuth.User user = result.user!;
    //prefs.setString('f_user', jsonEncode(user));
    return user.uid;
  }

  Future<String> signUp(String email, String password) async {
    var result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    fireAuth.User user = result.user!;
    return user.uid;
  }

  Future<fireAuth.User?> getCurrentUser() async {
    fireAuth.User? user = _firebaseAuth.currentUser;
    return user;
  }

  Future<void> signOut() async {
    await _secondaryAuth.signOut();
    return await _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    fireAuth.User user = _firebaseAuth.currentUser!;
    user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    fireAuth.User user = _firebaseAuth.currentUser!;
    return user.emailVerified;
  }
}