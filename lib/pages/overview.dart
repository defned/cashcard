import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/main.dart';
import 'package:example_flutter/pages/entries.dart';
import 'package:example_flutter/pages/pay.dart';
import 'package:example_flutter/pages/registration.dart';
import 'package:example_flutter/pages/settings.dart';
import 'package:example_flutter/pages/topup.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

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

  StreamSubscription<String> _subscription;
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    _subscription = serialPort.stream.listen((onData) {
      if (!isBusy && !Navigator.of(context).canPop()) {
        isBusy = true;
        app.db.get(onData).then((record) async {
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
                      MaterialCommunityIcons.getIconData(
                          "account-card-details"),
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
                      color: Colors.red.shade600,
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
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
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
            tooltip: tr('settingsMenuTooltip'),
            icon: Icon(Icons.settings),
            onPressed: jumpTo(SettingsPage()),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Column(
              children: <Widget>[
                createButton(tr('registration'),
                    onTap: jumpTo(RegistrationPage())),
                createButton(tr('topUp'), onTap: jumpTo(TopUpPage())),
                createButton(tr('pay'), onTap: jumpTo(PayPage())),
                createButton(tr('entries'), onTap: jumpTo(EntriesPage())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget createButton(String s, {Null Function() onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RawMaterialButton(
          fillColor: Colors.lightBlue.shade100,
          onPressed: onTap,
          child: Container(
            height: 250,
            child: Center(
              child: AutoSizeText(s,
                  style: TextStyle(fontSize: 40), maxLines: 1, group: group),
            ),
          ),
        ),
      ),
    );
  }
}
