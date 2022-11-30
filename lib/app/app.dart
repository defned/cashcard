import 'dart:async';

import 'package:cashcard/app/app_config.dart';
import 'package:cashcard/app/app_localizations.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/pages/overview.dart';
import 'package:cashcard/util/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class Application extends WidgetsBindingObserver {
  // StreamController<SnackBarMessage> messageController =
  //     StreamController<SnackBarMessage>();
  // late Stream<SnackBarMessage> syncMessages;
  // final Router router = Router();
  late Db db;

  Application() {
    // syncMessages = messageController.stream;

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

late Application app;

class AppComponent extends StatefulWidget {
  const AppComponent({super.key});

  @override
  AppComponentState createState() => AppComponentState();
}

class AppComponentState extends State<AppComponent> {
  late StreamSubscription _sub;
  late StreamSubscription _messageSubscription;
  final _messageScaffoldKey = GlobalKey<ScaffoldState>();

  AppComponentState() {
    // Routes.configureRoutes(app.router);
  }

  @override
  initState() {
    super.initState();
    app.init();
    // _messageSubscription = app.syncMessages.listen((message) {
    //   _messageScaffoldKey.currentState.showSnackBar(SnackBar(
    //     content: Row(
    //       children: <Widget>[
    //         Expanded(
    //             child: Text(message.message,
    //                 textAlign: TextAlign.center,
    //                 style: TextStyle(fontWeight: FontWeight.w700))),
    //         if (message.action != null)
    //           CapsuleButton(
    //             child: Padding(
    //               padding: const EdgeInsets.symmetric(horizontal: 16.0),
    //               child: Text(
    //                 message.actionMessage,
    //                 style: TextStyle(
    //                     color: message.type == SnackBarType.error
    //                         ? Colors.red.withOpacity(0.95)
    //                         : Colors.black.withOpacity(0.8),
    //                     fontWeight: FontWeight.w800),
    //               ),
    //             ),
    //             color: Colors.white,
    //             onTap: () {
    //               _messageScaffoldKey.currentState.hideCurrentSnackBar();
    //               message.action();
    //             },
    //           )
    //       ],
    //     ),
    //     backgroundColor: message.type == SnackBarType.error
    //         ? Colors.red.withOpacity(0.95)
    //         : Colors.black.withOpacity(0.8),
    //     duration: message.duration,
    //   ));
    // });
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
      home: const OverviewPage(),
      // builder: (context, child) {
      //   return Scaffold(
      //     key: _messageScaffoldKey,
      //     body: const OverviewPage(),
      //   );
      // },
      // navigatorObservers: [AppNavigatorObserver()],
      onGenerateTitle: (BuildContext context) =>
          AppLocalization.of(context).translate('title'),
      localeListResolutionCallback: (locales, supportedLocales) {
        for (var l in locales!) {
          log(l.languageCode);
        }
        for (var locale in locales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode &&
                supportedLocale.countryCode == locale.countryCode) {
              return supportedLocale;
            }
          }
        }

        return supportedLocales.first;
      },
      localizationsDelegates: const [
        AppLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale(AppConfig.language.toString().toLowerCase(),
          AppConfig.language.toString().toUpperCase()),
      supportedLocales: const [
        //second param is country code
        Locale('en', 'US'),
        Locale('hu', 'HU'),
      ],
      debugShowCheckedModeBanner: false,
      theme: blackTheme(),
      // onGenerateRoute: app.router.generator,
      // initialRoute: Routes.overviewPage,
    );
  }
}

// class AppNavigatorObserver extends NavigatorObserver {
//   static final Logger _logger = Logger("app.AppNavigatorObserver");

//   void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
//     _logger.fine(
//         "Route pushed: ${previousRoute?.settings?.name} -> ${route?.settings?.name}");
//   }

//   void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
//     _logger.fine(
//         "Route popped: ${previousRoute?.settings?.name} -> ${route?.settings?.name}");
//   }

//   void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {
//     _logger.fine(
//         "Route removed: ${previousRoute?.settings?.name} -> ${route?.settings?.name}");
//   }

//   void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
//     _logger.fine(
//         "Route replaced: ${oldRoute?.settings?.name} -> ${newRoute?.settings?.name}");
//   }
// }
