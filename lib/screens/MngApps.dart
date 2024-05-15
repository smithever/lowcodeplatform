import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:json_theme/json_theme.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/CommonFunctions.dart';
import 'package:smith_base_app/services/db.dart';
import 'package:uuid/uuid.dart';

class MngApps extends StatefulWidget{
  MngApps(
      {Key, key, required this.permission, required this.orgID, required this.user}): super(key: key);

  final AppUser user;
  final RolePermission permission;
  final String orgID;

  @override
  State<StatefulWidget> createState() => new _MngAppsState();
}

class _MngAppsState extends State<MngApps>{
  final DatabaseService _db = DatabaseService();
  bool isNarrowLayout = false;
  bool _initDone = false;
  List<OrgApp> _apps = <OrgApp>[];
  OrgApp? _selApp;
  ScrollController _controller = ScrollController();

  @override
  void initState(){
    _initData();
    super.initState();
  }

  void _initData() async{
    print("Manage App Page loading...");
    setState(()=>_initDone = false);
    try{
      _apps = await _db.getAllOrgApps(widget.orgID);
      if(_apps.isNotEmpty){
        _selApp = _apps[0];
      }
      setState(()=>_initDone = true);
    }catch(e){
      setState(()=>_initDone = true);
      print("Failed to load data: " + e.toString());
      Fluttertoast.showToast(msg: "Failed to load data: " + e.toString());
    }
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
              if(isNarrowLayout) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditAppForm(
                                permission: widget.permission,
                                orgID: widget.orgID,
                                user: widget.user,
                                orgApp: new OrgApp(),
                                isEdit: false)));
              }
              else{
                setState(()=> _selApp = new OrgApp(docID: ""));
              }
            }
        )
            : null
    );
  }

  Widget appBar() {
    return new AppBar(
      title: Text('Manage Apps', style: TextStyle(fontSize: 14),),
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
          if(_selApp != null)
          Expanded(child:
           EditAppForm(
             isEdit: _selApp!.docID != "" ? false : true,
             orgApp: _selApp!,
             orgID: widget.orgID,
             permission: widget.permission,
             user: widget.user,
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
                    itemCount: _apps.length,
                    itemBuilder: (BuildContext context, index){
                      return ListTile(
                        title: Text(_apps[index].name!),
                        subtitle: Text(_apps[index].description!),
                        onTap: (){
                          if(isNarrowLayout) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        EditAppForm(
                                            permission: widget.permission,
                                            orgID: widget.orgID,
                                            user: widget.user,
                                            orgApp: _apps[index],
                                            isEdit: true)));
                          }
                          else{
                            setState(()=> _selApp = _apps[index]);
                          }
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

}

class EditAppForm extends StatefulWidget{
  EditAppForm(
      {Key, key, required this.permission, required this.orgID, required this.user, required this.orgApp, required this.isEdit}): super(key: key);

  final AppUser user;
  final RolePermission permission;
  final String orgID;
  final OrgApp orgApp;
  final bool isEdit;

  @override
  State<StatefulWidget> createState() => new _EditAppFormState();
}

class _EditAppFormState extends State<EditAppForm> {
  final DatabaseService _db = DatabaseService();
  final CommonFunctionsService _common = CommonFunctionsService();
  final TextEditingController _secretController = new TextEditingController();
  final TextEditingController _appThemeController = new TextEditingController();
  final TextEditingController _appConfigController = new TextEditingController();
  bool _initDone = false;
  OrgApp _selApp = new OrgApp();
  bool _isEdit = false;

  @override
  void initState() {
    _initData();
    super.initState();
  }

  void _initData(){
    if(widget.isEdit) {
      _selApp = widget.orgApp;
      _secretController.text = _selApp.secret!;
      _appConfigController.text = json.encode(_selApp.appConfig);
      _appThemeController.text = json.encode(_selApp.appTheme);
      _isEdit = true;
    }
    if(_selApp.appTheme == null){
      _appThemeController.text = '''{
  "backgroundColor": "#f5f5f5",
  "buttonColor": "#0d47a1",
  "buttonTheme": {
    "buttonColor": "#0d47a1",
    "textTheme": "primary"
  },
  "canvasColor": "#ffffff",
  "disabledColor": "#e0e0e0",
  "errorColor": "#d50000",
  "fontFamily": "lato",
  "iconTheme": {
    "color": "#37474f"
  },
  "primaryColor": "#37474f",
  "primaryColorBrightness": "dark",
  "toggleableActiveColor": "#33691e"
}''';
      _selApp.appTheme = json.decode(_appThemeController.text);
    }
    if(_selApp.appConfig == null){
      _appConfigController.text = '''{
      "WelcomeMessage": "Welcome to this app"
}''';
      _selApp.appConfig = json.decode(_appConfigController.text);
    }
    setState(()=> _initDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: appBar() as PreferredSizeWidget?,
        body: _form(),
    );
  }

  Widget appBar() {
    return new AppBar(
      title: widget.orgApp.name != null ? Text(widget.orgApp.name!, style: TextStyle(fontSize: 14)) : Text("New App", style: TextStyle(fontSize: 14)),
      toolbarHeight: 40,
      actions: [
        IconButton(
          icon: Icon(Icons.save),
          onPressed: () async{
            ProgressDialog pr = new ProgressDialog(context, title: Text("Info!"), message: Text("Saving..."));
            pr.show();
            try {
              if (_isEdit) {
                await _db.updateOrgApp(_selApp, widget.orgID);
                pr.dismiss();
                Fluttertoast.showToast(msg: "App saved");
              }
              else {
                _selApp.createdByUserID = widget.user.docID;
                _selApp.createdDate = DateTime.now();
                _selApp.del = false;
                _selApp.version = 1;
                String docID = await _db.createOrgApp(_selApp, widget.orgID);
                if(docID != "") {
                  setState((){_selApp.docID = docID; _isEdit = true;});
                  pr.dismiss();
                  Fluttertoast.showToast(msg: "New App saved");
                }else{
                  Fluttertoast.showToast(msg: "Failed to save");
                  pr.dismiss();
                }
              }
            }catch(e){
              pr.dismiss();
              ErrorLog error = new ErrorLog(
                logTime: DateTime.now(),
                message: e.toString(),
                module: "Manage App - Failed to save",
                userID: widget.user.docID
              );
              _db.addErrorLog(widget.orgID, error);
              Fluttertoast.showToast(msg: "Failed to save");
            }
          },
        )
      ],
    );
  }

  Widget _form() {
    ProgressDialog pr = new ProgressDialog(context, title: Text("info!"), message: Text("Loading..."));
    if(!_initDone){
      return LinearProgressIndicator();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Form(
        child: Column(
          children: [
            TextFormField(
                decoration: InputDecoration(labelText: 'App ID:'),
                obscureText: false,
                textInputAction: TextInputAction.next,
                initialValue: _selApp.docID,
                enabled: false
              // The validator receives the text that the user has entered.
            ),
            TextFormField(
                decoration: InputDecoration(labelText: 'Name:'),
                obscureText: false,
                textInputAction: TextInputAction.next,
                onChanged: (val) => _selApp.name = val,
                initialValue: _selApp.name,
                enabled: widget.permission.r
              // The validator receives the text that the user has entered.
            ),
            TextFormField(
                decoration: InputDecoration(
                    labelText: 'Secret:',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.autorenew),
                    onPressed: (){
                      _secretController.clear();
                      String guid = Uuid().v1();
                      _secretController.text = guid.toString();
                      _selApp.secret = guid.toString();
                    },
                  )
                ),
                controller: _secretController,
                obscureText: false,
                textInputAction: TextInputAction.next,
                onChanged: (val) => _selApp.secret = val,
                readOnly: true,
                enabled: widget.permission.r
              // The validator receives the text that the user has entered.
            ),
            TextFormField(
              controller: _appThemeController,
              decoration: InputDecoration(
                  labelText: 'App Theme JSON:',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.upload_file),
                    onPressed: () async {
                      _appThemeController.clear();
                      Map jsonVal = await _common.getJsonFromFile();
                      _appThemeController.text = json.encode(jsonVal);
                      _selApp.appTheme = jsonVal;
                    },
                  )
              ),
              obscureText: false,
              textInputAction: TextInputAction.next,
              minLines: 3,
              maxLines: 20,
              enabled: true,
              readOnly: true,
              // The validator receives the text that the user has entered.
            ),
            TextFormField(
              controller: _appConfigController,
              decoration: InputDecoration(
                  labelText: 'App Config JSON:',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.upload_file),
                    onPressed: () async {
                      _appConfigController.clear();
                      Map jsonVal = await _common.getJsonFromFile();
                      _appConfigController.text = json.encode(jsonVal);
                      _selApp.appConfig = jsonVal;
                    },
                  )
              ),
              obscureText: false,
              textInputAction: TextInputAction.next,
              minLines: 3,
              maxLines: 30,
              enabled: true,
              readOnly: true,
              // The validator receives the text that the user has entered.
            )
          ],
        ),
      ),
    );
  }

}

