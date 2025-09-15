import 'package:cashcard/app/app_config.dart';
import 'package:cashcard/app/app_localizations.dart';
import 'package:cashcard/app/routes.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/util/logging.dart';
import 'package:fluro/fluro.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';

class Application extends WidgetsBindingObserver {
  final Router router = Router();
  Db db;

  Application() {
    AppConfig.init();

    db = Db(
      host: AppConfig.dbHost,
      port: AppConfig.dbPort,
      dbName: AppConfig.dbName,
      userName: AppConfig.dbUserName,
      password: AppConfig.dbPassword,
    );
  }

  void init() {
    // db.connect();
  }

  void dipose() {
    // db.disconnect();
  }
}

Application app;

showInfo(BuildContext context, String info) {
  Flushbar(
      flushbarStyle: FlushbarStyle.FLOATING,
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.only(
          left: MediaQuery.of(context).size.width - 500 - 30, top: 15),
      borderRadius: 8,
      maxWidth: 500,
      duration: Duration(milliseconds: 1500),
      backgroundColor: AppColors.ok,
      messageText: Text(
        info,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, color: Colors.white),
      ))
    ..show(context);
}

showError(BuildContext context, String error) {
  Flushbar(
      flushbarStyle: FlushbarStyle.FLOATING,
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.only(
          left: MediaQuery.of(context).size.width - 500 - 30, top: 15),
      borderRadius: 8,
      maxWidth: 500,
      duration: Duration(milliseconds: 2000),
      backgroundColor: AppColors.error,
      messageText: Text(
        error,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, color: Colors.white),
      ))
    ..show(context);
}

class AppComponent extends StatefulWidget {
  @override
  State createState() {
    return AppComponentState();
  }
}

class AppComponentState extends State<AppComponent> {
  final _messageScaffoldKey = GlobalKey<ScaffoldState>();

  AppComponentState() {
    Routes.configureRoutes(app.router);
  }

  @override
  initState() {
    super.initState();
    app.init();
  }

  @override
  dispose() {
    app.dipose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return Scaffold(
          key: _messageScaffoldKey,
          body: child,
        );
      },
      navigatorObservers: [AppNavigatorObserver()],
      onGenerateTitle: (BuildContext context) =>
          AppLocalization.of(context).translate('title'),
      localeListResolutionCallback: (locales, supportedLocales) {
        locales.forEach((l) => log(l.languageCode));
        for (var locale in locales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode &&
                supportedLocale.countryCode == locale.countryCode)
              return supportedLocale;
          }
        }

        return supportedLocales.first;
      },
      localizationsDelegates: [
        AppLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale(AppConfig.language.toString().toLowerCase(),
          AppConfig.language.toString().toUpperCase()),
      supportedLocales: [
        //second param is country code
        Locale('en', 'US'),
        Locale('hu', 'HU'),
      ],
      debugShowCheckedModeBanner: false,
      theme: blackTheme(),
      onGenerateRoute: app.router.generator,
      initialRoute: Routes.overviewPage,
    );
  }
}

class AppNavigatorObserver extends NavigatorObserver {
  static final Logger _logger = Logger("app.AppNavigatorObserver");

  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    _logger.fine(
        "Route pushed: ${previousRoute?.settings?.name} -> ${route?.settings?.name}");
  }

  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    _logger.fine(
        "Route popped: ${previousRoute?.settings?.name} -> ${route?.settings?.name}");
  }

  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {
    _logger.fine(
        "Route removed: ${previousRoute?.settings?.name} -> ${route?.settings?.name}");
  }

  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    _logger.fine(
        "Route replaced: ${oldRoute?.settings?.name} -> ${newRoute?.settings?.name}");
  }
}
