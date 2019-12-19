import 'dart:async';
import 'dart:io';

import 'package:example_flutter/db/db.dart';
import 'package:path/path.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/app/style.dart';
import 'package:example_flutter/main.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:example_flutter/widget/filedialog.dart';
import 'package:example_flutter/widget/progressdialog.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      loadDetails(onData);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  pay() async {
    try {
      await app.db.pay(_cardIdFieldController.text,
          int.parse(_propertyFieldController.text));
      showInfo("${tr('pay')} ${tr('succeeded')}");
      resetFields();
    } catch (e) {
      showError(tr("${e.toString()}"));
    }
  }

  topUp() async {
    try {
      await app.db.topUp(_cardIdFieldController.text,
          int.parse(_propertyFieldController.text));
      showInfo("${tr('topUp')} ${tr('succeeded')}");
      resetFields();
    } catch (e) {
      showError(tr("${e.toString()}"));
    }
  }

  loadDetails(String data) async {
    try {
      DbRecord record = await app.db.get(data);
      resetFields();
      _cardIdFieldController.text = data;
      _balanceFieldController.text = "${record.balance} Ft";
    } catch (e) {
      try {
        if (e == DbExceptions.noRows) {
          await app.db.register(data);
          showInfo("${tr('registrationPageTitle')} ${tr('succeeded')}");
          resetFields();
        }

        DbRecord record = await app.db.get(data);

        _cardIdFieldController.text = data;
        _balanceFieldController.text = "${record.balance} Ft";
      } catch (e) {
        showError(tr("${e.toString()}"));
      }
    }
  }

  resetFields() {
    setState(() {
      _cardIdFieldController.clear();
      _balanceFieldController.clear();
      _propertyFieldController.clear();
      propertyFocus.requestFocus();
    });
  }

  showInfo(String info) {
    Flushbar(
        flushbarStyle: FlushbarStyle.FLOATING,
        flushbarPosition: FlushbarPosition.TOP,
        margin: EdgeInsets.only(
            left: MediaQuery.of(this.context).size.width - 500 - 30, top: 15),
        borderRadius: 8,
        maxWidth: 500,
        duration: Duration(milliseconds: 1500),
        backgroundColor: AppColors.ok,
        messageText: Text(
          info,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, color: Colors.white),
        ))
      ..show(this.context);
  }

  showError(String error) {
    Flushbar(
        flushbarStyle: FlushbarStyle.FLOATING,
        flushbarPosition: FlushbarPosition.TOP,
        margin: EdgeInsets.only(
            left: MediaQuery.of(this.context).size.width - 500 - 30, top: 15),
        borderRadius: 8,
        maxWidth: 500,
        duration: Duration(milliseconds: 2000),
        backgroundColor: AppColors.error,
        messageText: Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, color: Colors.white),
        ))
      ..show(this.context);
  }

  bool _validId = false;
  bool _validProp = false;
  double radius() => 10;
  final FocusNode cardIdFocus = FocusNode();
  // final FocusNode _cardIdFocus = FocusNode();
  final FocusNode propertyFocus = FocusNode();
  final FocusNode _pageFocus = FocusNode();
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
      body: RawKeyboardListener(
        focusNode: _pageFocus,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            bool isCTRL =
                Platform.isMacOS ? event.isMetaPressed : event.isControlPressed;

            bool isImport = event.logicalKey.keyLabel == "i";
            bool isExport = event.logicalKey.keyLabel == "e";

            if (isCTRL && isImport) {
              showImportDialog();
            } else if (isCTRL && isExport) {
              showExportDialog();
            }

            // if (event.logicalKey.keyId == 54 &&
            //     (_propertyFieldKey.currentState.value
            //             as String)
            //         .isNotEmpty) {
            //   validate();
            // }
          }
        },
        child: Center(
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
                              Text(tr('cardId'),
                                  style: TextStyle(fontSize: 40)),
                              SizedBox(height: 10),
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
                                  // prefixIcon: Icon(
                                  //   MaterialCommunityIcons.getIconData(
                                  //       "account-card-details"),
                                  //   size: 45,
                                  // ),
                                  suffix: _cardIdFieldController.text.isNotEmpty
                                      ? IconButton(
                                          iconSize: 35,
                                          onPressed: () {
                                            loadDetails(
                                                _cardIdFieldController.text);
                                          },
                                          icon: Icon(Icons.input),
                                        )
                                      : null,
                                ),
                                validator: (value) {
                                  refresh(() => _validId = value.isNotEmpty);
                                  return null;
                                },
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 45,
                                    // fontWeight: FontWeight.bold,
                                    // fontFamily: 'Advanced_Led_Board-7.ttf',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brightText),
                                key: _cardIdFieldKey,
                                controller: _cardIdFieldController,
                              ),
                            ]),
                          ),
                          SizedBox(width: 30),
                          Expanded(
                            child: Column(children: <Widget>[
                              Text(tr('balance'),
                                  style: TextStyle(fontSize: 40)),
                              SizedBox(height: 10),
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
                                    // suffixText:
                                    //     _balanceFieldController.text.isNotEmpty
                                    //         ? "Ft"
                                    //         : null,
                                    // suffixStyle: TextStyle(
                                    //     color: AppColors.brightText,
                                    //     fontSize: 35),
                                    // prefixIcon: Icon(
                                    //   Icons.monetization_on,
                                    //   size: 45,
                                    // ),
                                    ),
                                validator: (value) {
                                  refresh(() => _validId = value.isNotEmpty);
                                  return null;
                                },
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 45,
                                    fontWeight: FontWeight.bold,
                                    // fontFamily: 'Arcade',
                                    color: AppColors.brightText),
                                controller: _balanceFieldController,
                              ),
                            ]),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Text(tr('amount'), style: TextStyle(fontSize: 40)),
                            SizedBox(height: 10),
                            RawKeyboardListener(
                              focusNode: _propertyFocus,
                              onKey: (event) {
                                // if (event.logicalKey.keyId == 54 &&
                                //     (_propertyFieldKey.currentState.value
                                //             as String)
                                //         .isNotEmpty) {
                                //   validate();
                                // }
                              },
                              child: TextFormField(
                                cursorColor: Colors.transparent,
                                focusNode: propertyFocus,
                                autocorrect: false,
                                autovalidate: true,
                                enableSuggestions: false,
                                decoration: InputDecoration(
                                  prefixText: "Ft",
                                  prefixStyle: TextStyle(
                                      color: AppColors.brightText,
                                      fontSize: 45),
                                  suffixIcon: _propertyFieldController
                                          .text.isNotEmpty
                                      ? IconButton(
                                          iconSize: 35,
                                          onPressed: () {
                                            Future.delayed(
                                                    Duration(milliseconds: 50))
                                                .then((_) {
                                              setState(() {
                                                _propertyFieldController
                                                    .clear();
                                                FocusScope.of(context)
                                                    .unfocus();
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
                                  fontSize: 75,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                  // fontFamily: 'Digit',
                                ),
                                key: _propertyFieldKey,
                                validator: (value) {
                                  if (value.isNotEmpty) {
                                    int amount = 0;
                                    try {
                                      amount = int.parse(value);
                                    } catch (e) {
                                      refresh(() => _validProp = false);
                                      return tr("notNumber");
                                    }

                                    if (amount <= 0) {
                                      refresh(() => _validProp = false);
                                      return tr("mustBePositive");
                                    }
                                  }
                                  refresh(() {
                                    _validProp = value.isNotEmpty;
                                    isButtonsActive = _validProp &&
                                        _cardIdFieldController.text.isNotEmpty;
                                  });
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
                    createButton(tr('topUp'), onTap: () {
                      topUp();
                    }),
                    createButton(tr('pay'), onTap: () {
                      pay();
                    }),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(radius()),
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
    setState(() {
      if (ctrl == _propertyFieldController) {}
    });
  }

  bool isButtonsActive = true;
  Widget createButton(String s, {Null Function() onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: RawMaterialButton(
          onPressed: isButtonsActive ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(radius()),
                border: Border.all(
                  width: 3,
                  color: isButtonsActive
                      ? AppColors.brightText
                      : AppColors.disabledColor,
                )),
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
            child: Center(
              child: AutoSizeText(s,
                  style: TextStyle(
                    fontSize: 50,
                    color: isButtonsActive
                        ? AppColors.brightText
                        : AppColors.disabledColor,
                  ),
                  maxLines: 1,
                  group: group),
            ),
          ),
        ),
      ),
    );
  }

  void showAbout() {
    showDialog<void>(
      barrierDismissible: true,
      context: this.context,
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

  final importKey = GlobalKey<ProgressDialogState>();
  showImportDialog() {
    showDialog<void>(
      barrierDismissible: false,
      context: this.context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade200,
          content: Container(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 2,
            child: Theme(
              data: whiteTheme(),
              child: FileDialog(
                title: tr('importAction'),
                onOpen: (fs) async {
                  List<DbRecord> records = [];
                  try {
                    records = serializeRecordsFromCSV(fs);
                    await app.db.import(records);
                    showInfo(
                        "${tr('importAction')} ${tr('succeeded')} ${records.length}/${records.length}");
                  } catch (e) {
                    showError("${tr('importAction')} ${tr('failed')}");
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  showExportDialog() {
    final DbRecordDataSource _dbRecordsDataSource = DbRecordDataSource()
      ..init("");
    showDialog<void>(
      barrierDismissible: false,
      context: this.context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade200,
          content: Container(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 2,
            child: Theme(
              data: whiteTheme(),
              child: FileDialog(
                title: tr('exportAction'),
                target: FileDialogTarget.DIRECTORY,
                onOpen: (dir) async {
                  List<DbRecord> records = _dbRecordsDataSource.getRecords();
                  String serializedRecords =
                      serializeRecordsIntoCSV(records).join("\n");
                  File exportFile = File(join(dir.absolute.path,
                      "export-${DateTime.now().toIso8601String().replaceAll(".", "").replaceAll(":", "").replaceAll("-", "").replaceAll(" ", "")}.csv"));
                  exportFile.writeAsStringSync(serializedRecords);
                  print("Export succeeded to '${exportFile.absolute.path}'");
                  showInfo(
                      "${tr('exportAction')} ${tr('succeeded')} ${records.length}/${records.length}");
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<DbRecord> serializeRecordsFromCSV(FileSystemEntity fs) {
    if (fs is! File) throw tr('invalidImportSource');

    List<String> lines = (fs as File).readAsLinesSync();
    String firstLine = lines.first.toUpperCase();
    Map<String, int> columnIds = {
      'ID': 0,
      'NAME': 0,
      'BALANCE': 0,
    };
    if (!firstLine.contains(';')) throw tr('invalidImportFormat');

    // Remapping indexes if needed
    List<String> header = firstLine.split(';');
    bool hasHeader = false;
    if (firstLine.contains('ID') || firstLine.contains('NAME')) {
      columnIds['ID'] = header.indexOf('ID');
      columnIds['NAME'] = header.indexOf('NAME');
      columnIds['BALANCE'] = header.indexOf('BALANCE');
      hasHeader = true;
    }

    List<DbRecord> res = [];
    for (var i = hasHeader ? 1 : 0; i < lines.length; i++) {
      List<String> splitted = lines[i].split(';');
      if (splitted.length != header.length) {
        print(tr('malformedInput'));
        continue;
      }

      if (splitted[columnIds['ID']].isEmpty) {
        print("Skipped record due to missing or empty property '${[
          splitted[columnIds['ID']]
        ]}'");
        continue;
      }

      res.add(DbRecord(
        splitted[columnIds['ID']],
        columnIds['BALANCE'] == -1
            ? null
            : int.tryParse(splitted[columnIds['BALANCE']]),
      ));
    }

    return res;
  }

  List<String> serializeRecordsIntoCSV(List<DbRecord> records) {
    const String SEP = ";";

    List<String> res = ['ID${SEP}BALANCE$SEP'];
    records.forEach((record) {
      res.add("${record.id}$SEP${record.balance}$SEP");
    });

    return res;
  }
}
