// import 'dart:io';

// import 'package:cashcard/app/app.dart';
// import 'package:cashcard/db/db.dart';
// import 'package:cashcard/widget/filedialog.dart';
// import 'package:cashcard/widget/progressdialog.dart';
// import 'package:cashcard/widget/subpage.dart';
// import 'package:cashcard/util/extensions.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_icons/flutter_icons.dart';
// import 'package:path/path.dart';

// /// Regsitration page
// class EntriesPage extends StatefulWidget {
//   /// Const constructor
//   const EntriesPage({Key key}) : super(key: key);

//   @override
//   _EntriesPageState createState() => _EntriesPageState();
// }

// class _EntriesPageState extends State<EntriesPage>
//     with StateWithLocalization<EntriesPage> {
//   final GlobalKey<FormFieldState> _cardNumberFieldKey =
//       GlobalKey<FormFieldState>();

//   refresh() {
//     setState(() {});
//   }

//   @override
//   void initState() {
//     super.initState();
//     _dbRecordsDataSource.addListener(refresh);
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     initDb("");
//   }

//   @override
//   void dispose() {
//     _dbRecordsDataSource.removeListener(refresh);
//     super.dispose();
//   }

//   initDb(String searchTerm) async {
//     setState(() {
//       _dbRecordsDataSource.init(searchTerm);
//     });
//   }

//   int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
//   int _sortColumnIndex;
//   bool _sortAscending = true;
//   final DbRecordDataSource _dbRecordsDataSource = DbRecordDataSource();

//   void _sort<T>(
//       Comparable<T> getField(DbRecord d), int columnIndex, bool ascending) {
//     _dbRecordsDataSource.sort<T>(getField, ascending);
//     setState(() {
//       _sortColumnIndex = columnIndex;
//       _sortAscending = ascending;
//     });
//   }

//   List<DbRecord> serializeRecordsFromCSV(FileSystemEntity fs) {
//     if (fs is! File) throw tr('invalidImportSource');

//     List<String> lines = (fs as File).readAsLinesSync();
//     String firstLine = lines.first.toUpperCase();
//     Map<String, int> columnIds = {
//       'ID': 0,
//       'NAME': 0,
//       'BALANCE': 0,
//     };
//     if (!firstLine.contains(';')) throw tr('invalidImportFormat');

//     // Remapping indexes if needed
//     List<String> header = firstLine.split(';');
//     bool hasHeader = false;
//     if (firstLine.contains('ID') || firstLine.contains('NAME')) {
//       columnIds['ID'] = header.indexOf('ID');
//       columnIds['NAME'] = header.indexOf('NAME');
//       columnIds['BALANCE'] = header.indexOf('BALANCE');
//       hasHeader = true;
//     }

//     List<DbRecord> res = [];
//     for (var i = hasHeader ? 1 : 0; i < lines.length; i++) {
//       List<String> splitted = lines[i].split(';');
//       if (splitted.length != header.length) {
//         log(tr('malformedInput'));
//         continue;
//       }

//       if (splitted[columnIds['ID']].isEmpty ||
//           splitted[columnIds['NAME']].isEmpty) {
//         log("Skipped record due to missing or empty property '${[
//           splitted[columnIds['ID']],
//           splitted[columnIds['NAME']]
//         ]}'");
//         continue;
//       }

//       res.add(DbRecord(
//         splitted[columnIds['ID']],
//         splitted[columnIds['NAME']],
//         columnIds['BALANCE'] == -1
//             ? null
//             : int.tryParse(splitted[columnIds['BALANCE']]),
//       ));
//     }

//     return res;
//   }

//   List<String> serializeRecordsIntoCSV(List<DbRecord> records) {
//     const String SEP = ";";

//     List<String> res = ['ID${SEP}NAME${SEP}BALANCE$SEP'];
//     records.forEach((record) {
//       res.add("${record.id}$SEP${record.name}$SEP${record.balance}$SEP");
//     });

//     return res;
//   }

