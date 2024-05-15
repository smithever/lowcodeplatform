import 'package:cloud_firestore/cloud_firestore.dart';

class AppPage {
  String? name;
  String? description;
  String? menu;
  int? iconCode;
  bool? showForPrivUser;
  bool? regOrgDB;

  AppPage({
    this.name,
    this.description,
    this.menu,
    this.iconCode,
    this.showForPrivUser,
    this.regOrgDB
  });
  factory AppPage.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return AppPage(
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      menu: data['menu'] ?? "",
      iconCode: data['iconCode'] ?? 58840,
      showForPrivUser: data['showForPrivUser'] ?? false,
      regOrgDB: data['regOrgDB'] ?? false
    );
  }
}

class ErrorMessage {
  String? title;
  String? details;
  ErrorMessage({
    this.title,
    this.details
});
}

class TermsAndConditions{
  String? docID;
  String? name;
  DateTime? lastUpdated;
  String? url;

  TermsAndConditions({
    this.docID,
    this.name,
    this.lastUpdated,
    this.url
  });
  factory TermsAndConditions.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return TermsAndConditions(
        docID: doc.id,
        name: data['name'] ?? '',
        lastUpdated: data['lastUpdated'].toDate() ?? '' as DateTime?,
        url: data['url'] ?? ''
    );
  }
}

class GeneralConfig{
  bool? requireAcceptTerms;
  String? newUserID;
  String? adminUserID;

  GeneralConfig({
    this.requireAcceptTerms,
    this.newUserID,
    this.adminUserID
});

  factory GeneralConfig.fromDB(QuerySnapshot q){
    var requireAcceptTerms = q.docs.firstWhere((DocumentSnapshot doc) => doc.id == "tc").data() as Map<String, dynamic>;
    var newUserID = q.docs.firstWhere((DocumentSnapshot doc) => doc.id == "GenRoles").data() as Map<String, dynamic>;
    var adminUserID = q.docs.firstWhere((DocumentSnapshot doc) => doc.id == "GenRoles").data() as Map<String, dynamic>;
    return GeneralConfig(
      requireAcceptTerms: requireAcceptTerms["requireAcceptTerms"] ?? false,
      newUserID: newUserID["newUser"] ?? false as String?,
      adminUserID: adminUserID["adminUser"] ?? false as String?,
    );
  }

}


class AppUser {
  String? docID;
  DateTime? dateCreated;
  String? createdByUserID;
  List<dynamic>? qString;
  String? roleID;
  String? ID;
  String? firstName;
  String? lastName;
  String? employeeNumber;
  String? cell;
  String? emailAddress;
  List<dynamic>? orgIDs;
  bool? del;
  bool? priv;
  String? lastUpdatedByUserID;
  var token;
  String? password;

  AppUser({
    this.docID,
    this.ID,
    this.dateCreated,
    this.qString,
    this.createdByUserID,
    this.roleID,
    this.firstName,
    this.lastName,
    this.employeeNumber,
    this.cell,
    this.emailAddress,
    this.del,
    this.priv,
    this.lastUpdatedByUserID,
    this.token,
    this.orgIDs,
    this.password
  });

  factory AppUser.fromDB(DocumentSnapshot doc){
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
        docID: doc.id,
        qString: data['qString'],
        dateCreated: data['dateCreated'].toDate() ?? '' as DateTime?,
        createdByUserID: data['createdByUserID'] ?? '',
        roleID: data['roleID'] ?? '',
        ID: data['ID'] ?? '',
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        cell: data['cell'] ?? '',
        emailAddress: data['emailAddress'] ?? '',
        del: data['del'] ?? 0 as bool?,
        priv: data['priv'] ?? 0 as bool?,
        lastUpdatedByUserID: data['lastUpdatedByUserID'] ?? '',
        token: data['lastUpdatedByUserID'] ?? '',
        orgIDs: data['orgIDs'],
        password: data['password'] ?? ''
    );
  }
}

class OrgUser {
  String? docID;
  DateTime? dateCreated;
  String? createdByUserID;
  String? roleID;
  List<dynamic>? qString;
  String? lastUpdatedByUserID;
  String? firstName;
  String? lastName;
  bool? del;

  OrgUser({
    this.docID,
    this.del,
    this.firstName,
    this.roleID,
    this.qString,
    this.createdByUserID,
    this.dateCreated,
    this.lastName,
    this.lastUpdatedByUserID
});

