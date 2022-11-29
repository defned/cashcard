import 'package:cashcard/app/app_localizations.dart';
import 'package:flutter/material.dart';

mixin StateWithLocalization<T extends StatefulWidget> on State<T> {
  String tr(String id) {
    String res = AppLocalization.of(context).translate(id);
    return res;
  }

  jumpTo(Widget widget) {
    return () {
      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => widget));
    };
  }
}
