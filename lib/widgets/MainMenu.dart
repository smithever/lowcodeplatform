import 'package:flutter/material.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';

class MainMenu extends StatelessWidget {
  final Function() onMenuToggleCallBack;
  final Function(AppPage) onMenuTapCallback;
  final Function() onLogOutCallBack;
  final List<RolePermission> permissions;
  final List<AppPage> pages;
  final bool? isUserPriv;
  final bool narrowLayout;
  final AppPage selectedPage;
  final bool orgFirebaseInitialized;

  MainMenu(
      {required this.onMenuTapCallback,
      required this.pages,
      required this.permissions,
      required this.isUserPriv,
      required this.onMenuToggleCallBack,
      required this.narrowLayout,
      required this.selectedPage,
      required this.onLogOutCallBack,
      required this.orgFirebaseInitialized});

  @override
  Widget build(BuildContext context) {
    AppPage selpage = selectedPage;
    List<AppPage> showPages = <AppPage>[];
    permissions.removeWhere((x) => x.hidden == true || x.r == false);
    print("Menu Organization Firebase Initialized = " + orgFirebaseInitialized.toString());
    pages.forEach((AppPage page) {
      if (page.menu == "main" &&
          (!page.regOrgDB! || (page.regOrgDB! && orgFirebaseInitialized))) {
        if (permissions
            .any((RolePermission permission) => permission.name == page.name)) {
          showPages.add(page);
        }
        if (isUserPriv!) {
          if (!showPages.contains(page) && page.showForPrivUser!) {
            showPages.add(page);
          }
        }
      }
    });

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraints) {
      if (contraints.maxWidth < 71) {
        return ListView(
          children: <Widget>[
            for (AppPage page in showPages)
              IconButton(
                  icon: Icon(
                      IconData(page.iconCode!, fontFamily: 'MaterialIcons')),
                  onPressed: () => {onMenuTapCallback(page)}),
            IconButton(
                icon: Icon(Icons.logout), onPressed: () => {onLogOutCallBack()}),
            Visibility(
                visible: !narrowLayout,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios_rounded),
                    onPressed: () => {onMenuToggleCallBack()},
                  ),
                ))
          ],
        );
      } else {
        return ListView(children: <Widget>[
          for (AppPage page in showPages)
            Card(
              elevation: 8.0,
              margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Container(
                child: ListTile(
                  title: Text(page.description!),
                  trailing: Tooltip(
                      message: page.description!,
                      child: Icon(
                        Icons.navigate_next,
                        size: 30,
                      )),
                  leading: Container(
                    padding: EdgeInsets.only(right: 12.0),
                    decoration: new BoxDecoration(
                        border: new Border(
                            right: new BorderSide(
                                width: 1.0, color: Colors.white24))),
                    child: Icon(
                        IconData(page.iconCode!, fontFamily: 'MaterialIcons')),
                  ),
                  onTap: () {
                    selpage = page;
                    onMenuTapCallback(selpage);
                  },
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
                elevation: 8.0,
                margin:
                    new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Container(
                  child: ListTile(
                    title: Text("Sign Out"),
                    leading: Icon(Icons.logout),
                    onTap: () => {onLogOutCallBack()},
                  ),
                )),
          ),
          Visibility(
              visible: !narrowLayout,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Card(
                    elevation: 8.0,
                    margin: new EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 6.0),
                    child: Container(
                      child: ListTile(
                        title: Text("Collapse Menu"),
                        leading: Icon(Icons.arrow_back_ios_outlined),
                        onTap: () => {onMenuToggleCallBack()},
                      ),
                    )),
              ))
        ]);
      }
    });
  }
}
