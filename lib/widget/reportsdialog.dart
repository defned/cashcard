// Jelentések dialógus
import 'dart:io';

import 'package:cashcard/app/app.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/util/exportservice.dart';
import 'package:cashcard/util/logging.dart';
import 'package:cashcard/widget/filedialog.dart';
import 'package:cashcard/util/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart' as MySQL;
import 'package:path/path.dart';

class ReportsDialog extends StatefulWidget {
  final Function onProductsChanged;
  const ReportsDialog({Key key, this.onProductsChanged}) : super(key: key);

  @override
  _ReportsDialogState createState() => _ReportsDialogState();
}

class _ReportsDialogState extends State<ReportsDialog>
    with StateWithLocalization<ReportsDialog>, SingleTickerProviderStateMixin {
  TabController _tabController;
  DateTime selectedDate = DateTime.now();
  String reportType = 'daily';
  List<Map<String, dynamic>> reportData = [];
  List<Map<String, dynamic>> bonusReportData = [];
  List<DbRecordProduct> productList = [];

  void initStateAsync() async {
    await _loadReport();
    await _loadBonusReport();
    await _loadProductsForFavourites();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchFieldController.addListener(keyTap);
    initStateAsync();
  }

  @override
  void dispose() {
    _searchFieldController.removeListener(keyTap);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportReport() async {
    String csv = 'Termék;Darabszám;Bevétel (Ft)\n';
    double totalRevenue = 0;
    int totalQuantity = 0;

    for (var item in reportData) {
      csv +=
          '"${item['name']}";${item['quantity']};${item['revenue'].toStringAsFixed(0)}\n';
      totalRevenue += item['revenue'];
      totalQuantity += item['quantity'];
    }

    csv += '\n"Összesen:";$totalQuantity;${totalRevenue.toStringAsFixed(0)}';

    String filename = reportType == 'daily'
        ? 'napi_jelentes_${selectedDate.year}_${selectedDate.month}_${selectedDate.day}.csv'
        : 'havi_jelentes_${selectedDate.year}_${selectedDate.month}.csv';

    bool success = await ExportService.exportToCSV(filename, csv);

    if (success) {
      showInfo(this.context, 'Export sikeres: $filename');
    } else {
      if (mounted) {
        showError(this.context, 'Hiba történt az exportálás során!');
      }
    }
  }

  Future<void> _exportBonusReport() async {
    String csv = 'ID;Darabszám;Bónusz\n';
    double totalRevenue = 0;
    int totalQuantity = 0;

    for (var item in bonusReportData) {
      csv += '"${item['name']}";${item['quantity']};${item['revenue']}\n';
      totalRevenue += item['revenue'];
      totalQuantity += item['quantity'];
    }

    csv += '\n"Összesen:";$totalQuantity;$totalRevenue';

    String filename = reportType == 'daily'
        ? 'napi_bonus_jelentes_${selectedDate.year}_${selectedDate.month}_${selectedDate.day}.csv'
        : 'havi_bonus_jelentes_${selectedDate.year}_${selectedDate.month}.csv';

    bool success = await ExportService.exportToCSV(filename, csv);

    if (success) {
      showInfo(this.context, 'Export sikeres: $filename');
    } else {
      if (mounted) {
        showError(this.context, 'Hiba történt az exportálás során!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: Colors.grey.shade200,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Jelentések és Exportálás/Importálás'),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 800,
          height: 600,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon:
                        Icon(Icons.trending_up, color: AppColors.disabledColor),
                    child: Text(
                      'Forgalmi jelentések',
                      style: TextStyle(color: AppColors.disabledColor),
                    ),
                  ),
                  Tab(
                    icon: Icon(Icons.card_giftcard,
                        color: AppColors.disabledColor),
                    child: Text(
                      'Bónusz jelentések',
                      style: TextStyle(color: AppColors.disabledColor),
                    ),
                  ),
                  Tab(
                    icon: Icon(Icons.favorite_border,
                        color: AppColors.disabledColor),
                    child: Text(
                      'Kedvencek',
                      style: TextStyle(color: AppColors.disabledColor),
                    ),
                  ),
                  Tab(
                    icon: Icon(Icons.file_download,
                        color: AppColors.disabledColor),
                    child: Text(
                      'Egyenleg export',
                      style: TextStyle(color: AppColors.disabledColor),
                    ),
                  ),
                  Tab(
                    icon: RotatedBox(
                      quarterTurns: 2,
                      child: Icon(Icons.file_download,
                          color: AppColors.disabledColor),
                    ),
                    child: Text(
                      'Egyenleg import',
                      style: TextStyle(color: AppColors.disabledColor),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReportTab(),
                    _buildBonusReportTab(),
                    _buildProductsForFavouriteTab(),
                    _buildAccountBalancesExportTab(),
                    _buildAccountBalancesImportTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountBalancesImportTab() {
    return FileDialog(
      actionButtonColor: Colors.green,
      actionButtonChild: Row(
        children: <Widget>[
          RotatedBox(quarterTurns: 2, child: Icon(Icons.file_download)),
          Text('${tr('importAction')} CSV'),
        ],
      ),
      onOpen: (fs) async {
        List<DbRecordBalance> records = [];
        try {
          records = serializeRecordsFromCSV(fs);
          await app.db.insertBalances(records);
          showInfo(this.context,
              "${tr('importAction')} ${tr('succeeded')} ${records.length}/${records.length}");
        } catch (e) {
          showError(this.context, "${tr('importAction')} ${tr('failed')}");
        }
      },
    );
  }

  Widget _buildAccountBalancesExportTab() {
    return FileDialog(
      actionButtonColor: Colors.green,
      actionButtonChild: Row(
        children: <Widget>[
          Icon(Icons.file_download),
          Text('${tr('exportAction')} CSV'),
        ],
      ),
      target: FileDialogTarget.DIRECTORY,
      onOpen: (dir) async {
        List<DbRecordBalance> records = await app.db.getBalanceAll("");
        String serializedRecords = serializeRecordsIntoCSV(records).join("\n");
        File exportFile = File(join(dir.absolute.path,
            "export-${DateTime.now().toIso8601String().replaceAll(".", "").replaceAll(":", "").replaceAll("-", "").replaceAll(" ", "")}.csv"));
        exportFile.writeAsStringSync(serializedRecords);
        log("Export succeeded to '${exportFile.absolute.path}'");
        showInfo(this.context,
            "${tr('exportAction')} ${tr('succeeded')} ${records.length}/${records.length}");
      },
    );
  }

  Widget _buildBonusReportTab() {
    double totalRevenue = bonusReportData.fold(
      0,
      (sum, item) => sum + item['revenue'],
    );

    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          children: [
            ActionChip(
                label: Text(
                  'Napi',
                  style: TextStyle(
                    fontWeight: reportType == "daily"
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 3,
                      color: reportType == "daily"
                          ? AppColors.disabledColor
                          : AppColors.brightText,
                    ),
                    borderRadius: BorderRadius.circular(10)),
                onPressed: () {
                  setState(() {
                    reportType = "daily";
                    _loadReport();
                  });
                }),
            const SizedBox(width: 10),
            ActionChip(
                label: Text(
                  'Havi',
                  style: TextStyle(
                    fontWeight: reportType == "monthly"
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 3,
                      color: reportType == "monthly"
                          ? AppColors.disabledColor
                          : AppColors.brightText,
                    ),
                    borderRadius: BorderRadius.circular(10)),
                onPressed: () {
                  setState(() {
                    reportType = "monthly";
                    _loadReport();
                  });
                }),
            SizedBox(width: 20),
            MaterialButton(
              child: Row(
                children: <Widget>[
                  Icon(Icons.calendar_today),
                  Text(
                    reportType == 'daily'
                        ? DateFormat('yyyy.MM.dd').format(selectedDate)
                        : DateFormat('yyyy.MM').format(selectedDate),
                  ),
                ],
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: this.context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    _loadReport();
                  });
                }
              },
            ),
          ],
        ),
        SizedBox(height: 20),
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Összes alkalom'),
                    Text(
                      '${bonusReportData.fold(0, (sum, item) => sum + (item['quantity']))} alkalom',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Összes bónusz'),
                    Text(
                      '${totalRevenue.toStringAsFixed(0)} Ft',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: [
                DataColumn(label: Text('Termék')),
                DataColumn(label: Text('Darabszám'), numeric: true),
                DataColumn(label: Text('Bónusz (Ft)'), numeric: true),
              ],
              rows: bonusReportData
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(Text(item['name'])),
                        DataCell(Text(item['quantity'].toString())),
                        DataCell(Text(item['revenue'].toStringAsFixed(0))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Spacer(),
            MaterialButton(
              color: Colors.green,
              child: Row(
                children: <Widget>[
                  Icon(Icons.file_download),
                  Text('${tr('exportAction')} CSV'),
                ],
              ),
              onPressed: _exportBonusReport,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildReportTab() {
    double totalRevenue = reportData.fold(
      0,
      (sum, item) => sum + item['revenue'],
    );

    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          children: [
            ActionChip(
                label: Text(
                  'Napi',
                  style: TextStyle(
                    fontWeight: reportType == "daily"
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 3,
                      color: reportType == "daily"
                          ? AppColors.disabledColor
                          : AppColors.brightText,
                    ),
                    borderRadius: BorderRadius.circular(10)),
                onPressed: () {
                  setState(() {
                    reportType = "daily";
                    _loadReport();
                  });
                }),
            const SizedBox(width: 10),
            ActionChip(
                label: Text(
                  'Havi',
                  style: TextStyle(
                    fontWeight: reportType == "monthly"
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 3,
                      color: reportType == "monthly"
                          ? AppColors.disabledColor
                          : AppColors.brightText,
                    ),
                    borderRadius: BorderRadius.circular(10)),
                onPressed: () {
                  setState(() {
                    reportType = "monthly";
                    _loadReport();
                  });
                }),
            SizedBox(width: 20),
            MaterialButton(
              child: Row(
                children: <Widget>[
                  Icon(Icons.calendar_today),
                  Text(
                    reportType == 'daily'
                        ? DateFormat('yyyy.MM.dd').format(selectedDate)
                        : DateFormat('yyyy.MM').format(selectedDate),
                  ),
                ],
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: this.context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    _loadReport();
                  });
                }
              },
            ),
          ],
        ),
        SizedBox(height: 20),
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Összes tétel'),
                    Text(
                      '${reportData.fold(0, (sum, item) => sum + (item['quantity']))} db',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Összes bevétel'),
                    Text(
                      '${totalRevenue.toStringAsFixed(0)} Ft',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: [
                DataColumn(label: Text('Termék')),
                DataColumn(label: Text('Darabszám'), numeric: true),
                DataColumn(label: Text('Bevétel (Ft)'), numeric: true),
              ],
              rows: reportData
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(Text(item['name'])),
                        DataCell(Text(item['quantity'].toString())),
                        DataCell(Text(item['revenue'].toStringAsFixed(0))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Spacer(),
            MaterialButton(
              color: Colors.green,
              child: Row(
                children: <Widget>[
                  Icon(Icons.file_download),
                  Text('${tr('exportAction')} CSV'),
                ],
              ),
              onPressed: _exportReport,
            ),
          ],
        )
      ],
    );
  }

  Future _loadBonusReport() async {
    MySQL.Results results;
    if (reportType == "monthly")
      results = await app.db.loadBonusReportMonthly(selectedDate);
    else if (reportType == "daily")
      results = await app.db.loadBonusReportDaily(selectedDate);

    if (results != null)
      setState(() {
        bonusReportData = results
            .map(
              (row) => {
                'name': row['id'],
                'quantity': row['total_quantity'] ?? 0,
                'revenue': row['total_revenue']?.toDouble() ?? 0.0,
              },
            )
            .toList();
      });
  }

  Future _loadReport() async {
    MySQL.Results results;
    if (reportType == "monthly")
      results = await app.db.loadReportMonthly(selectedDate);
    else if (reportType == "daily")
      results = await app.db.loadReportDaily(selectedDate);

    if (results != null)
      setState(() {
        reportData = results
            .map(
              (row) => {
                'name': row['product_name'],
                'quantity': row['total_quantity'] ?? 0,
                'revenue': row['total_revenue']?.toDouble() ?? 0.0,
              },
            )
            .toList();
      });
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

  Future _loadProductsForFavourites() async {
    List<DbRecordProduct> results = await app.db.getProductAll("");

    if (results != null) {
      setState(() {
        productList = results;
        onSortColumn(sortedColumnIndex, sortAscending);
      });
    }
  }

  void keyTap() {
    setState(() {});
  }

  onSortColumn(int columnIndex, bool ascending) {
    setState(() {
      sortedColumnIndex = columnIndex;
      sortAscending = ascending;

      if (columnIndex == 0) {
        if (ascending) {
          productList.sort((a, b) => a.name.compareTo(b.name));
        } else {
          productList.sort((a, b) => b.name.compareTo(a.name));
        }
      } else if (columnIndex == 1) {
        if (ascending) {
          productList.sort((a, b) => a.priceHuf.compareTo(b.priceHuf));
        } else {
          productList.sort((a, b) => b.priceHuf.compareTo(a.priceHuf));
        }
      } else if (columnIndex == 2) {
        if (ascending) {
          productList.sort((a, b) => a.categoryName.compareTo(b.categoryName));
        } else {
          productList.sort((a, b) => b.categoryName.compareTo(a.categoryName));
        }
      } else if (columnIndex == 3) {
        if (ascending) {
          productList.sort(
              (a, b) => (a.favourite ? 1 : 0).compareTo((b.favourite ? 1 : 0)));
        } else {
          productList.sort(
              (a, b) => (b.favourite ? 1 : 0).compareTo((a.favourite ? 1 : 0)));
        }
      }
    });
  }

  bool isLoading = false;
  int sortedColumnIndex = 0;
  bool sortAscending = true;
  TextEditingController _searchFieldController = TextEditingController();
  Widget _buildProductsForFavouriteTab() {
    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 450,
              child: TextFormField(
                controller: _searchFieldController,
                autocorrect: false,
                autovalidate: true,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: tr("search"),
                  prefixIcon: Icon(Icons.search, size: 36),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Text(
              'Összes termék: ${productList.length} db',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 10),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AbsorbPointer(
                absorbing: isLoading,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    sortAscending: sortAscending,
                    sortColumnIndex: sortedColumnIndex,
                    columns: [
                      DataColumn(
                          label: Text('Név'),
                          onSort: (columnIndex, ascending) =>
                              onSortColumn(columnIndex, ascending)),
                      DataColumn(
                          label: Text('Ár'),
                          numeric: true,
                          onSort: (columnIndex, ascending) =>
                              onSortColumn(columnIndex, ascending)),
                      DataColumn(
                          label: Text('Csoport'),
                          onSort: (columnIndex, ascending) =>
                              onSortColumn(columnIndex, ascending)),
                      DataColumn(
                          label: Text('Kedvenc'),
                          onSort: (columnIndex, ascending) =>
                              onSortColumn(columnIndex, ascending)),
                    ],
                    rows: productList
                        .where((p) {
                          bool res = true;
                          if (_searchFieldController.text != "" &&
                              !(p.name.toLowerCase().contains(
                                      _searchFieldController.text
                                          .toLowerCase()) ||
                                  (p.code != null &&
                                      p.code.toLowerCase().contains(
                                          _searchFieldController.text
                                              .toLowerCase())))) res = false;
                          return res;
                        })
                        .map(
                          (item) => DataRow(
                            cells: [
                              DataCell(Text(item.name)),
                              DataCell(
                                Text('${item.priceHuf} Ft'),
                              ),
                              DataCell(Text(item.categoryName)),
                              DataCell(
                                IconButton(
                                  icon: Icon(
                                    item.favourite
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: item.favourite
                                        ? Colors.amber
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      isLoading = true;
                                    });

                                    await app.db.changeProductFavourite(
                                        item.id, !item.favourite);
                                    await _loadProductsForFavourites();
                                    if (widget.onProductsChanged != null)
                                      widget.onProductsChanged();

                                    await Future.delayed(
                                        Duration(milliseconds: 250));
                                    setState(() {
                                      isLoading = false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              if (isLoading) ...[
                Container(color: Colors.grey.shade200.withAlpha(220)),
                Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildCustomersTab() {
  //   double totalBalance = customerList.fold(
  //     0,
  //     (sum, item) => sum + item['balance'],
  //   );

  //   return Column(
  //     children: [
  //       SizedBox(height: 10),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Összes vásárló: ${customerList.length} fő',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //               Text(
  //                 'Összes egyenleg: ${totalBalance.toStringAsFixed(0)} Ft',
  //                 style: TextStyle(fontSize: 14, color: Colors.green[700]),
  //               ),
  //             ],
  //           ),
  //           ElevatedButton.icon(
  //             icon: Icon(Icons.download),
  //             label: Text('Vásárlók exportálása'),
  //             onPressed: _exportCustomers,
  //             style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
  //           ),
  //         ],
  //       ),
  //       SizedBox(height: 10),
  //       Expanded(
  //         child: SingleChildScrollView(
  //           scrollDirection: Axis.vertical,
  //           child: SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             child: DataTable(
  //               columns: [
  //                 DataColumn(label: Text('Kártya ID')),
  //                 DataColumn(label: Text('Név')),
  //                 DataColumn(label: Text('Egyenleg'), numeric: true),
  //                 DataColumn(label: Text('Tranzakciók'), numeric: true),
  //                 DataColumn(label: Text('Össz. költés'), numeric: true),
  //                 DataColumn(label: Text('Regisztráció')),
  //               ],
  //               rows: customerList
  //                   .map(
  //                     (item) => DataRow(
  //                       cells: [
  //                         DataCell(Text(item['card_id'])),
  //                         DataCell(Text(item['name'])),
  //                         DataCell(
  //                           Text(
  //                             '${item['balance'].toStringAsFixed(0)} Ft',
  //                             style: TextStyle(
  //                               color: item['balance'] > 0
  //                                   ? Colors.green
  //                                   : Colors.red,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ),
  //                         DataCell(Text(item['transaction_count'].toString())),
  //                         DataCell(
  //                           Text(
  //                             '${item['total_spent'].toStringAsFixed(0)} Ft',
  //                           ),
  //                         ),
  //                         DataCell(
  //                           Text(
  //                             item['created_at'].toString().substring(0, 10),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   )
  //                   .toList(),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
