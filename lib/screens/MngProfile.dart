import 'package:firebase_auth/firebase_auth.dart' as fireAuth;
import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/db.dart';
import 'package:validators/validators.dart' as validator;

class MngProfilePage extends StatefulWidget {
  MngProfilePage(
      {Key? key,
        this.loggedUser})
      : super(key: key);

  final AppUser? loggedUser;

  @override
  State<StatefulWidget> createState() => new _MngProfilePageState();
}

class _MngProfilePageState extends State<MngProfilePage> {
  final _formKey = GlobalKey<FormState>();
  var _formKey2 = GlobalKey<FormState>();
  AppUser? _user = new AppUser();
  final _db = DatabaseService();
  bool initDone = false;
  String? _errorMessage = '';

  @override
  void initState() {
    _user = widget.loggedUser;
    initDone = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: appBar() as PreferredSizeWidget?,
        body: initDone
            ? new SingleChildScrollView(
            scrollDirection: Axis.vertical, child: Padding(child: _regForm(), padding: EdgeInsets.all(10.0)))
            : new LinearProgressIndicator());
  }

  Widget appBar() {
    return new AppBar(
      title: Text('My Profile'),
    );
  }

  Widget showErrorMessage() {
    if (_errorMessage != '' && _errorMessage != null) {
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

  Widget _regForm() {
    ProgressDialog pr = new ProgressDialog(context,
        message: Text("Loading..."), title: Text("Info!"));
    return new Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text('Login Details:'),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Email Address:'),
              keyboardType: TextInputType.emailAddress,
              onSaved: (val) => _user!.emailAddress = val,
              initialValue: _user!.emailAddress,
              enabled: false,
              textInputAction: TextInputAction.next,
              // The validator receives the text that the user has entered.
              validator: (String? val) {
                if (!validator.isEmail(val!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            TextButton(
              child: Text("Change Password"),
              onPressed: () async{
                 await _changePassword();
              },
            ),
            ListTile(
              title: Text('Personal Details:'),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'First Name:'),
              textInputAction: TextInputAction.next,
              onSaved: (val) => _user!.firstName = val,
              initialValue: _user!.firstName,
              // The validator receives the text that the user has entered.
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please complete';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Last Name:'),
              textInputAction: TextInputAction.next,
              onSaved: (val) => _user!.lastName = val,
              initialValue: _user!.lastName,
              // The validator receives the text that the user has entered.
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please complete';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'ID/Passport Number:'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onSaved: (val) => _user!.ID = val,
              initialValue: _user!.ID,
              // The validator receives the text that the user has entered.
              validator: null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Cellphone:'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onSaved: (val) => _user!.cell = val,
              initialValue: _user!.cell,
              // The validator receives the text that the user has entered.
              validator: (value) {
                if (validator.isNumeric(value!) && value.length < 10) {
                  return 'Please enter a valid cellphone number';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: () {
                // Validate returns true if the form is valid, otherwise false.
                if (_formKey.currentState!.validate()) {
                  pr.show();
                  // If the form is valid, display a snackbar. In the real world,
                  // you'd often call a server or save the information in a database.
                  _formKey.currentState!.save();
                  _user!.roleID = widget.loggedUser!.roleID;
                  _user!.lastUpdatedByUserID = widget.loggedUser!.docID;
                    print('Updating User');
                    _db.updateUser(_user!).then((ret) {
                      print(ret.toString());
                      pr.dismiss();
                      _formKey.currentState!.reset();
                      return showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Completed"),
                              content: Text(ret),
                              actions: <Widget>[
                                new TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'))
                              ],
                            );
                          });
                    });
                }
              },
              child: Text('Submit'),
            )
          ],
        ));
  }

  Future<Widget?> _changePassword(){
    ProgressDialog pr = new ProgressDialog(context,
        message: Text("Loading..."), title: Text("Info!"));
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          String? password = '';
          String? currPassword = '';
          return AlertDialog(
            content: Form(
              key: _formKey2,
              child: SingleChildScrollView(child: Container(
                height: 400,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(1.0),
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'Current Password:'),
                        obscureText: true,
                        onSaved: (val) => currPassword = val,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator: (String? val) {
                          if (val!.length < 7) {
                            return 'Password must be a minimum of 7 characters';
                          }
                          _formKey2.currentState!.save();
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(1.0),
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'New Password:'),
                        obscureText: true,
                        onSaved: (val) => password = val,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator: (String? val) {
                          if (val!.length < 7) {
                            return 'Password must be a minimum of 7 characters';
                          }
                          _formKey2.currentState!.save();
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(1.0),
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'Repeat New Password:'),
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (String? val) {
                          if (val!.length < 7) {
                            return 'Password must be a minimum of 7 characters';
                          } else if (password != null && val != password) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                    ElevatedButton(
                      child: Text("Save"),
                      onPressed: () async {
                        if (_formKey2.currentState!.validate()) {
                          pr.show();
                          _formKey2.currentState!.save();
                          try {
                            var ar = await fireAuth.FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                email: _user!.emailAddress!,
                                password: currPassword!);
                            fireAuth.User user = ar.user!;
                            await user.updatePassword(password!);
                            Future.delayed(Duration(seconds: 1)).then((q){
                              Navigator.of(context).pop();
                            });
                          }catch(e){
                            fireAuth.FirebaseException ex = e as fireAuth.FirebaseException;
                            setState(() => _errorMessage = ex.message);
                          }
                          pr.dismiss();
                        }
                      },
                    ),
                    showErrorMessage(),
                  ],
                ),
              ),),
            ),
          );
        });
  }
}
