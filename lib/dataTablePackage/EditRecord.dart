import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/CommonFunctions.dart';
import 'package:smith_base_app/services/db.dart';

class EditRecordForm extends StatefulWidget{
  EditRecordForm(
      {Key, key, required this.permission, required this.orgID, required this.user, required this.isEdit, required this.record, required this.table, this.onSuccess}): super(key: key);

  final AppUser? user;
  final RolePermission permission;
  final String? orgID;
  final OrgDataTable table;
  final DataRecord record;
  final bool isEdit;
  final Function(DataRecord)? onSuccess;

  @override
  State<StatefulWidget> createState() => new _EditRecordFormState();
}

class _EditRecordFormState extends State<EditRecordForm>{
  bool isNarrowLayout = false;
  bool _initDone = false;
  DataRecord _record = new DataRecord();
  List<GlobalKey<FormState>> _formKeyList = <GlobalKey<FormState>>[];
  final List<String> jsonTypes = ["string", "number", "json", "array", "boolean"];
  final DatabaseService _db = DatabaseService();
  final CommonFunctionsService _common = CommonFunctionsService();
  List<OrgDataColumn>? _lstColumns = <OrgDataColumn>[];

  @override
  void initState(){
    super.initState();
    initData();
  }

  void initData(){
    _lstColumns = widget.table.columns;
    if(widget.isEdit){
      _record = widget.record;
    }else{
      _record = DataRecord(
        docID: "",
        del: false,
        media: <OrgMedia>[],
        status: "NEW",
        dateCreated: DateTime.now(),
        qString: <String>[],
        values: {}
      );
    }
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
        body: _body()
    );
  }

  Widget appBar() {
    return new AppBar(
      title: Text('Table ${widget.table.name} Form', style: TextStyle(fontSize: 14),),
      toolbarHeight: 40,
      actions: [

      ],
    );
  }

  Widget _body() {
    return recordList();
  }

  Widget recordList(){
    if(!_initDone){
      return ListTile(title: LinearProgressIndicator(),);
    }
    else{
      return Container(
        width: 400,
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
              children: [
                Expanded(
                    child: Wrap(
                      children: [
                        for(OrgDataColumn column in _lstColumns!)
                          if(widget.isEdit)
                            getInput(column, _record.values![column.name])
                          else
                            getInput(column, "")
                      ],
                    )
                ),
                Center(
                  child: ElevatedButton(
                    child: Wrap(children: [Icon(Icons.save), Text("Save", style: TextStyle(fontSize: 20),)]),
                    onPressed:(){save();},
                  ),
                )
              ],
            ),
        )
      );
    }
  }

  save() async{
    ProgressDialog pr = new ProgressDialog(context,
        message: Text("Loading..."), title: Text("Info!"));
    int formKeyValidCount = 0;
    for(GlobalKey<FormState> formkey in _formKeyList){
      if(formkey.currentState!.validate()) {
        formkey.currentState!.save();
        formKeyValidCount += 1;
      }
    }
    if(_formKeyList.length != formKeyValidCount){
      return;
    }else {
      pr.show();
      //Ensure that unique columns are indeed unique
      try {
        for(OrgDataColumn column in _lstColumns!) {
          if (column.unique!) {
            if (!widget.isEdit || (widget.isEdit && _record.values![column.name] !=
                widget.record.values![column.name])){
              List<DataRecord> lst = await _db.getDataRecordsByKeyValue(
                  widget.orgID!, widget.table.docID, column.name,
                  _record.values![column.name], 1);
            if (lst.isNotEmpty) {
              pr.dismiss();
              _common.showMessage("Validation!", "Column ${column
                  .name} must be unique. The value already exists in the database",
                  context);
              return;
            }
          }
          }
        }
      } catch (e) {
        pr.dismiss();
        _common.showMessage("Error!",
            "Validation error please contact your system administrator. Possible missing FireStore index",
            context);
        return;
      }
      try {
        if(widget.isEdit){
          print("Form is in edit mode, testing if any value was changed");
          if(widget.record.toJson() != _record.toJson()){
            RecordAudit auditLog = new RecordAudit(
              logTime: DateTime.now(),
              userID: widget.user!.docID,
              prevValue: widget.record.toJson(),
              newValue: _record.toJson(),
              docID: _record.docID,
            );
            _record.qString = generateQString();
            print("Updating DataRecord to FireStore");
            await _db.updateDataRecord(widget.orgID!, widget.table.docID, _record, auditLog);          widget.onSuccess!(_record);
            pr.dismiss();
            _common.showMessage("Info", "Record saved successfully", context)
                .then((value) => Navigator.pop(context));
          }
          else{
            pr.dismiss();
            _common.showMessage("Info", "No change to record", context)
                .then((value) => Navigator.pop(context));
            return;
          }
        }
        else {
          _record.qString = generateQString();
          String docID = await _db.createDataRecord(
              widget.orgID!, widget.table.docID, _record);
          if (docID.contains("Error")) {
            throw docID;
          }
          widget.onSuccess!(_record);
          pr.dismiss();
          _common.showMessage("Info", "Record saved successfully", context)
              .then((value) => Navigator.pop(context));

        }
      } catch (e) {
        print(e);
        _common.showMessage("Error",
            "Could not save data record, please contact your system administrator should the error persist",
            context);
        ErrorLog log = new ErrorLog(
          logTime: DateTime.now(),
          module: "Table: ${widget.table.name}. Add Data Record",
          userID: widget.user!.docID,
          message: e.toString()
        );
        _db.addErrorLog(widget.orgID!, log);
      }
  }
  }

  List<String> generateQString(){
    List<String> qString = <String>[];
    for(OrgDataColumn column in _lstColumns!){
      if(column.canSearch!){
        qString.addAll(_db.createQueryStr(_record.values![column.name].toString()));
      }
    }
    return qString;
  }

  Widget getInput(OrgDataColumn column, var value) {
    switch(column.type){
      case 'string'
        : GlobalKey<FormState> formKey = GlobalKey<FormState>();
         _formKeyList.add(formKey);
        return new Form(
        key: formKey,
        child: TextFormField(
          decoration: InputDecoration(labelText: column.name),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: TextInputType.text,
          onSaved: (val) => _record.values![column.name] = val,
          initialValue: widget.isEdit ? _record.values![column.name] : '',
          //enabled: userEdit? false : true,
          textInputAction: TextInputAction.next,
          // The validator receives the text that the user has entered.
          validator: (String? val) {
            if(val!.length < column.minLength!) {
              return 'Entry must have a minimum length of ${column.minLength.toString()}';
            }
            if(val.length > column.maxLength!){
              return 'Entry cannot be exceed ${column.maxLength.toString()} characters';
            }
            if(column.regex != ""){
              RegExp regex = new RegExp(column.regex!);
              if(!regex.hasMatch(val)){
                return 'Entry does not match custom regex validation. (Regex: ${regex.pattern})';
              }
            }
            return null;
          },
        ),
      );
      case 'number'
          :
        GlobalKey<FormState> formKey = GlobalKey<FormState>();
        _formKeyList.add(formKey);
        return Form(
        key: formKey,
        child: TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(labelText: column.name),
          keyboardType: TextInputType.number,
          onSaved: (val) => _record.values![column.name] = int.tryParse(val!),
          initialValue: widget.isEdit ? _record.values![column.name].toString() : '0',
          //enabled: userEdit? false : true,
          textInputAction: TextInputAction.next,
          // The validator receives the text that the user has entered.
          validator: (String? str) {
            int? val = int.tryParse(str!);
            if(val == null){
              return "Entry must be a number";
            }
            if(val < column.minLength!) {
              return 'Entry must have a minimum value of ${column.minLength.toString()}';
            }
            if(val > column.maxLength!){
              return 'Entry cannot be exceed ${column.maxLength.toString()}';
            }
            if(column.regex != ""){
              RegExp regex = new RegExp(column.regex!);
              if(!regex.hasMatch(val.toString())){
                return 'Entry does not match custom regex validation. (Regex: ${regex.pattern})';
              }
            }
            return null;
          },
        ),
      );
      case 'json'
      //TODO: Create needed widget
          : return Container();
      case 'array'
      //TODO: Create needed widget
          : return Container();
      case 'boolean'
      //TODO: Create needed widget
          : return Container();
      case 'calculated'
      //TODO: Create needed widget
        : return Container();
      default:
        return Container();
    }
  }

}