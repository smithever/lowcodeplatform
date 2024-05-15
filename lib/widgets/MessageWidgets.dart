import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smith_base_app/services/CommonFunctions.dart';
import 'package:photo_view/photo_view.dart';

final CommonFunctionsService _common = new CommonFunctionsService();
// type: 0 = text, 1 = image, 2 = sticker, 3 = System, 4 = Voice Note, 5 = File, 6 = Contact, 7 = Video
//Message type: 0 text
class MsgType0 extends StatelessWidget {
  final Reply? reply;
  final marginLTRB;
  final Color? color;
  final Color? textColor;

  MsgType0({this.reply, this.marginLTRB, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Text(
          reply!.content!,
          style: TextStyle(color: textColor),
        ),
        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
        width: MediaQuery.of(context).size.width * 0.65,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.0)),
        margin: marginLTRB
    );
  }
}



//Message type: 1 image
class MsgType1 extends StatelessWidget {
  final Reply? reply;
  final marginLTRB;
  final color;
  final downloadDirectory;
  final greyColor = Color(0xffaeaeae);
  final greyColor2 = Color(0xffE8E8E8);
  final themeColor = Color(0xfff5a623);
  final primaryColor = Color(0xff203152);

  MsgType1({this.reply, this.marginLTRB, this.color, this.downloadDirectory});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Wrap(
        children: [
        TextButton(
          child: Material(
            child: CachedNetworkImage(
              placeholder: (context, url) =>
                  Container(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          themeColor),
                    ),
                    width:
                    MediaQuery
                        .of(context)
                        .size
                        .width * 0.65,
                    height: 200.0,
                    padding: EdgeInsets.all(70.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                  ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageUrl: reply!.content!,
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.65,
              height: 200.0,
              fit: BoxFit.cover,
            ),
            borderRadius:
            BorderRadius.all(Radius.circular(8.0)),
            clipBehavior: Clip.hardEdge,
          ),
          onPressed: () {
            print("Photo Viewer Actioned");
            Navigator.push(context,MaterialPageRoute(
              builder: (context) => AppPhotoView(imageURL: reply!.content,)
            ));
            return;
          },
        ),
          Container(
            padding: EdgeInsets.fromLTRB(0.0, 65.0, 5.0, 0.0),
            child: Center(
              child: Material(
                child: IconButton(
                  icon: Icon(
                    Icons.file_download,
                    size: 45.0,
                    color: color,
                  ),
                  onPressed: () {
                    _common.fileDownload(reply!.content!, downloadDirectory);
                  },
                ),
                borderRadius:
                BorderRadius.all(Radius.circular(1.0)),
                clipBehavior: Clip.hardEdge,
                color: Color.fromRGBO(0, 0, 0, 0),
              ),
            ),
          ),
        ]),
        margin: marginLTRB
    );
  }
}

//Message type: 2 sticker
class MsgType2 extends StatelessWidget {
  final Reply? reply;
  final marginLTRB;
  final color;

  MsgType2({this.reply, this.marginLTRB, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(

    );
  }
}

//Message type: 3 system
class MsgType3 extends StatelessWidget {
  final Reply? reply;
  final marginLTRB;
  final color;

  MsgType3({this.reply, this.marginLTRB, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          child: Text(
            reply!.content!,
            style: TextStyle(color: Colors.white),
          ),
          padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
          width: MediaQuery.of(context).size.width * 0.50,
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8.0)),
        margin: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.25, 0.0, 0.0, 0.0),
      )
    );
  }
}

//Message type: 4 Voice Note
class MsgType4 extends StatelessWidget {
  final Reply? reply;
  final marginLTRB;
  final color;

  MsgType4({this.reply, this.marginLTRB, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(

    );
  }
}

//Message type: 5 File
class MsgType5 extends StatelessWidget {
  final Reply? reply;
  final marginLTRB;
  final downloadDirectory;
  final Color? color;
  final Color? textColor;

  MsgType5({this.reply, this.marginLTRB, this.downloadDirectory, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Wrap(
          children: <Widget>[
            Material(
              child: IconButton(
                icon: Icon(
                  Icons.file_download,
                  size: 45.0,
                  color: color,
                ),
                onPressed: () {
                  _common.fileDownload(reply!.content!, downloadDirectory);
                },
              ),
              borderRadius:
              BorderRadius.all(Radius.circular(1.0)),
              clipBehavior: Clip.hardEdge,
              color: Color.fromRGBO(0, 0, 0, 0),
            ),
            Container(
              child: Text(
                reply!.fileName!,
                style: TextStyle(color: textColor),
                overflow: TextOverflow.clip,
              ),
              padding:
              EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
              width: MediaQuery.of(context).size.width * 0.65,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.0)),
              margin: EdgeInsets.only(left: 10.0),
            ),
          ],
        ),
        margin: marginLTRB
    );
  }
}

//Message type: 6 Contact
class MsgType6 extends StatelessWidget {
  final Reply? reply;
  final marginLTRB;
  final color;

  MsgType6({this.reply, this.marginLTRB, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(

    );
  }
}

//Message type: 7 Video
class MsgType7 extends StatelessWidget {
  final Reply? reply;
  final marginLTRB;
  final color;

  MsgType7({this.reply, this.marginLTRB, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(

    );
  }
}

class AppPhotoView extends StatelessWidget {
  final imageURL;
  AppPhotoView({this.imageURL});
  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
          imageProvider: NetworkImage(imageURL),
        )
    );
  }
}

