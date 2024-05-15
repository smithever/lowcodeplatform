import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/db.dart';

class MngDataTablesSecurity extends StatefulWidget{
  MngDataTablesSecurity(
      {Key, key, required this.permission, required this.orgID, required this.user, required this.table, this.onChange}): super(key: key);

  final AppUser? user;
  final RolePermission permission;
  final String? orgID;
  final OrgDataTable table;
  final Function(List<RolePermission>?)? onChange;

  @override
  State<StatefulWidget> createState() => new _MngDataTablesSecurityState();
}

class _MngDataTablesSecurityState extends State<MngDataTablesSecurity>{
  final DatabaseService _db = DatabaseService();
  bool isNarrowLayout = false;
  bool _initDone = false;
  OrgDataTable _selTable = new OrgDataTable();
  List<RolePermission>? _rpList = <RolePermission>[];
  //TODO: Write a fetch next data on scroll controller

  @override
  void initState(){
    super.initState();
    initData();
  }

  void initData(){
    _selTable = widget.table;
    _rpList = _selTable.permissions;
    _rpList!.removeWhere((RolePermission rp) => rp.name == null);
    _initDone = true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: appBar() as PreferredSizeWidget?,
        body: _body(),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: widget.permission.c! ?
        FloatingActionButton(
          child: Icon(Icons.add),
            onPressed: (){
              _addNew();
            }
        )
            : null
    );
  }

  Widget appBar() {
    return new AppBar(
      title: Text('Table: ${_selTable.name} Security', style: TextStyle(fontSize: 14),),
      toolbarHeight: 40,
      actions: [

      ],
    );
  }

  Widget _body() {
    return tableList();
  }


  Widget tableList(){
    if(_rpList!.isNotEmpty) {
      print(_rpList!.first.toJson());
    }
    if(!_initDone){
      return ListTile(title: LinearProgressIndicator(),);
    }
    else{
      return Padding(
        padding: EdgeInsets.all(14),
        child: Container(
          child: Column(
            children:[
              if(_rpList!.isNotEmpty)
                Wrap(
                  children: List.generate(_rpList!.length, (int i) {
                    return new ExpansionTile(
                            title: Text(_rpList![i].name!),
                            children: <Widget>[
                              CheckboxListTile(
                                title: Text('Create'),
                                value: _rpList![i].c,
                                onChanged: (bool? val) {
                                  setState(() {
                                    _rpList![i].c = val;
                                  });
                                  widget.onChange!(_rpList);
                                },
                              ),
                              CheckboxListTile(
                                title: Text('Read'),
                                value: _rpList![i].r,
                                onChanged: (bool? val) {
                                  setState(() {
                                    _rpList![i].r = val;
                                  });
                                  widget.onChange!(_rpList);
                                },
                              ),
                              CheckboxListTile(
                                title: Text('Update'),
                                value: _rpList![i].u,
                                onChanged: (bool? val) {
                                  setState(() {
                                    _rpList![i].u = val;
                                  });
                                  widget.onChange!(_rpList);
                                },
                              ),
                              CheckboxListTile(
                                title: Text('Delete'),
                                value: _rpList![i].d,
                                onChanged: (bool? val) {
                                  setState(() {
                                    _rpList![i].d = val;
                                  });
                                  widget.onChange!(_rpList);
                                },
                              ),
                            ]);}).toList()
                )
            ]
          ),
        ),
      );
    }
  }

  Future<void> _addNew() async{
    List<UserRole> roleLst = await _db.allOrgUserRoles(widget.orgID);
    UserRole ur = await (showDialog<UserRole>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text("Select Role Permission"),
            children: [
              TypeAheadField<UserRole>(
                textFieldConfiguration: TextFieldConfiguration(
                    autofocus: false,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Search User Roles'
                    )
                ),
                suggestionsCallback: (String pattern) async {
                  if(pattern.length > 1) {
                    return roleLst.where((UserRole ur) => ur.name!.toLowerCase().contains(pattern.toLowerCase()));
                  }
                  else{
                    return <UserRole>[];
                  }
                },
                itemBuilder: (BuildContext context, UserRole suggestion) {
                  return ListTile(
                    title: Text(
                        suggestion.name!),
                  );
                },
                onSuggestionSelected: (suggestion) async {
                  Navigator.pop(context, suggestion);
                },
              ),
            ],
          );
        }
    ) as Future<UserRole>);
    if(ur.docID != null){
      _rpList!.add(new RolePermission(
          del: false,
          description: "For user role: ${ur.name} on data table: ${_selTable.name}",
          name: ur.name,
          hidden: false,
          roleID: ur.docID,
          c: false,
          r: false,
          u: false,
          d: false
      ));
      setState(() => _rpList);
      widget.onChange!(_rpList);
    }
  }

}