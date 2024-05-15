import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/dataTablePackage/EditDataTable.dart';
import 'package:smith_base_app/dataTablePackage/MngTableData.dart';
import 'package:smith_base_app/services/db.dart';

class MngDataTables extends StatefulWidget{
  MngDataTables(
  {Key, key, required this.permission, required this.orgID, required this.user, required this.userOrgRole}): super(key: key);

  final AppUser? user;
  final RolePermission permission;
  final String? orgID;
  final UserRole userOrgRole;

  @override
  State<StatefulWidget> createState() => new _MngDataTablesState();
}

class _MngDataTablesState extends State<MngDataTables>{
  final DatabaseService _db = DatabaseService();
  bool isNarrowLayout = false;
  bool _initDone = false;
  List<OrgDataTable> _dataTables = <OrgDataTable>[];
  OrgDataTable _selTable = new OrgDataTable();
  ScrollController _controller = ScrollController();
  //TODO: Write a fetch next data on scroll controller
  bool newTable = false;

  @override
  void initState(){
    initData();
    super.initState();
  }

  void initData() async{
    setState(()=> _initDone = false);
    _dataTables = await _db.getDataTables(widget.orgID!);
    setState(()=> _initDone = true);
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
                  if(isNarrowLayout){
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => EditDataTablePage(
                          user: widget.user,
                          orgID: widget.orgID,
                          isEdit: false,
                          dataTable: new OrgDataTable(),
                          onNewTableCreated: (){
                            initData();
                          },
                          permission: widget.permission,
                      ))
                    );
                  }
                  else{
                    setState(() {
                      _selTable = new OrgDataTable(docID: "new");
                      newTable = true;
                    });
                  }
                }
            )
            : null
    );
  }

  Widget appBar() {
    return new AppBar(
      title: Text('Manage Data Tables', style: TextStyle(fontSize: 14),),
      toolbarHeight: 40,
      actions: [

      ],
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

  Widget _narrowLayout(){
    return tableList();
  }

  Widget _wideLayout(){
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: tableList(),
        ),
        if(_selTable.docID != null)
          Expanded(child:
            EditDataTablePage(
              isEdit: !newTable,
              orgID: widget.orgID,
              dataTable: _selTable,
              onNewTableCreated: (){

              },
              user: widget.user,
              permission: widget.permission,
            )
          )
      ],
    );
  }

  Widget tableList(){
    if(!_initDone){
      return ListTile(title: LinearProgressIndicator(),);
    }
    else{
      return Container(
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
                    shrinkWrap: true,
                    controller: _controller,
                    itemCount: _dataTables.length,
                    itemBuilder: (BuildContext context, index){
                      return ListTile(
                        title: Text(_dataTables[index].name!),
                        subtitle: Text(_dataTables[index].description!),
                        onTap: (){
                            _showBottom(_dataTables[index]);
                        },
                      );
                    }
                )
            )
          ],
        ),
      );
    }
  }

  void _showBottom(OrgDataTable table) {
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
                        onPressed: widget.permission.r!
                            ? () {
                          if(isNarrowLayout){
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => MngTableData(
                                    permission: getUserTablePermission(table),
                                    orgID: widget.orgID,
                                    user: widget.user,
                                    table: table
                                )
                                )
                            );
                          }
                          else{
                            setState(() {
                              _selTable = table;
                              newTable = false;
                            });
                          }
                        }
                            : null,
                        child: Text("View Records"))
                  ]),
                  TableRow(children: [
                    new TextButton(
                        onPressed: widget.permission.u!
                            ? () {
                          if(isNarrowLayout){
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => EditDataTablePage(
                                    user: widget.user,
                                    orgID: widget.orgID,
                                    isEdit: true,
                                    dataTable: table,
                                    onNewTableCreated: (){
                                      initData();
                                    },
                                  permission: widget.permission,
                                ))
                            );
                          }
                          else{
                            setState(() {
                              _selTable = table;
                              newTable = false;
                            });
                          }
                        }
                            : null,
                        child: Text("Configuration"))
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
                                          table.name!),
                                  actions: <Widget>[
                                    new TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel')),
                                    new TextButton(
                                        onPressed: () async {

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

  RolePermission getUserTablePermission(OrgDataTable table){
    print("User org role id: ${widget.userOrgRole.docID}");
    return table.permissions!.firstWhere((RolePermission rp) => rp.roleID == widget.userOrgRole.docID, orElse: (){return new RolePermission(
      roleID: widget.user!.roleID,
      c: false,
      r: false,
      u: false,
      d: false,
      hidden: false,
      name: "TempPermission",
      description: "",
      del: false,
      docID: ""
    );});
  }
}