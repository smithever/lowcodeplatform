import 'package:flutter/material.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'dart:io';

class ErrorPage extends StatefulWidget {
  ErrorPage(
      {Key? key, this.errorMessage})
      : super (key: key);

  final ErrorMessage? errorMessage;

  @override
  State<StatefulWidget> createState() => new _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  ErrorMessage? _errorMessage = new ErrorMessage();
  bool _initDone = false;

  @override
  void initState(){
    _errorMessage = widget.errorMessage;
    _initDone = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    return new Scaffold(
      appBar: new AppBar(
        title: Text("Error!"),
        backgroundColor: Colors.red,
      ),
      body: _initDone
        ? _body()
        : new LinearProgressIndicator()
    );
  }

  Widget _body() {
    return new Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.error),
            title: Text(_errorMessage!.title!),
            subtitle: Text(_errorMessage!.details!),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                child: const Text('RETRY'),
                onPressed: () {Navigator.pop(context);},
              ),
              const SizedBox(width: 8),
              TextButton(
                child: const Text('CLOSE'),
                onPressed: () {exit(0);},
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}
