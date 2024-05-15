import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/screens/Chat.dart';
import 'package:smith_base_app/screens/NewMessage.dart';
import 'package:smith_base_app/services/db.dart';

class MngMessagesPage extends StatefulWidget {
  MngMessagesPage(
      {Key? key, required this.loggedInUser, required this.rolePermission, required this.orgID, required this.gotoMessage, required this.message, required this.orgSettings})
      : super(key: key);

  final AppUser? loggedInUser;
  final RolePermission rolePermission;
  final String? orgID;
  final bool gotoMessage;
  final Message message;
  final OrgSettings orgSettings;

  @override
  State<StatefulWidget> createState() => new _MngMessagesPageState();
}

class _MngMessagesPageState extends State<MngMessagesPage> {
  List<Message> messages = <Message>[];
  final _db = DatabaseService();
  late bool isNarrowLayout;
  Message selMessage = new Message();

  @override
  void initState() {
    if(widget.gotoMessage){
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatPage(
                  loggedInUser: widget.loggedInUser,
                  message: widget.message,
                  orgID: widget.orgID,
                orgSettings: widget.orgSettings,
              ))).then((x){
        _db.setUserMessageAsRead(widget.loggedInUser!.docID, widget.message.userMessage!.docID, widget.orgID);
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: appBar() as PreferredSizeWidget?,
      body: layout(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: widget.rolePermission.c!
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NewMessagePage(
                    loggedInUser: widget.loggedInUser,
                    rolePermission: widget.rolePermission,
                    isEdit: false,
                    message: new Message(),
                    orgID: widget.orgID,
                  )));
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
      title: Text('Chats'),
    );
  }

  Widget layout(){
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
    return body();
  }

  Widget _wideLayout(){
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: body(),
        ),
        if(selMessage.docID != null)
          Expanded(
            child: ChatPage(
              loggedInUser: widget.loggedInUser,
              message: selMessage,
              orgSettings: widget.orgSettings,
              orgID: widget.orgID,
            ),
          )
      ],
    );
  }

  Widget body() {
    return new Container(
      child: StreamBuilder(
        stream: FirebaseFirestore.instanceFor(app: Firebase.app(widget.orgID!)).collection('Messages').where(
            "to", arrayContains: widget.loggedInUser!.emailAddress).where('del', isEqualTo: false).orderBy('date', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            );
          } else {
            print("Count of messages retrieved from database: " + snapshot.data!.docs.length.toString());
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) {
                 return buildItem(context, snapshot.data!.docs[index]);},
              itemCount: snapshot.data!.docs.length,
            );
          }
        },
      ),
    );
  }

  buildItem(BuildContext context, DocumentSnapshot document) {
    Message message = Message.fromDb(document);
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("Organizations").doc(widget.orgID).collection('Users').doc(widget.loggedInUser!.docID).collection('UserMessages').where('messageID', isEqualTo: message.docID).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
        if(!snapshot.hasData || snapshot.data!.docs.length < 1){
          _db.addUserMessage(widget.loggedInUser!.docID, message, widget.orgID);
          return Container();
        }
        message.userMessage = UserMessage.fromDb(snapshot.data?.docs[0]);
        if(message.date!.isAfter(message.userMessage!.date!)){
          message.userMessage!.read = false;
        }
        messages.add(message);
        return Container(
          child: TextButton(
            child: Row(
              children: <Widget>[
                 Icon(
                    Icons.chat,
                    size: 45.0,
                    color: Colors.grey,
                  ),
                Flexible(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          child: Text(
                            '${message.subject}',style: TextStyle(color: Colors.black),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                        ),
                        Container(
                          child: Text(
                            '${message.date!.toUtc().toString().substring(0,11)}',
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                        )
                      ],
                    ),
                    margin: EdgeInsets.only(left: 20.0),
                  ),
                ),
              ],
            ),
            onPressed: () {
              if(isNarrowLayout) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ChatPage(
                              loggedInUser: widget.loggedInUser,
                              message: message,
                              orgSettings: widget.orgSettings,
                              orgID: widget.orgID,
                            ))).then((x) {
                  _db.setUserMessageAsRead(
                      widget.loggedInUser!.docID, message.userMessage!.docID,
                      widget.orgID);
                });
              }
              else{
                setState(() {
                  selMessage = message;
                });
              }
            },
            onLongPress: () {
              return _showBottom(message);
            },
            style: ButtonStyle(
              textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(color: Colors.black)),
              backgroundColor: MaterialStateProperty.all<Color?>(message.userMessage!.read!? Colors.grey[50] : Colors.blueGrey),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0)),
              shape: MaterialStateProperty.all<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)))
            ),
          ),
          margin: EdgeInsets.only(),
        );
      },
    );
  }

  void _showBottom(Message message) {
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
                        onPressed: widget.rolePermission.u! && message.admins!.contains(widget.loggedInUser!.emailAddress)? () {
                          Navigator.pop(context);
                          if(isNarrowLayout) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        NewMessagePage(
                                          loggedInUser: widget.loggedInUser,
                                          rolePermission: widget.rolePermission,
                                          isEdit: true,
                                          message: message,
                                          orgID: widget.orgID,
                                        )));
                          }else{
                            setState(() {
                              selMessage = message;
                            });
                          }
                        } : null,
                        child: Text("Edit"))
                  ]),
                  TableRow(children: [
                    new TextButton(
                        onPressed: widget.rolePermission.d! && message.admins!.contains(widget.loggedInUser!.emailAddress)? () {
                          Navigator.of(context).pop();
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Alert!"),
                                  content: Text("Are you sure you want to delete " +
                                      message.subject!),
                                  actions: <Widget>[
                                    new TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel')),
                                    new TextButton(
                                        onPressed: () async {
                                          await _db.deleteMessage(message.docID, widget.orgID!);
                                          Navigator.pop(context);
                                        },
                                        child: Text('Yes'))
                                  ],
                                );
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