  factory OrgUser.fromDB(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return OrgUser(
      docID: doc.id,
      del: data['del'] ?? false,
      firstName: data['firstName'] ?? '',
      roleID: data['roleID'] ?? '',
      qString: data['qString'],
      createdByUserID: data['createdByUserID'] ?? '',
      dateCreated: data['dateCreated'].toDate() ?? '' as DateTime?,
      lastName: data['lastName'] ?? '',
      lastUpdatedByUserID: data['lastUpdatedByUserID'] ?? ''
    );
  }
}

class UserRole {
  String? docID;
  String? name;
  bool? del;
  bool? hidden;

  UserRole({
    this.docID,
    this.name,
    this.del,
    this.hidden,
  });

  factory UserRole.fromDB(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserRole(
        docID: doc.id,
        name: data['name'] ?? '',
        del: data['del'] ?? false,
        hidden: data['hidden'] ?? false,
    );
  }

}

class RolePermission{
  String? docID;
  String? roleID;
  String? name;
  String? description;
  bool? c;
  bool? r;
  bool? u;
  bool? d;
  bool? del;
  bool? hidden;

  RolePermission({
    this.docID,
    this.roleID,
    this.name,
    this.description,
    this.c,
    this.r,
    this.u,
    this.d,
    this.del,
    this.hidden
  });

  factory RolePermission.fromDB(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return RolePermission(
        docID: doc.id,
        roleID: data['roleID'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        c: data['c'] ?? false,
        r: data['r'] ?? false,
        u: data['u'] ?? false,
        d: data['d'] ?? false,
        del: data['del'] ?? false,
        hidden: data['hidden'] ?? false
    );
  }

  factory RolePermission.fromJson(Map data) {
    return RolePermission(
        docID: "",
        roleID: data['roleID'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        c: data['c'] ?? false,
        r: data['r'] ?? false,
        u: data['u'] ?? false,
        d: data['d'] ?? false,
        del: data['del'] ?? false,
        hidden: data['hidden'] ?? false
    );
  }

  Map<String, dynamic> toJson(){
    return{
      "roleID": roleID,
      "name": name,
      "description": description,
      "c": c,
      "r": r,
      "u": u,
      "d": d,
      "del": del,
      "hidden": hidden
    };
  }

}

class Organization{
  String? docID;
  String? name;
  String? tel;
  String? address;

  Organization({
    this.docID,
    this.name,
    this.tel,
    this.address
});

  factory Organization.fromDB(DocumentSnapshot doc){
    Map data = doc.data() as Map<String, dynamic>;
    return Organization(
      docID: doc.id,
      name: data["Name"] ?? '',
      tel: data["Tel"] ?? '',
      address: data["Address"] ?? ''
    );
  }
}

class AcceptedTerms{
  String? docID;
  String? termID;
  String? name;
  DateTime? dateAccepted;

  AcceptedTerms({
    this.docID,
    this.termID,
    this.name,
    this.dateAccepted
  });

  factory AcceptedTerms.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return AcceptedTerms(
        docID: doc.id,
        termID: data["termID"]??'',
        name: data["name"]??'',
        dateAccepted: data["dateAccepted"].toDate() ??'' as DateTime?
    );
  }
}

class Message {
  String? docID;
  String? from;
  List<dynamic>? to;
  List<dynamic>? admins;
  String? subject;
  DateTime? date;
  int? type;
  bool? del;
  bool? allowReplies;
  UserMessage? userMessage;

  Message({
    this.docID,
    this.from,
    this.to,
    this.admins,
    this.subject,
    this.date,
    this.type,
    this.del,
    this.allowReplies,
    this.userMessage
  });

  factory Message.fromDb(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return Message(
        docID: doc.id,
        from: data['from'] ?? '',
        to: data['to'] ?? '' as List<dynamic>?,
        admins: data['admins'] ?? '' as List<dynamic>?,
        subject: data['subject'] ?? '',
        date: data['date'].toDate() ?? '' as DateTime?,
        type: data['type'] ?? 0,
        del: data['del'] ?? false,
        allowReplies: data['allowReplies'] ?? false,
        userMessage: new UserMessage()
    );
  }
}

class Reply {
  String? docID;
  String? from;
  String? fromName;
  String? content;
  String? fileName;
  double? fileSizeMb;
  DateTime? date;
  int? type;
  bool? del;

