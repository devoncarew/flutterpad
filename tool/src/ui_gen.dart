import 'dart:convert' show JSON;

import 'model.dart';

// TODO: use the dart writer class

void main() {
  List<Widget> widgets = Widget.parseWidgets('tool/widgets.json');
  UIGenerator gen = new UIGenerator(widgets);

  Map ui = gen.generateUI(gen.getWidget('Text'), mainElement: true);
  print(JSON.encode(ui));
  print('');
  print(printAsDart(ui));

  print('');

  ui = gen.generateUI(gen.getWidget('Chip'), mainElement: true);
  print(JSON.encode(ui));
  print('');
  print(printAsDart(ui));
}

class UIGenerator {
  final List<Widget> widgets;
  Map<String, Widget> _map = {};

  UIGenerator(this.widgets) {
    for (Widget w in widgets) {
      _map[w.name] = w;
    }
  }

  Map generateUI(Widget widget, {bool mainElement: false}) {
    List params = [];

    // TODO:
    for (Property property in widget.properties) {
      if (property.required) {
        if (property.valueType) {
          params.add(getForValueType(property.type));
        } else {
          // TODO:
          params.add(null);
        }
      }
    }

    if (mainElement) {
      for (Property property in widget.properties) {
        if (property.required) continue;

        String id = '${widget.name}/${property.type}/${property.name}';

        // if (!property.valueType) {
        //   Widget childWidgetType = _map[property.name];
        //
        //   if (childWidgetType != null) {
        //     params.add({
        //       property.name: generateUI(childWidgetType)
        //     });
        //   }
        // }

        if (id.endsWith('/Widget/label')) {
          // /Widget/label
          params.add({ property.name: generateUI(_map['Text']) });
        } else if (id.endsWith('/String/title')) {
          // /String/title
          params.add({ property.name: getForValueType(property.type) });
        } else if (id.endsWith('/String/icon')) {
          // /String/icon
          params.add({ property.name: 'content/add' });
        } else if (id.endsWith('/bool/value')) {
          params.add({ property.name: true });
        } else if (id == 'FloatingActionButton/Widget/child') {
          // FloatingActionButton/Widget/child
          // Icon String icon ('content/add')
          // child: new Icon(
          //   icon: 'content/add'
          // )
          params.add({ property.name: generateUI(_map['Icon'], mainElement: true) });
        } else if (id.endsWith('/Widget/child')) {
          // /Widget/child
          params.add({ property.name: generateUI(_map['Text']) });
        }
      }
    }

    return { widget.name: params };
  }

  static String getForValueType(String typeName) {
    if (typeName == 'String') return 'Lorem Ipsum';
    return null;
  }

  Widget getWidget(String name) => _map[name];
}

String printAsDart(Map ui) {
  return new _DartPrinter().traverse(ui);
}

// new Material(
//   child: new Chip(
//     label: new Text('Lorem Ipsum')
//   )
// )

class _DartPrinter {
  StringBuffer buf = new StringBuffer();
  int indent = 0;

  String traverse(Map ui) {
    buf.clear();
    _traverse(ui);
    return buf.toString().replaceAll(new RegExp(':  +'), ': ');
  }

  void _traverse(Map ui) {
    String className = ui.keys.first;
    List params = ui[className];

    if (params.isEmpty) {
      writeln('new ${className}()');
    } else if (params.length == 1 && isSimple(params.single)) {
      dynamic param = params.single;
      if (param is String) {
        writeln("new ${className}('${param}')");
      } else {
        writeln("new ${className}(${param})");
      }
    } else {
      writeln('new ${className}(');
      for (int i = 0; i < params.length; i++) {
        String suffix = i != params.length - 1 ? ',' : '';
        dynamic param = params[i];
        if (isSimple(param)) {
          if (param is String) {
            writeln("'${param}'${suffix}");
          } else {
            writeln('${param}${suffix}');
          }
        } else {
          Map m = param;
          String paramName = m.keys.first;
          Map data = m[paramName];

          write('${paramName}: ');
          if (data is Map) {
            _traverse(data);
            if (suffix.isNotEmpty) writeln('${suffix}');
          } else {
            if (data is String) {
              writeln("'${data}'${suffix}");
            } else {
              writeln('${data}${suffix}');
            }
          }
        }
      }
      writeln(')');
    }
  }

  static bool isSimple(param) {
    if (param is String || param is bool || param is int) {
      return true;
    }
    if (param == null) return true;
    return false;
  }

  // TODO: we need to scan per output char
  void write(String str) {
    bool calcedIndent = false;
    if (str.startsWith('}') || str.startsWith(')')) {
      calcedIndent = true;
      _updateIndent(str);
    }
    buf.write('${_indentStr}${str}');
    if (!calcedIndent) _updateIndent(str);
  }

  void writeln(String str) {
    bool calcedIndent = false;
    if (str.startsWith('}') || str.startsWith(')')) {
      calcedIndent = true;
      _updateIndent(str);
    }
    buf.writeln('${_indentStr}${str}');
    if (!calcedIndent) _updateIndent(str);
  }

  void _updateIndent(String str) {
    for (int i = 0; i < str.length; i++) {
      String c = str[i];
      if (c == '(' || c == '{') indent++;
      if (c == ')' || c == '}') indent--;
    }
  }

  String get _indentStr => ''.padRight(indent * 2);
}
