import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fireAuth;
import 'package:smith_base_app/screens/SignUp.dart';
import 'package:smith_base_app/services/auth.dart';

class SignInPage extends StatefulWidget {
  SignInPage({this.auth, this.loginCallback});

  final BaseAuth? auth;
  final VoidCallback? loginCallback;

  @override
  State<StatefulWidget> createState() => new _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final fireAuth.FirebaseAuth _firebaseAuth = fireAuth.FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isLoginForm = true;
  final _formKey = new GlobalKey<FormState>();
  String? _email;
  String? _password;
  String? _errorMessage;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState!;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("BaseApp"),
        ),
        body: Stack(
          children: <Widget>[_showForm(), _showCircularProgress()],
        ));
  }

  Widget _showForm() {
    return new Center(child: Container(
      constraints: BoxConstraints(minWidth: 200, maxWidth: 400),
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              showLogo(),
              showEmailInput(),
              showPasswordInput(),
              showPrimaryButton(),
              showErrorMessage(),
              _showForgotPasswordButton(),
              _showRegisterParent()
            ],
          ),
        )));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 50.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/Smart LDS Logo.png'),
        ),
      ),
    );
  }

  Widget showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) => value!.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value!.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value!.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => _password = value!.trim(),
      ),
    );
  }

  Widget showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new ElevatedButton(
            style: ButtonStyle(
              elevation: MaterialStateProperty.all<double>(5.0),
            ),
            child: new Text(_isLoginForm ? 'Login' : 'Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ));
  }

  Widget _showForgotPasswordButton() {
    return new TextButton(
        child: Text('Forgot password?',
            style: new TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          if (validateAndSave()) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Forgot Password"),
                  content: Text(
                      "Password reset email sent. Please refer to the email for further instructions"),
                  actions: [
                    TextButton(
                      child: Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _firebaseAuth.sendPasswordResetEmail(email: _email!);
                      },
                    ),
                  ],
                );
              },
            );
          }
        });
  }

  Widget _showRegisterParent() {
    return new TextButton(
        child: Text('Register new user',
            style: new TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SignUpPage(
                    auth: widget.auth,
                    loginCallBack: widget.loginCallback,
                  ))).then((val){
            widget.loginCallback!();
          });
        });
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    _isLoginForm = true;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState!.reset();
    _errorMessage = "";
  }

  void toggleFormMode() {
    resetForm();
    setState(() {
      _isLoginForm = !_isLoginForm;
    });
  }

  Widget showErrorMessage() {
    if (_errorMessage!.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage!,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        if (_isLoginForm) {
          userId = await widget.auth!.signIn(_email, _password);
          print('Signed in: $userId');
        } else {

        }
        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 &&  _isLoginForm) {
          widget.loginCallback!();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _formKey.currentState!.reset();
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }
}