  Reply({
    this.docID,
    this.from,
    this.fromName,
    this.content,
    this.fileName,
    this.fileSizeMb,
    this.date,
    this.type,
    this.del
  });
  factory Reply.fromDb(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return Reply(
        docID: doc.id,
        from: data['from'] ?? '',
        fromName: data['fromName'] ?? '',
        content: data['content'] ?? '',
        fileName: data['fileName'] ?? '',
        fileSizeMb: data['fileSizeMb'] ?? 0,
        date: data['date'].toDate() ?? '' as DateTime?,
        type: data['type'] ?? 0,
        del: data['del'] ?? false
    );
  }
}

class UserMessage {
  String? docID;
  String? orgID;
  String? messageID;
  DateTime? date;
  String? subject;
  bool? del;
  bool? read;
  bool? notificationsOn;
  bool? isFavorite;

  UserMessage({
    this.docID,
    this.messageID,
    this.date,
    this.subject,
    this.del,
    this.read,
    this.notificationsOn,
    this.isFavorite,
    this.orgID
  });
  factory UserMessage.fromDb(DocumentSnapshot? doc){
    var data = doc?.data() as Map<String, dynamic>;
    return UserMessage(
        docID: doc?.id,
        messageID: data['messageID'] ?? '',
        date: data['date'].toDate() ?? '' as DateTime?,
        subject: data['subject'] ?? '',
        del: data['del'] ?? false,
        read: data['read'] ?? false,
        notificationsOn: data['notificationsOn'] ?? true,
        isFavorite: data['isFavorite'] ?? false,
        orgID: data["orgID"] ?? ""
    );
  }
}

class OrgSettings{
  OrgCounters? counters;
  OrgFileUploadParams? uploadParams;
  OrgMedia? media;
  OrgTheme? theme;
  OrgFirestoreSettings? firestoreSettings;

  OrgSettings({
    this.firestoreSettings,
    this.uploadParams,
    this.counters,
    this.media,
    this.theme,
});

  factory OrgSettings.fromDB(QuerySnapshot q){
    return OrgSettings(
      counters: OrgCounters.fromDB(q.docs.firstWhere((DocumentSnapshot doc) => doc.id == "counters")),
      uploadParams: OrgFileUploadParams.fromDB(q.docs.firstWhere((DocumentSnapshot doc) => doc.id == "uploadParams")),
      //TODO: Create a new class to store global org media such as logo
      media: new OrgMedia(),
      theme: OrgTheme.fromDB(q.docs.firstWhere((DocumentSnapshot doc) => doc.id == "theme")),
      firestoreSettings: OrgFirestoreSettings.fromDB(q.docs.firstWhere((DocumentSnapshot doc) => doc.id == "firestoreSettings"))
    );
  }

  List<String> keys(){
    return [
      "counters",
      "uploadParams",
      "media",
      "theme",
      "firestoreSettings"
    ];
  }

}

class OrgCounters{
  int? invoiceNo;
  int? quotationNo;
  int? statementNo;

  OrgCounters({
    this.invoiceNo,
    this.quotationNo,
    this.statementNo
});

  factory OrgCounters.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return OrgCounters(
      invoiceNo: data["invoiceNo"] ?? 0,
      quotationNo: data["quotationNo"] ?? 0,
      statementNo: data["statementNo"] ?? 0
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'invoiceNo': invoiceNo,
      'quotationNo': quotationNo,
      'statementNo': statementNo
    };
  }
}

class OrgFileUploadParams{
  List<dynamic>? imageFileTypes;
  int? maxImageMb;
  List<dynamic>? otherFileTypes;
  int? maxOtherMb;
  List<dynamic>? videoFileTypes;
  int? maxVideoMb;
  List<dynamic>? audioFileTypes;
  int? maxAudioMb;
  List<dynamic>? documentFileTypes;
  int? maxDocumentMb;

  OrgFileUploadParams({
    this.audioFileTypes,
    this.documentFileTypes,
    this.imageFileTypes,
    this.maxAudioMb,
    this.maxDocumentMb,
    this.maxImageMb,
    this.maxOtherMb,
    this.maxVideoMb,
    this.otherFileTypes,
    this.videoFileTypes,
});

