import 'dart:convert' show JSON;

import 'package:flutter/material.dart';
import 'package:flutter/http.dart' as http;

import 'src/ui_builder.g.dart';

const String uiUrl = 'https://flutterpad.firebaseio.com/ui.json';

void main() {
  runApp(
    new MaterialApp(
      title: "FlutterPad",
      routes: <String, RouteBuilder>{
        '/': (RouteArguments args) => new FlutterPad()
      }
    )
  );
}

class FlutterPad extends StatefulComponent {
  State createState() => new FlutterPadState();
}

class FlutterPadState extends State {
  String uiState =
    "\nTo pair this device, visit:\n\n"
    "https://flutterpad.firebaseapp.com\n\n"
    "XJC 78F";

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("FlutterPad"),
        right: <Widget>[
          new IconButton(
            icon: 'action/autorenew',
            onPressed: _update
          )
        ]
      ),
      body: new Material(
        child: new Container(
          padding: const EdgeDims.all(12.0),
          child: new Card(
            child: new Text(
              uiState,
              style: new TextStyle(
                fontSize: 20.0,
                textAlign: TextAlign.center
              )
            )
          )
        )
      )
    );
  }

  void _update() {
    print('retrieving $uiUrl');

    http.get(uiUrl).then((http.Response response) {
      print('response: ${response.statusCode}');
      String jsonText = response.body;
      var result = JSON.decode(jsonText);
      print(result);
      setState(() {
        uiState = jsonText;
      });
    });
  }
}
