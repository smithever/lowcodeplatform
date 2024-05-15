import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';
import 'package:smith_base_app/dataTablePackage/EditRecord.dart';
import 'package:smith_base_app/services/CommonFunctions.dart';
import 'package:smith_base_app/services/ExpressionService.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class CodeEditorPage extends StatefulWidget {
  CodeEditorPage({
    Key? key,
    required this.user,
    required this.orgID,
    required this.isEdit,
    required this.dataTable,
    required this.onSave,
    required this.permission,
    this.codeExpression
  }): super(key: key);

  final AppUser? user;
  final OrgDataTable dataTable;
  final bool isEdit;
  final String? codeExpression;
  final String? orgID;
  final Function(String?) onSave;
  final RolePermission permission;

  @override
  _CodeEditorPageState createState() => _CodeEditorPageState();
}

class _CodeEditorPageState extends State<CodeEditorPage> {
  final CommonFunctionsService _common = new CommonFunctionsService();
  final _controller = TextEditingController();
  final _consoleController = TextEditingController();
  final ExpressionService _expService = new ExpressionService();
  FocusNode _focusNode = FocusNode();
  GlobalKey _textFieldKey = GlobalKey();
  TextStyle _textFieldStyle = TextStyle(fontSize: 20);
  String? _codeExpression = '#variable1# = "No Value"; \n result = #variable1#';
  bool _initDone = false;
  late OverlayEntry suggestionTagoverlayEntry;
  List<ExpressionSuggestion> suggestions = <ExpressionSuggestion>[];
  bool _testStatus = false;
  DataRecord _testRecord = new DataRecord();
  bool showConsole = false;
  bool showForm = false;
  bool isNarrowLayout = false;

  @override
  void initState() {
    _controller.addListener(listen);
    super.initState();
    initData();
  }

  void initData(){
    setState(()=> _initDone = false);
    for(String? columnName in widget.dataTable.getKeys()){
      suggestions.add(new ExpressionSuggestion(
        docID: '',
        name: columnName,
        description: "The value of Column $columnName from table ${widget.dataTable.name}",
        sample: '\${Record.value.$columnName}'
      ));
    }
    suggestions.addAll(_expService.getExpressionSuggestions());
    suggestions.add(new ExpressionSuggestion(
      docID: '',
      name: "status",
      description: "Status value of the record",
      sample: '\${Record.status}'
    ));
    suggestions.add(new ExpressionSuggestion(
        docID: '',
        name: "dateCreated",
        description: "Creation date of the record",
        sample: '\${Record.dateCreated}'
    ));
    if(widget.codeExpression != null){
      _codeExpression = widget.codeExpression;
      _testStatus = true;
      }
    setState(() {
      _controller.text = _codeExpression!;
    });
    setState(()=> _initDone = true);
  }

  @override
  void dispose() {
    suggestionTagoverlayEntry.remove();
    _controller.removeListener(listen);
    super.dispose();
  }

  void listen() {
  }