  factory OrgFileUploadParams.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return OrgFileUploadParams(
      audioFileTypes: data["audioFileTypes"] ?? <dynamic>[],
      documentFileTypes: data["documentFileTypes"] ?? <dynamic>[],
      imageFileTypes: data["imageFileTypes"] ?? <dynamic>[],
      maxAudioMb: data["maxAudioMb"] ?? 0,
      maxDocumentMb: data["maxDocumentMb"] ?? 0,
      maxImageMb: data["maxImageMb"] ?? 0,
      maxOtherMb: data["maxOtherMb"] ?? 0,
      maxVideoMb: data["maxVideoMb"] ?? 0,
      otherFileTypes: data["otherFileTypes"] ?? <dynamic>[],
      videoFileTypes: data["videoFileTypes"] ?? <dynamic>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audioFileTypes': audioFileTypes,
      'documentFileTypes': documentFileTypes,
      'imageFileTypes': imageFileTypes,
      'maxAudioMb': maxAudioMb,
      'maxDocumentMb': maxDocumentMb,
      'maxImageMb': maxImageMb,
      'maxOtherMb': maxOtherMb,
      'maxVideoMb': maxVideoMb,
      'otherFileTypes': otherFileTypes,
      'videoFileTypes': videoFileTypes
    };
  }

}

class OrgTheme{
  String? color;
  bool? darkMode;

  OrgTheme({
    this.color,
    this.darkMode
});

  factory OrgTheme.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return OrgTheme(
      color: data["color"] ?? "0xFF990000",
      darkMode: data["darkMode"] ?? true
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'color': color,
      'darkMode': darkMode
    };
  }
}

class OrgFirestoreSettings{
  String? apiKey;
  String? appId;
  String? projectId;
  String? messagingSenderId;
  Map? privKeyJson;

  OrgFirestoreSettings({
    this.apiKey,
    this.appId,
    this.messagingSenderId,
    this.projectId,
    this.privKeyJson,
});

  factory OrgFirestoreSettings.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return OrgFirestoreSettings(
      apiKey: data["apiKey"] ?? "",
      messagingSenderId: data["messagingSenderId"] ?? "",
      appId: data["appId"] ?? "",
      projectId: data["projectId"] ?? "",
      privKeyJson: data["privKeyJson"] ?? {}
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'apiKey': apiKey,
      'messagingSenderId': messagingSenderId,
      'appId': appId,
      'projectId': projectId,
      'privKeyJson': privKeyJson
    };
  }

}

class OrgDataTable{
  String? docID;
  List<OrgDataColumn>? columns = <OrgDataColumn>[];
  String? primaryKeyID;
  String? name;
  String? description;
  bool? del;
  List<RolePermission>? permissions;

  OrgDataTable({
    this.docID,
    this.columns,
    this.primaryKeyID,
    this.name,
    this.description,
    this.del,
    this.permissions
  });

  factory OrgDataTable.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    List<OrgDataColumn> c = <OrgDataColumn>[];
    List<RolePermission> p = <RolePermission>[];
    for(Map column in data["columns"]){
      c.add(OrgDataColumn.fromJson(column));
    }
    for(Map perm in data["permissions"]){
      p.add(RolePermission.fromJson(perm));
    }
    return OrgDataTable(
      docID: doc.id,
      columns: c,
      primaryKeyID: data["primaryKeyID"] ?? "",
      name: data["name"] ?? "",
      description: data["name"] ?? "",
      del: data["del"] ?? false,
      permissions: p
    );
  }

  List<String?> getKeys(){
    List<String?> ret = <String?>[];
    for(OrgDataColumn column in columns!){
      ret.add(column.name);
    }
    return ret;
  }

  Map<String, dynamic> toJson(){
    print("Called DataTable to json");
    var c = [];
    if(columns!.isNotEmpty){
    for(OrgDataColumn column in columns!){
      if(column.name != null) {
        c.add(column.toJson());
      }
    }}
    print(c.toString());
    var p = [];
    if(permissions!.isNotEmpty) {
      for (RolePermission perm in permissions!) {
        if(perm.roleID != "") {
          p.add(perm.toJson());
        }
      }
    }
    print(p.toString());
    return{
      "columns": c,
      "primaryKeyID" : primaryKeyID,
      "name" : name,
      "description" : description,
      "del": del,
      "permissions": p
    };
  }
}

class OrgDataColumn{
  String? docID;
  String? name;
  String? type;
  int? maxLength;
  int? minLength;
  bool? canSearch;
  bool? del;
  String? regex;
  bool? unique;
  String? expression;

