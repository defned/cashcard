import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalization {
  final Locale locale;

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  static const LocalizationsDelegate<AppLocalization> delegate =
      _AppLocalzationsDelegate();

  static Map<String, String> _localizedStrings;

  static Future<AppLocalization> load(Locale locale) async {
    String jsonString =
        await rootBundle.loadString('lang/${locale.languageCode}.json');

    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return AppLocalization(locale);
  }

  String translate(String key) {
    return _localizedStrings[key];
  }
}

class _AppLocalzationsDelegate extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalzationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hu'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) => AppLocalization.load(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalization> old) {
    // we do not need it yet due to the fact that we are replacing only strings
    // no other UI element
    return false;
  }
}
