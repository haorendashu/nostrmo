import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/nip07_dialog.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../client/event.dart';
import '../client/nip07/nip07_methods.dart';
import '../generated/l10n.dart';
import '../main.dart';

class WebViewRouter extends StatefulWidget {
  String url;

  WebViewRouter({required this.url});

  static void open(BuildContext context, String link) {
    if (PlatformUtil.isPC()) {
      launchUrl(Uri.parse(link));
      return;
    }
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

  void nip07Reject(String resultId, String contnet) {
    var script = "window.nostr.reject(\"$resultId\", \"${contnet}\");";
    _controller.runJavaScript(script);
  }

  @override
  void initState() {
    super.initState();
    _controller.addJavaScriptChannel(
      "Nostrmo_JS_getPublicKey",
      onMessageReceived: (jsMsg) async {
        var jsonObj = jsonDecode(jsMsg.message);
        var resultId = jsonObj["resultId"];

        var comfirmResult =
            await NIP07Dialog.show(context, NIP07Methods.getPublicKey);
        if (comfirmResult == true) {
          var pubkey = nostr!.publicKey;
          var script = "window.nostr.callback(\"$resultId\", \"$pubkey\");";
          _controller.runJavaScript(script);
        } else {
          nip07Reject(resultId, S.of(context).Forbid);
        }
      },
    );
    _controller.addJavaScriptChannel(
      "Nostrmo_JS_signEvent",
      onMessageReceived: (jsMsg) async {
        var jsonObj = jsonDecode(jsMsg.message);
        var resultId = jsonObj["resultId"];
        var content = jsonObj["msg"];

        var comfirmResult = await NIP07Dialog.show(
            context, NIP07Methods.signEvent,
            content: content);

        if (comfirmResult == true) {
          try {
            var eventObj = jsonDecode(content);
            var tags = eventObj["tags"];
            Event event = Event(nostr!.publicKey, eventObj["kind"], tags ?? [],
                eventObj["content"]);
            event.sign(nostr!.privateKey!);

            var eventResultStr = jsonEncode(event.toJson());
            // TODO this method to handle " may be error
            eventResultStr = eventResultStr.replaceAll("\"", "\\\"");
            var script =
                "window.nostr.callback(\"$resultId\", JSON.parse(\"$eventResultStr\"));";
            _controller.runJavaScript(script);
          } catch (e) {
            nip07Reject(resultId, S.of(context).Sign_fail);
          }
        } else {
          nip07Reject(resultId, S.of(context).Forbid);
        }
      },
    );
    _controller.setNavigationDelegate(NavigationDelegate(
      onWebResourceError: (error) {
        print(error);
      },
      onPageFinished: (url) {
        _controller.runJavaScript("""
window.nostr = {
_call(channel, message) {
    return new Promise((resolve, reject) => {
        var resultId = "callbackResult_" + Math.floor(Math.random() * 100000000);
        var arg = {"resultId": resultId};
        if (message) {
            arg["msg"] = message;
        }
        var argStr = JSON.stringify(arg);
        channel.postMessage(argStr);
        window.nostr._requests[resultId] = {resolve, reject}
    });
},
_requests: {},
callback(resultId, message) {
    window.nostr._requests[resultId].resolve(message);
},
reject(resultId, message) {
    window.nostr._requests[resultId].reject(message);
},
async getPublicKey() {
    return window.nostr._call(Nostrmo_JS_getPublicKey);
},

async signEvent(event) {
    return window.nostr._call(Nostrmo_JS_signEvent, JSON.stringify(event));
},
};
""");
      },
    ));
  }

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
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
                      child: Text(s.Copy_current_Url),
                    ),
                    PopupMenuItem(
                      value: "copyInitUrl",
                      child: Text(s.Copy_init_Url),
                    ),
                    PopupMenuItem(
                      value: "openInBrowser",
                      child: Text(s.Open_in_browser),
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
      // if (StringUtil.isNotBlank(url)) {
      //   _doCopy(url!);
      // }
      _controller.runJavaScript(
          "window.nostr.callback(\"callbackResult_86205894\", \"37c10448a0fd9295d166100dcd80b01f52f3cc70c98431a89f480fc9f8256861\");");
    } else if (value == "copyInitUrl") {
      _doCopy(widget.url);
    } else if (value == "openInBrowser") {
      var _url = Uri.parse(widget.url);
      launchUrl(_url);
    }
  }

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      BotToast.showText(text: S.of(context).Copy_success);
    });
  }
}