  OrgDataColumn({
    this.docID,
    this.name,
    this.type,
    this.maxLength,
    this.canSearch,
    this.del,
    this.minLength,
    this.regex,
    this.unique,
    this.expression
});

  factory OrgDataColumn.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return OrgDataColumn(
      docID: doc.id,
      name: data["name"] ?? '',
      type:  data["type"] ?? "",
      maxLength: data["maxLength"] ?? 1,
      canSearch: data["canSearch"] ?? false,
      del: data["del"] ?? false,
      minLength: data["minLength"] ?? 0,
      regex: data["regex"] ?? "",
      unique: data["unique"] ?? false,
      expression: data["expression"] ?? ''
    );
  }

  factory OrgDataColumn.fromJson(Map data){
    return OrgDataColumn(
        docID: "",
        name: data["name"] ?? '',
        type:  data["type"] ?? "",
        maxLength: data["maxLength"] ?? 1,
        canSearch: data["canSearch"] ?? false,
        del: data["del"] ?? false,
        minLength: data["minLength"] ?? 0,
        regex: data["regex"] ?? "",
        unique: data["unique"] ?? false,
        expression: data["expression"] ?? ''
    );
  }

  Map<String, dynamic> toJson(){
    return{
      "name": name,
      "type": type,
      "maxLength": maxLength,
      "canSearch": canSearch,
      "del": del,
      "minLength": minLength,
      "regex": regex,
      "unique": unique,
      "expression": expression
    };
  }

}

class DataRecord{
  String? docID;
  Map<dynamic, dynamic>? values; //Map<DataColumn.DocID, value>
  List<dynamic>? qString;
  bool? del;
  DateTime? dateCreated;
  String? status;
  List<OrgMedia>? media;

  DataRecord({
    this.docID,
    this.values,
    this.qString,
    this.del,
    this.dateCreated,
    this.status,
    this.media
});

  factory DataRecord.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    List<OrgMedia> orgMedia = <OrgMedia>[];
    if(data["media"] != null) {
      for (Map media in data["media"]) {
        orgMedia.add(OrgMedia.fromJson(media));
      }
    }
    return DataRecord(
      docID: doc.id,
      values: data["values"] ?? <dynamic,dynamic>{},
      qString: data["qString"] ?? <dynamic>[],
      del: data["del"] ?? false,
      dateCreated: data["dateCreated"].toDate() ?? DateTime.now(),
      status: data["status"] ?? "",
      media: (orgMedia),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      "values": values,
      "qString": qString,
      "del": del,
      "dateCreated": dateCreated,
      "status": status,
      "media": media
    };
  }

}

class OrgApp{
  String? docID;
  String? name;
  String? description;
  bool? del;
  int? version;
  String? createdByUserID;
  DateTime? createdDate;
  String? secret;
  Map? appTheme;
  Map? appConfig;

  OrgApp({
    this.docID,
    this.name,
    this.description,
    this.del,
    this.version,
    this.createdByUserID,
    this.createdDate,
    this.secret,
    this.appTheme,
    this.appConfig
});
  factory OrgApp.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return OrgApp(
      docID: doc.id,
      description: data["description"] ?? "",
      name: data["name"] ?? "",
      del: data["del"] ?? false,
      version: data["version"] ?? 0,
      createdByUserID: data["createdByUserID"] ?? "",
      createdDate: data["createdDate"].toDate() ?? '',
      secret: data["secret"] ?? "",
      appTheme: data["appTheme"] ?? {},
      appConfig: data["appConfig"] ?? {},
    );
  }

  Map<String, dynamic> toJson(){
    return{
    "description": description,
    "name": name,
    "del": del,
    "version": version,
    "createdByUserID": createdByUserID,
    "createdDate": createdDate,
    "secret": secret,
    "appTheme": appTheme,
    "appConfig": appConfig
    };
  }
}

class AuditLog{
  String? docID;
  String? userID;
  String? collection;
  String? alteredDocID;
  String? details;
  DateTime? logTime;

  AuditLog({
    this.docID,
    this.userID,
    this.collection,
    this.alteredDocID,
    this.details,
    this.logTime
});

