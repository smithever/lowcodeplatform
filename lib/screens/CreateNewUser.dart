import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/db.dart';
import 'package:validators/validators.dart' as validator;
import 'package:uuid/uuid.dart';

enum Menu { SignOut }

class CreateNewUserPage extends StatefulWidget {
  CreateNewUserPage(
      {Key? key,
      required this.loggedUser,
      required this.user,
      required this.isEdit,
      required this.orgID,
      required this.onNewUserCreated})
      : super(key: key);

  final AppUser? loggedUser;
  final AppUser user;
  final bool isEdit;
  final String? orgID;
  final void Function() onNewUserCreated;

  @override
  State<StatefulWidget> createState() => new _CreateNewUserPageState();
}

class _CreateNewUserPageState extends State<CreateNewUserPage> {
  final _formKey = GlobalKey<FormState>();
  AppUser _user = new AppUser();
  OrgUser _orgUser = new OrgUser();
  bool userEdit = false;
  UserRole? selectedRole;
  final _db = DatabaseService();
  List<UserRole> lstRoles = <UserRole>[];
  List<DropdownMenuItem> _lstDrpRoles = <DropdownMenuItem>[];
  bool initDone = false;

  OrgDataTable table = OrgDataTable();

  @override
  void initState() {
    super.initState();
    initData();
  }

  void initData() async{
    if(widget.isEdit){
      _user = widget.user;
      _orgUser = await _db.getOrgUser(_user.docID, widget.orgID);
      userEdit = true;
    }
    _lstDrpRoles = await buildDrpUserRole();
    print(_lstDrpRoles);
    setState(() {
      _orgUser =_orgUser;
      _user = _user;
      userEdit = userEdit;
      initDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: appBar() as PreferredSizeWidget?,
        body: initDone
            ? widget.orgID != null ?
                        new SingleChildScrollView(
                        scrollDirection: Axis.vertical, child: _regForm())
                        : Text("You must belong to an organization to create a new user. or alter an existing user")
            : new LinearProgressIndicator());
  }

  Widget appBar() {
    return new AppBar(
      title: userEdit ? Text('Edit user') : Text('Create new user'),
    );
  }

  Future<List<DropdownMenuItem<UserRole>>> buildDrpUserRole() async {
    print('Building UserRole dropdown items based on Logged in user');
    List<DropdownMenuItem<UserRole>> items = [];
      List<UserRole> ret = await _db.allOrgUserRoles(this.widget.orgID);
        ret.forEach((UserRole ur) {
          if(!ur.hidden! || widget.loggedUser!.priv!){
            if(userEdit && _orgUser.roleID == ur.docID){
              selectedRole = ur;
            }
            items.add(DropdownMenuItem<UserRole>(
                value: ur, child: Text(ur.name!)));
          }
        });
    return items;
  }

  Widget _regForm() {
    ProgressDialog pr = new ProgressDialog(context,
        message: Text("Loading..."), title: Text("Info!"));
    return Container(
      padding: const EdgeInsets.all(8.0),
      constraints: BoxConstraints(maxWidth: 400),
      child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text('Select Role'),
              ),
              DropdownButton<UserRole>(
                value: selectedRole, //initDone ? _lstDrpRoles[0].value : null,
                hint: Text('Select User Role'),
                onChanged: (val) {
                  setState(() {
                    selectedRole = val;
                    print(selectedRole!.name);
                  });
                },
                items: _lstDrpRoles as List<DropdownMenuItem<UserRole>>?,
              ),
              ListTile(
                title: Text('Login Details:'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email Address:'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (val) => _user.emailAddress = val,
                initialValue: userEdit ? _user.emailAddress : '',
                enabled: userEdit? false : true,
                textInputAction: TextInputAction.next,
                // The validator receives the text that the user has entered.
                validator: (String? val) {
                  if (!validator.isEmail(val!)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              if(!widget.isEdit)
              TextFormField(
                decoration: InputDecoration(labelText: 'Password:'),
                obscureText: true,
                textInputAction: TextInputAction.next,
                onSaved: (val) => _user.password = val,
                initialValue: userEdit ? _user.password : '',
                enabled: userEdit? false : true,
                // The validator receives the text that the user has entered.
                validator: (String? val) {
                  if (val!.length < 7) {
                    return 'Password must be a minimum of 7 characters';
                  }
                  _formKey.currentState!.save();
                  return null;
                },
              ),
              if(!widget.isEdit)
              TextFormField(
                decoration: InputDecoration(labelText: 'Repeat Password:'),
                obscureText: true,
                textInputAction: TextInputAction.next,
                initialValue: userEdit ? _user.password : '',
                enabled: userEdit? false : true,
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
                decoration: InputDecoration(labelText: 'First Name:'),
                textInputAction: TextInputAction.next,
                onSaved: (val) => _user.firstName = val,
                initialValue: userEdit ? _user.firstName : '',
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
                onSaved: (val) => _user.lastName = val,
                initialValue: userEdit ? _user.lastName : '',
                // The validator receives the text that the user has entered.
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please complete';
                  }
                  return null;
                },
              ),
              if(!widget.isEdit)
              TextFormField(
                decoration: InputDecoration(labelText: 'ID/Passport Number:'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSaved: (val) => _user.ID = val,
                initialValue: userEdit ? _user.ID : '',
                // The validator receives the text that the user has entered.
                validator: null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Cellphone:'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSaved: (val) => _user.cell = val,
                initialValue: userEdit ? _user.cell : '',
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
                    // If the form is valid, display a snackbar. In the real world,
                    // you'd often call a server or save the information in a database.
                    _formKey.currentState!.save();
                    if (selectedRole == null) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Info'),
                              content: Text('Please select role'),
                              actions: <Widget>[
                                new TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'))
                              ],
                            );
                          });
                    }
                    else if (userEdit) {
                      pr.show();
                      print('Updating User');
                      _user.roleID = selectedRole!.docID;
                      _user.lastUpdatedByUserID = widget.loggedUser!.docID;
                      _db.createNewUser(_user, false, widget.orgID).then((ret) {
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
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('OK'))
                                ],
                              );
                            });
                      });
                      }
                       else {
                      pr.show();
                          print('Creating new user');
                        _user.docID = Uuid().v4();
                        _user.createdByUserID = widget.loggedUser!.docID;
                        _user.del = false;
                        _user.priv = false;
                        _user.dateCreated = new DateTime.now();
                        _user.roleID = selectedRole!.docID;
                        _user.lastUpdatedByUserID = widget.loggedUser!.docID;
                        _db.createNewUser(_user, true, widget.orgID).then((ret) async{
                          print(ret.toString());
                          pr.dismiss();
                          _formKey.currentState!.reset();
                          widget.onNewUserCreated();
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
          ))
    );
  }
}
