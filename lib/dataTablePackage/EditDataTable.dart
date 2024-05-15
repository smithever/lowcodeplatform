import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/codeEditor/CodeEditorPage.dart';
import 'package:smith_base_app/dataTablePackage/MngDataTableSecurity.dart';
import 'package:smith_base_app/services/CommonFunctions.dart';
import 'package:smith_base_app/services/db.dart';

class EditDataTablePage extends StatefulWidget{
  EditDataTablePage({
    Key? key,
    required this.user,
    required this.orgID,
    required this.isEdit,
    required this.dataTable,
    required this.onNewTableCreated,
    required this.permission
}): super(key: key);

  final AppUser? user;
  final OrgDataTable dataTable;
  final bool isEdit;
  final String? orgID;
  final void Function() onNewTableCreated;
  final RolePermission permission;

  @override
  State<StatefulWidget> createState() => new _EditDataTablePage();
}

class _EditDataTablePage extends State<EditDataTablePage>{
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final CommonFunctionsService _common = CommonFunctionsService();
  OrgDataTable _dataTable = new OrgDataTable();
  bool _initDone = false;
  bool isNarrowLayout = false;
  bool showSecurity = false;
  double _pagePadding = 10;

  @override
  void initState(){
    super.initState();
    initData();
  }

  void initData() async{
    if(widget.isEdit){
      setState(() {
        _dataTable = widget.dataTable;
      });
    }else{
      _dataTable.columns = <OrgDataColumn>[];
      _dataTable.permissions = <RolePermission>[];
    }
    setState(()=> _initDone = true);
  }

  void keyBoardToggle() {
    print("On keyboard toggle event");
    print(MediaQuery.of(context).viewInsets.bottom);
}