  List<ExpressionSuggestion> filterSuggestions(String lastTypeValue){
    List<ExpressionSuggestion> ret = <ExpressionSuggestion>[];
    ret.addAll(suggestions.where((ExpressionSuggestion item) => item.sample!.startsWith(lastTypeValue)).toList());
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar() as PreferredSizeWidget?,
      body: _layoutBuilder(),
    );
  }

  Widget appBar(){
    return AppBar(
      title: Text("Expression Editor"),
      actions: [
        IconButton(icon: Icon(Icons.save), onPressed: ()=>save()),
        IconButton(icon: Icon(Icons.play_arrow), onPressed: ()=>test())
      ],
    );
  }

  Widget _layoutBuilder() {
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
        Expanded(
          child: body(),
        ),
        if(showForm)
          Column(
            children: [
              SizedBox(
                width: 400,
                child:  Expanded(
                  child: EditRecordForm(
                      user: widget.user,
                      orgID: widget.orgID,
                      table: widget.dataTable,
                      permission: widget.dataTable.permissions!.firstWhere((RolePermission rp) => rp.roleID == widget.user!.roleID),
                      isEdit: false,
                      record: _testRecord,
                      onSuccess: (DataRecord record){
                        _testRecord = record;
                        test();
                      }
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget body(){
    if(!_initDone){
      return new LinearProgressIndicator();
    }
    return Container(
      padding: EdgeInsets.all(17),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              focusNode: _focusNode,
              key: _textFieldKey,
              style: GoogleFonts.spaceMono(),
              decoration: InputDecoration(

              ),
              autofocus: true,
              onChanged: (String val){
                _testStatus = false;
                showOverlaidTag(context, filterSuggestions(_controller.value.selection.textBefore(_controller.value.text).split(" ").last));
              },
            ),
            if(showConsole)
              TextField(
                controller: _consoleController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style: GoogleFonts.spaceMono().copyWith(color: Colors.lightGreen),
                decoration: InputDecoration(
                  fillColor: Colors.black,
                ),
                autofocus: true,
                enabled: false,
              ),
          ],
        ),
      ),
    );
  }

  save(){
    //first make sure that the expression was run and tested for errors.
    if(!_testStatus){
      return _common.showMessage("Info!", "Please ensure that the expression is tested prior to save", context);
    }
    //If tested for errors then pass back to the table edit screen.
    widget.onSave(_codeExpression);
    suggestionTagoverlayEntry.remove();
    return _common.showMessage("Info!", "Saved to table editor", context);
  }

  test(){
    if(_testRecord.values == null){
      //show form to create a dataRecord
      if(isNarrowLayout){
        Navigator.push(context, MaterialPageRoute(builder: (context) =>
            EditRecordForm(
                user: widget.user,
                orgID: widget.orgID,
                table: widget.dataTable,
                permission:getUserTablePermission(widget.dataTable),
                isEdit: false,
                record: _testRecord,
                onSuccess: (DataRecord record){
                  _testRecord = record;
                  test();
                }
            ),
        ));
      }
      suggestionTagoverlayEntry.remove();
      setState(() {
        showConsole = false;
        showForm = true;
      });
      return;
    }else{
      //when a dataRecord exists then run the expression
      try {
        _consoleController.text = "";
        List<ExpressionResult> results = _expService.executeExpressionOnRecord(
            widget.user, _testRecord, _controller.text);
        for(ExpressionResult expResult in results){
          _consoleController.text = _consoleController.text + "\n" + JsonEncoder.withIndent('  ').convert(expResult);
        }
      }catch(e){
        _consoleController.text = e.toString();
      }
      setState(() {
        showConsole = true;
        showForm = false;
      });
    }
  }

  showOverlaidTag(BuildContext context, List<ExpressionSuggestion> suggestions) async {
    try{
      suggestionTagoverlayEntry.remove();
    }catch(e){

    }
    if (suggestions.isNotEmpty) {
      TextPosition pos = _controller.selection.base;
      double windowWidth = MediaQuery
          .of(context)
          .size
          .width;
      double dx = (pos.offset * 10).roundToDouble();
      double dy = _focusNode.offset.dy;
      double enters = '\n'
          .allMatches(_controller.value.text)
          .length
          .toDouble();
      if (enters > 0) {
        dx = (_controller.value.text
            .split('\n')
            .last
            .length * 10).roundToDouble();
      }
      if (dx > windowWidth || enters > 0) {
        double rows = (dx / windowWidth).ceilToDouble() + ('\n'
            .allMatches(_controller.value.text)
            .length);
        double mod = dx - ((dx / windowWidth).floorToDouble() * windowWidth);
        print("mod: $mod, rows: $rows");
        dx = mod;
        dy = _focusNode.offset.dy + (rows * 24);
      }
      print("dx:$dx, dy:$dy");

      TextPainter painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          style: _textFieldStyle,
          text: "what is thisfdgdfgdfgdfgdgfdfggsdgdffd",
        ),
      );
      painter.layout();


      OverlayState overlayState = Overlay.of(context)!;
      suggestionTagoverlayEntry = OverlayEntry(builder: (context) {
        return Positioned(

          // Decides where to place the tag on the screen.
            top: dy + painter.height + 3,
            left: (dx + painter.width) > windowWidth ? windowWidth -
                painter.width - 30 : (dx),

            // Tag code.
            child: Material(
              elevation: 4.0,
              color: Colors.lightBlueAccent,
              child: Container(
                width: painter.width,
                height: 200,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for(ExpressionSuggestion sug in suggestions)
                        ListTile(
                          title: Text(sug.name!),
                          subtitle: Text(sug.sample!),
                          onTap: () {
                            final selection = _controller.value.selection;
                            final text = _controller.value.text;
                            final before = selection.textBefore(text);
                            int lastLength = before
                                .split(" ")
                                .last
                                .length;
                            _controller.text = _controller.text.replaceRange(
                                (selection.start - lastLength), selection.start, sug.sample!);
                            _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                          },
                        )
                    ],
                  ),
                ),
              ),
            ));
      });
      overlayState.insert(suggestionTagoverlayEntry);

      // Removes the over lay entry from the Overly after 500 milliseconds
      // await Future.delayed(Duration(milliseconds: 2000));
      // suggestionTagoverlayEntry.remove();
    }
  }

  RolePermission getUserTablePermission(OrgDataTable table){
    return table.permissions!.firstWhere((RolePermission rp) => rp.roleID == widget.permission.roleID, orElse: (){return new RolePermission(
        roleID: widget.user!.roleID,
        c: false,
        r: false,
        u: false,
        d: false,
        hidden: false,
        name: "TempPermission",
        description: "",
        del: false,
        docID: ""
    );});
  }
}