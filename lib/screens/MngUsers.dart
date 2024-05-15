import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/screens/CreateNewUser.dart';
import 'package:smith_base_app/services/db.dart';


enum Menu { SignOut }

class MngUsersPage extends StatefulWidget {
  MngUsersPage(
      {Key? key,
      required this.user,required this.permission, required this.orgID, required this.onCloseCallBack})
      : super(key: key);

  final AppUser? user;
  final RolePermission permission;
  final String? orgID;
  final void Function() onCloseCallBack;
  final TextEditingController controller = new TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  State<StatefulWidget> createState() => new _MngUsersPageState();
}

class _MngUsersPageState extends State<MngUsersPage> {
  final _db = DatabaseService();
  List<AppUser> _users = <AppUser>[];
  ScrollController _controller = ScrollController();
  bool flagGotData = false;
  bool _noData = true;
  String _qString = '';
  bool showFilter = false;
  bool isNarrowLayout = true;
  bool _fetchingNext = false;
  AppUser _selUser = AppUser();
  bool newUser = false;

  void _toggleFilter(){
    showFilter = !showFilter;
    setState(()=> showFilter);
  }

  @override
  void initState() {
    widget.controller.text = _qString;
    _controller.addListener(_scrollListner);
    filterUsers(_qString);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.onCloseCallBack();
  }

