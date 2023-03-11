import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nostrmo/data/db.dart';
import 'package:nostrmo/router/user/user_router.dart';
import 'package:provider/provider.dart';

import 'client/cust_nostr.dart';
import 'client/nostr_builder.dart';
import 'consts/base.dart';
import 'consts/colors.dart';
import 'consts/router_path.dart';
import 'consts/theme_style.dart';
import 'generated/l10n.dart';
import 'provider/data_util.dart';
import 'provider/index_provider.dart';
import 'provider/metadata_provider.dart';
import 'provider/setting_provider.dart';
import 'router/edit/editor_router.dart';
import 'router/index/index_router.dart';
import 'util/colors_util.dart';
import 'util/string_util.dart';

late SettingProvider settingProvider;

late MetadataProvider metadataProvider;

late IndexProvider indexProvider;

CustNostr? nostr;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var dbInitTask = DB.getCurrentDatabase();
  var dataUtilTask = DataUtil.getInstance();
  Future.wait([dbInitTask, dataUtilTask]);

  var settingTask = SettingProvider.getInstance();
  var metadataTask = MetadataProvider.getInstance();
  var futureResultList = await Future.wait([settingTask, metadataTask]);
  settingProvider = futureResultList[0] as SettingProvider;
  metadataProvider = futureResultList[1] as MetadataProvider;
  indexProvider = IndexProvider();

  if (StringUtil.isNotBlank(settingProvider.privateKey)) {
    nostr = genNostr(settingProvider.privateKey!);
  }

  FlutterNativeSplash.remove();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyApp();
  }
}

class _MyApp extends State<MyApp> {
  reload() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Locale _locale = Localizations.localeOf(context);

    Locale? locale;
    if (StringUtil.isNotBlank(settingProvider.i18n)) {
      for (var item in S.delegate.supportedLocales) {
        if (item.languageCode == settingProvider.i18n) {
          locale = Locale(settingProvider.i18n!);
          break;
        }
      }
    }

    var lightTheme = getLightTheme();
    var darkTheme = getDarkTheme();
    ThemeData defaultTheme;
    ThemeData? defaultDarkTheme;
    if (settingProvider.themeStyle == ThemeStyle.LIGHT) {
      defaultTheme = lightTheme;
    } else if (settingProvider.themeStyle == ThemeStyle.DARK) {
      defaultTheme = darkTheme;
    } else {
      defaultTheme = lightTheme;
      defaultDarkTheme = darkTheme;
    }

    return MultiProvider(
      providers: [
        ListenableProvider<SettingProvider>.value(
          value: settingProvider,
        ),
        ListenableProvider<MetadataProvider>.value(
          value: metadataProvider,
        ),
        ListenableProvider<IndexProvider>.value(
          value: indexProvider,
        ),
      ],
      child: MaterialApp(
        builder: BotToastInit(), //1.调用BotToastInit
        navigatorObservers: [BotToastNavigatorObserver()], //2.注册路由观察者
        debugShowCheckedModeBanner: false,
        locale: locale,
        title: Base.APP_NAME,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        theme: defaultTheme,
        darkTheme: defaultDarkTheme,
        initialRoute: RouterPath.INDEX,
        routes: {
          RouterPath.INDEX: (context) => IndexRouter(reload: reload),
          RouterPath.EDITOR: (context) => EditorRouter(),
          RouterPath.USER: (context) => UserRouter(),
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  ThemeData getLightTheme() {
    Color color500 = Color(0xff519495);

    MaterialColor themeColor = ColorList.getThemeColor(color500.value);

    Color? mainTextColor;
    Color hintColor = Colors.grey;

    var textTheme = TextTheme(
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
    );

    return ThemeData(
      brightness: Brightness.light,
      platform: TargetPlatform.iOS,
      primarySwatch: themeColor,
      // scaffoldBackgroundColor: Base.SCAFFOLD_BACKGROUND_COLOR,
      // scaffoldBackgroundColor: Colors.grey[100],
      scaffoldBackgroundColor: Colors.grey[100],
      primaryColor: themeColor[500],
      appBarTheme: AppBarTheme(
        // color: Base.APPBAR_COLOR,
        backgroundColor: themeColor[500],
        // titleTextStyle: titleTextStyle,
      ),
      dividerColor: Colors.grey,
      cardColor: Colors.white,
      // dividerColor: Colors.grey[200],
      // indicatorColor: ColorsUtil.hexToColor("#818181"),
      textTheme: textTheme,
      hintColor: hintColor,
    );
  }

  ThemeData getDarkTheme() {
    Color color500 = Color(0xff519495);

    MaterialColor themeColor = ColorList.getThemeColor(color500.value);

    Color? mainTextColor;
    Color? topFontColor = Colors.white;
    Color hintColor = Colors.grey;

    var textTheme = TextTheme(
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
    );
    var titleTextStyle = TextStyle(
      color: topFontColor,
      // color: Colors.black,
    );

    return ThemeData(
      brightness: Brightness.dark,
      platform: TargetPlatform.iOS,
      primarySwatch: themeColor,
      // scaffoldBackgroundColor: Base.SCAFFOLD_BACKGROUND_COLOR,
      scaffoldBackgroundColor: ColorsUtil.hexToColor("#212121"),
      primaryColor: themeColor[500],
      appBarTheme: AppBarTheme(
        // color: Base.APPBAR_COLOR,
        backgroundColor: Colors.grey[800],
        titleTextStyle: titleTextStyle,
      ),
      dividerColor: Colors.grey[200],
      cardColor: Colors.grey[800],
      // indicatorColor: ColorsUtil.hexToColor("#818181"),
      textTheme: textTheme,
      hintColor: hintColor,
    );
  }
}