  factory AuditLog.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      docID: doc.id,
      userID: data["userID"] ?? "",
      collection: data["collection"] ?? "",
      alteredDocID: data["alteredDocID"] ?? "",
      details: data["details"] ?? "",
      logTime: data["logTime"].toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson(){
    return{
      "userID": userID,
      "collection": collection,
      "alteredDocID": alteredDocID,
      "details": details,
      "logTime": logTime
    };
  }
}

class RecordAudit{
  String? docID;
  String? userID;
  Map? prevValue;
  Map? newValue;
  DateTime? logTime;

  RecordAudit({
    this.docID,
    this.userID,
    this.prevValue,
    this.newValue,
    this.logTime
  });

  factory RecordAudit.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return RecordAudit(
      docID: doc.id,
      userID: data["userID"] ?? "",
      prevValue: data["prevValue"] ?? {},
      newValue: data["newValue"] ?? {},
      logTime: data["logTime"].toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson(){
    return{
      "userID": userID,
      "prevValue": prevValue,
      "newValue": newValue,
      "logTime": logTime
    };
  }
}

class OrgMedia{
  String? docID;
  int? version;
  String? url;
  String? type;
  DateTime? dateTimeCreated;
  String? createdByUserID;
  bool? del;

  OrgMedia({
   this.docID,
   this.version,
   this.url,
   this.type,
   this.dateTimeCreated,
   this.createdByUserID,
   this.del
});

  factory OrgMedia.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return OrgMedia(
      docID: doc.id,
      version: data["version"] ?? 1,
      url: data["url"] ?? "",
      type: data["type"] ?? "other",
      dateTimeCreated: data["dateTimeCreated"].toDate() ?? DateTime.now(),
      createdByUserID: data["createdByUserID"] ?? "",
      del: data["del"] ?? false
    );
  }

  factory OrgMedia.fromJson(Map data){
    return OrgMedia(
        docID: "",
        version: data["version"] ?? 1,
        url: data["url"] ?? "",
        type: data["type"] ?? "other",
        dateTimeCreated: data["dateTimeCreated"].toDate() ?? DateTime.now(),
        createdByUserID: data["createdByUserID"] ?? "",
        del: data["del"] ?? false
    );
  }

  Map<String, dynamic> toJson(){
    return {
      "version": version,
      "url": url,
      "type": type,
      "dateTimeCreated": dateTimeCreated,
      "createdByUserID": createdByUserID,
      "del": del
    };
  }

}

class ErrorLog{
  String? docID;
  DateTime? logTime;
  String? userID;
  String? module;
  String? message;

  ErrorLog({
    this.docID,
    this.logTime,
    this.userID,
    this.module,
    this.message
});

  factory ErrorLog.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return ErrorLog(
      docID: doc.id,
      logTime: data["logTime"].toDate() ?? "" as DateTime?,
      userID: data["userID"] ?? "",
      module: data["module"] ?? "",
      message:  data["message"] ?? ""
    );
  }

  factory ErrorLog.fromJson(Map data){
    return ErrorLog(
        docID: "",
        logTime: data["logTime"].toDate() ?? "" as DateTime?,
        userID: data["userID"] ?? "",
        module: data["module"] ?? "",
        message:  data["message"] ?? ""
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "logTime": logTime,
      "userID": userID,
      "module": module,
      "message": message
    };
  }
}

class ExpressionSuggestion{
  String? docID;
  String? name;
  String? description;
  String? sample;

  ExpressionSuggestion({
    this.docID,
    this.name,
    this.description,
    this.sample
});

  factory ExpressionSuggestion.fromDB(DocumentSnapshot doc){
    var data = doc.data() as Map<String, dynamic>;
    return ExpressionSuggestion(
      docID: doc.id,
      description: data["description"] ?? '',
      name: data["name"] ?? '',
      sample: data["sample"] ?? ''
    );
  }

  factory ExpressionSuggestion.fromJson(Map data){
    return ExpressionSuggestion(
      docID: '',
        description: data["description"] ?? '',
        name: data["name"] ?? '',
        sample: data["sample"] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "sample": sample,
      "description": description,
      "name": name,
    };
  }

}

class ExpressionResult{
  String? docID;
  String? variable;
  String? expression;
  String? result;

  ExpressionResult({
    this.docID,
    this.variable,
    this.expression,
    this.result
});

  Map<String, dynamic> toJson(){
    return{
      "Variable": variable,
      "Expression" : expression,
      "Result": result
    };
  }
}