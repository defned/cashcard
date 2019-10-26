import 'package:example_flutter/app/app_localizations.dart';
import 'package:flutter/material.dart';

mixin StateWithLocalization<T extends StatefulWidget> on State<T> {
  String tr(String id) {
    return AppLocalizations.of(context).translate(id);
  }

  jumpTo(Widget widget) {
    return () {
      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => widget));
    };
  }
}
