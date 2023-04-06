import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../main.dart';

class WebViewRouter extends StatefulWidget {
  String url;

  WebViewRouter({required this.url});

  static void open(BuildContext context, String link) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return WebViewRouter(url: link);
    }));
  }

  @override
  State<StatefulWidget> createState() {
    return _WebViewRouter();
  }
}

class _WebViewRouter extends CustState<WebViewRouter> {
  WebViewController _controller = WebViewController();

  double btnWidth = 40;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var paddingTop = mediaDataCache.padding.top;
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;

    var btnTopPosition = Base.BASE_PADDING + Base.BASE_PADDING_HALF;

    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: paddingTop),
        child: Stack(
          children: [
            WebViewWidget(
              controller: _controller,
            ),
            Positioned(
              left: Base.BASE_PADDING,
              top: btnTopPosition,
              child: GestureDetector(
                onTap: () {
                  RouterUtil.back(context);
                },
                child: Container(
                  height: btnWidth,
                  width: btnWidth,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(btnWidth / 2),
                  ),
                  child: Icon(Icons.arrow_back_ios_new),
                  alignment: Alignment.center,
                ),
              ),
            ),
            Positioned(
              right: Base.BASE_PADDING,
              top: btnTopPosition,
              child: PopupMenuButton<String>(
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: "copyCurrentUrl",
                      child: Text("Copy current Url"),
                    ),
                    PopupMenuItem(
                      value: "copyInitUrl",
                      child: Text("Copy init Url"),
                    ),
                    PopupMenuItem(
                      value: "openInBrowser",
                      child: Text("Open in browser"),
                    ),
                  ];
                },
                onSelected: onPopupSelected,
                child: Container(
                  height: btnWidth,
                  width: btnWidth,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(btnWidth / 2),
                  ),
                  child: Icon(Icons.more_horiz),
                  alignment: Alignment.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> onPopupSelected(String value) async {
    var url = await _controller.currentUrl();
    if (value == "copyCurrentUrl") {
      if (StringUtil.isNotBlank(url)) {
        _doCopy(url!);
      }
    } else if (value == "copyInitUrl") {
      _doCopy(widget.url);
    } else if (value == "openInBrowser") {
      var _url = Uri.parse(widget.url);
      launchUrl(_url);
    }
  }

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      BotToast.showText(text: "Copy success!");
    });
  }
}
