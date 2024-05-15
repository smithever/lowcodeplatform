import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:firebase_auth/firebase_auth.dart' as fireAuth;

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore getOrgFireStore(orgID){
    print("Get org firestore instanc called");
    if (!Firebase.apps.contains(Firebase.app(orgID))){
      throw "Firestore not initialized";
    }
    else{
      return FirebaseFirestore.instanceFor(app: Firebase.app(orgID));
    }
  }

  //_db.settings(Settings(persistenceEnabled: true, cacheSizeBytes: 99999999);
//#region General
  Future<GeneralConfig> getGeneralConfig() async {
    GeneralConfig ret = new GeneralConfig();
    QuerySnapshot q = await _db.collection("Config").get();
    if (q.docs.isNotEmpty) {
      ret = GeneralConfig.fromDB(q);
    }
    return ret;
  }

  Future<List<AppPage>> getAppPages() async {
    List<AppPage> ret = <AppPage>[];
    QuerySnapshot q = await _db.collection('AppPages').get();
    if (q.docs.isNotEmpty) {
      q.docs.forEach((DocumentSnapshot doc) {
        ret.add(AppPage.fromDB(doc));
      });
    }
    return ret;
  }

  //#endregion
//region UserManagement
  Future<AppUser> getUser(String id) async {
    AppUser ret = new AppUser();
    DocumentSnapshot doc = await _db.collection('Users').doc(id).get();
    if (doc.exists) {
      ret = AppUser.fromDB(doc);
    }
    return ret;
  }

  Future<OrgUser> getOrgUser(String? docID, String? orgID) async {
    OrgUser ret = OrgUser();
    DocumentSnapshot doc = await _db.collection("Organizations").doc(orgID)
        .collection("Users").doc(docID)
        .get();
    if (doc.exists) {
      ret = OrgUser.fromDB(doc);
    }
    return ret;
  }

  Future<String> signUpNewUser(AppUser user) async {
    print("Sign Up a new user");
    try{
      List<String> qstr = [];
      qstr.addAll(createQueryStr(user.firstName!));
      qstr.addAll(createQueryStr(user.lastName!));
      var app = Firebase.app();
      try {
        await fireAuth.FirebaseAuth
            .instanceFor(app: app)
            .createUserWithEmailAndPassword(email: user.emailAddress!, password: user.password!);
        await fireAuth.FirebaseAuth
            .instanceFor(app: app).currentUser!.sendEmailVerification();
        GeneralConfig generalConfig = await getGeneralConfig();
        await _db.collection('Users').add({
          'dateCreated': user.dateCreated ?? '',
          'createdByUserID': user.createdByUserID ?? '',
          'qString': qstr,
          'roleID': generalConfig.newUserID,
          'ID': user.ID ?? '',
          'firstName': user.firstName ?? '',
          'lastName': user.lastName ?? '',
          'cell': user.cell ?? '',
          'emailAddress': user.emailAddress ?? '',
          'del': false,
          'priv': false,
          'lastUpdatedByUserID': user.lastUpdatedByUserID ?? '',
          'orgIDs': user.orgIDs
        });
        return "User created successfully";
      }
      on fireAuth.FirebaseAuthException catch (e) {
        print(e.message);
        throw(e);
      }
    }catch(ex){
      return "User creation failed: " + ex.toString();
    }
  }

  Future<String> createNewUser(AppUser usr, bool newUser, String? orgID) async {
    try {
      List<String> qstr = [];
      qstr.addAll(createQueryStr(usr.firstName!));
      qstr.addAll(createQueryStr(usr.lastName!));
      List<String?> orgIDs = [];
      if (newUser) {
        //First make sure that this user does not exist within all of the users
        QuerySnapshot q = await _db.collection("Users").where(
            "emailAddress", isEqualTo: usr.emailAddress).get();
        if (q.docs.isNotEmpty) {
          //The user exists so let us update the user OrgID's
          AppUser existingUser = AppUser.fromDB(q.docs.first);
          //Update the user OrgID's
          if (orgID != '') {
            if (!existingUser.orgIDs!.contains(orgID)) {
              existingUser.orgIDs!.add(orgID);
              await _db.collection("").doc(existingUser.docID).update({
                'orgIDs': existingUser.orgIDs
              });
            }
            //Make sure that this user is part of the organization
            DocumentSnapshot doc = await _db.collection("Organizations").doc(
                orgID).collection("Users").doc(existingUser.docID).get();
            if (!doc.exists) {
              await _db.collection("Organizations").doc(orgID).collection(
                  "Users").doc(existingUser.docID).set({
                'dateCreated': usr.dateCreated ?? '',
                'createdByUserID': usr.createdByUserID ?? '',
                'roleID': usr.roleID ?? '',
                'qString': qstr,
                'lastUpdatedByUserID': usr.lastUpdatedByUserID ?? '',
                'firstName': existingUser.firstName ?? '',
                'lastName': existingUser.lastName ?? '',
                'del': false,
              });
            }
            return "The user already exists in the system, added the user to this organization";
          }
        }
        else {
          //The user does not exist at all and needs to be created
          // Create the user AUTH object in FireAuth
          GeneralConfig generalConfig = await getGeneralConfig();
          fireAuth.UserCredential res = await register(
              usr.emailAddress, usr.password).catchError((error) {
            // Handle Errors here.
            print(error.toString());
            throw error.code;
          });
          assert(res.user != null);
          // If the creation of the new user in FireAuth is successful then create the user in the FireStore
          if (newUser) {
            //Create the User
            orgIDs.add(orgID);
            await _db.collection('Users').doc(res.user!.uid).set({
              'dateCreated': usr.dateCreated ?? '',
              'createdByUserID': usr.createdByUserID ?? '',
              'qString': qstr,
              'roleID': generalConfig.newUserID,
              'ID': usr.ID ?? '',
              'firstName': usr.firstName ?? '',
              'lastName': usr.lastName ?? '',
              'cell': usr.cell ?? '',
              'emailAddress': usr.emailAddress ?? '',
              'del': false,
              'priv': false,
              'lastUpdatedByUserID': usr.lastUpdatedByUserID ?? '',
              'orgIDs': orgIDs
            });
            //Add the user to Org Users
            await _db.collection("Organizations").doc(orgID)
                .collection("Users")
                .doc(res.user!.uid)
                .set({
              'dateCreated': usr.dateCreated ?? '',
              'createdByUserID': usr.createdByUserID ?? '',
              'roleID': usr.roleID ?? '',
              'qString': qstr,
              'lastUpdatedByUserID': usr.lastUpdatedByUserID ?? '',
              'firstName': usr.firstName ?? '',
              'lastName': usr.lastName ?? '',
              'del': false,
            });
          }
          return 'Created a new User';
        }
      } else {
        orgIDs.addAll(usr.orgIDs!.cast<String>().toList());
        await _db.collection('Users').doc(usr.docID).update({
          'dateCreated': usr.dateCreated ?? '',
          'createdByUserID': usr.createdByUserID ?? '',
          'qString': qstr,
          'ID': usr.ID ?? '',
          'firstName': usr.firstName ?? '',
          'lastName': usr.lastName ?? '',
          'cell': usr.cell ?? '',
          'emailAddress': usr.emailAddress ?? '',
          'del': usr.del ?? false,
          'priv': false,
          'lastUpdatedByUserID': usr.lastUpdatedByUserID ?? '',
          'orgIDs': usr.orgIDs
        });
        await _db.collection("Organizations").doc(orgID)
            .collection("Users")
            .doc(usr.docID)
            .update({
          'dateCreated': usr.dateCreated ?? '',
          'createdByUserID': usr.createdByUserID ?? '',
          'roleID': usr.roleID ?? '',
          'qString': qstr,
          'lastUpdatedByUserID': usr.lastUpdatedByUserID ?? '',
          'firstName': usr.firstName ?? '',
          'lastName': usr.lastName ?? '',
          'del': usr.del,
        });
        return "User updated";
      }
    } catch (ex) {
      return "User creation failed: " + ex.toString();
    }
    return 'User creation failed';
  }

  Future<fireAuth.UserCredential> register(String? email,
      String? password) async {
    var app = Firebase.app("Secondary");
      try {
        fireAuth.UserCredential userCredential = await fireAuth.FirebaseAuth
            .instanceFor(app: app)
            .createUserWithEmailAndPassword(email: email!, password: password!);
        fireAuth.FirebaseAuth
            .instanceFor(app: app).currentUser!.sendEmailVerification();
        return userCredential;
      }
      on fireAuth.FirebaseAuthException catch (e) {
        print(e.message);
        throw(e);
      }
  }

  Future<String> updateUser(AppUser user) async {
    List<String> qstr = [];
    qstr.addAll(createQueryStr(user.firstName!));
    qstr.addAll(createQueryStr(user.lastName!));
    print("Updating user with ID: " + user.docID!);
    WriteBatch batch = _db.batch();
    DocumentReference userMain = _db.collection("Users").doc(user.docID);
    batch.update(userMain, {
      'qString': qstr,
      'ID': user.ID ?? '',
      'firstName': user.firstName ?? '',
      'lastName': user.lastName ?? '',
      'cell': user.cell ?? '',
      'emailAddress': user.emailAddress ?? '',
      'del': user.del ?? false,
      'priv': false,
      'lastUpdatedByUserID': user.docID ?? '',
      'orgIDs': user.orgIDs
    });
    if (user.orgIDs!.length > 0) {
      user.orgIDs!.forEach((orgID) {
        DocumentReference orgUser = _db.collection("Organizations")
            .doc(orgID)
            .collection("Users")
            .doc(user.docID);
        batch.update(orgUser, {
          'dateCreated': user.dateCreated ?? '',
          'createdByUserID': user.createdByUserID ?? '',
          'roleID': user.roleID ?? '',
          'qString': qstr,
          'lastUpdatedByUserID': user.lastUpdatedByUserID ?? '',
          'firstName': user.firstName ?? '',
          'lastName': user.lastName ?? '',
          'del': user.del ?? false,
        });
      });
    }
    try {
      await batch.commit();
      return "User Updated";
    }
    catch (e) {
      return "User update failed to commit";
    }
  }

  Future<List<AppUser>> getUsers(int initAmount, String? orgID,
      String query) async {
    print("Retrieving users from the database");
    List<AppUser> ret = <AppUser>[];
    try {
      Query q = _db.collection("Organizations").doc(orgID).collection("Users")
          .where('del', isEqualTo: false);
      if (query == '') {
        QuerySnapshot qs = await q.orderBy('firstName').limit(initAmount).get();
        if (qs.docs.isNotEmpty) {
          await Future.forEach(qs.docs, (DocumentSnapshot orgDoc) async {
            DocumentSnapshot doc = await _db.collection("Users")
                .doc(orgDoc.id)
                .get();
            ret.add(AppUser.fromDB(doc));
          });
        }
      } else {
        QuerySnapshot qs = await q.where("qString", arrayContains: query)
            .orderBy('firstName')
            .limit(initAmount)
            .get();
        if (qs.docs.isNotEmpty) {
          await Future.forEach(qs.docs, (DocumentSnapshot orgDoc) async {
            DocumentSnapshot doc = await _db.collection("Users")
                .doc(orgDoc.id)
                .get();
            ret.add(AppUser.fromDB(doc));
          });
        }
      }
      ret.sort((a, b) => a.firstName!.compareTo(b.firstName!));
      return ret;
    } catch (e) {
      print(
          'Some error occurred when trying to retrieve users: ' + e.toString());
      return ret;
    }
  }

  Future<List<AppUser>> getNextUsers(int initAmount, String? orgID, String query,
      AppUser lastUser) async {
    print("Retrieving users from the database");
    DocumentSnapshot lastDoc = await _db.collection("Organizations").doc(orgID)
        .collection("Users").doc(lastUser.docID)
        .get();
    List<AppUser> ret = <AppUser>[];
    try {
      Query q = _db.collection("Organizations").doc(orgID).collection("Users")
          .where('del', isEqualTo: false);
      if (query == '') {
        QuerySnapshot qs = await q.orderBy('firstName').startAfterDocument(
            lastDoc).limit(initAmount).get();
        if (qs.docs.isNotEmpty) {
          Future.forEach(qs.docs, (DocumentSnapshot orgDoc) async {
            DocumentSnapshot doc = await _db.collection("Users")
                .doc(orgDoc.id)
                .get();
            ret.add(AppUser.fromDB(doc));
          });
        }
      } else {
        QuerySnapshot qs = await q.where("qString", arrayContains: query)
            .orderBy('firstName')
            .startAfterDocument(lastDoc)
            .limit(initAmount)
            .get();
        if (qs.docs.isNotEmpty) {
          Future.forEach(qs.docs, (DocumentSnapshot orgDoc) async {
            DocumentSnapshot doc = await _db.collection("Users")
                .doc(orgDoc.id)
                .get();
            ret.add(AppUser.fromDB(doc));
          });
        }
      }
      ret.sort((a, b) => a.firstName!.compareTo(b.firstName!));
      return ret;
    } catch (e) {
      print(
          'Some error occurred when trying to retrieve users: ' + e.toString());
      return ret;
    }
  }


  Future<bool> isUserTermsAccepted(String userID) async {
    QuerySnapshot qterms = await _db.collection("Config").doc("t&c").collection(
        "pages").get();
    if (qterms.docs.isNotEmpty) {
      List<TermsAndConditions> lstTerms = <TermsAndConditions>[];
      qterms.docs
          .forEach((doc) => lstTerms.add(TermsAndConditions.fromDB(doc)));
      QuerySnapshot qut = await _db
          .collection("Users")
          .doc(userID)
          .collection("AcceptedTerms")
          .get();
      if (qut.docs.isNotEmpty) {
        List<AcceptedTerms> lstAccTerms = <AcceptedTerms>[];
        qut.docs.forEach((doc) => lstAccTerms.add(AcceptedTerms.fromDB(doc)));
        for(TermsAndConditions tc in lstTerms){
          if (lstAccTerms.any((at) => at.termID == tc.docID)) {
            AcceptedTerms ac =
            lstAccTerms.firstWhere((item) => item.termID == tc.docID);
            if (ac.dateAccepted!.isBefore(tc.lastUpdated!)) {
              return false;
            }
            return true;
          }
          return false;
        }
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  Future<List<TermsAndConditions>> getTermsAndConditions() async {
    List<TermsAndConditions> lstTC = <TermsAndConditions>[];
    QuerySnapshot qterms = await _db.collection("Config").doc("t&c").collection(
        "pages").get();
    if (qterms.docs.isNotEmpty) {
      qterms.docs.forEach((doc) => lstTC.add(TermsAndConditions.fromDB(doc)));
    }
    return lstTC;
  }

  Future<void> acceptTerms(String? userID,
      List<TermsAndConditions> lstTC) async {
    lstTC.forEach((term) async {
      QuerySnapshot ref = await _db
          .collection("Users")
          .doc(userID)
          .collection("AcceptedTerms")
          .where("termID", isEqualTo: term.docID)
          .get();
      if (ref.docs.isEmpty) {
        _db.collection("Users").doc(userID).collection("AcceptedTerms").add({
          'termID': term.docID,
          'name': term.name,
          'dateAccepted': DateTime.now()
        });
      } else {
        _db
            .collection("Users")
            .doc(userID)
            .collection("AcceptedTerms")
            .doc(ref.docs[0].id)
            .update({'dateAccepted': DateTime.now()});
      }
    });
    return null;
  }

  Future<void> deleteUser(String? docID, String? orgID) {
    return _db.collection("Organizations").doc(orgID).collection('Users').doc(
        docID).update({'del': true});
  }

  Future<void> saveUserDeviceToken(String? deviceToken, String userID) async {
    return _db
        .collection('Users')
        .doc(userID)
        .collection('deviceTokens')
        .doc(deviceToken)
        .set({
      'dateCreated': DateTime.now(),
    });
  }

  List<String> createQueryStr(String x) {
    x.replaceAll(' ', '');
    List<String> lst = [];
    for (int i = 0; i < x.length; i++) {
      lst.add(x.substring(0, i + 1).toLowerCase());
    }
    return lst;
  }

  Future<List<Organization>> getUserOrganizations(List<dynamic> orgIDs,
      String? userID) async {
    List<Organization> ret = <Organization>[];
    await Future.forEach(orgIDs, (dynamic id) async {
      DocumentSnapshot dr = await _db.collection('Organizations').doc(id)
          .collection('Users').doc(userID)
          .get();
      if (dr.exists) {
        DocumentSnapshot doc = await _db.collection('Organizations')
            .doc(id)
            .get();
        ret.add(Organization.fromDB(doc));
      }
    }
    );
    return ret;
  }

  //#endregion
//#region RoleManagement
  Future<UserRole> getMainUserRole(String roleID) async {
    UserRole ret = new UserRole();
    DocumentSnapshot doc = await _db.collection('UserRole').doc(roleID).get();
    if (doc.exists) {
      ret = UserRole.fromDB(doc);
    }
    return ret;
  }

  Future<UserRole> getOrgUserRole(String? userID, String? orgID) async {
    UserRole ret = new UserRole();
    DocumentSnapshot orgUser = await _db
        .collection("Organizations")
        .doc(orgID)
        .collection('Users')
        .doc(userID)
        .get();
    if (orgUser.exists) {
      var data = orgUser.data() as Map<String, dynamic>;
      String? roleID = data['roleID'];
      DocumentSnapshot doc = await _db
          .collection("Organizations")
          .doc(orgID)
          .collection('UserRole').doc(roleID).get();
      if (doc.exists) {
        ret = UserRole.fromDB(doc);
      }
    }
    return ret;
  }

  Future<List<UserRole>> allOrgUserRoles(orgID) async {
    List<UserRole> ret = <UserRole>[];
    QuerySnapshot q = await _db
        .collection("Organizations")
        .doc(orgID)
        .collection('UserRole')
        .where('del', isEqualTo: false)
        .orderBy('name')
        .get();
    if (q.docs.isNotEmpty) {
      q.docs.forEach((DocumentSnapshot doc) {
        ret.add(UserRole.fromDB(doc));
      });
    }
    return ret;
  }

  Future<String> addNewOrgRole(UserRole orgRole, List<AppPage> pages,
      String? orgID) async {
    DocumentReference ur = await _db
        .collection("Organizations")
        .doc(orgID)
        .collection('UserRole')
        .add({
      'del': orgRole.del,
      'hidden': orgRole.hidden,
      'name': orgRole.name
    });
    pages.forEach((AppPage page) {
      _db
          .collection("Organizations")
          .doc(orgID)
          .collection('RolePermission').add({
        'roleID': ur.id,
        'name': page.name,
        'description': page.description,
        'c': false,
        'r': false,
        'u': false,
        'd': false,
        'del': false,
        'hidden': page.menu == 'main' ? false: true
      });
    });
    return ur.id;
  }

  Future<String> addOrgRolePermission(RolePermission rolePermission,
      String? orgID) async {
    DocumentReference ret = await _db
        .collection("Organizations")
        .doc(orgID)
        .collection('RolePermission').add({
      'roleID': rolePermission.roleID,
      'name': rolePermission.name,
      'description': rolePermission.description,
      'c': rolePermission.c,
      'r': rolePermission.r,
      'u': rolePermission.u,
      'd': rolePermission.d,
      'del': rolePermission.del,
      'hidden': rolePermission.hidden
    });
    return ret.id;
  }

  Future<void> toggleOrgRoleHidden(String? orgRoleID, bool val, String? orgID) {
    return _db
        .collection("Organizations")
        .doc(orgID)
        .collection('UserRole').doc(orgRoleID).update({
      'hidden': val,
    });
  }

  Future<List<RolePermission>> getOrgRolePermissions(String? roleId,
      String? orgID) async {
    List<RolePermission> ret = <RolePermission>[];
    QuerySnapshot q = await _db
        .collection("Organizations")
        .doc(orgID)
        .collection('RolePermission')
        .where('del', isEqualTo: false)
        .where('roleID', isEqualTo: roleId)
        .get();
    if (q.docs.isNotEmpty) {
      q.docs.forEach((DocumentSnapshot doc) {
        ret.add(RolePermission.fromDB(doc));
      });
    }
    return ret;
  }

  Future<void> updateOrgRolePermission(String? docID, String crud, bool? val,
      String? orgID) {
    return _db
        .collection("Organizations")
        .doc(orgID)
        .collection('RolePermission').doc(docID).update({
      crud: val,
    });
  }

  Future<void> deleteOrgRolePermission(String? roleID,
      String? replacementRoleID, String? orgID) async {
    QuerySnapshot rolePerms = await _db
        .collection("Organizations")
        .doc(orgID)
        .collection('RolePermission')
        .where('roleID', isEqualTo: roleID)
        .get();
    DocumentSnapshot role =
    await _db
        .collection("Organizations")
        .doc(orgID)
        .collection('UserRole').doc(roleID).get();
    QuerySnapshot affectedUsers = await _db
        .collection("Organizations")
        .doc(orgID)
        .collection('Users')
        .where('roleID', isEqualTo: roleID)
        .get();
    WriteBatch batch = _db.batch();
    rolePerms.docs.forEach((doc) {
      batch.delete(doc.reference);
    });
    affectedUsers.docs.forEach((doc) {
      batch.update(doc.reference, {'roleID': replacementRoleID});
    });
    batch.delete(role.reference);
    batch.commit();
  }

//#endregion
//#region Messages
  Future<Message> getMessage(String messageID, String orgID) async {
    Message msg = new Message();
    if(Firebase.apps.contains(Firebase.app(orgID))) {
      DocumentSnapshot doc = await FirebaseFirestore.instanceFor(app: Firebase.app(orgID))
          .collection("Messages")
          .doc(messageID)
          .get();
      if (doc.exists) {
        msg = Message.fromDb(doc);
      }
    }
    return msg;
  }

  Future<String> addMessage(Message message, String orgID) async {
    if(Firebase.apps.contains(Firebase.app(orgID))) {
      await FirebaseFirestore.instanceFor(app: Firebase.app(orgID)).collection(
          'Messages').add({
        'from': message.from,
        'to': message.to,
        'admins': message.admins,
        'subject': message.subject,
        'date': message.date,
        'type': message.type,
        'del': message.del,
        'allowReplies': message.allowReplies
      });
      return "Success";
    }else{return "Failed";}
  }

  Future<String> updateMessage(Message message, String orgID) async {
    if(Firebase.apps.contains(Firebase.app(orgID))) {
      await FirebaseFirestore.instanceFor(app: Firebase.app(orgID)).collection('Messages').doc(message.docID).update({
        'from': message.from,
        'to': message.to,
        'admins': message.admins,
        'subject': message.subject,
        'type': message.type,
        'allowReplies': message.allowReplies
      });
      return "Success";
    }
    else {
      return "Failed";
    }
  }

  Future<void> deleteMessage(messageID, String orgID) async {
    if(Firebase.apps.contains(Firebase.app(orgID))) {
      return await FirebaseFirestore.instanceFor(app: Firebase.app(orgID))
          .collection('Messages')
          .doc(messageID)
          .update({'del': true});
    }else{return;}
  }

  Future<void> addReply(String? messageID, Reply reply, String orgID) async {
    if(Firebase.apps.contains(Firebase.app(orgID))) {
      await FirebaseFirestore.instanceFor(app: Firebase.app(orgID))
          .collection('Messages')
          .doc(messageID)
          .collection('Replies')
          .add({
        'from': reply.from,
        'fromName': reply.fromName,
        'fileName': reply.fileName,
        'fileSizeMb': reply.fileSizeMb,
        'content': reply.content,
        'date': reply.date,
        'type': reply.type,
        'del': reply.del
      });
      await FirebaseFirestore.instanceFor(app: Firebase.app(orgID))
          .collection('Messages')
          .doc(messageID)
          .update({'date': reply.date});
    }
    else{return;}
  }

  Future<UserMessage> getUserMessage(String messageID, String userID, String orgID) async {
    UserMessage um = new UserMessage();
    QuerySnapshot querySnapshot = await _db.collection("Organizations").doc(orgID).collection('Users').doc(userID)
        .collection('UserMessages').where('messageID', isEqualTo: messageID)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      um = UserMessage.fromDb(querySnapshot.docs[0]);
    }
    return um;
  }

  Future<void> setUserMessageAsRead(String? userID, String? userMessageID, String? orgID) {
    return _db.collection("Organizations").doc(orgID)
        .collection('Users')
        .doc(userID)
        .collection('UserMessages')
        .doc(userMessageID)
        .update({'read': true, 'date': DateTime.now()});
  }

  Future<void> addUserMessage(String? userID, Message message, String? orgID) async {
    QuerySnapshot check = await _db.collection("Organizations").doc(orgID)
        .collection('Users')
        .doc(userID)
        .collection('UserMessages')
        .where('messageID', isEqualTo: message.docID)
        .get();
    if (check.docs.length == 0) {
      await _db.collection("Organizations").doc(orgID)
          .collection('Users')
          .doc(userID)
          .collection('UserMessages')
          .add({
        'messageID': message.docID,
        'date': message.date,
        'subject': message.subject,
        'del': false,
        'read': false,
        'notificationsOn': true,
        'isFavorite': false,
        'orgID': orgID,
      });
    }
  }

  Future<String> uploadChatMedia(String? messageID, var fileData,
      SettableMetadata? metadata, String fileName, String orgID) async {
    print('Starting file upload');
    if(Firebase.apps.contains(Firebase.app(orgID))) {
      final Reference storageReference = FirebaseStorage.instanceFor(app: Firebase.app(orgID))
          .ref()
          .child('chatMedia')
          .child(messageID!)
          .child(fileName);
      final UploadTask uploadTask =
      storageReference.putData(fileData, metadata);
      try {
        await uploadTask.whenComplete(() => null);
        print('File upload complete');
        var ret = await storageReference.getDownloadURL();
        print(ret);
        return ret;
      } catch (e) {
        print('File upload failed: ' + e.toString());
        return 'ERROR:' + e.toString();
      }
    }
    else{
      return "ERROR: The firebase Storage for organization could not be initialized";
    }
  }
//#endregion
//#region OrgManagement
  Future<OrgSettings> getOrgSettings(orgID) async{
    OrgSettings ret = new OrgSettings();
    QuerySnapshot q = await _db.collection("Organizations").doc(orgID).collection("GeneralConfig").get();
    if(q.docs.isNotEmpty){
      ret = OrgSettings.fromDB(q);
    }
    return ret;
  }

  Future<String> updateOrgSettings(OrgSettings orgSettings, String? orgID) async{
    CollectionReference collection = _db.collection("Organizations").doc(orgID).collection("GeneralConfig");
    WriteBatch batch = _db.batch();
    List<String> s = OrgSettings().keys();
    for(String key in s){
      DocumentReference ref = collection.doc(key);
      switch(key){
        case 'firestoreSettings':
          batch.update(ref, orgSettings.firestoreSettings!.toJson());
          break;
        case 'uploadParams':
          batch.update(ref, orgSettings.uploadParams!.toJson());
          break;
        case 'counters':
          batch.update(ref, orgSettings.counters!.toJson());
          break;
        case 'media':
          batch.update(ref, orgSettings.media!.toJson());
          break;
        case 'theme':
          batch.update(ref, orgSettings.theme!.toJson());
      }
    }
    try{
      await batch.commit();
      return "Settings updated";
    }
    catch(e){
      return "Failed to save settings";
    }
  }

  Future<String> createOrgApp(OrgApp orgApp, String orgID) async{
    try{
      print("Create new Org App called");
      DocumentReference doc = await _db.collection("Organizations").doc(orgID).collection("Apps").add(orgApp.toJson());
      print("New org App record created AppID: ${doc.id}");
      return doc.id;
    }catch(e){
      print("Failed to create new app. Error: $e");
      throw e;
    }
  }

  Future<String> updateOrgApp(OrgApp orgApp, String orgID) async{
    try{
      await _db.collection("Organizations").doc(orgID).collection("Apps").doc(orgApp.docID).update(orgApp.toJson());
      return "Success";
    }catch(e){
      throw e;
    }
  }

  Future<List<OrgApp>> getAllOrgApps(String orgID) async{
    List<OrgApp> ret = <OrgApp>[];
    try{
      QuerySnapshot q = await _db.collection("Organizations").doc(orgID).collection("Apps").get();
      if(q.docs.isNotEmpty){
        for(DocumentSnapshot doc in q.docs){
          ret.add(OrgApp.fromDB(doc));
        }
      }
      return ret;
    }catch(e){
      throw e;
    }
  }
//#endregion
//#region DataTableManagement
  Future<String> createDataTable(String orgID, OrgDataTable table) async{
    try{
      table.del = false;
      DocumentReference doc = await getOrgFireStore(orgID).collection("DataTables").add(table.toJson());
      return doc.id;
    }catch(e){
      throw e;
    }
  }

  Future<String> updateDataTable(String orgID, OrgDataTable table) async{
    try{
      await getOrgFireStore(orgID).collection("DataTables").doc(table.docID).update(table.toJson());
      return "Success";
    }catch(e){
      throw e;
    }
  }

  Future<List<OrgDataTable>> getDataTables(String orgID) async{
    List<OrgDataTable> ret = <OrgDataTable>[];
    QuerySnapshot q = await getOrgFireStore(orgID).collection("DataTables").where("del", isEqualTo: false).get();
    if(q.docs.isNotEmpty){
      for(DocumentSnapshot doc in q.docs){
        ret.add(OrgDataTable.fromDB(doc));
      }
    }
    return ret;
  }

  Future<OrgDataTable> getDataTable(String orgID, String docID) async{
    OrgDataTable ret = new OrgDataTable();
    DocumentSnapshot doc = await getOrgFireStore(orgID).collection("DataTables").doc(docID).get();
    if(doc.exists){
      ret = OrgDataTable.fromDB(doc);
    }
    return ret;
  }

  Future<String> createDataRecord(String orgID, String? tableID, DataRecord record) async{
    try{
      DocumentReference doc = await getOrgFireStore(orgID).collection("DataTables").doc(tableID).collection("DataRecords").add(record.toJson());
      return doc.id;
    }catch(e){
      throw e;
    }
  }

  Future<String> updateDataRecord(String orgID, String? tableID, DataRecord record, RecordAudit audit) async{
    try{
      DocumentReference ref = getOrgFireStore(orgID).collection("DataTables").doc(tableID).collection("DataRecords").doc(record.docID);
      await ref.update(record.toJson());
      await ref.collection("Audit").add(audit.toJson());
      return "Success";
    }catch(e){
      throw e;
    }
  }

  Future<List<DataRecord>> getDataRecords(String? orgID, String? tableID, int initAmount, String query) async{
    List<DataRecord> ret = <DataRecord>[];
    QuerySnapshot q;
    try {
      if (query.isNotEmpty) {
        q = await getOrgFireStore(orgID).collection("DataTables")
            .doc(tableID).collection("DataRecords").where(
            "del", isEqualTo: false)
            .where("qString", arrayContains: query.toLowerCase()).orderBy(
            "dateCreated", descending: false).limit(initAmount)
            .get();
      } else {
        q = await getOrgFireStore(orgID).collection("DataTables")
            .doc(tableID).collection("DataRecords").where(
            "del", isEqualTo: false)
            .orderBy(
            "dateCreated", descending: false).limit(initAmount)
            .get();
      }
      if (q.docs.isNotEmpty) {
        for (DocumentSnapshot doc in q.docs) {
          ret.add(DataRecord.fromDB(doc));
        }
      }
    }catch(e){
      print("getDataRecords failed");
      FirebaseException ex = e as FirebaseException;
      throw ex.message!;
    }
    return ret;
  }

  Future<List<DataRecord>> getNextDataRecords(String orgID, String tableID, String lastRecordID, String query, int initAmount) async{
    List<DataRecord> ret = <DataRecord>[];
    QuerySnapshot q;
    DocumentSnapshot lastDoc = await getOrgFireStore(orgID).collection("DataTables").doc(tableID).collection("DataRecords").doc(lastRecordID).get();
    if(query.isNotEmpty) {
      q = await getOrgFireStore(orgID).collection("DataTables")
          .doc(tableID).collection("DataRecords").where("del", isEqualTo: false)
          .where("qString", arrayContains: query.toLowerCase())
          .orderBy("dateCreated", descending: false)
          .startAfterDocument(lastDoc)
          .limit(initAmount)
          .get();
    }else{
      q = await getOrgFireStore(orgID).collection("DataTables")
          .doc(tableID).collection("DataRecords").where("del", isEqualTo: false)
          .orderBy(
          "dateCreated", descending: false)
          .startAfterDocument(lastDoc)
          .limit(initAmount)
          .get();
    }
    if(q.docs.isNotEmpty){
      for(DocumentSnapshot doc in q.docs){
        ret.add(DataRecord.fromDB(doc));
      }
    }
    return ret;
  }

  Future<List<DataRecord>> getNextDataRecordsByKeyValue(String orgID, String tableID, String key, String value, int initAmount, String lastRecordID) async{
    List<DataRecord> ret = <DataRecord>[];
    DocumentSnapshot lastDoc = await getOrgFireStore(orgID).collection("DataTables").doc(tableID).collection("DataRecords").doc(lastRecordID).get();
    QuerySnapshot q;
    q = await getOrgFireStore(orgID).collection("DataTables")
        .doc(tableID)
        .collection("DataRecords")
        .where("del", isEqualTo: false)
        .where("values.$key", isEqualTo: value)
        .orderBy("dateCreated", descending: false)
        .startAfterDocument(lastDoc)
        .limit(initAmount)
        .get();
    if(q.docs.isNotEmpty){
      for(DocumentSnapshot doc in q.docs){
        ret.add(DataRecord.fromDB(doc));
      }
    }
    return ret;
  }

  Future<List<DataRecord>> getDataRecordsByKeyValue(String orgID, String? tableID, String? key, String? value, int initAmount) async{
    List<DataRecord> ret = <DataRecord>[];
    QuerySnapshot q;
    try {
      q = await getOrgFireStore(orgID).collection("DataTables")
          .doc(tableID)
          .collection("DataRecords")
          .where("del", isEqualTo: false)
          .where("values.$key", isEqualTo: value)
          .orderBy("dateCreated", descending: false)
          .limit(initAmount)
          .get();
      if (q.docs.isNotEmpty) {
        for (DocumentSnapshot doc in q.docs) {
          ret.add(DataRecord.fromDB(doc));
        }
      }
      return ret;
    }catch(ex){
      FirebaseException e = ex as FirebaseException;
      if(e.message!.contains("The query requires an index")){
        ErrorLog log = new ErrorLog(
          logTime: DateTime.now(),
          message: ex.message,
          userID: "Undefined",
          module: "getDataRecordsByKeyValue"
        );
        addErrorLog(orgID, log);
      }
      throw e;
    }
  }

  Future<void> deleteDataRecords(String orgID, String? tableID, List<DataRecord> dataRecords)async{
    try{
      FirebaseFirestore fireStore = getOrgFireStore(orgID);
      WriteBatch batch = fireStore.batch();
      CollectionReference col = fireStore.collection("DataTables")
          .doc(tableID)
          .collection("DataRecords");
      for(DataRecord dr in dataRecords){
        DocumentReference ref = col.doc(dr.docID);
        batch.delete(ref);
      }
      await batch.commit();
      return;
    }catch(e){
      throw e;
    }
  }

  Future<String> addDataRecordAudit(String orgID, RecordAudit auditLog, String tableID, String recordID) async{
    try{
      DocumentReference doc = await getOrgFireStore(orgID).collection("DataTables")
          .doc(tableID)
          .collection("DataRecords")
          .doc(recordID)
          .collection("Audit")
          .add(auditLog.toJson());
      return doc.id;
    }catch(e){
      throw "Error" + e.toString();
    }
  }
//#endregion
//#region Auditing
  Future<void> addAuditLog(String orgID, AuditLog record) async{
    try{
      await getOrgFireStore(orgID).collection("AuditRecords").add(record.toJson());
    }catch(e){
      throw e;
    }
  }

  Future<List<AuditLog>> getAuditLog(String orgID, initAmount) async{
    List<AuditLog> ret = <AuditLog>[];
    QuerySnapshot q = await getOrgFireStore(orgID).collection("AuditRecords").orderBy("logTime", descending: true).limit(initAmount).get();
    if(q.docs.isNotEmpty){
      for(DocumentSnapshot doc in q.docs){
        ret.add(AuditLog.fromDB(doc));
      }
    }
    return ret;
  }

  Future<List<AuditLog>> getNextAuditLog(String orgID, initAmount, lastAuditId) async{
    List<AuditLog> ret = <AuditLog>[];
    DocumentSnapshot lastDoc = await getOrgFireStore(orgID).collection("AuditRecords").doc(lastAuditId).get();
    QuerySnapshot q = await getOrgFireStore(orgID).collection("AuditRecords").orderBy("logTime", descending: true).startAfterDocument(lastDoc).limit(initAmount).get();
    if(q.docs.isNotEmpty){
      for(DocumentSnapshot doc in q.docs){
        ret.add(AuditLog.fromDB(doc));
      }
    }
    return ret;
  }

  Future<void> addErrorLog(String orgID, ErrorLog log) async{
    try{
      await getOrgFireStore(orgID).collection("ErrorLog").add(log.toJson());
    }catch(e){
      throw "Error: " + e.toString();
    }
  }

  Future<List<ErrorLog>> getErrorLog(String orgID, initAmount) async{
    List<ErrorLog> ret = <ErrorLog>[];
    QuerySnapshot q = await getOrgFireStore(orgID).collection("ErrorLog").orderBy("logTime", descending: true).limit(initAmount).get();
    if(q.docs.isNotEmpty){
      for(DocumentSnapshot doc in q.docs){
        ret.add(ErrorLog.fromDB(doc));
      }
    }
    return ret;
  }

  Future<List<ErrorLog>> getNextErrorLog(String orgID, initAmount, lastErrorId) async{
    List<ErrorLog> ret = <ErrorLog>[];
    DocumentSnapshot lastDoc = await getOrgFireStore(orgID).collection("ErrorLog").doc(lastErrorId).get();
    QuerySnapshot q = await getOrgFireStore(orgID).collection("ErrorLog").orderBy("logTime", descending: true).startAfterDocument(lastDoc).limit(initAmount).get();
    if(q.docs.isNotEmpty){
      for(DocumentSnapshot doc in q.docs){
        ret.add(ErrorLog.fromDB(doc));
      }
    }
    return ret;
  }

//#endregion
}
