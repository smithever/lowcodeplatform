import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/dataTablePackage/EditRecord.dart';
import 'package:smith_base_app/services/CommonFunctions.dart';
import 'package:smith_base_app/services/db.dart';

class MngTableData extends StatefulWidget{
  MngTableData(
      {Key, key, required this.permission, required this.orgID, required this.user, required this.table}): super(key: key);

  final AppUser? user;
  final RolePermission permission;
  final String? orgID;
  final OrgDataTable table;

  @override
  State<StatefulWidget> createState() => new _MngTableDataState();
}

class _MngTableDataState extends State<MngTableData>{
  final DatabaseService _db = DatabaseService();
  final CommonFunctionsService _common = CommonFunctionsService();
  final TextEditingController _searchController = TextEditingController();
  bool isNarrowLayout = false;
  bool _initDone = false;
  List<DataRecord> _records = <DataRecord>[];
  List<DataRecord> _selectedRecords = <DataRecord>[];
  List<String?> _columnNames = <String>[];
  String _searchString = "";

  @override
  void initState(){
    initData();
    super.initState();
  }

  //TODO: Add Excel import and Export functionality
  //TODO: Add Manage DataRecord Media functionality

  Future<void> initData() async{
    _columnNames = widget.table.getKeys();
    try {
      _records = await _db.getDataRecords(
          widget.orgID, widget.table.docID, 50, _searchString);
    }catch(e){
      ErrorLog log = new ErrorLog(
        logTime: DateTime.now(),
        module: "Table: ${widget.table.name}. Failed to retrieve data from database",
        userID: widget.user!.docID,
        message: e.toString(),
      );
      _db.addErrorLog(widget.orgID!, log);
      print("NOW PRINTING ERROR");
      print(e.toString());
      if(e.toString().contains("The query requires an index")){
        _common.showMessage("Error!", "Could not search records. Possible missing database index", context);
      }
    }
    _selectedRecords = <DataRecord>[];
    setState(() {
      _initDone = true;
    });
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: widget.permission.c! ?
        FloatingActionButton(
          child: Icon(Icons.add),
            onPressed: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context){
                  return EditRecordForm(
                      permission: widget.permission,
                      orgID: widget.orgID,
                      user: widget.user,
                      isEdit: false,
                      record: new DataRecord(),
                      table: widget.table,
                      onSuccess: (DataRecord record){
                        setState(() {
                          _records.add(record);
                        });
                      },
                  );
                }));
            }
        )
            : null
    );
  }

  Widget appBar() {
    return new AppBar(
      title: Text('${widget.table.name} - Data Records', style: TextStyle(fontSize: 14),),
      toolbarHeight: 40,
      actions: [
        if(_selectedRecords.length == 1)
          IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
        if(_selectedRecords.length > 0)
          IconButton(icon: Icon(Icons.delete), onPressed: onDelete),
        IconButton(icon: Icon(Icons.search), onPressed: onSearch),
      ],
    );
  }

  onEdit(){
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context){
      return EditRecordForm(
        permission: widget.permission,
        orgID: widget.orgID,
        user: widget.user,
        isEdit: true,
        record: _selectedRecords.first,
        table: widget.table,
        onSuccess: (DataRecord record){
          _records.remove(record);
          _records.add(record);
          setState(()=> _records);
        },
      );
    }));
  }

  onDelete(){
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Warning!"),
            content: Text("Are you sure! If you continue these items will be permanently deleted"),
            actions: <Widget>[
              new TextButton(
                  onPressed: () async{
                    ProgressDialog pr = new ProgressDialog(context,
                        message: Text("Loading..."), title: Text("Info!"));
                    Navigator.of(context).pop();
                    pr.show();
                    try {
                      await _db.deleteDataRecords(
                          widget.orgID!, widget.table.docID, _selectedRecords);
                      pr.dismiss();
                      for(DataRecord r in _selectedRecords){
                        _records.remove(r);
                      }
                      setState(()=> _records);
                    }catch(e){
                      pr.dismiss();
                      ErrorLog log = new ErrorLog(
                        logTime: DateTime.now(),
                        userID: widget.user!.docID,
                        module: "Table: ${widget.table.name} DataRecord bulk delete",
                        message: e.toString()
                      );
                      _db.addErrorLog(widget.orgID!, log);
                      _common.showMessage("Error!", "Delete failed", context);
                    }
                  },
                  child: Text('DELETE ITEMS!')),
              new TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'))
            ],
          );
        });
  }

  onSearch(){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20.0)), //this right here
            child: Container(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                          hintText: 'What would you like to search for?'),
                    ),
                    SizedBox(
                      width: 320.0,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                            setState(() {
                              _searchString = _searchController.value.text;
                            });
                            initData();
                        },
                        child: Text(
                          "Search",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _body() {
    return InteractiveViewer(
      child: table(),
    );
  }


  Widget table(){
    if(!_initDone){
      return ListTile(title: LinearProgressIndicator(),);
    }
    else{
      return Container(
        child: Column(
          children: [
            Expanded(
                child: _records.isEmpty || _columnNames.isEmpty ? Container(child: Text("No records in table"),) : Wrap(
                  children: [
                    DataTable(
                      onSelectAll: (bool? sel){
                        if(sel!){
                          setState(() {
                            _selectedRecords = _records;
                          });
                        }else{
                          setState(() {
                            _selectedRecords = <DataRecord>[];
                          });
                        }
                      },
                        showCheckboxColumn: true,
                        columns: List.generate(_columnNames.length, (int i) {
                          return DataColumn(label: Text(_columnNames[i]!));
                        }),
                        rows: List.generate(_records.length, (int index) {
                          return DataRow(
                            selected: _selectedRecords.contains(_records[index]),
                            onSelectChanged: (bool? sel){
                              if(sel!){
                                setState(() {
                                  _selectedRecords.add(_records[index]);
                                });
                              }else{
                                setState(() {
                                  _selectedRecords.remove(_records[index]);
                                });
                              }
                            },
                              cells: List.generate(_columnNames.length, (int i) {
                                var val = _records[index].values![_columnNames[i]];
                                if(val == null){
                                  val = '';
                                }
                                return DataCell(Text(val.toString()));
                              }),
                          );
                        }),
                    )
                  ]
                ),
            )
          ],
        ),
      );
    }
  }

}