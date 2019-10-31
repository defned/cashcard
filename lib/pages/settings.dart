import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/app/app_config.dart';
import 'package:example_flutter/app/app_localizations.dart';
import 'package:example_flutter/db/db.dart';
import 'package:example_flutter/main.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:example_flutter/widget/subpage.dart';
import 'package:ffi_libserialport/libserialport.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with StateWithLocalization<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameFieldKey = GlobalKey<FormFieldState>();
  final _passwordFieldKey = GlobalKey<FormFieldState>();
  final _hostFieldKey = GlobalKey<FormFieldState>();
  final _portFieldKey = GlobalKey<FormFieldState>();
  final _databaseNameFieldKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return SubPage(
        onPop: () {},
        actions: <Widget>[
          IconButton(
              tooltip: tr("aboutTooltip"),
              icon: Icon(Icons.info_outline),
              onPressed: showAbout)
        ],
        title: tr('settingsPageTitle'),
        child: ListView(
          children: <Widget>[
            SizedBox(height: 20),
            buildGeneralCard(
              tr("general"),
              [
                buildGeneralRow(
                  tr('language'),
                  DropdownButtonFormField(
                    items: ['en', 'hu']
                        .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              tr(f),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900),
                            )))
                        .toList(),
                    value: ['en', 'hu'].contains(AppConfig.language)
                        ? AppConfig.language
                        : null,
                    onChanged: (lang) async {
                      await AppLocalization.load(
                          Locale(lang, lang.toUpperCase()));
                      setState(() {
                        AppConfig.language = lang;
                        AppConfig.store();
                        Scaffold.of(context).showSnackBar(SnackBar(
                            backgroundColor: Colors.green.shade600,
                            content: Text(
                                "${tr('language')} ${tr('refresh').toLowerCase()} ${tr('succeeded')}")));
                      });
                    },
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (SerialPort.getAvailablePorts().isNotEmpty)
              buildGeneralCard(
                tr("communication"),
                [
                  buildGeneralRow(
                    tr('serialPort'),
                    DropdownButtonFormField(
                      items: SerialPort.getAvailablePorts()
                          .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900),
                              )))
                          .toList(),
                      value: SerialPort.getAvailablePorts()
                              .contains(AppConfig.port)
                          ? AppConfig.port
                          : null,
                      onChanged: (port) {
                        setState(() {
                          AppConfig.port = port;
                          serialPortMainToIsolateStream
                              .send([IsolateState.EXIT]);
                          serialPortMainToIsolateStream
                              .send([IsolateState.INIT, AppConfig.port]);
                          AppConfig.store();
                          Scaffold.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.green.shade600,
                              content: Text(
                                  "${tr('serialPort').toLowerCase()[0].toUpperCase()} ${tr('refresh').toLowerCase()} ${tr('succeeded')}")));
                        });
                      },
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            if (SerialPort.getAvailablePorts().isEmpty)
              buildGeneralCard(tr("communication"), [
                Text(tr('serialPortNotFound'),
                    style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w900))
              ]),
            buildGeneralCard(
              tr('database'),
              [
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildGeneralRow(
                        tr('username'),
                        TextFormField(
                          key: _usernameFieldKey,
                          initialValue: AppConfig.dbUserName,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      buildGeneralRow(
                        tr('password'),
                        TextFormField(
                          key: _passwordFieldKey,
                          obscureText: true,
                          initialValue: AppConfig.dbPassword,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      SizedBox(height: 20),
                      buildGeneralRow(
                        tr('host'),
                        TextFormField(
                          key: _hostFieldKey,
                          initialValue: AppConfig.dbHost,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      buildGeneralRow(
                        tr('port'),
                        TextFormField(
                          key: _portFieldKey,
                          validator: (v) {
                            int p = int.tryParse(v);
                            if (p == null || p <= 0) return tr('invalidPort');
                            return null;
                          },
                          initialValue: AppConfig.dbPort.toString(),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      buildGeneralRow(
                        tr('databaseName'),
                        TextFormField(
                          key: _databaseNameFieldKey,
                          initialValue: AppConfig.dbName,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
              MaterialButton(
                child: Row(
                  children: <Widget>[
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 10),
                    Text(tr('refresh'),
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))
                  ],
                ),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    // If the form is valid, display a Snackbar.
                    String dbUserName = _usernameFieldKey.currentState.value;
                    String dbPassword = _passwordFieldKey.currentState.value;
                    String dbHost = _hostFieldKey.currentState.value;
                    int dbPort = int.parse(_portFieldKey.currentState.value);
                    String dbName = _databaseNameFieldKey.currentState.value;
                    try {
                      try {
                        await app.db.close();
                      } catch (e) {}
                      app.db = Db(
                        host: dbHost,
                        port: dbPort,
                        dbName: dbName,
                        userName: dbUserName,
                        password: dbPassword,
                      );
                      await app.db.connect();
                      AppConfig.dbHost = dbHost;
                      AppConfig.dbPort = dbPort;
                      AppConfig.dbName = dbName;
                      AppConfig.dbUserName = dbUserName;
                      AppConfig.dbPassword = dbPassword;
                      AppConfig.store();
                      print("Db connection refresh succeeded");
                      Scaffold.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.green.shade600,
                          content: Text(
                              "${tr('database')} ${tr('refresh').toLowerCase()} ${tr('succeeded')}")));
                    } catch (e) {
                      print("Db connection refresh failed");
                      Scaffold.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.red.shade600,
                          content: Text(
                              "${tr('database')} ${tr('refresh').toLowerCase()} ${tr('failed')} - ${e.toString()}")));
                      try {
                        await app.db.close();
                      } catch (e) {}
                      app.db = Db(
                        host: AppConfig.dbHost,
                        port: AppConfig.dbPort,
                        dbName: AppConfig.dbName,
                        userName: AppConfig.dbUserName,
                        password: AppConfig.dbPassword,
                      );
                      await app.db.connect();
                    }
                  }
                },
              ),
            ),
          ],
        ));
  }

  Widget buildGeneralCard(String title, List<Widget> children,
      [Widget action]) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(title,
                      style:
                          TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  if (action != null) action
                ],
              ),
              SizedBox(height: 10),
              Container(
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: children),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGeneralRow(String title, Widget field) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 20),
            Expanded(
              child: field,
            ),
          ],
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
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
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
        );
      },
    );
  }
}
