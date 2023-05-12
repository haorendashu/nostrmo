import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/webview_provider.dart';
import 'package:provider/provider.dart';

import 'generated/l10n.dart';

class HomeComponent extends StatefulWidget {
  Widget child;

  Locale? locale;

  ThemeData? theme;

  HomeComponent({
    required this.child,
    this.locale,
    this.theme,
  });

  @override
  State<StatefulWidget> createState() {
    return _HomeComponent();
  }
}

class _HomeComponent extends State<HomeComponent> {
  @override
  Widget build(BuildContext context) {
    var _webviewProvider = Provider.of<WebViewProvider>(context);

    return MaterialApp(
      locale: widget.locale,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: widget.theme,
      home: Stack(
        children: [
          Positioned.fill(child: widget.child),
          webViewProvider.url != null
              ? Positioned(
                  child: Offstage(
                  offstage: !_webviewProvider.showable,
                  child: WebViewRouter(url: _webviewProvider.url!),
                ))
              : Container()
        ],
      ),
    );
  }
}
