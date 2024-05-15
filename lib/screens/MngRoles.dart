import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/screens/EditRolePermissions.dart';
import 'package:smith_base_app/services/db.dart';

class MngRolesPage extends StatefulWidget {
  MngRolesPage(
      {Key? key,
      required this.loggedUser,
      required this.pagePermission,
      required this.orgID,
      required this.editPagePermission})
      : super(key: key);

  final AppUser? loggedUser;
  final RolePermission pagePermission;
  final RolePermission editPagePermission;
  final String? orgID;

  @override
  State<StatefulWidget> createState() => new _MngRolesPageState();
}

class _MngRolesPageState extends State<MngRolesPage> {
  bool flagGotData = false;
  final _db = DatabaseService();
  List<UserRole> userRoles = <UserRole>[];
  final myController = TextEditingController();
  UserRole? replacementRole;
  List<AppPage> appPages = <AppPage>[];
  bool isNarrowLayout = true;
  UserRole _selectedRole = UserRole();

  @override
  void initState() {
    super.initState();
    initData();
  }

  void initData()async{
    userRoles = await _db.allOrgUserRoles(widget.orgID);
    appPages = await _db.getAppPages();
    appPages.removeWhere((AppPage page) => page.regOrgDB == false);
    setState(() => userRoles);
    setState(() => appPages);
    setState(() => flagGotData = true);
  }

  void updateDropDown(UserRole val){
    print('Select replacement role: ' + val.name!);
    setState(() {
      replacementRole = val;
    });
  }

  void addUserRole(String id, String name) {
    UserRole ur = new UserRole();
    ur.docID = id;
    ur.name = name;
    ur.del = false;
    ur.hidden = true;
    userRoles.add(ur);
    setState(() => userRoles);
  }

  @override
  Widget build(BuildContext context) {
    ProgressDialog pr = new ProgressDialog(context,message: Text("Loading..."), title: Text("Info!"));
    return new Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: appBar() as PreferredSizeWidget?,
      body: _body(),
      floatingActionButton: widget.pagePermission.c!
          ? FloatingActionButton(
              onPressed: () {
                //Navigator.pop(context);
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Create new Role"),
                        content: TextFormField(
                          controller: myController,
                          decoration: InputDecoration(labelText: 'Role Name:'),
                        ),
                        actions: <Widget>[
                          new TextButton(
                              onPressed: () {
                                print('Create new Role: ' + myController.text);
                                pr.show();
                                if(myController.text.length > 3){
                                  UserRole newRole = UserRole(
                                    name: myController.text,
                                    hidden: false,
                                    del: false
                                  );
                                  _db.addNewOrgRole(newRole, appPages, widget.orgID).then((ret){
                                  addUserRole(ret, myController.text);
                                  pr.dismiss();
                                  Navigator.pop(context);
                                  });
                                }
                                else{
                                  pr.dismiss();
                                }
                                },
                              child: Text('SAVE')),
                          new TextButton(
                              onPressed: () {Navigator.of(context).pop();},
                              child: Text('CANCEL'))
                        ],
                      );
                    });
                return;
              },
              child: Icon(Icons.add),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget appBar() {
    return new AppBar(
      title: Text('Manage User Roles', style: TextStyle(fontSize: 14),),
      toolbarHeight: 40,
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
    return roleList();
  }

  Widget _wideLayout(){
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: roleList(),
        ),
        if(_selectedRole.docID != null)
        Expanded(
            child: EditPermissionsPage(
              orgID: widget.orgID,
              rolePermission: widget.editPagePermission,
              loggedUser: widget.loggedUser,
              selectedRole: _selectedRole,
            )
        )
      ],
    );
  }

  Widget roleList() {
    if (!flagGotData) {
      return ListTile(title: LinearProgressIndicator());
    }
    return ListView.builder(
      itemCount: userRoles.length,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(userRoles[index].name!),
            onTap: () {
              _showBottom(userRoles[index]);
            });
      },
    );
  }

  void _showBottom(UserRole selRole) {
    List<DropdownMenuItem<UserRole>> dropItems = <DropdownMenuItem<UserRole>>[];
    userRoles.forEach((role){
      if(role.docID != selRole.docID){
        dropItems.add(new DropdownMenuItem<UserRole>(value: role, child: Text(role.name!)));
      }
    });
    ProgressDialog pr = new ProgressDialog(context,message: Text("Loading..."), title: Text("Info!"));
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
                        onPressed: widget.pagePermission.u!? () {
                          Navigator.pop(context);
                          if(isNarrowLayout) {
                            Navigator.push(context, MaterialPageRoute(builder: (
                                context) =>
                                EditPermissionsPage(
                                  orgID: widget.orgID,
                                  rolePermission: widget.editPagePermission,
                                  loggedUser: widget.loggedUser,
                                  selectedRole: selRole,
                                )));
                          }
                          else{
                            setState(() => {_selectedRole = selRole});
                          }
                        } : null,
                        child: Text("Update"))
                  ]),
                  TableRow(children: [
                    new TextButton(
                        onPressed: widget.pagePermission.d!? () {
                                showDialog<UserRole>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) => Dialog(
                                  child: Container(
                                      margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                      height: double.infinity,
                                      child: Column(
                                        children: <Widget>[
                                          Text("Are you sure you want to delete " +
                                              selRole.name! +
                                              ". This will affect multiple users, please select a role below to apply to the affected users"),
                                          new Row(
                                            children: <Widget>[
                                              DropdownButton<UserRole>(
                                                value: replacementRole,
                                                items: dropItems,
                                                hint: Text("Select Role"),
                                                onChanged: (val) {
                                                  Navigator.pop(context, val);
                                                  updateDropDown(val!);
                                                  pr.show();
                                                  if(replacementRole != null){
                                                    _db.deleteOrgRolePermission(selRole.docID, replacementRole!.docID, widget.orgID).then((ret){
                                                      pr.dismiss();
                                                      userRoles.remove(selRole);
                                                      setState(() => userRoles);
                                                    });
                                                  }
                                                  else{
                                                    pr.dismiss();
                                                  }
                                                },
                                              )
                                            ],
                                          ),
                                          new Row(
                                            children: <Widget>[
                                              new TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('Cancel')),
                                              ],
                                          )
                                        ],
                                      )
                                  ),
                                )
                             ).then((val) {
                               setState(() {
                                 print(val!.name);
                               });
                                });
                                return;
                        } : null,
                        child: Text("Delete"))
                  ]),
                  TableRow(children: [
                    new TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Back"))
                  ]),
                ],
              ));
        });
  }

}


