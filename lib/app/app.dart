import 'package:cashcard/app/app_config.dart';
import 'package:cashcard/app/app_localizations.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/pages/overview.dart';
import 'package:cashcard/util/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class Application extends WidgetsBindingObserver {
  late Db db;

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
}

late Application app;

class AppComponent extends StatefulWidget {
  const AppComponent({super.key});

  @override
  AppComponentState createState() => AppComponentState();
}

class AppComponentState extends State<AppComponent> {
  AppComponentState();

  @override
  initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const OverviewPage(),
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
    );
  }
}
