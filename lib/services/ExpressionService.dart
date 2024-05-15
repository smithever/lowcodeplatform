import 'package:expression_language/expression_language.dart';
import 'package:smith_base_app/classes/mainClassLib.dart';

class ExpressionService{

  List<ExpressionResult> executeExpressionOnRecord(AppUser? user, DataRecord record, String expression){
    expression = expression.replaceAll(" ", "").replaceAll("\n", "").trim();
    print(expression);
    List<ExpressionResult> ret = <ExpressionResult>[];
    List expArray = expression.split(";");
    for(String item in expArray as Iterable<String>){
      if(item.split("=")[0] == "return"){
        ret.add(ExpressionResult(
            docID: '',
            variable: "return",
            expression: item.split("=")[1],
            result: ret.firstWhere((ExpressionResult er) => er.variable == item.split("=")[1]).result
        ));
      }else {
        String variable = item.split("=")[0];
        String expression = parseExpression(item.split("=")[1], user, record);
        if (ret.isNotEmpty) {
          for(ExpressionResult x in ret) {
            print(x.variable);
            if (expression.contains(x.variable!)) {
              expression = expression.replaceAll(x.variable!,"\"" + x.result.toString() + "\"");
            }
          }
        }
        String result = calcExpression(expression);
        ret.add(ExpressionResult(
            docID: '',
            variable: variable,
            expression: expression,
            result: result
        ));
      }
    }
    return ret;
  }

  String calcExpression(String expString){
    print("Calculating expression: $expString");
    var expressionGrammarDefinition = ExpressionGrammarParser({});
    var parser = expressionGrammarDefinition.build();
    var result = parser.parse(expString);
    var expression = result.value as Expression;
    var value = expression.evaluate();
    return value.toString();
  }

  String parseExpression(String expression, AppUser? user, DataRecord record){
    print("Called function parse expression");
    String ret = expression;
    while(ret.contains(r"${")){
      int start = ret.indexOf(r"${");
      int end = ret.indexOf("}");
      String reference = ret.substring(start,end+1);
      String newValue = getValue(reference, user, record)!;
      print("Start index: $start | End index: $end");
        String first = ret.substring(0, start);
        String last = ret.substring(end + 1, ret.length);
        print("First = $first , Last = $last");
        ret = first + "\"" + newValue + "\"" + last;
        print("Expression Updated: $ret");
    }
    return ret;
  }

  String? getValue(String reference, AppUser? user, DataRecord record){
    print("parsing value of: " + reference);
    List items = reference.replaceAll(r"$","").replaceAll("{","").replaceAll("}","").split(".");
    switch(items[0]){
      case 'Record' :
        switch(items[1]){
          case 'value' :
            return record.values![items[2]].toString();
          case 'status' :
            return record.status.toString();
          case 'dateCreated' :
            return record.dateCreated!.toIso8601String();
          default : return "";
        }
      case 'User' :
        switch(items[1]){
          case 'firstName' :
            return user!.firstName.toString();
          case 'lastName' :
            return user!.lastName.toString();
          case 'email' :
            return user!.emailAddress.toString();
          case 'cell' :
            return user!.cell.toString();
          case 'id' :
            return user!.docID;
          default : return "";
        }
      default : return "";
    }
  }

