import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/auth.dart';
import 'package:smith_base_app/services/db.dart';
import 'package:validators/validators.dart' as validator;

class SignUpPage extends StatefulWidget {
  SignUpPage({Key? key, @required this.auth, @required this.loginCallBack})
      : super(key: key);

  final BaseAuth? auth;
  final Function? loginCallBack;

  @override
  State<StatefulWidget> createState() => new _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  AppUser _user = new AppUser();
  String? selectedRoleID;
  final _db = DatabaseService();
  bool initDone = false;

  @override
  void initState() {
    setRoleID().then((void n) {
      setState(() => initDone = true);
    });
    super.initState();
  }
  
  Future<void> setRoleID() async{
    print('Getting remote config');
    // final RemoteConfig remoteConfig = await RemoteConfig.instance;
    // await remoteConfig.fetch(expiration: const Duration(hours: 5));
    // await remoteConfig.activateFetched();
    // selectedRoleID =  remoteConfig.getString("parentRoleID");
    GeneralConfig gen = await _db.getGeneralConfig();
    selectedRoleID = gen.newUserID;
    return print("RemoteConfig retrieved: " + selectedRoleID!);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: appBar() as PreferredSizeWidget?,
        body: initDone
            ? new SingleChildScrollView(
            scrollDirection: Axis.vertical, child: _regForm())
            : new LinearProgressIndicator());
  }

  Widget appBar(){
    return new AppBar(
      title: Text('SignUp Page'),
    );
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
              decoration: InputDecoration(labelText: 'Email Address: *'),
              keyboardType: TextInputType.emailAddress,
              onSaved: (val) => _user.emailAddress = val,
              textInputAction: TextInputAction.next,
              // The validator receives the text that the user has entered.
              validator: (String? val) {
                if (!validator.isEmail(val!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password: *'),
              obscureText: true,
              textInputAction: TextInputAction.next,
              onSaved: (val) => _user.password = val,
              // The validator receives the text that the user has entered.
              validator: (String? val) {
                if (val!.length < 7) {
                  return 'Password must be a minimum of 7 characters';
                }
                _formKey.currentState!.save();
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Repeat Password: *'),
              obscureText: true,
              textInputAction: TextInputAction.next,
              // The validator receives the text that the user has entered.
              validator: (String? val) {
                if (val!.length < 7) {
                  return 'Password must be a minimum of 7 characters';
                } else if (_user.password != null && val != _user.password) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            ListTile(
              title: Text('Personal Details:'),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'First Name: *'),
              textInputAction: TextInputAction.next,
              onSaved: (val) => _user.firstName = val,
              // The validator receives the text that the user has entered.
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please complete';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Last Name: *'),
              textInputAction: TextInputAction.next,
              onSaved: (val) => _user.lastName = val,
              // The validator receives the text that the user has entered.
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please complete';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Cellphone: *'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onSaved: (val) => _user.cell = val,
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
                  _user.roleID = selectedRoleID;
                  _user.lastUpdatedByUserID = null;
                    print('Creating new user with roleID $selectedRoleID');
                    if (selectedRoleID == null) {
                      pr.dismiss();
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Info'),
                              content: Text('Something has gone wrong. Creation of new User role is not allowed. Please contact support for assistance'),
                              actions: <Widget>[
                                new TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'))
                              ],
                            );
                          });
                    } else {
                      _user.createdByUserID = null;
                      _user.del = false;
                      _user.priv = false;
                      _user.dateCreated = new DateTime.now();
                      _user.ID = null;
                      _user.orgIDs = [""];
                      _db.signUpNewUser(_user).then((ret) async{
                        print(ret.toString());
                        pr.dismiss();
                        _formKey.currentState!.reset();
                        Navigator.of(context).pop();
                        return showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Completed"),
                                content: Text(ret),
                                actions: <Widget>[
                                  new TextButton(
                                      onPressed: () {
                                        widget.loginCallBack!;
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('OK'))
                                ],
                              );
                            });
                      });
                    }
                }
              },
              child: Text('Submit'),
            )
          ],
        ));
  }
}