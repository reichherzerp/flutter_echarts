library flutter_echarts;

// --- FIX_BLINK ---
import 'dart:io' show Platform;
// --- FIX_BLINK ---

import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'echarts_script.dart' show echartsScript;

/// <!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=0, target-densitydpi=device-dpi" /><style type="text/css">body,html,#chart{height: 100%;width: 100%;margin: 0px;}div {-webkit-tap-highlight-color:rgba(255,255,255,0);}</style></head><body><div id="chart" /></body></html>
/// 'data:text/html;base64,' + base64Encode(const Utf8Encoder().convert( /* STRING ABOVE */ ))
const htmlBase64 =
    'data:text/html;base64,PCFET0NUWVBFIGh0bWw+PGh0bWw+PGhlYWQ+PG1ldGEgY2hhcnNldD0idXRmLTgiPjxtZXRhIG5hbWU9InZpZXdwb3J0IiBjb250ZW50PSJ3aWR0aD1kZXZpY2Utd2lkdGgsIGluaXRpYWwtc2NhbGU9MS4wLCBtYXhpbXVtLXNjYWxlPTEuMCwgbWluaW11bS1zY2FsZT0xLjAsIHVzZXItc2NhbGFibGU9MCwgdGFyZ2V0LWRlbnNpdHlkcGk9ZGV2aWNlLWRwaSIgLz48c3R5bGUgdHlwZT0idGV4dC9jc3MiPmJvZHksaHRtbCwjY2hhcnR7aGVpZ2h0OiAxMDAlO3dpZHRoOiAxMDAlO21hcmdpbjogMHB4O31kaXYgey13ZWJraXQtdGFwLWhpZ2hsaWdodC1jb2xvcjpyZ2JhKDI1NSwyNTUsMjU1LDApO308L3N0eWxlPjwvaGVhZD48Ym9keT48ZGl2IGlkPSJjaGFydCIgLz48L2JvZHk+PC9odG1sPg==';

class Echarts extends StatefulWidget {
  Echarts(
      {Key key,
      @required this.option,
      this.extraScript = '',
      this.onMessage,
      this.extensions = const [],
      this.theme,
      this.captureAllGestures = false,
      this.captureHorizontalGestures = false,
      this.captureVerticalGestures = false,
      this.onLoad,
      this.color = const Color(0xff1D2B64),
      this.reloadAfterInit = true})
      : super(key: key);

  final String option;

  final String extraScript;

  final void Function(String message) onMessage;

  final List<String> extensions;

  final String theme;

  final bool captureAllGestures;

  final bool captureHorizontalGestures;

  final bool captureVerticalGestures;

  final void Function() onLoad;

  final Color color;

  final bool reloadAfterInit;

  @override
  _EchartsState createState() => _EchartsState();
}

class _EchartsState extends State<Echarts> {
  WebViewController _controller;

  String _currentOption;

  // --- FIX_BLINK ---
  double _opacity = Platform.isAndroid ? 0.0 : 1.0;
  // --- FIX_BLINK ---

  @override
  void initState() {
    super.initState();
    _currentOption = widget.option;

    if (Platform.isIOS ? true : false) {
      new Future.delayed(const Duration(milliseconds: 1500), () {
        _controller.reload();
        print("hat nach 1s reload");
      });
    }
  }

  void init() async {
    final extensionsStr = this.widget.extensions.length > 0
        ? this
            .widget
            .extensions
            .reduce((value, element) => (value ?? '') + '\n' + (element ?? ''))
        : '';
    final themeStr =
        this.widget.theme != null ? '\'${this.widget.theme}\'' : 'null';
    await _controller?.evaluateJavascript('''
      $echartsScript
      $extensionsStr
      var chart = echarts.init(document.getElementById('chart'), $themeStr);
      ${this.widget.extraScript}
      chart.setOption($_currentOption, true);
    ''');
    if (widget.onLoad != null) {
      widget.onLoad();
    }
  }

  Set<Factory<OneSequenceGestureRecognizer>> getGestureRecognizers() {
    Set<Factory<OneSequenceGestureRecognizer>> set = Set();
    if (this.widget.captureAllGestures ||
        this.widget.captureHorizontalGestures) {
      set.add(Factory<HorizontalDragGestureRecognizer>(() {
        return HorizontalDragGestureRecognizer()
          ..onStart = (DragStartDetails details) {}
          ..onUpdate = (DragUpdateDetails details) {}
          ..onDown = (DragDownDetails details) {}
          ..onCancel = () {}
          ..onEnd = (DragEndDetails details) {};
      }));
    }
    if (this.widget.captureAllGestures || this.widget.captureVerticalGestures) {
      set.add(Factory<VerticalDragGestureRecognizer>(() {
        return VerticalDragGestureRecognizer()
          ..onStart = (DragStartDetails details) {}
          ..onUpdate = (DragUpdateDetails details) {}
          ..onDown = (DragDownDetails details) {}
          ..onCancel = () {}
          ..onEnd = (DragEndDetails details) {};
      }));
    }
    return set;
  }

  void update(String preOption) async {
    _currentOption = widget.option;
    if (_currentOption != preOption) {
      await _controller?.evaluateJavascript('''
        try {
          chart.setOption($_currentOption, true);
        } catch(e) {
        }
      ''');
    }
  }

  @override
  void didUpdateWidget(Echarts oldWidget) {
    super.didUpdateWidget(oldWidget);
    update(oldWidget.option);
  }

  // --- FIX_IOS_LEAK ---
  @override
  void dispose() {
    if (Platform.isIOS) {
      _controller.clearCache();
    }
    super.dispose();
  }
  // --- FIX_IOS_LEAK ---

  @override
  Widget build(BuildContext context) {
    // --- FIX_BLINK ---
    return Opacity(
        opacity: _opacity,
        // --- FIX_BLINK ---
        child: Stack(children: [
          Container(
              child: WebView(
                  initialUrl: htmlBase64,
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (WebViewController webViewController) {
                    _controller = webViewController;
                  },
                  onPageFinished: (String url) {
                    // --- FIX_BLINK ---
                    if (Platform.isAndroid) {
                      setState(() {
                        _opacity = 1.0;
                      });
                    }
                    // --- FIX_BLINK ---
                    init();
                  },
                  javascriptChannels: <JavascriptChannel>[
                    JavascriptChannel(
                        name: 'Messager',
                        onMessageReceived:
                            (JavascriptMessage javascriptMessage) {
                          widget?.onMessage(javascriptMessage.message);
                        }),
                  ].toSet(),
                  gestureRecognizers: getGestureRecognizers())),
          Container(
            margin: EdgeInsets.only(
                right: 10.0 * MediaQuery.of(context).size.height * 0.01 / 7.4,
                top: 10.0 * MediaQuery.of(context).size.height * 0.01 / 7.4),
            child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.refresh,
                      color: this.widget.color,
                      size: 20.0 *
                          MediaQuery.of(context).size.height *
                          0.01 /
                          7.4),
                  tooltip: "Reload",
                  onPressed: () {
                    _controller.reload();
                    print("graph reloaded");
                  },
                )),
          )
        ]));
  }
}
