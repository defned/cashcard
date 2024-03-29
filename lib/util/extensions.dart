import 'package:example_flutter/app/app_localizations.dart';
import 'package:flutter/material.dart';

mixin StateWithLocalization<T extends StatefulWidget> on State<T> {
  String tr(String id) {
    String res = AppLocalization.of(context).translate(id);
    return res ?? id;
  }

  jumpTo(Widget widget) {
    return () {
      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => widget));
    };
  }
}

extension StringExtension on String {
  String replaceRegExp(RegExp pattern, String strReplacePattern) =>
      this.replaceAllMapped(pattern, (match) {
        var replacedString = strReplacePattern;
        for (var i = 0; i <= match.groupCount; i++) {
          replacedString = replacedString.replaceAll('\$$i', match.group(i));
        }
        return replacedString;
      });
}
