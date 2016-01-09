import 'package:flutter/material.dart';

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

class FlutterPad extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("FlutterPad"),
        right: <Widget>[
          new IconButton(
            icon: 'navigation/more_vert',
            onPressed: () => print('overflow')
          )
        ]
      ),
      body: new Material(
        child: new Container(
          padding: const EdgeDims.all(12.0),
          child: new Card(
            child: new Text(
              "\nTo pair this device, visit:\n\n"
              "https://flutterpad.firebaseapp.com\n\n"
              "XJC 78F",
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
}
