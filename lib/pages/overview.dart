import 'dart:async';
import 'dart:io';

import 'package:cashcard/app/app_config.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/util/logging.dart';
import 'package:cashcard/widget/expandable.dart';
import 'package:path/path.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cashcard/app/app.dart';
import 'package:cashcard/widget/products.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/main.dart';
import 'package:cashcard/util/extensions.dart';
import 'package:cashcard/widget/filedialog.dart';
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

  Future<List<DbRecordProduct>> _dbProducts = Future.value([]);

  @override
  void initState() {
    super.initState();
    _subscription =
        serialPort.stream.map((data) => data.trim()).listen(loadDetails);
    _dbProducts = app.db.getProductAll("");
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  pay() async {
    try {
      await app.db.pay(_cardIdFieldController.text,
          int.tryParse(_propertyFieldController.text));
      showInfo("${tr('pay')} ${tr('succeeded')}");
      resetFields();
    } catch (e) {
      showError(tr("${e.toString()}"));
    }
  }

  topUp() async {
    try {
      await app.db.topUp(_cardIdFieldController.text,
          int.tryParse(_propertyFieldController.text));
      showInfo("${tr('topUp')} ${tr('succeeded')}");
      resetFields();
    } catch (e) {
      showError(tr("${e.toString()}"));
    }
  }

  loadDetails(String data) async {
    if (AppConfig.transformationFrom != null) {
      final hasMatch = AppConfig.transformationFrom.hasMatch(data);

      if (hasMatch && AppConfig.transformationTo != null)
        data = data.replaceRegExp(
            AppConfig.transformationFrom, AppConfig.transformationTo);
      else if (!hasMatch) {
        log("$data id is not matching against pattern");
        showError(tr("invalidID"));
        return;
      }
    }

    try {
      DbRecordBalance record = await app.db.getBalance(data);
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

        DbRecordBalance record = await app.db.getBalance(data);

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

  // bool _validId = false;
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
        title: Row(
          children: <Widget>[
            Text(
              tr('title'),
              style: TextStyle(fontSize: 20),
            ),
            Expanded(child: createInfoFields()),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: tr("aboutTooltip"),
            icon: Icon(Icons.info_outline),
            onPressed: showAbout,
          )
        ],
      ),
      body: RawKeyboardListener(
        autofocus: true,
        focusNode: _pageFocus,
        onKey: (event) {
          log(event);
          if (event is RawKeyDownEvent) {
            // bool isCTRL = Platform.isMacOS
            //     ? event.isMetaPressed
            //     : event.isControlPressed || event.logicalKey.keyLabel == "9";

            bool isImport = event.logicalKey.keyLabel ==
                "i" || /* What the heck?! Flutter is buggy here ... */ event
                    .logicalKey.keyLabel ==
                "\\";
            bool isExport = event.logicalKey.keyLabel ==
                "e" || /* What the heck?! Flutter is buggy here ... */ event
                    .logicalKey.keyLabel ==
                "-";

            if (/*isCTRL && */ isImport) {
              showImportDialog();
            } else if (/*isCTRL && */ isExport) {
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
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                child: FutureBuilder<List<DbRecordProduct>>(
                  initialData: [],
                  future: _dbProducts,
                  builder: (context, state) => Products(
                    products: state.data,
                    onTap: (DbRecordProduct p) {
                      log("Clicked to the $p");
                      setValue(p.priceHuf);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expandable(
              leading: const Icon(Icons.keyboard, size: 55),
              // initiallyExpanded: true,
              title: Row(children: <Widget>[
                const SizedBox(width: 15),
                createBalanceInput(),
                const SizedBox(width: 30),
                Container(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          createButton(tr('topUp'), onTap: topUp),
                          const SizedBox(width: 10),
                          createButton(tr('pay'), onTap: pay),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    createButtons(),
                    const SizedBox(width: 15),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget createInfoFields() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(width: 10),
        AutoSizeText(tr('cardId'),
            minFontSize: 15, style: TextStyle(fontSize: 25)),
        const SizedBox(width: 10),
        SizedBox(
          width: 200,
          child: TextFormField(
            enabled: false,
            focusNode: cardIdFocus,
            cursorColor: Colors.transparent,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              disabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
            key: _cardIdFieldKey,
            controller: _cardIdFieldController,
          ),
        ),
        // NOTE: Only for test purposes
        // IconButton(
        //   iconSize: 35,
        //   onPressed: () {
        //     _cardIdFieldController.text = "12312312";
        //     loadDetails(_cardIdFieldController.text);
        //   },
        //   icon: Icon(Icons.input),
        // ),
        const SizedBox(width: 10),
        AutoSizeText(tr('balance'),
            minFontSize: 15, style: TextStyle(fontSize: 25)),
        SizedBox(width: 10),
        SizedBox(
          width: 200,
          child: TextFormField(
            enabled: false,
            decoration: InputDecoration(
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none),
            // focusNode: cardIdFocus,
            cursorColor: Colors.transparent,
            enableSuggestions: false,
            autofocus: true,
            autocorrect: false,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
            controller: _balanceFieldController,
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget createBalanceInput() {
    return Expanded(
      child: Column(
        children: <Widget>[
          const SizedBox(height: 15),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(tr('amount'), style: TextStyle(fontSize: 30)),
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
                child: Stack(
                  children: <Widget>[
                    TextFormField(
                      enabled: false,
                      cursorColor: Colors.transparent,
                      focusNode: propertyFocus,
                      autocorrect: false,
                      autovalidate: true,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        disabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: AppColors.brightText)),
                      ),
                      controller: _propertyFieldController,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
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
                    if (_propertyFieldController.text.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            "Ft",
                            style: TextStyle(
                                color: AppColors.brightText, fontSize: 45),
                          ),
                        ),
                      ),
                    if (_propertyFieldController.text.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: IconButton(
                            iconSize: 35,
                            onPressed: () {
                              Future.delayed(Duration(milliseconds: 50))
                                  .then((_) {
                                setState(() {
                                  _propertyFieldController.clear();
                                });
                              });
                            },
                            icon: Icon(Icons.clear),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget createButtons() {
    return Container(
      constraints: BoxConstraints(maxWidth: 485),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        // Row(
        //   mainAxisSize: MainAxisSize.max,
        //   children: <Widget>[
        //     createButton(tr('topUp'), onTap: topUp),
        //     const SizedBox(width: 10),
        //     createButton(tr('pay'), onTap: pay),
        //   ],
        // ),
        // SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(radius()),
              border: Border.all(
                width: 3,
                color: AppColors.brightText,
              )),
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              VirtualKeyboard(
                  fontSize: 30,
                  textColor: AppColors.brightText,
                  height: 200,
                  type: VirtualKeyboardType.Numeric,
                  onKeyPress: _onKeyPress),
              SizedBox(height: 20),
            ],
          ),
        ),
      ]),
    );
  }

  void setValue(int value) {
    // Update the screen
    TextEditingController ctrl = _propertyFieldController;
    ctrl.text = value.toString();
    setState(() {
      if (ctrl == _propertyFieldController) {}
    });
  }

  /// Fired when the virtual keyboard key is pressed.
  _onKeyPress(VirtualKeyboardKey key) {
    TextEditingController ctrl;
    ctrl = _propertyFieldController;

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
  Widget createButton(String s, {void Function() onTap}) {
    return Expanded(
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
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          child: Center(
            child: AutoSizeText(s,
                style: TextStyle(
                  fontSize: 35,
                  color: isButtonsActive
                      ? AppColors.brightText
                      : AppColors.disabledColor,
                ),
                maxLines: 1,
                group: group),
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
                  List<DbRecordBalance> records = [];
                  try {
                    records = serializeRecordsFromCSV(fs);
                    await app.db.insertBalances(records);
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
                  List<DbRecordBalance> records =
                      _dbRecordsDataSource.getBalanceRecords();
                  String serializedRecords =
                      serializeRecordsIntoCSV(records).join("\n");
                  File exportFile = File(join(dir.absolute.path,
                      "export-${DateTime.now().toIso8601String().replaceAll(".", "").replaceAll(":", "").replaceAll("-", "").replaceAll(" ", "")}.csv"));
                  exportFile.writeAsStringSync(serializedRecords);
                  log("Export succeeded to '${exportFile.absolute.path}'");
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

  List<DbRecordBalance> serializeRecordsFromCSV(FileSystemEntity fs) {
    if (fs is! File) throw tr('invalidImportSource');

    List<String> lines = (fs as File).readAsLinesSync();
    String firstLine = lines.first.toUpperCase();
    Map<String, int> columnIds = {
      'ID': 0,
      'BALANCE': 0,
    };
    if (!firstLine.contains(';')) throw tr('invalidImportFormat');

    // Remapping indexes if needed
    List<String> header = firstLine.split(';');
    bool hasHeader = false;
    if (firstLine.contains('ID')) {
      columnIds['ID'] = header.indexOf('ID');
      columnIds['BALANCE'] = header.indexOf('BALANCE');
      hasHeader = true;
    }

    List<DbRecordBalance> res = [];
    for (var i = hasHeader ? 1 : 0; i < lines.length; i++) {
      List<String> splitted = lines[i].split(';');
      if (splitted.length != header.length) {
        log(tr('malformedInput'));
        continue;
      }

      if (splitted[columnIds['ID']].isEmpty) {
        log("Skipped record due to missing or empty property '${[
          splitted[columnIds['ID']]
        ]}'");
        continue;
      }

      res.add(DbRecordBalance(
        splitted[columnIds['ID']],
        columnIds['BALANCE'] == -1
            ? null
            : int.tryParse(splitted[columnIds['BALANCE']]),
      ));
    }

    return res;
  }

  List<String> serializeRecordsIntoCSV(List<DbRecordBalance> records) {
    const String SEP = ";";

    List<String> res = ['ID${SEP}BALANCE$SEP'];
    records.forEach((record) {
      res.add("${record.id}$SEP${record.balance}$SEP");
    });

    return res;
  }
}
