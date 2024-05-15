import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/screens/AcceptTerms.dart';
import 'package:smith_base_app/screens/HomePage.dart';
import 'package:smith_base_app/screens/SignIn.dart';
import 'package:smith_base_app/services/auth.dart';
import 'package:smith_base_app/services/db.dart';

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
  EMAIL_NOT_VERIFIED,
  ACCEPT_TERMS
}

class RootPage extends StatefulWidget {
  RootPage({this.auth});

  final BaseAuth? auth;

  @override
  State<StatefulWidget> createState() => new _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final _db = DatabaseService();
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  AppUser loggedUser = new AppUser();
  bool status = false;
  bool goToMessage = false;
  Message message = new Message();
  bool showConnectionErrorP = false;
  bool initDone = false;

  @override
  void initState() {
    super.initState();
    print('Root page loaded');
    print('Retrieving remote config');
    initLoad();
  }

  Future<void> initLoad() async{
    try{
        User? user = await widget.auth!.getCurrentUser();
          if(user?.uid == null){
            print('Not logged in');
            authStatus = AuthStatus.NOT_LOGGED_IN;
          }
          else {
            print('Retrieving user data');
            this.loggedUser = await _db.getUser(user!.uid);
            if (this.loggedUser.docID != null) {
              bool isTermsAccepted = await _db.isUserTermsAccepted(user.uid);
              if(this.loggedUser.del!){
                print('This user was deleted');
                  widget.auth!.signOut();
                  authStatus = AuthStatus.NOT_LOGGED_IN;
              }
              else if(user.emailVerified == false){
                print('User email address is not verified');
                user.sendEmailVerification();
                  authStatus = AuthStatus.EMAIL_NOT_VERIFIED;
                widget.auth!.signOut();
              }
              else if(!isTermsAccepted){
                print('This user has not accepted Terms and Conditions yet');
                  authStatus = AuthStatus.ACCEPT_TERMS;
              }
              else{
                  authStatus = AuthStatus.LOGGED_IN;
              }
            }
            else{
              authStatus = AuthStatus.NOT_LOGGED_IN;
            }
          }
          setState(() => initDone = true);
    }catch(e){
      print('Root page try catch failed');
      authStatus = AuthStatus.NOT_LOGGED_IN;
        showConnectionErrorP = true;
      setState(() => initDone = true);
    }
  }

  void resumeCallback(String messageID)async{
    // print("Root Resume callback");
    // setState(() => goToMessage = true);
    // message = await _db.getMessage(messageID, );
    // if(message.docID != ''){
    //   if(message.to.contains(loggedUser.emailAddress)){
    //     UserMessage userMessage = await _db.getUserMessage(messageID, loggedUser.docID);
    //     message.userMessage = userMessage;
    //     setState(() => message);
    //     build(context);
    //   }
    //   else{
    //     setState(() => goToMessage = false);
    //   }
    // }else{
    //   setState(() => goToMessage = false);
    // }
  }

  void launchCallback(String messageID) async{
    // print("Root Launch callback");
    // setState(() => goToMessage = true);
    // message = await _db.getMessage(messageID);
    // if(message.docID != ''){
    //   if(message.to.contains(loggedUser.emailAddress)){
    //     UserMessage userMessage = await _db.getUserMessage(messageID, loggedUser.docID);
    //     message.userMessage = userMessage;
    //     setState(() => message);
    //   }
    //   else{
    //     setState(() => goToMessage = false);
    //   }
    // }else{
    //   setState(() => goToMessage = false);
    // }
  }

  void loginCallback() async {
    setState(()=> initDone = false);
    User? user = await widget.auth!.getCurrentUser();
      if(user != null ) {
        this.loggedUser = await _db.getUser(user.uid);
        var t = await user.getIdToken();
        this.loggedUser.token = t;
        bool isTermsAccepted = await _db.isUserTermsAccepted(user.uid);
        if (this.loggedUser.del!) {
          print('User deleted');
          widget.auth!.signOut();
          setState(() => authStatus = AuthStatus.NOT_LOGGED_IN);
        }
        else if (user.emailVerified == false) {
          setState(() => authStatus = AuthStatus.EMAIL_NOT_VERIFIED);
        }
        else if (!isTermsAccepted) {
          setState(() {
            authStatus = AuthStatus.ACCEPT_TERMS;
          });
        }
        else {
          setState(() {
            authStatus = AuthStatus.LOGGED_IN;
          });
        }
      }
    setState(()=> initDone = true);
  }

  void logoutCallback() {
    print("logout called in root");
    for(FirebaseApp app in Firebase.apps){
      FirebaseAuth.instanceFor(app: app).signOut();
    }
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      loggedUser = new AppUser();
    });
  }

  Widget buildWaitingScreen() {
    print('Root building the waiting screen.......');
    if(showConnectionErrorP == false){
        return Scaffold(
          body: Container(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          ),
        );
      }
      else{
        return Scaffold(
          body: Container(
            alignment: Alignment.center,
            child: Text("You're offline. Please check you're internet connection"),
          ),
        );
      }
  }

  Widget showEmailVerificationMessage() {
    print('Evert - Showing email verification dialog.....');
    return Scaffold(
      body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text("Please verify your email address before you can login. An email verification link was sent to " + loggedUser.emailAddress! + " kindly follow the email instructions."),
                )
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    setState(() {
                      authStatus = AuthStatus.NOT_LOGGED_IN;
                      loggedUser = new AppUser();
                    });
                  },
                )
              ],
            )
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Now rooting to the relevant page: ' + authStatus.toString());
    if(!initDone){return buildWaitingScreen();}
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
      case AuthStatus.NOT_LOGGED_IN:
        return new SignInPage(
          auth: widget.auth,
          loginCallback: loginCallback,
        );
      case AuthStatus.LOGGED_IN:
        print("Logged User ID: " + loggedUser.docID.toString());
          return new HomePage(
            user: this.loggedUser,
            onLogOutCallBack: logoutCallback,
          );
      case AuthStatus.EMAIL_NOT_VERIFIED:
        return showEmailVerificationMessage();
      case AuthStatus.ACCEPT_TERMS:
        return new AcceptTermsPage(
          auth: widget.auth,
          loggedUser: loggedUser,
          logoutCallback: logoutCallback,
          loginCallBack: loginCallback,
        );
      default:
        return buildWaitingScreen();
    }
  }

}

