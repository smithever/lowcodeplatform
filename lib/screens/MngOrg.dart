import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/CommonFunctions.dart';
import 'package:smith_base_app/services/db.dart';
import 'package:file_picker/file_picker.dart';

class MngOrganizationPage extends StatefulWidget {
  MngOrganizationPage(
  {Key? key, required this.permission, required this.user, required this.orgSettings, required this.orgID}):
   super (key: key);

  final RolePermission permission;
  final AppUser? user;
  final OrgSettings orgSettings;
  final String? orgID;

  @override
  State<StatefulWidget> createState() => new _MngOrganizationPageState();
}

class _MngOrganizationPageState extends State<MngOrganizationPage> {
  final DatabaseService _db = new DatabaseService();
  final CommonFunctionsService _common = new CommonFunctionsService();
  final TextEditingController _privFirebaseKeyController = new TextEditingController();
  bool _initDone = false;
  String _selSetting = '';
  bool isNarrowLayout = true;
  OrgSettings _orgSettings = new OrgSettings();


  @override
  void initState() {
    _orgSettings = widget.orgSettings;
    _privFirebaseKeyController.text = json.encode(
        _orgSettings.firestoreSettings!.privKeyJson);
    _initDone = true;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: appBar() as PreferredSizeWidget?,
      body: _initDone
          ? SingleChildScrollView(child: _body())
          : new LinearProgressIndicator(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: !widget.permission.r! ? null :
      FloatingActionButton(
          child: Icon(Icons.save_rounded),
          onPressed: () async {
            String ret = await _db.updateOrgSettings(
                _orgSettings, widget.orgID);
            return showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Info!"),
                    content: Text(ret),
                    actions: <Widget>[
                      new TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK')),
                    ],
                  );
                });
          }
      ),
    );
  }

  Widget appBar() {
    return new AppBar(
      toolbarHeight: 40,
      title: Text('Organization Settings'),
    );
  }

  Widget _body() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 600) {
            isNarrowLayout = false;
            return _wideLayout();
          }
          else {
            isNarrowLayout = true;
            return _narrowLayout();
          }
        });
  }

  Widget _wideLayout() {
    List<String> s = OrgSettings().keys();
    if (!_initDone) {
      return ListTile(title: LinearProgressIndicator());
    }
    else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Container(
              child: Column(
                children: [
                  for(String key in s)
                    ListTile(
                      title: Text(key),
                      onTap: () {
                        setState(() => _selSetting = key);
                      },
                    )
                ],
              ),
            ),
          ),
          if(_selSetting != "")
            Expanded(
                child: _rootConfigs(_selSetting)
            ),
        ],
      );
    }
  }

  Widget _narrowLayout() {
    List<String> keys = OrgSettings().keys();
    if (!_initDone) {
      return ListTile(title: LinearProgressIndicator());
    }
    else {
      return Expanded(child: Container(
        child: Column(
          children: [
            for(String key in keys)
              ExpansionTile(
                title: Text(key),
                children: [
                  _rootConfigs(key)
                ],
              )
          ],
        ),
      ));
    }
  }

  Widget _rootConfigs(String key) {
    switch (key) {
      case 'firestoreSettings':
        return _firstoreSettingsForm();
      case 'uploadParams':
        return _fileUploadParams();
      case 'counters':
        return _countersForm();
      case 'media':
        return Placeholder();
      case 'theme':
        return _themeForm();
      default:
        return Placeholder();
    }
  }

  Widget _firstoreSettingsForm() {
    return Container(
      child: Column(
        children: [
          TextFormField(
              decoration: InputDecoration(labelText: 'API Key:'),
              obscureText: false,
              textInputAction: TextInputAction.next,
              onChanged: (val) => _orgSettings.firestoreSettings!.apiKey = val,
              initialValue: _orgSettings.firestoreSettings!.apiKey,
              enabled: widget.permission.r
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
              decoration: InputDecoration(labelText: 'App ID:'),
              obscureText: false,
              textInputAction: TextInputAction.next,
              onChanged: (val) => _orgSettings.firestoreSettings!.appId = val,
              initialValue: _orgSettings.firestoreSettings!.appId,
              enabled: widget.permission.r
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
              decoration: InputDecoration(labelText: 'Project ID:'),
              obscureText: false,
              textInputAction: TextInputAction.next,
              onChanged: (val) =>
              _orgSettings.firestoreSettings!.projectId = val,
              initialValue: _orgSettings.firestoreSettings!.projectId,
              enabled: widget.permission.r
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
              decoration: InputDecoration(labelText: 'Messaging Sender ID:'),
              obscureText: false,
              textInputAction: TextInputAction.next,
              onChanged: (val) =>
              _orgSettings.firestoreSettings!.messagingSenderId = val,
              initialValue: _orgSettings.firestoreSettings!.messagingSenderId,
              enabled: widget.permission.r
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            controller: _privFirebaseKeyController,
            decoration: InputDecoration(
                labelText: 'Private Key Json:',
                suffixIcon: IconButton(
                  icon: Icon(Icons.upload_file),
                  onPressed: () async {
                    _privFirebaseKeyController.clear();
                    Map jsonVal = await _common.getJsonFromFile();
                    _privFirebaseKeyController.text = json.encode(jsonVal);
                    _orgSettings.firestoreSettings!.privKeyJson = jsonVal;
                  },
                )
            ),
            obscureText: false,
            textInputAction: TextInputAction.next,
            minLines: 3,
            maxLines: 50,
            onChanged: (val) =>
            _orgSettings.firestoreSettings!.privKeyJson = json.decode(val),
            enabled: true,
            readOnly: true,

            // The validator receives the text that the user has entered.
          )
        ],
      ),
    );
  }

  Widget _themeForm() {
    return Container(
      child: Column(
        children: [
          SwitchListTile(
              title: Text("Enable Dark Mode"),
              value: _orgSettings.theme!.darkMode!,
              onChanged: (bool value) {
                setState(() {
                  _orgSettings.theme!.darkMode = value;
                });
              }
          ),
          TextFormField(
              decoration: InputDecoration(labelText: 'Main Color HEX:'),
              obscureText: false,
              textInputAction: TextInputAction.next,
              onChanged: (val) => _orgSettings.theme!.color = val,
              initialValue: _orgSettings.theme!.color,
              enabled: widget.permission.r
            // The validator receives the text that the user has entered.
          )
        ],
      ),
    );
  }

  Widget _countersForm() {
    return Container(
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Next Invoice No:'),
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (val) {
              _orgSettings.counters!.invoiceNo = int.parse(val);
            },
            initialValue: _orgSettings.counters!.invoiceNo.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Next Quotation No:'),
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (val) {
              _orgSettings.counters!.quotationNo = int.parse(val);
            },
            initialValue: _orgSettings.counters!.quotationNo.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Next Statement No:'),
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (val) {
              _orgSettings.counters!.statementNo = int.parse(val);
            },
            initialValue: _orgSettings.counters!.statementNo.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
        ],
      ),
    );
  }

  Widget _fileUploadParams() {
    return Container(
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Max Image Upload Size Mb:'),
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (val) {
              _orgSettings.uploadParams!.maxImageMb = int.parse(val);
            },
            initialValue: _orgSettings.uploadParams!.maxImageMb.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(
                labelText: 'Allowed Image Upload File Types:'),
            autofillHints: ["wav", "mp3"],
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            onChanged: (val) {
              _orgSettings.uploadParams!.imageFileTypes = val.split(",");
            },
            initialValue: _orgSettings.uploadParams!.imageFileTypes.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Max Video Upload Size Mb:'),
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (val) {
              _orgSettings.uploadParams!.maxVideoMb = int.parse(val);
            },
            initialValue: _orgSettings.uploadParams!.maxVideoMb.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(
                labelText: 'Allowed Video Upload File Types:'),
            autofillHints: ["mp4"],
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            onChanged: (val) {
              _orgSettings.uploadParams!.videoFileTypes = val.split(",");
            },
            initialValue: _orgSettings.uploadParams!.videoFileTypes.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Max Audio Upload Size Mb:'),
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (val) {
              _orgSettings.uploadParams!.maxAudioMb = int.parse(val);
            },
            initialValue: _orgSettings.uploadParams!.maxAudioMb.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(
                labelText: 'Allowed Audio Upload File Types:'),
            autofillHints: ["mp4"],
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            onChanged: (val) {
              _orgSettings.uploadParams!.audioFileTypes = val.split(",");
            },
            initialValue: _orgSettings.uploadParams!.audioFileTypes.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(
                labelText: 'Max Documents Upload Size Mb:'),
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (val) {
              _orgSettings.uploadParams!.maxDocumentMb = int.parse(val);
            },
            initialValue: _orgSettings.uploadParams!.maxDocumentMb.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(
                labelText: 'Allowed Documents Upload File Types:'),
            autofillHints: ["xlx", "doc", "pdf"],
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            onChanged: (val) {
              _orgSettings.uploadParams!.audioFileTypes = val.split(",");
            },
            initialValue: _orgSettings.uploadParams!.audioFileTypes.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Max Other Upload Size Mb:'),
            obscureText: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (val) {
              _orgSettings.uploadParams!.maxDocumentMb = int.parse(val);
            },
            initialValue: _orgSettings.uploadParams!.maxDocumentMb.toString(),
            enabled: widget.permission.r,
            // The validator receives the text that the user has entered.
          ),
        ],
      ),
    );
  }

}