  @override
  Widget build(BuildContext context){
    return new Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appBar() as PreferredSizeWidget?,
      body: !_initDone ? new LinearProgressIndicator()
      : Container(
        padding: EdgeInsets.only(bottom: _pagePadding),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: _body(),
        ),
      )
    );
  }

  Widget appBar() {
    return new AppBar(
      title: widget.isEdit ? Text('Edit table:${widget.dataTable.name}', style: TextStyle(fontSize: 14)) : Text('Create new table', style: TextStyle(fontSize: 14)),
      toolbarHeight: 40,
      actions: [
        IconButton(icon: Icon(Icons.save_outlined), onPressed: ()=>saveForm(), tooltip: "Save",),
        IconButton(icon: Icon(Icons.security), onPressed: ()=>togglePermissions(), tooltip: "Security Permissions",),
      ],
    );
  }

  void togglePermissions(){
    if(isNarrowLayout){
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MngDataTablesSecurity(
            user: widget.user,
            orgID: widget.orgID,
            permission: widget.permission,
            table: _dataTable,
            onChange: (List<RolePermission>? rpLst){
              _dataTable.permissions = rpLst;
            },
          ))
      );
    }
    else{
      showSecurity = !showSecurity;
    }
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
    return _createForm();
  }

  Widget _wideLayout(){
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: _createForm(),
        ),
        if(showSecurity)
          Expanded(child:
            MngDataTablesSecurity(
              user: widget.user,
              orgID: widget.orgID,
              permission: widget.permission,
              table: _dataTable,
              onChange: (List<RolePermission>? rpLst){
                _dataTable.permissions = rpLst;
            },
            ),
          )
      ],
    );
  }

  Widget _createForm(){
    return Form(
        key: _formKey,
        child: Column(
          children: [
            ListTile(
              title: Text("Table Details:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Table Name:'),
              keyboardType: TextInputType.text,
              onSaved: (val) => _dataTable.name = val,
              initialValue: widget.isEdit ? _dataTable.name : '',
              enabled: true,
              textInputAction: TextInputAction.next,
              // The validator receives the text that the user has entered.
              validator: (String? val) {
                if (val!.length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Table Description:'),
              keyboardType: TextInputType.text,
              onSaved: (val) => _dataTable.description = val,
              initialValue: widget.isEdit ? _dataTable.description : '',
              enabled: true,
              textInputAction: TextInputAction.next,
              // The validator receives the text that the user has entered.
              validator: (String? val) {
                if (val!.length < 3) {
                  return 'Description must be at least 3 characters';
                }
                return null;
              },
            ),
            Divider(),
            ListTile(
              title: Text("Columns:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            ),
            if(_dataTable.columns!.isNotEmpty)
              Column(
                children: List.generate(_dataTable.columns!.length, (i) {
                  return new ExpansionTile(
                    maintainState: true,
                      title: _dataTable.columns![i].name != null ? Text(_dataTable.columns![i].name!) : Text("New Column"),
                      children: [
                        _ColumnForm(
                          permission: widget.permission,
                          table: widget.dataTable,
                          orgID: widget.orgID,
                          user: widget.user,
                          onKeyboardToggle: keyBoardToggle,
                          column: _dataTable.columns![i],
                          onChange: (OrgDataColumn column){
                            setState(() {
                              _dataTable.columns![i] = column;
                            });
                          },
                        )
                      ]
                  );
                })
              ),
            IconButton(
                icon: Icon(Icons.add),
                onPressed: (){
                  OrgDataColumn column = new OrgDataColumn(
                      canSearch: false,
                      unique: false,
                      regex: '',
                      name: '',
                      type: 'string',
                      minLength: 0,
                      maxLength: 0,
                  );
                  setState(() {
                    _dataTable.columns!.add(column);
                  });
                }
            )
          ],
        ),
      );
  }


  Future<void> saveForm() async{
    ProgressDialog pr = new ProgressDialog(context, message: Text("Loading..."), title: Text("Info!"));
    if(_formKey.currentState!.validate()){
      _formKey.currentState!.save();
      pr.show();
      AuditLog audit = new AuditLog(
        userID: widget.user!.docID,
        logTime: DateTime.now(),
        details: widget.isEdit ? "Altered Data Table ${widget.dataTable.docID}" : "Created new Table ${_dataTable.name}",
        alteredDocID:  widget.isEdit ? widget.dataTable.docID : _dataTable.name
      );
      try {
        if(widget.isEdit){
          await _db.updateDataTable(widget.orgID!, _dataTable);
        }
        else{
          await _db.createDataTable(widget.orgID!, _dataTable);
        }
        await _db.addAuditLog(widget.orgID!, audit);
        pr.dismiss();
        _common.showMessage("Success!", "Data Table saved", context);
      }catch(e){
        print(e.toString());
        _common.showMessage("Error!", "Failed to create new Table", context).then((value) => pr.dismiss());
        pr.dismiss();
        ErrorLog log = new ErrorLog(
          logTime: DateTime.now(),
          message: e.toString(),
          module: "EditTable/SaveForm",
          userID: widget.user!.docID,
        );
        _db.addErrorLog(widget.orgID!, log);
      }
    }
  }


}

class _ColumnForm extends StatefulWidget {
  _ColumnForm({
    Key? key,
    required this.column,
    required this.onChange,
    required this.onKeyboardToggle,
    required this.permission,
    required this.user,
    required this.table,
    required this.orgID
  }): super(key: key);
  
  final AppUser? user;
  final OrgDataTable table;
  final RolePermission permission;
  final OrgDataColumn column;
  final Function(OrgDataColumn) onChange;
  final Function() onKeyboardToggle;
  final String? orgID;

  @override
  State<StatefulWidget> createState() => _ColumnFormState();
}

class _ColumnFormState extends State<_ColumnForm>{
  final CommonFunctionsService _common = CommonFunctionsService();
  final List<String> jsonTypes = ["string", "number", "json", "array", "boolean", "calculated"];
  final TextEditingController _codeEditorController = new TextEditingController();
  OrgDataColumn column = new OrgDataColumn();
  FocusNode _focusNode = new FocusNode();

  @override
  void initState() {
    _codeEditorController.addListener(listen);
    column = widget.column;
    super.initState();
    _focusNode.addListener(_focusNodeListener);
  }

  @override
  void dispose() {
    _codeEditorController.removeListener(listen);
    _focusNode.removeListener(_focusNodeListener);
    super.dispose();
  }

  void listen() {
    print(_codeEditorController.selection.base);
    print(_codeEditorController.selection.extent);
  }

  Future<Null> _focusNodeListener() async {
    if (_focusNode.hasFocus){
      print('TextField got the focus');
    } else {
      print('TextField lost the focus');
    }
  }

  @override
  Widget build(BuildContext context) {
    setState(() => column);
    try {
      return Padding(
        padding: EdgeInsets.all(18),
        child: Wrap(children: [
          TextFormField(
            onTap: ()=>{widget.onKeyboardToggle()},
            onEditingComplete: ()=>{widget.onKeyboardToggle()},
            decoration: InputDecoration(labelText: 'Column Name:'),
            keyboardType: TextInputType.text,
            onChanged: (val) {
              if(val.length > 0){
                column.name = val;
                widget.onChange(column);
              }
            },
            initialValue: column.name,
            enabled: true,
            textInputAction: TextInputAction.next,
            // The validator receives the text that the user has entered.
            validator: (String? val) {
              if (val!.length < 1) {
                return 'Name must be at least 1 characters';
              }
              return null;
            },
          ),
          ListTile(
            title: Text("Data type:"),
          ),
          DropdownButton<String>(
            value: column.type,
            icon: const Icon(Icons.arrow_downward),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue){
              setState(() {
                column.type = newValue;
              });
              widget.onChange(column);
            },
            items: jsonTypes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value)
              );
            }).toList(),
          ),
          if(column.type == "string" || column.type == "number" || column.type == 'array')
          TextFormField(
            decoration: InputDecoration(labelText: 'Minimum Length / Value:'),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            initialValue: column.minLength.toString(),
            onChanged: (val){
              if(val.isNotEmpty){
                column.minLength = int.tryParse(val);
                widget.onChange(column);
              }
            },
            enabled: true,
            textInputAction: TextInputAction.next,
            // The validator receives the text that the user has entered.
          ),
          if(column.type == "string" || column.type == "number" || column.type == 'array')
          TextFormField(
            decoration: InputDecoration(labelText: 'Maximum Length / Value:'),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            initialValue: column.maxLength.toString(),
            onChanged: (val){
              if(val.isNotEmpty){
                setState(() {
                  column.maxLength = int.tryParse(val);
                });
                if(column.maxLength! > 36 || column.maxLength! < 1){
                  setState((){
                    column.canSearch = false;
                    column.unique = false;
                  });
                }
                widget.onChange(column);
              }
            },
            enabled: true,
            textInputAction: TextInputAction.next,
            // The validator receives the text that the user has entered.
          ),
          if(column.type == "string" || column.type == "number")
          SwitchListTile(
              title: Text("Allow Search"),
              value: column.canSearch!,
              onChanged: (bool val){
                if(val) {
                  if (column.maxLength! > 35 || column.maxLength! < 1 || column.type != "string") {
                    _common.showMessage("Alert!",
                        "Maximum length must not be 0 or more than 35 characters. And type must be string", context);
                  }
                  else {
                    column.canSearch = val;
                    setState(() => column);
                    widget.onChange(column);
                  }
                }else {
                  column.canSearch = val;
                  setState(() => column);
                  widget.onChange(column);
                }
              }
          ),
          if(column.type == "string" || column.type == "number")
          SwitchListTile(
              title: Text("Force Unique"),
              value: column.unique!,
              onChanged: (bool val){
                if(val) {
                  if (column.maxLength! > 35 || column.maxLength! < 1 || column.type != "string") {
                    _common.showMessage("Alert!",
                        "Maximum length must not be 0 or more than 35 characters. And type must be string", context);
                  } else {
                    column.unique = val;
                    setState(() => column.canSearch);
                    widget.onChange(column);
                  }
                } else {
                  column.unique = val;
                  setState(() => column.canSearch);
                  widget.onChange(column);
                }
              }
          ),
          if(column.type == "string" || column.type == "number")
          TextFormField(
            decoration: InputDecoration(labelText: 'Validation Regex:'),
            keyboardType: TextInputType.text,
            initialValue: column.regex,
            onChanged: (val){
              if(val.isNotEmpty){
                column.regex = val;
                widget.onChange(column);
              }
            },
            enabled: true,
            textInputAction: TextInputAction.next,
            // The validator receives the text that the user has entered.
            validator: (String? val) {
              return null;
            },
          ),
          if(column.type == "calculated")
            TextFormField(
              focusNode: _focusNode,
              controller: _codeEditorController,
              decoration: InputDecoration(labelText: 'Calculation Expression'),
              keyboardType: TextInputType.multiline,
              initialValue: column.expression,
              readOnly: true,
              onTap: (){
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CodeEditorPage(
                      user: widget.user, 
                      orgID: widget.orgID, 
                      isEdit: true, 
                      dataTable: widget.table, 
                      onSave: (String? val){},
                      permission: widget.permission,
                      codeExpression: column.expression,
                  ))
                );
              },
              onChanged: (val){
                if(val.isNotEmpty){
                  column.expression = val;
                  widget.onChange(column);
                }
              },
              enabled: true,
              textInputAction: TextInputAction.next,
              // The validator receives the text that the user has entered.
              validator: (String? val) {
                return null;
              },
            )
        ],),
      );
    } catch (e, s) {
      print(s);
      return Wrap(children: []);
    }
  }

}