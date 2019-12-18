import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/app/style.dart';
import 'package:example_flutter/main.dart';
import 'package:example_flutter/pages/pay.dart';
import 'package:example_flutter/pages/settings.dart';
import 'package:example_flutter/pages/topup.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';

class OverviewPage extends StatefulWidget {
  /// Constructor
  const OverviewPage({Key key}) : super(key: key);

  @override

  /// State creator
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with StateWithLocalization<OverviewPage> {
  AutoSizeGroup group = AutoSizeGroup();

  final TextEditingController _cardIdFieldController = TextEditingController();
  final TextEditingController _balanceFieldController = TextEditingController();
  final TextEditingController _propertyFieldController =
      TextEditingController();
  final GlobalKey<FormFieldState> _cardIdFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _propertyFieldKey =
      GlobalKey<FormFieldState>();

  StreamSubscription<String> _subscription;

  // Holds the text that user typed.
  String text = '';

  // True if shift enabled.
  bool shiftEnabled = false;

  // is true will show the numeric keyboard.
  bool isNumericMode = true;

  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    _subscription = serialPort.stream.listen((onData) {
      _cardIdFieldController.text = onData;
      app.db.get(onData).then((record) {
        _balanceFieldController.text = "${record.balance} Ft";
      });
      propertyFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void showModal() {
    if (!isBusy && !Navigator.of(context).canPop()) {
      isBusy = true;
      app.db.get("onData").then((record) async {
        await showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            Future.delayed(Duration(milliseconds: 3000), () {
              Navigator.maybePop(context);
              isBusy = false;
            });
            return AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    MaterialCommunityIcons.getIconData("account-card-details"),
                    size: 100,
                  ),
                  SizedBox(width: 25),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5),
                        RichText(
                            text: TextSpan(
                          text: "${tr('cardId')}: ",
                          children: [
                            TextSpan(
                                text: "${record.id}",
                                style: TextStyle(
                                    fontSize: 21,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900))
                          ],
                          style: TextStyle(
                              fontSize: 21,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        )),
                        SizedBox(height: 10),
                        RichText(
                            text: TextSpan(
                          text: "${tr('name')}: ",
                          children: [
                            TextSpan(
                                text: "${record.name}",
                                style: TextStyle(
                                    fontSize: 21,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900))
                          ],
                          style: TextStyle(
                              fontSize: 21,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        )),
                        SizedBox(height: 10),
                        RichText(
                            text: TextSpan(
                          text: "${tr('balance')}: ",
                          children: [
                            TextSpan(
                                text: "${record.balance} HUF",
                                style: TextStyle(
                                    fontSize: 21,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900))
                          ],
                          style: TextStyle(
                              fontSize: 21,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        )),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }, onError: (e) async {
        String trErr = tr(e.toString());
        if (trErr == null) trErr = e.toString();

        await showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            Future.delayed(Duration(milliseconds: 3000), () {
              Navigator.maybePop(context);
              isBusy = false;
            });
            return AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    MaterialIcons.getIconData('warning'),
                    size: 40,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 25),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          trErr,
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      });
    }
  }

  validate() async {
    if (isBusy) return;
    try {
      isBusy = true;
      await app.db.pay(_cardIdFieldController.value.text,
          int.parse(_propertyFieldKey.currentState.value));
      _cardIdFieldController.clear();
      _propertyFieldController.clear();
      cardIdFocus.requestFocus();

      Flushbar(
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.TOP,
          margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.width - 400 - 30, top: 15),
          borderRadius: 8,
          maxWidth: 400,
          duration: Duration(milliseconds: 1500),
          backgroundColor: AppColors.ok,
          messageText: Text(
            "${tr('payPageTitle')} ${tr('succeeded')}",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, color: Colors.white),
          ))
        ..show(context);
    } catch (e) {
      String trErr = tr(e.toString());
      if (trErr == null) trErr = e.toString();

      Flushbar(
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.TOP,
          margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.width - 400 - 30, top: 15),
          borderRadius: 8,
          maxWidth: 400,
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
          messageText: Text(
            "${tr('payPageTitle')} ${tr('failed')}",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, color: Colors.white),
          ))
        ..show(context);
    }
    isBusy = false;
  }

  bool _validId = false;
  bool _validProp = false;

  final FocusNode cardIdFocus = FocusNode();
  final FocusNode _cardIdFocus = FocusNode();
  final FocusNode propertyFocus = FocusNode();
  final FocusNode _propertyFocus = FocusNode();

  void refresh(Function f) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) setState(f);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('title'),
          style: TextStyle(fontSize: 20),
        ),
        actions: <Widget>[
          IconButton(
              tooltip: tr("aboutTooltip"),
              icon: Icon(Icons.info_outline),
              onPressed: showAbout)
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 10,
              child: Container(
                constraints: BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Row(children: <Widget>[
                        Expanded(
                          child: Column(children: <Widget>[
                            Text(tr('cardId'), style: TextStyle(fontSize: 40)),
                            SizedBox(height: 20),
                            TextFormField(
                              // enabled: false,
                              // decoration: InputDecoration(
                              //   focusedBorder: InputBorder.none,
                              //   enabledBorder: InputBorder.none,
                              // ),
                              focusNode: cardIdFocus,
                              cursorColor: Colors.transparent,
                              enableSuggestions: false,
                              autofocus: true,
                              autocorrect: false,
                              autovalidate: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  MaterialCommunityIcons.getIconData(
                                      "account-card-details"),
                                  size: 45,
                                ),
                              ),
                              validator: (value) {
                                refresh(() => _validId = value.isNotEmpty);
                                return null;
                              },
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 45,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brightText),
                              key: _cardIdFieldKey,
                              controller: _cardIdFieldController,
                            ),
                          ]),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(children: <Widget>[
                            Text(tr('balance'), style: TextStyle(fontSize: 40)),
                            SizedBox(height: 20),
                            TextFormField(
                              // enabled: false,
                              // decoration: InputDecoration(
                              //   focusedBorder: InputBorder.none,
                              //   enabledBorder: InputBorder.none,
                              // ),
                              // focusNode: cardIdFocus,
                              cursorColor: Colors.transparent,
                              enableSuggestions: false,
                              autofocus: true,
                              autocorrect: false,
                              autovalidate: true,
                              decoration: InputDecoration(
                                suffixText:
                                    _balanceFieldController.text.isNotEmpty
                                        ? "Ft"
                                        : null,
                                prefixIcon: Icon(
                                  Icons.monetization_on,
                                  size: 45,
                                ),
                              ),
                              validator: (value) {
                                refresh(() => _validId = value.isNotEmpty);
                                return null;
                              },
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 45,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brightText),
                              // key: _cardIdFieldKey,
                              controller: _balanceFieldController,
                            ),
                            // SizedBox(height: 20),
                          ]),
                        ),
                      ]),
                    ),
                    // SizedBox(height: 50),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text(tr('amount'), style: TextStyle(fontSize: 40)),
                          SizedBox(height: 20),
                          RawKeyboardListener(
                            focusNode: _propertyFocus,
                            onKey: (event) {
                              if (event.logicalKey.keyId == 54 &&
                                  (_propertyFieldKey.currentState.value
                                          as String)
                                      .isNotEmpty) {
                                validate();
                              }
                            },
                            child: TextFormField(
                              cursorColor: Colors.transparent,
                              focusNode: propertyFocus,
                              autocorrect: false,
                              autovalidate: true,
                              enableSuggestions: false,
                              decoration: InputDecoration(
                                prefixText: "Ft",
                                suffixIcon: _propertyFieldController
                                        .text.isNotEmpty
                                    ? IconButton(
                                        iconSize: 35,
                                        onPressed: () {
                                          Future.delayed(
                                                  Duration(milliseconds: 50))
                                              .then((_) {
                                            setState(() {
                                              _propertyFieldController.clear();
                                              FocusScope.of(context).unfocus();
                                            });
                                          });
                                        },
                                        icon: Icon(Icons.clear),
                                      )
                                    : null,
                              ),
                              controller: _propertyFieldController,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 55,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent),
                              key: _propertyFieldKey,
                              validator: (value) {
                                if (value.isNotEmpty) {
                                  int amount = 0;
                                  try {
                                    amount = int.parse(value);
                                  } catch (e) {
                                    refresh(() => _validProp = false);
                                    return "Not a number";
                                  }

                                  if (amount <= 0) {
                                    refresh(() => _validProp = false);
                                    return "Amount must be positive";
                                  }
                                }
                                refresh(() => _validProp = value.isNotEmpty);
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 150,
              constraints: BoxConstraints(maxWidth: 800),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  createButton(tr('topUp'), onTap: jumpTo(TopUpPage())),
                  // createButton(tr('balance'), onTap: jumpTo(PayPage())),
                  createButton(tr('pay'), onTap: jumpTo(PayPage())),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    width: 3,
                    color: AppColors.brightText,
                  )),
              constraints: BoxConstraints(maxWidth: 600),
              child: VirtualKeyboard(
                  fontSize: 35,
                  textColor: AppColors.brightText,
                  height: 250,
                  type: VirtualKeyboardType.Numeric,
                  onKeyPress: _onKeyPress),
            ),
            SizedBox(height: 40)
          ],
        ),
      ),
    );
  }

  /// Fired when the virtual keyboard key is pressed.
  _onKeyPress(VirtualKeyboardKey key) {
    TextEditingController ctrl;

    if (cardIdFocus.hasFocus) {
      ctrl = _cardIdFieldController;
    } else if (propertyFocus.hasFocus) {
      ctrl = _propertyFieldController;
    } else
      return;

    if (key.keyType == VirtualKeyboardKeyType.String) {
      ctrl.text = ctrl.text + (shiftEnabled ? key.capsText : key.text);
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          if (ctrl.text.length == 0) return;
          ctrl.text = ctrl.text.substring(0, ctrl.text.length - 1);
          // if (text.length == 0) return;
          // text = text.substring(0, text.length - 1);
          break;
        case VirtualKeyboardKeyAction.Return:
          ctrl.text = ctrl.text + '\n';
          // text = text + '\n';
          break;
        case VirtualKeyboardKeyAction.Space:
          ctrl.text = ctrl.text + key.text;
          // text = text + key.text;
          break;
        case VirtualKeyboardKeyAction.Shift:
          shiftEnabled = !shiftEnabled;
          break;
        default:
      }
    }
    // Update the screen
    setState(() {});
  }

  Widget createButton(String s, {Null Function() onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: RawMaterialButton(
          onPressed: onTap,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  width: 3,
                  color: AppColors.brightText,
                )),
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
            child: Center(
              child: AutoSizeText(s,
                  style: TextStyle(fontSize: 50), maxLines: 1, group: group),
            ),
          ),
        ),
      ),
    );
  }

  void showAbout() {
    showDialog<void>(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.black,
                  size: 100,
                ),
                SizedBox(width: 25),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                        text: "${tr('author')}: ",
                        children: [
                          TextSpan(
                              text: "${tr('authorName')}",
                              style: TextStyle(
                                  fontSize: 21,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900)),
                        ],
                        style: TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      )),
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                        text: "${tr('email')}: ",
                        children: [
                          TextSpan(
                              text: "${tr('authorEmail')}",
                              style: TextStyle(
                                  fontSize: 21,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900)),
                        ],
                        style: TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      )),
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                        text: "${tr('version')}: ",
                        children: [
                          TextSpan(
                              text: "${tr('versionNumber')}",
                              style: TextStyle(
                                  fontSize: 21,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900)),
                        ],
                        style: TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      )),
                      SizedBox(height: 10),
                      Text(
                        "${tr('about')}",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