//   final importKey = GlobalKey<ProgressDialogState>();
//   // final exportKey = GlobalKey<ProgressDialogState>();
//   final FocusNode cardIdFocus = FocusNode();
//   @override
//   Widget build(BuildContext context) {
//     return SubPage(
//       actions: <Widget>[
//         MaterialButton(
//           onPressed: _dbRecordsDataSource.selectedRowCount > 0
//               ? () async {
//                   List<String> ids = _dbRecordsDataSource
//                       .getRecords()
//                       .where((e) => e.selected)
//                       .toList()
//                       .map((e) => e.id)
//                       .toList();
//                   if (ids.isNotEmpty)
//                     app.db.delete(ids).then((_) {
//                       initDb(_cardNumberFieldKey.currentState.value);
//                     });
//                 }
//               : null,
//           child: Row(
//             children: <Widget>[
//               Icon(
//                 MaterialCommunityIcons.getIconData("delete"),
//                 size: 20,
//               ),
//               SizedBox(width: 2),
//               Text(tr('deleteAction')),
//             ],
//           ),
//         ),
//         MaterialButton(
//           onPressed: () async {
//             await showDialog<void>(
//               barrierDismissible: false,
//               context: context,
//               builder: (context) {
//                 return AlertDialog(
//                   backgroundColor: Colors.grey.shade200,
//                   content: Container(
//                     width: MediaQuery.of(context).size.width / 2,
//                     height: MediaQuery.of(context).size.height / 2,
//                     child: FileDialog(
//                       title: tr('importAction'),
//                       onOpen: (fs) async {
//                         List<DbRecord> records = [];
//                         try {
//                           records = serializeRecordsFromCSV(fs);
//                           showDialog<void>(
//                             barrierDismissible: true,
//                             context: context,
//                             builder: (context) {
//                               return ProgressDialog(
//                                   key: importKey,
//                                   progress: 0,
//                                   maxCount: records.length);
//                             },
//                           );
//                           app.db.import(records, onProgress: (p) {
//                             setState(() {
//                               importKey.currentState.progress.value = p;
//                             });
//                           }).then((_) {
//                             setState(() {
//                               _dbRecordsDataSource
//                                   .init(_cardNumberFieldKey.currentState.value);
//                             });
//                           });
//                         } catch (e) {
//                           await showDialog<void>(
//                             barrierDismissible: false,
//                             context: context,
//                             builder: (context) {
//                               Future.delayed(Duration(milliseconds: 3000),
//                                   () => Navigator.maybePop(context));
//                               return AlertDialog(
//                                 content: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Icon(
//                                       MaterialIcons.getIconData('warning'),
//                                       size: 40,
//                                       color: Colors.red.shade600,
//                                     ),
//                                     SizedBox(width: 25),
//                                     Expanded(
//                                       child: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             "${tr('importAction')} ${tr('failed')}",
//                                             style: TextStyle(
//                                                 fontSize: 21,
//                                                 fontWeight: FontWeight.bold),
//                                             // textAlign: TextAlign.center,
//                                           ),
//                                           SizedBox(height: 10),
//                                           Flexible(
//                                             child: Text(
//                                               e.toString(),
//                                               // textAlign: TextAlign.center,
//                                               style: TextStyle(
//                                                   fontSize: 21,
//                                                   fontWeight: FontWeight.bold),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           );
//                         }
//                       },
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//           child: Row(
//             children: <Widget>[
//               Icon(
//                 MaterialCommunityIcons.getIconData("import"),
//                 size: 20,
//               ),
//               SizedBox(width: 2),
//               Text(tr('importAction')),
//             ],
//           ),
//         ),
//         MaterialButton(
//           onPressed: _dbRecordsDataSource.selectedRowCount > 0
//               ? () async {
//                   await showDialog<void>(
//                     barrierDismissible: false,
//                     context: context,
//                     builder: (context) {
//                       return AlertDialog(
//                         backgroundColor: Colors.grey.shade200,
//                         content: Container(
//                           width: MediaQuery.of(context).size.width / 2,
//                           height: MediaQuery.of(context).size.height / 2,
//                           child: FileDialog(
//                             title: tr('exportAction'),
//                             target: FileDialogTarget.DIRECTORY,
//                             onOpen: (dir) async {
//                               List<DbRecord> records =
//                                   _dbRecordsDataSource.getRecords();
//                               String serializedRecords =
//                                   serializeRecordsIntoCSV(records).join("\n");
//                               File exportFile = File(join(dir.absolute.path,
//                                   "export-${DateTime.now().toIso8601String().replaceAll(".", "").replaceAll(":", "").replaceAll("-", "").replaceAll(" ", "")}.csv"));
//                               exportFile.writeAsStringSync(serializedRecords);
//                               log(
//                                   "Export succeeded to '${exportFile.absolute.path}'");
//                               await showDialog<void>(
//                                 barrierDismissible: true,
//                                 context: context,
//                                 builder: (context) {
//                                   return AlertDialog(
//                                     content: Column(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: <Widget>[
//                                         Flexible(
//                                             child: Text(tr('progress'),
//                                                 textAlign: TextAlign.center,
//                                                 style: TextStyle(
//                                                     fontSize: 22,
//                                                     fontWeight:
//                                                         FontWeight.bold))),
//                                         SizedBox(height: 20),
//                                         Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.start,
//                                           children: <Widget>[
//                                             Icon(
//                                               Icons.check,
//                                               size: 40,
//                                               color: Colors.green.shade600,
//                                             ),
//                                             SizedBox(width: 10),
//                                             Text(
//                                               "${tr('importAction')} ${tr('succeeded')} (${records.length} / ${records.length})",
//                                               style: TextStyle(
//                                                   fontSize: 21,
//                                                   fontWeight: FontWeight.bold),
//                                             ),
//                                           ],
//                                         ),
//                                         Flexible(
//                                             child: Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                               vertical: 10.0),
//                                           child: LinearProgressIndicator(
//                                             value: 1,
//                                           ),
//                                         )),
//                                         Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.end,
//                                           children: <Widget>[
//                                             MaterialButton(
//                                               child: Text(tr('close')),
//                                               onPressed: () {
//                                                 initDb(_cardNumberFieldKey
//                                                     .currentState.value);
//                                                 Navigator.maybePop(context);
//                                               },
//                                             )
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 }
//               : null,
//           child: Row(
//             children: <Widget>[
//               Icon(
//                 MaterialCommunityIcons.getIconData("export"),
//                 size: 20,
//               ),
//               SizedBox(width: 2),
//               Text(tr('exportAction')),
//             ],
//           ),
//         )
//       ],
//       onPop: () {},
//       title: tr('entriesPageTitle'),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
//         child: Column(
//           children: <Widget>[
//             Row(
//               children: <Widget>[
//                 SizedBox(width: 10),
//                 Text(tr('name'), style: TextStyle(fontSize: 20)),
//                 SizedBox(width: 10),
//                 Flexible(
//                   flex: 2,
//                   child: TextFormField(
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     key: _cardNumberFieldKey,
//                     onChanged: (value) {
//                       initDb(value);
//                     },
//                   ),
//                 ),
//                 Spacer(flex: 3)
//               ],
//             ),
//             SizedBox(height: 20),
//             Expanded(
//               child: Scrollbar(
//                 child: ListView(
//                   // padding: const EdgeInsets.all(20.0),
//                   children: <Widget>[
//                     PaginatedDataTable(
//                       header: Text(tr('entriesTableHeader')),
//                       rowsPerPage: _rowsPerPage,
//                       onRowsPerPageChanged: (int value) {
//                         setState(() {
//                           _rowsPerPage = value;
//                         });
//                       },
//                       sortColumnIndex: _sortColumnIndex,
//                       sortAscending: _sortAscending,
//                       onSelectAll: _dbRecordsDataSource.selectAll,
//                       columns: <DataColumn>[
//                         DataColumn(
//                           label: Text(tr("cardId"),
//                               style: TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold)),
//                           tooltip: tr('cardIdTooltip'),
//                           onSort: (int columnIndex, bool ascending) =>
//                               _sort<String>((DbRecord d) => d.name, columnIndex,
//                                   ascending),
//                         ),
//                         DataColumn(
//                           label: Text(tr("name"),
//                               style: TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold)),
//                           tooltip: tr('nameTooltip'),
//                           onSort: (int columnIndex, bool ascending) =>
//                               _sort<String>((DbRecord d) => d.name, columnIndex,
//                                   ascending),
//                         ),
//                         DataColumn(
//                           label: Text(
//                             tr('balanceHeaderTitle'),
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           tooltip: tr('balanceTooltip'),
//                           numeric: true,
//                           onSort: (int columnIndex, bool ascending) =>
//                               _sort<num>((DbRecord d) => d.balance, columnIndex,
//                                   ascending),
//                         ),
//                       ],
//                       source: _dbRecordsDataSource,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
