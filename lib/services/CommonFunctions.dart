import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:open_file/open_file.dart';

class CommonFunctionsService {

  RolePermission getPagePermission(List<RolePermission> lstRolePerm, AppPage page, bool? isPriv){
    RolePermission perm = new RolePermission();
    if(lstRolePerm.length > 0) {
      if (lstRolePerm.where((RolePermission permission) =>
      permission.name == page.name).length > 0) {
        perm = lstRolePerm.firstWhere((RolePermission permission) => permission
            .name == page.name);
      }
    }
    if(perm.docID == null && isPriv! && page.showForPrivUser! && page.menu == "main"){
      perm = new RolePermission(
          name: page.name,
          roleID: "",
          description: page.description,
          c: true,
          r: true,
          u: true,
          d: true,
          del: false,
          hidden: true
      );
    }
    return perm;
  }

  Future<String> fileDownload(String url, _downloadsDirectory) async {
    print("Downloading the file");
    String ret = "";
    Stream<FileResponse> fileResponse = DefaultCacheManager().getFileStream(url, withProgress: true);
    FileInfo fileInfo = await (fileResponse.first as Future<FileInfo>);
    File file = new File(_downloadsDirectory + "/" + fileInfo.file.path.split('/').last);
    if (file.existsSync()){
      print("File already exists");
      Fluttertoast.showToast(msg: "File already exists");
      OpenFile.open(file.path);
    }
    else{
      print("File not found downloading the file from the server");
      file.writeAsBytesSync(fileInfo.file.readAsBytesSync());
      OpenFile.open(file.path);
    }
    return ret;

  }

  Future<dynamic> showMessage(String title, String content, BuildContext context){
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              new TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'))
            ],
          );
        });
  }

  Future<Map> getJsonFromFile() async {
    Map ret = {};
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result!.files.length < 1) {
      Fluttertoast.showToast(
          msg: "No file uploaded");
      return ret;
    }
    PlatformFile file = result.files[0];
    // clear file values
    String fileType = file.name.split(".").last;
    if (fileType != 'json') {
      Fluttertoast.showToast(
          msg: "Upload of filetype " + fileType + ' is not allowed! Please upload valid .json file');
      return ret;
    }
    String fileContent = Utf8Codec().decode(file.bytes!.toList());
    ret = await json.decode(fileContent);
    return ret;
  }
}
