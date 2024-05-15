import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/db.dart';

class NewMessagePage extends StatefulWidget {
  NewMessagePage(
      {Key? key,required this.loggedInUser, required this.rolePermission, required this.isEdit, required this.message, required this.orgID})
      : super(key: key);

  final AppUser? loggedInUser;
  final RolePermission rolePermission;
  final bool isEdit;
  final String? orgID;
  final Message message;

  @override
  State<StatefulWidget> createState() => new _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage>
    with SingleTickerProviderStateMixin {
  Message message = new Message();
  bool toggleUser = false;
  bool formError = false;
  bool groupAddError = false;
  bool initDone = false;
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  late TabController _controller;
  final _db = DatabaseService();
  late bool isEdit;

  @override
  void initState() {
    _controller = new TabController(length: 3, vsync: this);
    message = new Message();
    message.allowReplies = true;
    setState(() => message);
    isEdit = widget.isEdit;
      if (isEdit) {
        message = widget.message;
        String toText = message.to.toString().replaceAll(", ", ";").replaceAll(
            "[", "").replaceAll("]", "");
        _toController.text = toText;
        _subjectController.text = message.subject!;
      }
      initDone = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: appBar() as PreferredSizeWidget?,
        body: body()
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget appBar() {
    return new AppBar(
        title: Text('New Chat'),
    );
  }

  Widget body() {
    if (!initDone) {
      return ListTile(title: LinearProgressIndicator());
    }
    return
        Card(
          child: new Wrap(
            spacing: 5,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.contact_mail),
                title: TypeAheadField<AppUser>(
                  textFieldConfiguration: TextFieldConfiguration(
                      autofocus: false,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        labelText: 'Search Users'
                      )
                  ),
                  suggestionsCallback: (String pattern) async {
                    if(pattern.length > 2) {
                      return await _db.getUsers(10, widget.orgID, pattern.toLowerCase());
                    }
                    else{
                      return <AppUser>[];
                    }
                  },
                  itemBuilder: (BuildContext context, AppUser suggestion) {
                    return ListTile(
                      title: Text(
                          suggestion.firstName! + " " +
                              suggestion.lastName!),
                      trailing: Text(suggestion.emailAddress!),
                    );
                  },
                  onSuggestionSelected: (suggestion) async {
                    if(!_toController.text.contains(suggestion.emailAddress!)){
                      _toController.text +=
                          suggestion.emailAddress! + ";";
                      setState(() => _toController.text);
                    }
                  },
                ),
              ),
              form(),
            ],
          ),
        );
  }

  Widget form() {
    ProgressDialog pr = new ProgressDialog(context,
        message: Text("Loading..."), title: Text("Info!"));
    return new Card(
      borderOnForeground: true,
      color: Colors.blueGrey,
      child: new Form(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: new Column(
              children: <Widget>[
                new Row(
                  children: <Widget>[
                    Text("To:"),
                  ],
                ),
                new Row(
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 120,
                      child: SingleChildScrollView(
                        child: Wrap(
                          children: List.generate(
                            _toController.text.split(';').length - 1,
                                (i) {
                              return Wrap(
                                children: <Widget>[
                                  Chip(
                                    label: Container(
                                      padding: const EdgeInsets.all(2.0),
                                      constraints: new BoxConstraints(maxWidth: 200.0 - 100.0),
                                      child: new Text(_toController.text.split(';')[i],
                                          overflow: TextOverflow.clip),
                                    ),
                                    onDeleted: (){
                                      print("Chip deleted: " + i.toString());
                                      String s = _toController.text.replaceFirst(_toController.text.split(';')[i] + ';', '');
                                      setState(() {
                                        _toController.text = s;
                                        print(_toController.text);
                                      });
                                    },
                                    deleteIcon: Icon(Icons.clear),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                new Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(1.0),
                        child: TextFormField(
                          decoration: InputDecoration(labelText: 'Subject:'),
                          controller: _subjectController,
                          onChanged: (val) {
                            print("Updating subject field");
                            setState(() => message.subject = val);
                          },
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          minLines: 1,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(child: formError ? Text(
                        "Please complete all required fields!",
                        style: TextStyle(color: Colors.red),) : null),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ListTile(
                        title: Text('Allow Replies'),
                        trailing: Switch(
                            value: message.allowReplies!,
                            onChanged: (bool val) {
                              setState(() => message.allowReplies = val);
                            }),
                      ),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        child: Text("Save"),
                        onPressed: () async {
                          pr.show();
                            if (message.subject != null &&
                                _toController.text.split(';').length > 1) {
                              print("Updating 'to' field");
                              List emails = _toController.text.split(";");
                              emails.removeLast();
                              emails.add(widget.loggedInUser!.emailAddress);
                              message.to = [];
                              message.to!.addAll(emails);
                              //Set all message fields before save
                              if(!isEdit) {
                                message.admins = [];
                                message.admins!.add(
                                    widget.loggedInUser!.emailAddress);
                                message.from = widget.loggedInUser!.emailAddress;
                                message.date = DateTime.now();
                                message.type = 1;
                                message.del = false;
                                await _db.addMessage(message, widget.orgID!);
                              }
                              else{
                                await _db.updateMessage(message, widget.orgID!);
                              }
                              //Now save the message to the database
                              Future.delayed(Duration(seconds: 1)).then((q) {
                                pr.dismiss();
                                Navigator.pop(context);
                              });
                            }
                            else {
                              setState(() {
                                formError = true;
                              });
                              Future.delayed(Duration(seconds: 1)).then((q) {
                                pr.dismiss();
                              });
                            }
                        },
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
      )
      );
  }

}