  void _scrollListner() async{
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      print("at the end of list");
      setState(() => _fetchingNext = true);
      List qArray = _qString.split(' ');
      String q = qArray[0];
      List<AppUser> users = await _db.getNextUsers(25, widget.orgID, q, _users.last);
      if (users.length > 0) {
        users.forEach((AppUser user) {
          int len = qArray.length;
          int count = 0;
          qArray.forEach((item) {
            if (user.qString
                .toString()
                .contains(item.toString().toLowerCase())) {
              count++;
            }
          });
          if (len == count && (widget.user!.priv! || user.priv == false)) {
            _users.add(user);
          }
        });
        setState(() => _users);
      }
      setState(() {
        _fetchingNext = false;
      });
    }
  }

  void filterUsers(String query) async {
    try {
      setState(() {
        flagGotData = false;
      });
      _users.clear();
      setState(() => _users);
      List qArray = _qString.split(' ');
      String q = qArray[0];
      List<AppUser> users = await _db.getUsers(20, widget.orgID, q);
        print('Users retured from DB: ' + users.length.toString());
        if (users.length > 0) {
          users.forEach((AppUser user) {
            int len = qArray.length;
            int count = 0;
            qArray.forEach((item) {
              if (user.qString
                  .toString()
                  .contains(item.toString().toLowerCase())) {
                count++;
              }
            });
            if (len == count && (widget.user!.priv! || user.priv == false)) {
              _users.add(user);
            }
          });
          setState(() {
            flagGotData = true;
            _noData = false;
          });
          setState(() => _users);
          setState(() {
            flagGotData = true;
          });
        } else {
          _noData = true;
          setState(() => _noData);
          setState(() {
            flagGotData = true;
          });
        }
    } catch (e) {
      _noData = true;
      setState(() => _noData);
      setState(() {
        flagGotData = true;
      });
      print('User filter broke.' + e.toString());
    }
  }

  void _showBottom(AppUser user) {
    showModalBottomSheet<void>(
        context: context,
        /*bottom sheet is like a drawer that pops off where you can put any
      controls you want, it is used typically for user notifications*/
        //builder lets your code generate the code
        builder: (BuildContext context) {
          return new Container(
              child: new Table(
            children: [
              TableRow(children: [
                new TextButton(
                    onPressed: widget.permission.u!
                        ? () {
          if(isNarrowLayout) {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        CreateNewUserPage(
                          loggedUser: widget.user,
                          user: user,
                          isEdit: true,
                          orgID: widget.orgID,
                          onNewUserCreated: ()=>{filterUsers(_qString)},
                        )));
          }
          else{
            setState(() {
              newUser = false;
              _selUser = user;
            });
          }
                          }
                        : null,
                    child: Text("Update"))
              ]),
              TableRow(children: [
                new TextButton(
                    onPressed: widget.permission.d!
                        ? () {
                            Navigator.of(context).pop();
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Alert!"),
                                    content: Text(
                                        "Are you sure you want to delete " +
                                            user.firstName! +
                                            ' ' +
                                            user.lastName!),
                                    actions: <Widget>[
                                      new TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel')),
                                      new TextButton(
                                          onPressed: () async {
                                            await _db.deleteUser(user.docID, widget.orgID);
                                            _users.remove(user);
                                            setState(() => _users);
                                            Navigator.pop(context);
                                          },
                                          child: Text('Yes'))
                                    ],
                                  );
                                });
                            return;
                          }
                        : null,
                    child: Text("Delete"))
              ]),
              TableRow(children: [
                new TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Back"))
              ]),
            ],
          ));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBar() as PreferredSizeWidget?,
      body: _body(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: widget.permission.c!
          ? FloatingActionButton(
              onPressed: () {
                if(isNarrowLayout) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CreateNewUserPage(
                                loggedUser: widget.user,
                                user: new AppUser(),
                                isEdit: false,
                                orgID: widget.orgID,
                                onNewUserCreated: () => {filterUsers(_qString)},
                              )));
                }
                else{
                  setState(() {
                    _selUser = new AppUser();
                    newUser = true;
                  });
                }
              },
              child: Icon(Icons.add),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _body() {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      if(constraints.maxWidth > 600){
        isNarrowLayout = false;
        return _wideLayout();
      }
      else{
        isNarrowLayout = true;
        return _narrowLayout();
      }
    });
  }

  Widget _narrowLayout() {
    return _usersList();
  }

  Widget _wideLayout(){
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: _usersList(),
        ),
        if(_selUser.docID != null && !newUser)
          Expanded(
              child: CreateNewUserPage(
                loggedUser: widget.user,
                user: _selUser,
                isEdit: true,
                orgID: widget.orgID,
                onNewUserCreated: () => {filterUsers(_qString)},
              )
          ),
        if(_selUser.docID == null && newUser)
          Expanded(
              child: CreateNewUserPage(
                loggedUser: widget.user,
                user: new AppUser(),
                isEdit: false,
                orgID: widget.orgID,
                onNewUserCreated: () => {filterUsers(_qString)},
              )
          ),
      ],
    );
  }

  Widget appBar() {
    return new AppBar(
      title: Text('Manage User', style: TextStyle(fontSize: 14),),
      toolbarHeight: 40,
      actions: [
        IconButton(icon: Icon(Icons.search), onPressed: () => {_toggleFilter()})
      ],
    );
  }

  Widget _usersList() {
    if (!flagGotData) {
      return ListTile(title: LinearProgressIndicator());
    }
    else {
      return Container(
        child: Column(
          children: <Widget>[
            Visibility(
                visible: showFilter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onSubmitted: (val) {
                      if (val.length > 3) {
                        _qString = val;
                        filterUsers(val);
                      }
                    },
                    controller: widget.controller,
                    key: widget._formKey,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: "Search",
                        hintText: "eg. John Smith",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(25.0)))),
                  ),
                )
            ),
            Expanded(
              child: _users.isNotEmpty
                  ? ListView.builder(
                shrinkWrap: true,
                controller: _controller,
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_users[index].firstName! +
                        ' ' +
                        _users[index].lastName!),
                    subtitle: Text(_users[index].emailAddress!),
                    onTap: () {
                      _showBottom(_users[index]);
                    },
                  );
                },
              )
                  : Text('No items'),
            ),
            Visibility(
              visible: _fetchingNext,
              child: ListTile(title: LinearProgressIndicator()),
            ),
          ],
        ),
      );
    }
  }
}
