import 'dart:convert' show JSON, HtmlEscape, HtmlEscapeMode;
import 'dart:io';

import 'src/html_gen.dart';
import 'src/model.dart';
import 'src/ui_gen.dart';

// TODO: guides

// TODO: show a decoration of the widget has a runnable example?

// TODO: Use a routing package

void main(List args) {
  Stopwatch watch = new Stopwatch()..start();

  File file = new File('web/index.html');

  Generator generator = new Generator(file);
  generator.generate();

  double seconds = watch.elapsedMilliseconds / 1000.0;
  print('Generated ${file.path} in ${seconds.toStringAsFixed(3)}s');
}

class Generator extends HtmlGen {
  final File outFile;
  List<SubPage> pages;

  Map<String, Widget> _widgetMap;

  UIGenerator uiGen;

  Generator(this.outFile) {
    _widgetMap = {};

    List<Widget> widgets = Widget.parseWidgets('tool/widgets.json');

    for (Widget widget in widgets) {
      _widgetMap[widget.name] = widget;
    }

    pages = new List.from(widgets.map((Widget widget) => new WidgetPage(widget)));

    uiGen = new UIGenerator(widgets);
  }

  void generate() {
    outFile.writeAsStringSync(_create());
  }

  String _create() {
    start(
      title: 'FlutterPad',
      cssRefs: [
        'https://cdn.jsdelivr.net/primer/2.5.0/primer.css',
        'https://cdn.jsdelivr.net/github-markdown-css/2.1.1/github-markdown.css',
        'https://cdn.jsdelivr.net/octicons/3.3.0/octicons.css'
      ],
      inlineStyle: _inlineCss,
      dartScripts: ['main.dart'],
      jsScripts: [
        'packages/browser/dart.js',
        'https://cdn.firebase.com/js/client/2.3.2/firebase.js'
      ]
    );

    header();
    startTag('div', c: "container", attributes: 'id=main-content');
    startTag('div', c: "columns docs-layout", attributes: 'flex layout no-x-scroll');

    startTag('div', c: "column one-fourth");
    nav();
    endTag();

    startTag('div', c: "column three-fourths markdown-body");
    contents();
    endTag();

    endTag();
    endTag();
    footer();
    end();

    return toString();
  }

  void header() {
    startTag('header', c: "masthead");
    startTag('div', c: "container");
    title();
    startTag('nav', c: "masthead-nav");

    tag(
      "a",
      href: "http://flutter.io/getting-started/",
      text: "Getting Started"
    );

    tag(
      "a",
      href: "http://docs.flutter.io/flutter/",
      text: "Documentation"
    );

    // pair device button
    startTag('button', c: 'btn btn-sm', attributes: 'type="button" id=device-button');
    // span(c: 'octicon octicon-device-mobile');
    span(text: 'Pair Device');
    endTag();

    endTag();
    endTag();
    endTag();
  }

  void title() {
    span(
      c: "masthead-logo",
      text: '<img src="flutter.svg" height="33px" class="masthead-logo mega-octicon"> FlutterPad'
    );
  }

  void nav() {
    // Iterable<String> categories = new LinkedHashSet.from(pages.map((s) => s.category));
    List<String> categories = ['Widgets', 'Material'];
    for (String category in categories) {
      navItems(category, pages.where((s) => s.category == category));
    }
  }

  void navItems(String category, List<SubPage> pages) {
    if (pages.isEmpty) return;

    startTag("nav", c: "menu docs-menu");
    span(c: "menu-heading", text: category);

    for (SubPage page in pages) {
      tag(
        "a",
        c: "menu-item",
        text: page.title,
        attributes: 'ref-id="${page.id}"'
      );
    }

    endTag();
  }

  void contents() {
    for (SubPage page in pages) {
      page.generate(this);
    }
  }

  void footer() {
    startTag('footer', c: "footer container");
    tag(
      'a',
      text: 'Privacy Policy',
      attributes: 'href="http://www.google.com/intl/en/policies/privacy/"',
      c: 'right'
    );
    endTag();
  }

  List<Widget> getChildren(Widget widget) {
    List<Widget> children = [];

    for (Widget w in _widgetMap.values) {
      if (w.parent == widget.name) children.add(w);
    }

    children.sort();

    return children;
  }

  List<Widget> getAncestors(Widget widget) {
    List<Widget> ancestors = [];

    Widget temp = getParent(widget);

    while (temp != null) {
      ancestors.insert(0, temp);
      temp = getParent(temp);
    }

    return ancestors;
  }

  Widget getParent(Widget widget) => _widgetMap[widget.parent];
}

abstract class SubPage {
  final String category;
  final String title;

  String get id;

  SubPage(this.category, this.title);

  void generate(HtmlGen gen);
}

class WidgetPage extends SubPage {
  final Widget widget;

  String get id => widget.name;

  WidgetPage(Widget widget):
    this.widget = widget,
    super(toTitleCase(widget.package), widget.name);

