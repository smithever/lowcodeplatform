import 'package:collection/collection.dart' show IterableExtension;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/dataTablePackage/MngDataTables.dart';
import 'package:smith_base_app/screens/MngApps.dart';
import 'package:smith_base_app/screens/MngMessages.dart';
import 'package:smith_base_app/screens/MngOrg.dart';
import 'package:smith_base_app/screens/MngProfile.dart';
import 'package:smith_base_app/screens/MngUsers.dart';
import 'package:smith_base_app/services/CommonFunctions.dart';
import 'package:smith_base_app/services/db.dart';
import 'package:smith_base_app/widgets/MainMenu.dart';
import 'package:smith_base_app/screens/MngRoles.dart';

AppPage selectedPage = new AppPage();

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.user, required this.onLogOutCallBack})
      : super(key: key);

  final AppUser user;
  final Function() onLogOutCallBack;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _db = new DatabaseService();
  final CommonFunctionsService _common = new CommonFunctionsService();
  bool _initDone = false;
  List<RolePermission> _permissions = <RolePermission>[];
  List<AppPage> _pages = <AppPage>[];
  String? _orgID = '';
  AppPage _selectedPage = selectedPage;
  bool showMainMenu = true;
  bool minMainMenu = true;
  UserRole _userOrgRole = UserRole();
  List<Organization> _organizations = <Organization>[];
  bool _showOrgSelector = false;
  OrgSettings _orgSettings = OrgSettings();
  bool _orgFirebaseInitialized = false;
  bool _orgUserAuthenticated = false;

  setSelectedPage(AppPage page) {
    print("Set selected page = " + page.name!);
    selectedPage = page;
    setState(() {
      _selectedPage = page;
    });
  }

  toggleMinMainMenu() {
    if (minMainMenu) {
      minMainMenu = false;
    } else {
      minMainMenu = true;
    }
    setState(() => minMainMenu);
  }

  toggleShowMainMenu() {
    print("Toggle show main menu");
    if (showMainMenu) {
      showMainMenu = false;
    } else {
      showMainMenu = true;
    }
    setState(() => showMainMenu);
  }

  @override
  void initState() {
    super.initState();
    _initiate();
  }

  void _initiate() async {
    print("Initiating Home Page");
      _pages = await _db.getAppPages();
      _organizations =
          await _db.getUserOrganizations(widget.user.orgIDs!, widget.user.docID);
      _showOrgSelector = true;
      if (widget.user.orgIDs!.length > 0) {
        await onOrgSelect(widget.user.orgIDs!.first);
      } else {
        setState(() => _initDone = true);
      }
  }

  Future<bool> authenticateOrgUser(String selectedOrgID) async{
    try {
      print("Authenticating the org firebase user");
      var user = await FirebaseAuth.instanceFor(app: Firebase.app(selectedOrgID))
          .signInWithEmailAndPassword(
          email: widget.user.emailAddress!,
          password: widget.user.docID!);
      if(user.user != null) {
        print("Org firebase user authenticated successfully");
        setState(() {
          _orgUserAuthenticated = true;
          _orgFirebaseInitialized = true;
        });
        return Future.value(true);
      }
      else{
        return Future.value(false);
      }
    } catch (e) {
      try {
        print("Firebase user could not be authenticated trying to create a new user");
        var user = await FirebaseAuth.instanceFor(app: Firebase.app(selectedOrgID))
            .createUserWithEmailAndPassword(
            email: widget.user.emailAddress!,
            password: widget.user.docID!);
          if(user.user != null) {
            print("Org firebase user authenticated successfully");
            setState(() {
              _orgUserAuthenticated = true;
              _orgFirebaseInitialized = true;
            });
            return Future.value(true);
          }
          else{
            throw "Failed to create org user";
          }
      } catch (e) {
        print("Org user authentication failed");
        print(e.toString());
        return false;
      }
    }
  }

  Future<void> onOrgSelect(selectedOrgID) async {
    print("Organization Selected");
    setState(() => _initDone = false);
    _orgID = selectedOrgID;
    _orgFirebaseInitialized = false;
    print("Retrieving Organization settings from main DB");
    _userOrgRole = await _db.getOrgUserRole(widget.user.docID, _orgID);
    _permissions = await _db.getOrgRolePermissions(_userOrgRole.docID, _orgID);
    _orgSettings = await _db.getOrgSettings(_orgID);
    print("Organization settings retrieved: User Org Role: ${_userOrgRole.name}");
    print("Test if firebase app exists for the Organization else create one");
    try {
      if (Firebase.apps.firstWhereOrNull(
              (FirebaseApp app) => app.name == selectedOrgID) != null
          ) {
        print("Firebase app exists, authenticating the user");
        authenticateOrgUser(selectedOrgID).then((result) {
          if(result){
            setState(() => _initDone = true);
          }
          else{
            throw "User Authentication failed";
          }
        });
      } else {
        print("Firebase app does not exist initializing a new one");
        Firebase.initializeApp(
            name: selectedOrgID,
            options: FirebaseOptions(
                apiKey: _orgSettings.firestoreSettings!.apiKey!,
                appId: _orgSettings.firestoreSettings!.appId!,
                messagingSenderId:
                _orgSettings.firestoreSettings!.messagingSenderId!,
                projectId: _orgSettings.firestoreSettings!.projectId!))
            .then((value) async{
          print("Firebase app initialized");
          authenticateOrgUser(selectedOrgID).then((result) {
            if(result){
              setState(() => _initDone = true);
            }
            else{
              throw "User Authentication failed";
            }
          });
        });
      }
    } catch (e) {
      print(e.toString());
      setState(() => _initDone = true);
      return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error!"),
              content: Text(
                  "Failed to connect to Firebase, please contact your system administrator"),
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
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: appBar() as PreferredSizeWidget?,
        body: _initDone ? _body() : new LinearProgressIndicator());
  }

  Widget _body() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth > 600) {
        return wideLayout(_selectedPage);
      } else {
        return narrowLayout(_selectedPage);
      }
    });
  }

  Widget appBar() {
    return new AppBar(
      title: _initDone ? Text("Hi") : null,
      leading: GestureDetector(
        onTap: () {
          toggleShowMainMenu();
        },
        child: Icon(
          Icons.menu, // add custom icons also
        ),
      ),
      actions: [
        if (_showOrgSelector)
          PopupMenuButton<Organization>(
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<Organization>>[
              for (Organization org in _organizations)
                PopupMenuItem<Organization>(
                    value: org,
                    child: org.docID == _orgID
                        ? ListTile(
                            leading: Icon(Icons.check),
                            title: Text(org.name!),
                          )
                        : Text(org.name!))
            ],
            icon: Icon(Icons.apartment),
            onSelected: (Organization org) {
              onOrgSelect(org.docID);
            },
          )
      ],
    );
  }

  Widget wideLayout(AppPage page) {
    return Row(
      children: [
        Visibility(
          visible: showMainMenu,
          child: SizedBox(
            width: minMainMenu ? 70 : 260,
            child: MainMenu(
              narrowLayout: false,
              isUserPriv: widget.user.priv,
              onMenuTapCallback: (AppPage page) {
                setSelectedPage(page);
              },
              pages: _pages,
              permissions: _permissions,
              onMenuToggleCallBack: () => {toggleMinMainMenu()},
              selectedPage: _selectedPage,
              onLogOutCallBack: (){
                print("logout called in home");
                widget.onLogOutCallBack();
              },
              orgFirebaseInitialized: _orgFirebaseInitialized && _orgUserAuthenticated ? true : false,
            ),
          ),
        ),
        Expanded(child: rootToPage(page))
      ],
    );
  }

  Widget narrowLayout(AppPage page) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: showMainMenu
          ? Row(key: UniqueKey(), children: [
              Expanded(
                child: MainMenu(
                  narrowLayout: true,
                  isUserPriv: widget.user.priv,
                  onMenuTapCallback: (AppPage page) {
                    setSelectedPage(page);
                    toggleShowMainMenu();
                  },
                  pages: _pages,
                  permissions: _permissions,
                  onMenuToggleCallBack: () => {toggleMinMainMenu()},
                  selectedPage: _selectedPage,
                  onLogOutCallBack: (){
                    print("logout called in home");
                    widget.onLogOutCallBack();
                  },
                  orgFirebaseInitialized: _orgFirebaseInitialized && _orgUserAuthenticated ? true : false,
                ),
              ),
            ])
          : Row(
              key: UniqueKey(),
              children: [Expanded(child: rootToPage(page))],
            ),
    );
  }

  rootToPage(AppPage page) {
    if (page.name == null) {
      return Scaffold(body: Placeholder());
    }
    RolePermission perm =
        _common.getPagePermission(_permissions, page, widget.user.priv);
    switch (page.name) {
      case 'MngUsers':
        return MngUsersPage(
          user: widget.user,
          permission: perm,
          orgID: _orgID,
          onCloseCallBack: () {},
        );
      case 'MngRoles':
        return MngRolesPage(
          editPagePermission: perm,
          pagePermission: perm,
          loggedUser: widget.user,
          orgID: _orgID,
        );
      case 'MngMessages':
        if (_orgFirebaseInitialized) {
          return MngMessagesPage(
            orgSettings: _orgSettings,
            orgID: _orgID,
            rolePermission: perm,
            gotoMessage: false,
            loggedInUser: widget.user,
            message: new Message(),
          );
        } else {
          return Scaffold(body: Placeholder());
        }
      case 'MngOrg':
        return MngOrganizationPage(
            permission: perm,
            user: widget.user,
            orgSettings: _orgSettings,
            orgID: _orgID);
      case 'MngProfile':
        return MngProfilePage(
          loggedUser: widget.user,
        );
      case 'MngDataTables' :
        return MngDataTables(
            userOrgRole: _userOrgRole,
            permission: perm,
            orgID: _orgID,
            user: widget.user);
      case 'MngApps':
        return MngApps(
            permission: perm,
            orgID: _orgID!,
            user: widget.user);
      default:
        return Scaffold(body: Placeholder());
    }
  }
}

//TODO: For every data edit screen throughout the app create an allocate work system that will stop users editing the same records