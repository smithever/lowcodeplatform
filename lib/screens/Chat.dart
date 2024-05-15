import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/db.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smith_base_app/widgets/MessageWidgets.dart';
import 'package:file_picker/file_picker.dart';

class ChatPage extends StatelessWidget {
  ChatPage(
      {Key? key, required this.loggedInUser, required this.message, required this.orgID, required this.orgSettings})
      : super(key: key);

  final AppUser? loggedInUser;
  final Message message;
  final String? orgID;
  final OrgSettings orgSettings;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        backgroundColor: Colors.white38,
        appBar: appBar() as PreferredSizeWidget?,
        body: new ChatScreen(
          loggedInUser: this.loggedInUser,
          message: this.message,
          orgID: orgID,
          orgSettings: orgSettings,
        ));
  }

  Widget appBar() {
    return new AppBar(
      title: Text(this.message.subject!),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final AppUser? loggedInUser;
  final Message? message;
  final String? orgID;
  final OrgSettings? orgSettings;

  ChatScreen(
      {Key? key,
      required this.loggedInUser,
      this.message, this.orgID, this.orgSettings})
      : super(key: key);

  @override
  State createState() => new ChatScreenState(
      loggedInUser: this.loggedInUser,
      message: this.message,
      );
}

class ChatScreenState extends State<ChatScreen> {
  final AppUser? loggedInUser;
  final Message? message;
  final _db = DatabaseService();
  final OrgFileUploadParams? uploadParams;
  final greyColor = Color(0xffaeaeae);
  final greyColor2 = Color(0xffE8E8E8);
  final themeColor = Color(0xfff5a623);
  final primaryColor = Color(0xff203152);
  String? _downloadsDirectory;
  ScrollController _controller = ScrollController();


  ChatScreenState(
      {Key? key,
      required this.loggedInUser,
      this.message,
      this.uploadParams});

  List<Reply> listReply = <Reply>[];

  //File data
  var fileData;
  String fileType = '';
  String fileName = '';
  SettableMetadata? fileMetadata;
  bool filePendingSend = false;
  int? fileMessageType;
  double? fileSize;
  bool sendButtonEnabled = true;

  late bool isLoading;
  late bool isShowSticker;
  String? imageUrl;

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    try {
      FlutterDownloader.initialize();
    } catch (e) {}
    _controller.addListener(_scrollListener);
    super.initState();
    initDownloadsDirectoryState();
    focusNode.addListener(onFocusChange);
    isLoading = false;
    isShowSticker = false;
    imageUrl = '';
  }

  void _scrollListener() {
    print("scrolling");
    if (_controller.offset <= _controller.position.minScrollExtent &&
        !_controller.position.outOfRange) {
      print("at the end of list");
    }
  }

  Future<void> initDownloadsDirectoryState() async {
    PermissionStatus hasPermission = await Permission.mediaLibrary.status;
    if (hasPermission.isDenied) {
      await Permission.mediaLibrary.request();
    }
    String? downloadsDirectory;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      downloadsDirectory = (await getLibraryDirectory()).toString();
    } catch (e) {
      print('Could not get the downloads directory');
    }

    if (!mounted) return;

    setState(() {
      _downloadsDirectory = downloadsDirectory;
    });
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  onSendMessage(String content, int? type) async {
    // type: 0 = text, 1 = image, 2 = sticker, 3 = System, 4 = Voice Note, 5 = File, 6 = Contact, 7 = Video
    ProgressDialog pr = new ProgressDialog(context,
        message: Text("Loading..."), title: Text("Info!"));
    pr.setMessage(Text("Sending...."));
    sendButtonEnabled = false;
    if (filePendingSend) {
      pr.show();
      await Future.delayed(Duration(milliseconds: 300));
      String ret = await _db.uploadChatMedia(
          widget.message!.docID, fileData, fileMetadata, fileName, widget.orgID!);
      if (ret.contains('ERROR')) {
        setState(() {
          sendButtonEnabled = true;
          filePendingSend = false;
        });
        pr.dismiss();
        return Fluttertoast.showToast(msg: 'File upload failed');
      }
      content = ret;
      type = fileMessageType;
    }
    if (content.trim() != '') {
      pr.show();
      await Future.delayed(Duration(milliseconds: 300));
      textEditingController.clear();
      Reply reply = new Reply();
      reply.from = widget.loggedInUser!.emailAddress;
      reply.fromName =
          widget.loggedInUser!.firstName! + ' ' + widget.loggedInUser!.lastName!;
      reply.fileSizeMb = fileSize;
      reply.fileName = fileName;
      reply.content = content;
      reply.date = DateTime.now();
      reply.type = type;
      reply.del = false;

      _db.addReply(widget.message!.docID, reply, widget.orgID!);

      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      setState(() {
        sendButtonEnabled = true;
        filePendingSend = false;
      });
      pr.dismiss();
      return Fluttertoast.showToast(msg: 'Sent');
    } else {
      setState(() {
        sendButtonEnabled = true;
        filePendingSend = false;
      });
      pr.dismiss();
      return Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),

              // Sticker
              (isShowSticker ? Container() : Container()),

              // Input content
              Visibility(
                visible: message!.allowReplies! ||
                    message!.admins!.contains(widget.loggedInUser!.emailAddress),
                child: buildInput(),
              ),
            ],
          ),

          // Loading
          buildLoading()
        ],
      );
  }

  Widget buildListMessage() {
    return Flexible(
      child: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red)))
          : StreamBuilder(
              stream: FirebaseFirestore.instanceFor(app: Firebase.app(widget.orgID!))
                  .collection('Messages')
                  .doc(widget.message!.docID)
                  .collection('Replies')
                  .orderBy('date', descending: true)
                  //.limit(20)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.red)));
                } else {
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) =>
                        buildItem(index, snapshot.data!.docs[index]),
                    itemCount: snapshot.data!.docs.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot doc) {
    var ownLTRB = EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0);
    var otherLTRB = EdgeInsets.fromLTRB(10.0,0.0,0.0,0.0);
    //Build reply and listReply
    Reply reply = Reply.fromDb(doc);
    listReply.add(reply);
    if (reply.from == widget.loggedInUser!.emailAddress) {
      // Right (my message) show the message on the right side
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              // type: 0 = text, 1 = image, 2 = sticker, 3 = System, 4 = Voice Note, 5 = File, 6 = Contact, 7 = Video
                  reply.type == 0
                    ? MsgType0(reply: reply, marginLTRB: ownLTRB, color: greyColor2, textColor: Colors.black,)
                  : reply.type == 1
                    ? MsgType1(reply: reply, marginLTRB: ownLTRB, color: greyColor2, downloadDirectory: _downloadsDirectory,)
                  : reply.type == 2
                    ? MsgType2(reply: reply, marginLTRB: ownLTRB, color: greyColor2,)
                  : reply.type == 3
                    ? MsgType3(reply: reply, marginLTRB: ownLTRB, color: greyColor2,)
                  : reply.type == 4
                    ? MsgType4(reply: reply, marginLTRB: ownLTRB, color: greyColor2,)
                  : reply.type == 5
                    ? MsgType5(reply: reply, marginLTRB: ownLTRB, downloadDirectory: _downloadsDirectory, color: greyColor2, textColor: Colors.black,)
                  : reply.type == 6
                    ? MsgType6(reply: reply, marginLTRB: ownLTRB, color: greyColor2,)
                  : reply.type == 7
                    ? MsgType7(reply: reply, marginLTRB: ownLTRB, color: greyColor2,)
                  : Container()
            ],
            mainAxisAlignment: MainAxisAlignment.end,
          ),
          if(reply.type != 3)
          Container(
            child: Text(
              reply.date!
                  .toLocal()
                  .toString()
                  .substring(0, 16),
              style: TextStyle(
                  color: greyColor,
                  fontSize: 12.0,
                  fontStyle: FontStyle.italic),
            ),
            margin: EdgeInsets.only(
                right: 10.0, top: 5.0, bottom: isLastMessageRight(index) ? 20.0 : 10.0,),
            alignment: Alignment.bottomRight,
          )
        ],
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                if(reply.type != 3)
                Material(
                  child: Container(
                    child: Center(
                      child: Tooltip(
                        message: reply.fromName!.trim(),
                        child: Text(reply.fromName!
                            .trim()
                            .substring(0, 1)
                            .toUpperCase()),
                      ),
                    ),
                    width: 35.0,
                    height: 35.0,
                    padding: EdgeInsets.all(5.0),
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(18.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                  color: Color.fromRGBO(153, 0, 0, 1.0),
                ),
                // type: 0 = text, 1 = image, 2 = sticker, 3 = System, 4 = Voice Note, 5 = File, 6 = Contact, 7 = Video
                    reply.type == 0
                    ? MsgType0(reply: reply, marginLTRB: otherLTRB, color: Colors.black45, textColor: Colors.white,)
                    : reply.type == 1
                    ? MsgType1(reply: reply, marginLTRB: otherLTRB, color: Color.fromRGBO(153, 0, 0, 1.0), downloadDirectory: _downloadsDirectory,)
                    : reply.type == 2
                    ? MsgType2(reply: reply, marginLTRB: otherLTRB, color: Colors.indigoAccent,)
                    : reply.type == 3
                    ? MsgType3(reply: reply, marginLTRB: otherLTRB, color: Colors.indigoAccent,)
                    : reply.type == 4
                    ? MsgType4(reply: reply, marginLTRB: otherLTRB, color: Colors.indigoAccent,)
                    : reply.type == 5
                    ? MsgType5(reply: reply, marginLTRB: otherLTRB, downloadDirectory: _downloadsDirectory, color: Color.fromRGBO(153, 0, 0, 1.0), textColor: Colors.white,)
                    : reply.type == 6
                    ? MsgType6(reply: reply, marginLTRB: otherLTRB, color: Colors.indigoAccent,)
                    : reply.type == 7
                    ? MsgType7(reply: reply, marginLTRB: otherLTRB, color: Colors.indigoAccent,)
                    : Container(),
              ],
            ),
            // Time
            if(reply.type != 3)
            Container(
              child: Text(
                reply.date!.toLocal().toString().substring(0, 16),
                style: TextStyle(
                    color: greyColor,
                    fontSize: 12.0,
                    fontStyle: FontStyle.italic),
              ),
              margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
            )
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }


  bool isLastMessageLeft(int index) {
    if ((index > 0  &&
            listReply[index - 1].from == widget.loggedInUser!.emailAddress) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listReply[index - 1].from != widget.loggedInUser!.emailAddress) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          //Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.attach_file),
                onPressed: getFile,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
          // Button to add Stickers
//          Material(
//            child: new Container(
//              margin: new EdgeInsets.symmetric(horizontal: 1.0),
//              child: new IconButton(
//                icon: new Icon(Icons.face),
//                onPressed: getSticker,
//                color: primaryColor,
//              ),
//            ),
//            color: Colors.white,
//          ),
          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: primaryColor, fontSize: 15.0),
                controller: textEditingController,
                enabled: !filePendingSend,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: greyColor),
                ),
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 1,
              ),
            ),
          ),
          Visibility(
            visible: filePendingSend,
            child: Material(
              child: new Container(
                margin: new EdgeInsets.symmetric(horizontal: 8.0),
                child: new IconButton(
                  icon: new Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      textEditingController.text = '';
                      filePendingSend = false;
                    });
                  },
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
          ),
          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () {
                  if (sendButtonEnabled) {
                    onSendMessage(textEditingController.text, 0);
                  }
                },
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border:
              new Border(top: new BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
    );
  }


  Future<void> getFile() async {
    FilePickerResult result = await (FilePicker.platform.pickFiles(
      allowMultiple: false,
    ) as Future<FilePickerResult>);

    for (PlatformFile file in result.files) {
      bool fileSupported = false;
      // clear file values
      fileType = '';
      fileName = '';
      fileMetadata = null;
      filePendingSend = false;
      fileMessageType = null;
      fileData = file.bytes;
      fileSize = double.parse(file.size.toString());
      fileType = file.path!
          .split('.')
          .last;
      fileName = file.path!
          .split('/')
          .last;
      print('File: ' +
          fileName +
          ' retrieved. Setting all values now. FileType: ' +
          fileType +
          ' FileName: ' +
          fileName +
          ' FileSize: ' +
          fileSize.toString() +
          'mb');
      if (widget.orgSettings!.uploadParams!.videoFileTypes!.contains(fileType)) {
        if (fileSize! > widget.orgSettings!.uploadParams!.maxVideoMb!) {
          Fluttertoast.showToast(
              msg: 'Max file upload size allowed: ' +
                  widget.orgSettings!.uploadParams!.maxVideoMb.toString() +
                  'MB');
          return;
        }else {
          fileMetadata = new SettableMetadata(contentType: 'video/' + fileType);
          fileMessageType = 7;
          fileSupported = true;
        }
      }
      if (widget.orgSettings!.uploadParams!.imageFileTypes!.contains(fileType)) {
        if (fileSize! > widget.orgSettings!.uploadParams!.maxImageMb!) {
          Fluttertoast.showToast(
              msg: 'Max file upload size allowed: ' +
                  widget.orgSettings!.uploadParams!.maxImageMb.toString() +
                  'MB');
          return;
        }else {
          fileMetadata = new SettableMetadata(contentType: 'image/' + fileType);
          fileMessageType = 1;
          fileSupported = true;
        }
      }
      if (widget.orgSettings!.uploadParams!.audioFileTypes!.contains(fileType)) {
        if (fileSize! > widget.orgSettings!.uploadParams!.maxAudioMb!) {
          Fluttertoast.showToast(
              msg: 'Max file upload size allowed: ' +
                  widget.orgSettings!.uploadParams!.maxAudioMb.toString() +
                  'MB');
          return;
        }else {
          fileMetadata = new SettableMetadata(contentType: 'audio/' + fileType);
          fileMessageType = 4;
          fileSupported = true;
        }
      }
      if (widget.orgSettings!.uploadParams!.documentFileTypes!.contains(fileType)) {
        if (fileSize! > widget.orgSettings!.uploadParams!.maxDocumentMb!) {
          Fluttertoast.showToast(
              msg: 'Max file upload size allowed: ' +
                  widget.orgSettings!.uploadParams!.maxDocumentMb.toString() +
                  'MB');
          return;
        }else {
          fileMetadata = new SettableMetadata(contentType: 'application/' + fileType);
          fileMessageType = 5;
          fileSupported = true;
        }
      }
      if (widget.orgSettings!.uploadParams!.otherFileTypes!.contains(fileType)) {
        if (fileSize! > widget.orgSettings!.uploadParams!.maxOtherMb!) {
          Fluttertoast.showToast(
              msg: 'Max file upload size allowed: ' +
                  widget.orgSettings!.uploadParams!.maxOtherMb.toString() +
                  'MB');
          return;
        }else {
          fileMetadata =
          new SettableMetadata(contentType: 'application/' + fileType);
          fileMessageType = 5;
          fileSupported = true;
        }
      }
      if (!fileSupported) {
        Fluttertoast.showToast(
            msg: "Upload of filetype " + fileType + ' is not allowed!');
        return;
      }
      setState(() {
        filePendingSend = true;
        textEditingController.text = fileName;
      });
      setState(() => fileSize);
      setState(() => fileType);
      setState(() => fileName);
      setState(() => fileData);
      setState(() => fileMetadata);
      setState(() => fileMessageType);
      return null;
    }
  }

}
