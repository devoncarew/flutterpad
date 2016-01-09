import 'dart:async';
import 'dart:html' hide Event;

import 'package:firebase/firebase.dart';

Element selected;
ButtonElement deviceButton;

Firebase firebase;

// TODO: use a router

void main() {
  List<Element> navElements = querySelectorAll('nav a');

  for (Element e in navElements) {
    e.onClick.listen((_) {
      if (selected == e) return;

      if (selected != null) {
        selected.classes.toggle('selected', false);
        _hidePage(selected);
      }

      selected = e;
      selected.classes.toggle('selected', true);

      _showPage(e);
    });
  }

  // new Future.delayed(Duration.ZERO, _initHighlighting);

  deviceButton = querySelector('#device-button');
  deviceButton.onClick.listen((_) => _handleDeviceClick());
}

void _hidePage(Element e) {
  String id = e.attributes['ref-id'];
  Element page = querySelector('#${id}');
  if (page != null) {
    page.attributes['hidden'] = '';
  }
}

void _showPage(Element e) {
  String id = e.attributes['ref-id'];
  Element page = querySelector('#${id}');

  if (page != null) {
    page.attributes.remove('hidden');
  }
}

void _handleDeviceClick() {
  _tryPairDevice().then((deviceDescription) {
    // TODO: show a toast

    // span(c: 'octicon octicon-device-mobile');
    // span(text: ' Pair Device');
    // <span class="octicon octicon-device-mobile">
    deviceButton.text = 'Paired: ${deviceDescription}';
    deviceButton.disabled = true;
  }).catchError((e) {
    // TODO: show error

    print(e);
  });
}

Future _tryPairDevice() {
  Firebase _firebase = new Firebase('https://flutterpad.firebaseio.com');

  return _firebase.authAnonymously().then((_) {
    Firebase deviceFirebase = _firebase.child('device');

    return deviceFirebase.onValue.first.then((Event e) {
      firebase = _firebase;
      return e.snapshot.val();
    });
  }).catchError((e) {
    throw e;
  });
}

// void _initHighlighting() {
//   JsObject hljs = context['hljs'];
//   if (hljs != null) {
//     hljs.callMethod('initHighlightingOnLoad');
//   } else {
//     print('hljs not available');
//   }
// }
