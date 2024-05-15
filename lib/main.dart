import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/screens/ErrorPage.dart';
import 'package:smith_base_app/services/AppStateNotifier.dart';
import 'package:smith_base_app/services/auth.dart';
import 'package:smith_base_app/services/root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
      ChangeNotifierProvider<ThemeChanger>(
          create: (_) => ThemeChanger(ThemeData.dark(), MaterialColor(0xFF990000, color)),
          child: new App()
      ));
}

class App extends StatelessWidget {
  // Create the initialization Future outside of `build`:
  //final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: initFirebase(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return MaterialApp(
              home: new ErrorPage(
                        errorMessage: new ErrorMessage(
                        title: "App failed to start",
                        details: snapshot.error.toString()
                      ),
          ));
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          print('Your app is starting up');
          final theme = Provider.of<ThemeChanger>(context);
          return MaterialApp(
            title: 'BaseApp',
            theme: theme.getTheme().copyWith(
                primaryColor: theme.getThemeColor(),
                buttonColor: theme.getThemeColor(),
            ),
            home: new RootPage(auth: new Auth()),
          );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator(),),));
      },
    );
  }

  Future<void> initFirebase() async{
    await Firebase.initializeApp();
    if(Firebase.apps.length < 2) {
      await Firebase.initializeApp(name: 'Secondary',
          options: FirebaseOptions(
              apiKey: "x",
              appId: "x",
              projectId: "x",
              messagingSenderId: "none"));
    }
    }
}

Map<int, Color> color = {
  50: Color.fromRGBO(255, 92, 87, .1),
  100: Color.fromRGBO(255, 92, 87, .2),
  200: Color.fromRGBO(255, 92, 87, .3),
  300: Color.fromRGBO(255, 92, 87, .4),
  400: Color.fromRGBO(255, 92, 87, .5),
  500: Color.fromRGBO(255, 92, 87, .6),
  600: Color.fromRGBO(255, 92, 87, .7),
  700: Color.fromRGBO(255, 92, 87, .8),
  800: Color.fromRGBO(255, 92, 87, .9),
  900: Color.fromRGBO(255, 92, 87, 1),
};