  List<ExpressionSuggestion> getExpressionSuggestions(){
    List<ExpressionSuggestion> ret = <ExpressionSuggestion>[];
    List<Map<String,String>> map = [
      {
        "name": "User.firstName",
        "description": "Logged in user first name",
        "sample": "\${User.firstName}"
      },
      {
        "name": "User.lastName",
        "description": "Logged in user last name",
        "sample": "\${User.lastName}"
      },
      {
        "name": "User.email",
        "description": "Logged in user email",
        "sample": "\${User.email}"
      },
      {
        "name": "User.cell",
        "description": "Logged in user cell",
        "sample": "\${User.cell}"
      },
      {
        "name": "User.id",
        "description": "Logged in user system id",
        "sample": "\${User.id}"
      },
      {
        "name": "bool contains(String value, String searchValue)",
        "description": "Returns true if value constains searchValue",
        "sample": "contains(\"abcd\", \"bc\")"
      },
      {
        "name": "String toString<T>(<T> value)",
        "description": "Returns .toString of the value",
        "sample": "toString(5)"
      },
      {
        "name": "int durationInDays(Duration value)",
        "description": "Returns duration in days of a given duration value",
        "sample": "durationInDays(duration(\"P5D1H\"))"
      },
      {
        "name": "int durationInHours(Duration value)",
        "description": "Returns duration in hours of a given duration value",
        "sample": "durationInHours(duration(\"P5D1H\"))"
      },
      {
        "name": "int durationInMinutes(Duration value)",
        "description": "Returns duration in minutes of a given duration value",
        "sample": "durationInMinutes(duration(\"P5D1H\"))"
      },
      {
        "name": "int durationInSeconds(Duration value)",
        "description": "Returns duration in seconds of a given duration value",
        "sample": "durationInSeconds(duration(\"P5D1H\"))"
      },
      {
        "name": "bool startsWith(String value, String searchValue)",
        "description": "Returns true if value starts with searchValue",
        "sample": "startsWith(\"Hello\", \"He\")"
      },
      {
        "name": "bool endsWith(String value, String searchValue)",
        "description": "Returns true if value ends with searchValue",
        "sample": "startsWith(\"Hello\", \"lo\")"
      },
      {
        "name": "bool isEmpty(String value)",
        "description": "Returns true if value is empty String",
        "sample": "isEmpty(\"\")"
      },
      {
        "name": "bool isNull(String value)",
        "description": "Returns true if value is null",
        "sample": "isNull(someNullExpression)"
      },
      {
        "name": "bool isNullOrEmpty(String value)",
        "description": "Returns true if value is null or empty String",
        "sample": "isNullOrEmpty(\"\")"
      },
      {
        "name": "bool matches(String value, String regex)",
        "description": "Returns true if value fully matches regex expression",
        "sample": "matches(\"test@email.com\",\"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+.[a-zA-Z0-9-]+\")"
      },
      {
        "name": "int length(String value)",
        "description": "length of the string",
        "sample": "length(\"Hi\")"
      },
      {
        "name": "int length(String value)",
        "description": "length of the string",
        "sample": "length(\"Hi\")"
      },
      {
        "name": "int count<T>(List<T> value)",
        "description": "length of the string",
        "sample": "count(@element.array)"
      },
      {
        "name": "DateTime dateTime(String value)",
        "description": "Try to parse value into DateTime, throws InvalidParameterException if it fails",
        "sample": "dateTime(\"1978-03-20 00:00:00.000\")"
      },
      {
        "name": "DateTime now()",
        "description": "Returns DateTime.now()",
        "sample": "now()"
      },
      {
        "name": "DateTime nowInUtc()",
        "description": "Returns DateTime.now().toUtc()",
        "sample": "nowInUtc()"
      },
      {
        "name": "Duration diffDateTime(DateTime left, DateTime right)",
        "description": "Returns difference between two dates - value is always positive",
        "sample": "diff(dateTime(\"1978-03-20\"), dateTime(\"1976-03-20\"))"
      },
      {
        "name": "Duration duration(String value)",
        "description": "Returns duration from Iso8601 String, thows InvalidParameterException if it fails",
        "sample": "duration(\"P5D1H\")"
      },
      {
        "name": "num round(num value, int precision, int roundingMode)",
        "description": "Rounds the value with given precision and rounding mode as an int (described below)",
        "sample": "round(1.5, 2, 0)"
      },
      {
        "name": "num round(num value, int precision, String roundingMode)",
        "description": "Rounds the value with given precision and rounding mode as a String (described below)",
        "sample": "round(13.5, 0, \"nearestEven\")"
      }
    ];
    for(Map item in map){
      ret.add(ExpressionSuggestion.fromJson(item));
    }
    return ret;
  }
}