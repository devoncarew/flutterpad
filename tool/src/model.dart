import 'dart:convert' show JSON;
import 'dart:io';

class Widget implements Comparable<Widget> {
  static List<Widget> parseWidgets(String path) {
    Map data = JSON.decode(new File(path).readAsStringSync());
    List<Widget> widgets = [];
    data.forEach((String key, Map value) {
      widgets.add(new Widget._(value));
    });
    return widgets;
  }

  String name;
  String docs;
  String package;
  String parent;
  bool isAbstract;
  List<Property> properties = [];

  Widget._(Map data) {
    name = data['name'];
    docs = data['docs'];
    package = data['package'];
    parent = data['parent'];
    isAbstract = data['abstract'] == true;

    if (data.containsKey('properties')) {
      properties = new List.from(data['properties'].map((m) => new Property._(m)));
    }
  }

  int compareTo(Widget other) => name.compareTo(other.name);
}

class Property {
  String name;
  String type;
  bool required;
  String docs;

  Property._(Map m) {
    name = m['name'];
    type = m['type'];
    required = m['required'] == true;
    docs = m['docs'];
  }

  bool get valueType {
    if (type == 'String') return true;
    if (type == 'int') return true;
    if (type == 'bool') return true;
    return false;
  }
}
