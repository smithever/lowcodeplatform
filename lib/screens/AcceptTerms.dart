import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:ndialog/ndialog.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/services/auth.dart';
import 'package:smith_base_app/services/db.dart';

class AcceptTermsPage extends StatefulWidget {
  AcceptTermsPage({Key? key, this.auth, this.loggedUser, this.logoutCallback, this.loginCallBack})
      : super(key: key);

  final BaseAuth? auth;
  final AppUser? loggedUser;
  final VoidCallback? logoutCallback;
  final VoidCallback? loginCallBack;

  @override
  State<StatefulWidget> createState() => new _AcceptTermsPageState();
}

class _AcceptTermsPageState extends State<AcceptTermsPage> {
  final _db = DatabaseService();
  List<TermsAndConditions> lstTC = <TermsAndConditions>[];
  bool dataLoaded = false;

  @override
  void initState() {
    loafData();
    super.initState();
  }

  void loafData() async{
    lstTC = await _db.getTermsAndConditions();
    setState(() => lstTC);
    setState(() => dataLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    ProgressDialog pr = new ProgressDialog(context,
        message: Text("Loading..."), title: Text("Info!"));
    return new Scaffold(
        appBar: appBar() as PreferredSizeWidget?,
        body: tcList(),
        bottomNavigationBar: TextButton(
          child: Text(" I accept all terms listed above", style: TextStyle(color: Colors.blue, fontSize: 18),),
          onPressed: ()async{
            pr.show();
            await _db.acceptTerms(widget.loggedUser!.docID, lstTC);
            await Future.delayed(Duration(seconds: 3));
            pr.dismiss();
            widget.loginCallBack!();
          },
        ),
    );
  }

  Widget appBar(){
    return new AppBar(
      title: Text('Accept Terms and Conditions'),
    );
  }

  Widget tcList(){
    if (!dataLoaded) {
    return LinearProgressIndicator();
    } else {
      return ListView.builder(
            itemCount: lstTC.length,
            shrinkWrap: true,
            physics: ScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              return ExpansionTile(
                title: Text(lstTC[index].name!),
                children: [
                  MyInAppWebView(
                      webUrl: lstTC[index].url,
                      webRect: Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, 600),
                    ),
                ],
              );
            }
        );
    }
  }

}

class MyInAppWebView extends StatelessWidget {
  String? webUrl;
  final Rect? webRect;
  InAppWebViewController? webView;
  MyInAppWebView({Key? key, this.webUrl, this.webRect}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var height = webRect!.height;
    InAppWebView webWidget = new InAppWebView(
      gestureRecognizers: Set()
        ..add(
          Factory<OneSequenceGestureRecognizer>(
                () => new EagerGestureRecognizer(),
          ),
        ),

        initialUrlRequest: new URLRequest(url: Uri.parse(webUrl!)),
        onWebViewCreated: (InAppWebViewController controller) {
          webView = controller;
        },
        onLoadStart:(InAppWebViewController controller, Uri? url) => _onLoadStart(controller, url),
        onProgressChanged: (InAppWebViewController controller, int progress) {
          double prog = progress / 100;
          print('InAppWebView.onProgressChanged: $prog');
        },
      onLoadStop: (InAppWebViewController controller, Uri? url) {
        controller.evaluateJavascript(source: '''(() => { return document.body.scrollHeight;})()''').then((value) {
          if(value == null || value == '') {
            return;
          }
          height = double.parse('$value');
        });
      },
    );
    return Container(
      width: webRect!.width,
      height: height,
      //margin: const EdgeInsets.all(10.0),
      child: webWidget
    );
  }

  void _onLoadStart(InAppWebViewController controller, Uri? url) {
    print("InAppWebView.onLoadStart: $url");
    this.webUrl = url.toString();
  }


}