  void generate(HtmlGen gen) {
    Generator _gen = gen;

    gen.startTag('div', c: 'markdown-body', attributes: 'hidden id="${id}"');
    String title = widget.isAbstract
      ? '${widget.name} <span class=modifier>abstract</span>' : widget.name;
    gen.tag("h1", text: title, c: "page-title");

    List<Widget> ancestors = _gen.getAncestors(widget);
    List<Widget> children = _gen.getChildren(widget);

    if (ancestors.isNotEmpty || children.isNotEmpty) {
      gen.startTag('p');

      if (ancestors.isNotEmpty) {
        gen.startTag('div');
        gen.span(text: 'Ancestors', c: 'subtle');
        // TODO: create hyperlinks
        gen.span(text: ancestors.reversed.map((w) => w.name).join(' > '));
        gen.endTag();
      }

      if (children.isNotEmpty) {
        gen.startTag('div');
        gen.span(text: 'Children', c: 'subtle');
        // TODO: create hyperlinks
        gen.span(text: children.map((w) => w.name).join(', '));
        gen.endTag();
      }

      gen.endTag();
    }

    if (widget.docs != null && widget.docs.isNotEmpty) {
      // TODO: emit as markdown
      gen.tag('p', text: widget.docs, c: 'lead');
    }

    // Create a code sample.
    if (!widget.isAbstract) {
      Map ui = _gen.uiGen.generateUI(widget, mainElement: true);
      String jsonEncoded = JSON.encode(ui);
      String dartSource = printAsDart(ui);

      // TODO: syntax highlight this
      gen.startTag('pre', c: 'prettyprint', newLine: false);
      gen.tag(
        'code',
        c: 'language-dart',
        attributes: 'data-lang="dart"',
        text: dartSource.trim(),
        newLine: false
      );
      gen.endTag();

      // Write out the json encoded UI data.
      gen.tag(
        'div',
        attributes: 'hidden id="${widget.name}-ui"',
        text: _htmlEncode(jsonEncoded)
      );
    }

    if (widget.properties.isNotEmpty) {
      // gen.tag('h2', text: 'Properties');

      for (Property p in widget.properties) {
        gen.startTag('div', c: 'property');
        gen.span(text: p.name, c: 'strong');
        // TODO: Hyperlink type.
        gen.span(text: p.type, c: 'subtle');
        if (p.required) {
          gen.span(text: '(required)', c: 'modifier');
        }
        if (p.docs != null) {
          // TODO: emit as markdown
          gen.tag('span', text: '— ${p.docs}');
        }
        gen.endTag();
      }
    }

    gen.endTag();
  }
}

String toTitleCase(String str) {
  return str.substring(0, 1).toUpperCase() + str.substring(1);
}

String _htmlEncode(String str) {
  return new HtmlEscape(HtmlEscapeMode.ELEMENT).convert(str);
}

const String _inlineCss = '''
body {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;

  overflow: hidden;

  display: flex;
  flex-direction: column;
}

header {
  flex-shrink: 0;
}

#main-content {
  overflow: hidden;
  flex: 1;
  display: flex;
  flex-direction: column;
}

#main-content div.column {
  overflow-x: auto;
}

footer.footer {
  flex-shrink: 0;

  margin-top: 1.5rem;
  padding: 10px 0;

  color: #999;
  text-transform: uppercase;
  letter-spacing: .4px;
  font-size: 12px;
  line-height: 20px;
  font-weight: 400;
  border-top: 1px solid #eee;
}

footer a {
  color: #999;
}

a.menu-item {
  cursor: pointer;
}

.masthead {
  padding-top: 1rem;
  padding-bottom: 1rem;
  margin-bottom: 1.5rem;
  text-align: left;
  background-color: #4078c0;
}

.masthead {
	color: rgba(255,255,255,0.5);
}

.masthead a:hover {
	color: #fff;
	text-decoration: none;
}

.masthead .masthead-logo {
	color: #fff;
	display: inline-block;
	font-size: 1.5rem;
}

.masthead .masthead-logo .mega-octicon {
	float: left;
	margin-right: .5rem;
}

.columns {
  margin-right: 0;
  margin-left: 0;
}

.masthead-nav {
  margin-top: 1rem;
  font-size: 1rem;

  color: #fff;
  font-weight: 500;

  float: right;
  margin-top: .5rem;
}

.masthead-nav a {
  color: rgba(255,255,255,0.5);
  font-weight: 500;
}

.masthead-nav a,
.masthead-nav button {
  margin-left: 1.25rem;
}

.masthead-nav a:hover,
.masthead-nav .white {
  color: #fff;
}

[flex] {
  flex: 1;
}

[layout] {
  display: flex;
}

[vertical] {
  flex-direction: column;
}

[hidden] {
  display: none;
}

[no-x-scroll] {
  overflow-x: hidden;
}

.strong {
  font-weight: 500;
  color: #222;
}

.subtle {
  color: #999;
}

.property {
  text-indent: -1em;
  margin-left: 1em;
}

.modifier {
  color: #999;
}
''';
