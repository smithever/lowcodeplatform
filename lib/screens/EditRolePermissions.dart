import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/db.dart';

class EditPermissionsPage extends StatefulWidget {
  EditPermissionsPage(
      {Key? key,
      required this.loggedUser,
      required this.orgID,
      required this.rolePermission,
      required this.selectedRole})
      : super(key: key);

  final AppUser? loggedUser;
  final RolePermission rolePermission;
  final UserRole selectedRole;
  final String? orgID;

  @override
  State<StatefulWidget> createState() => new _EditPermissionsPageState();
}

class _EditPermissionsPageState extends State<EditPermissionsPage> {
  bool flagGotData = false;
  final _db = DatabaseService();
  List<RolePermission> rolePermissions = <RolePermission>[];

  @override
  void initState() {
    setState(() => flagGotData = false);
    _db.getOrgRolePermissions(widget.selectedRole.docID, widget.orgID).then((ret) {
      rolePermissions.addAll(ret);
      _updateUserRolePages(widget.selectedRole.docID, rolePermissions);
      setState(() => flagGotData = true);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(appBar: appBar() as PreferredSizeWidget?, body: permList());
  }

  Widget appBar() {
    return new AppBar(
      title: Text('Edit ' + widget.selectedRole.name!, style: TextStyle(fontSize: 14),),
      toolbarHeight: 40,
      actions: <Widget>[
        new Icon(Icons.visibility),
        new Switch(
            value: !widget.selectedRole.hidden!,
            onChanged: (bool val) {
              _db.toggleOrgRoleHidden(widget.selectedRole.docID, !val, widget.orgID).then((ret){
                setState(() {
                  widget.selectedRole.hidden = !val;
                });
              });
            })
      ],
    );
  }

  Widget permList() {
    if (!flagGotData) {
      return ListTile(title: LinearProgressIndicator());
    }
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Divider(),
            Expanded(
              child: ListView.builder(
              itemCount: rolePermissions.length,
              itemBuilder: (context, index) {
                return ExpansionTile(
                    title: Text('Page: ' + rolePermissions[index].name!),
                    children: <Widget>[
                      CheckboxListTile(
                        title: Text('Create'),
                        value: rolePermissions[index].c,
                        onChanged: (bool? val) {
                          _db.updateOrgRolePermission(rolePermissions[index].docID, 'c', val, widget.orgID).then((ret){
                            setState(() {
                              rolePermissions[index].c = val;
                            });
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Read'),
                        value: rolePermissions[index].r,
                        onChanged: (bool? val) {
                          _db.updateOrgRolePermission(rolePermissions[index].docID, 'r', val, widget.orgID).then((ret){
                            setState(() {
                              rolePermissions[index].r = val;
                            });
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Update'),
                        value: rolePermissions[index].u,
                        onChanged: (bool? val) {
                          _db.updateOrgRolePermission(rolePermissions[index].docID, 'u', val, widget.orgID).then((ret){
                            setState(() {
                              rolePermissions[index].u = val;
                            });
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Delete'),
                        value: rolePermissions[index].d,
                        onChanged: (bool? val) {
                          _db.updateOrgRolePermission(rolePermissions[index].docID, 'd', val, widget.orgID).then((ret){
                            setState(() {
                              rolePermissions[index].d = val;
                            });
                          });
                        },
                      ),
                    ]);
              },
      ),
            ),
          ],
        ),
    );
  }

  void _updateUserRolePages(String? roleID, List<RolePermission> lstRP) async{
    List<AppPage> lstPages = await _db.getAppPages();
    lstPages.forEach((AppPage page) async{
      if(lstRP.firstWhereOrNull((rp) => rp.name == page.name) == null){
        RolePermission rp = new RolePermission(
          roleID: roleID,
          name: page.name,
          description: page.description,
          c: false,
          r: false,
          u: false,
          d: false,
          del: false,
          hidden: page.menu == 'main' ? false : true
        );
       rp.docID = await _db.addOrgRolePermission(rp, widget.orgID);
        setState(() {
          rolePermissions.add(rp);
        });
      }
    });
  }
}
