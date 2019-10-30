import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:example_flutter/app/app_config.dart';
import 'package:example_flutter/app/app_localizations.dart';
import 'package:example_flutter/app/routes.dart';
import 'package:example_flutter/app/style.dart';
import 'package:example_flutter/db/db.dart';
import 'package:example_flutter/util/snackbarmessage.dart';
import 'package:example_flutter/widget/capsulebutton.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

class Application extends WidgetsBindingObserver {
  StreamController<SnackBarMessage> messageController =
      StreamController<SnackBarMessage>();
  Stream<SnackBarMessage> syncMessages;
  final Router router = Router();
  Db db;

  Application() {
    syncMessages = messageController.stream;

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
    db.connect();
  }

  void dipose() {
    db.close();
  }
}

Application app;

class AppComponent extends StatefulWidget {
  @override
  State createState() {
    return AppComponentState();
  }
}

class AppComponentState extends State<AppComponent> {
  StreamSubscription _sub;
  StreamSubscription _messageSubscription;
  final _messageScaffoldKey = GlobalKey<ScaffoldState>();

  AppComponentState() {
    Routes.configureRoutes(app.router);
  }

  @override
  initState() {
    super.initState();
    app.init();
    _messageSubscription = app.syncMessages.listen((message) {
      if (message is SnackBarMessage) {
        _messageScaffoldKey.currentState.showSnackBar(SnackBar(
          content: Row(
            children: <Widget>[
              Expanded(
                  child: Text(message.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700))),
              if (message.action != null)
                CapsuleButton(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      message.actionMessage,
                      style: TextStyle(
                          color: message.type == SnackBarType.error
                              ? Colors.red.withOpacity(0.95)
                              : Colors.black.withOpacity(0.8),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  color: Colors.white,
                  onTap: () {
                    _messageScaffoldKey.currentState.hideCurrentSnackBar();
                    message.action();
                  },
                )
            ],
          ),
          backgroundColor: message.type == SnackBarType.error
              ? Colors.red.withOpacity(0.95)
              : Colors.black.withOpacity(0.8),
          duration: message.duration,
        ));
      }
    });
  }

  @override
  dispose() {
    _sub.cancel();
    _messageSubscription.cancel();
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
          AppLocalizations.of(context).translate('title'),
      localeListResolutionCallback: (locales, supportedLocales) {
        locales.forEach((l) => print(l.languageCode));
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
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        //second param is country code
        Locale('en', 'US'),
        Locale('hu', 'HU'),
      ],
      debugShowCheckedModeBanner: false,
      theme: basicTheme,
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
