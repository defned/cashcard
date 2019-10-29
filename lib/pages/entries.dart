import 'dart:async';

import 'package:example_flutter/db/db.dart';
import 'package:example_flutter/main.dart';
import 'package:example_flutter/widget/subpage.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Regsitration page
class RegistrationPage extends StatefulWidget {
  /// Const constructor
  const RegistrationPage({Key key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with StateWithLocalization<RegistrationPage> {
  final TextEditingController _cardNumberFieldController =
      TextEditingController();
  final GlobalKey<FormFieldState> _cardNumberFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _cardOwnerFieldKey =
      GlobalKey<FormFieldState>();
  StreamSubscription<String> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = serialPort.stream.listen((onData) {
      _cardNumberFieldController.text = onData;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  final FocusNode cardIdFocus = FocusNode();
  @override
  Widget build(BuildContext context) {
    return SubPage(
      onPop: () {},
      title: tr('registrationPageTitle'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        child: Center(
          child:PaginatedDataTable(columns: <DataColumn>[DataColumn(label: Text("ID"), onSort: (_, __) {})]),
        ),
      ),
    );
  }
}
