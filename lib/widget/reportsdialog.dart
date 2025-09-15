// Jelentések dialógus
import 'package:cashcard/app/app.dart';
import 'package:cashcard/util/exportservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart' as MySQL;

class ReportsDialog extends StatefulWidget {
  const ReportsDialog();

  @override
  _ReportsDialogState createState() => _ReportsDialogState();
}

class _ReportsDialogState extends State<ReportsDialog>
    with SingleTickerProviderStateMixin {
  // TabController _tabController;
  DateTime selectedDate = DateTime.now();
  String reportType = 'daily';
  List<Map<String, dynamic>> reportData = [];
  // List<Map<String, dynamic>> productList = [];
  // List<Map<String, dynamic>> customerList = [];

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(length: 3, vsync: this);
    _loadReport();
    // _loadProducts();
    // _loadCustomers();
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  // Future<void> _loadReport() async {
  //   try {
  //     final conn = await app.db;
  //     String query;
  //     List<Object> params;

  //     if (reportType == 'daily') {
  //       query = '''
  //         SELECT p.name, SUM(ti.quantity) as total_quantity,
  //                SUM(ti.quantity * ti.unit_price) as total_revenue
  //         FROM transaction_items ti
  //         JOIN transactions t ON ti.transaction_id = t.id
  //         JOIN products p ON ti.product_id = p.id
  //         WHERE DATE(t.transaction_date) = ?
  //         GROUP BY p.id, p.name
  //         ORDER BY total_revenue DESC
  //       ''';
  //       params = [DateFormat('yyyy-MM-dd').format(selectedDate)];
  //     } else {
  //       query = '''
  //         SELECT p.name, SUM(ti.quantity) as total_quantity,
  //                SUM(ti.quantity * ti.unit_price) as total_revenue
  //         FROM transaction_items ti
  //         JOIN transactions t ON ti.transaction_id = t.id
  //         JOIN products p ON ti.product_id = p.id
  //         WHERE YEAR(t.transaction_date) = ? AND MONTH(t.transaction_date) = ?
  //         GROUP BY p.id, p.name
  //         ORDER BY total_revenue DESC
  //       ''';
  //       params = [selectedDate.year, selectedDate.month];
  //     }

  //     var results = await conn.query(query, params);

  //     setState(() {
  //       reportData = results
  //           .map(
  //             (row) => {
  //               'name': row['name'],
  //               'quantity': row['total_quantity'] ?? 0,
  //               'revenue': row['total_revenue']?.toDouble() ?? 0.0,
  //             },
  //           )
  //           .toList();
  //     });
  //   } catch (e) {
  //     print('Jelentés betöltési hiba: $e');
  //   }
  // }

  // Future<void> _loadProducts() async {
  //   try {
  //     final conn = await DatabaseService.getConnection();
  //     var results = await conn.query('''
  //       SELECT p.*, pg.name as group_name
  //       FROM products p
  //       LEFT JOIN product_groups pg ON p.group_id = pg.id
  //       WHERE p.active = TRUE
  //       ORDER BY pg.sort_order, p.name
  //     ''');

  //     setState(() {
  //       productList = results
  //           .map(
  //             (row) => {
  //               'id': row['id'],
  //               'barcode': row['barcode'] ?? '',
  //               'name': row['name'],
  //               'price': row['price'].toDouble(),
  //               'group': row['group_name'] ?? 'Egyéb',
  //               'is_favorite': row['is_favorite'] == 1,
  //               'stock': row['stock'] ?? 0,
  //             },
  //           )
  //           .toList();
  //     });
  //   } catch (e) {
  //     print('Termékek betöltési hiba: $e');
  //   }
  // }

  // Future<void> _loadCustomers() async {
  //   try {
  //     final conn = await DatabaseService.getConnection();
  //     var results = await conn.query('''
  //       SELECT c.*,
  //              COUNT(DISTINCT t.id) as transaction_count,
  //              COALESCE(SUM(t.total_amount), 0) as total_spent
  //       FROM customers c
  //       LEFT JOIN transactions t ON c.id = t.customer_id AND t.cancelled = FALSE
  //       GROUP BY c.id
  //       ORDER BY c.balance DESC, c.card_id
  //     ''');

  //     setState(() {
  //       customerList = results
  //           .map(
  //             (row) => {
  //               'id': row['id'],
  //               'card_id': row['card_id'],
  //               'name': row['name'] ?? 'Nincs megadva',
  //               'balance': row['balance'].toDouble(),
  //               'transaction_count': row['transaction_count'] ?? 0,
  //               'total_spent': row['total_spent'].toDouble(),
  //               'created_at': row['created_at'].toString(),
  //             },
  //           )
  //           .toList();
  //     });
  //   } catch (e) {
  //     print('Vásárlók betöltési hiba: $e');
  //   }
  // }

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
      showInfo(context, 'Export sikeres: $filename');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Row(
      //       children: [
      //         Icon(Icons.check_circle, color: Colors.white),
      //         SizedBox(width: 10),
      //         Text('Export sikeres: $filename'),
      //         Spacer(),
      //         TextButton(
      //           onPressed: () => FileExportService.openExportFolder(),
      //           child: Text(
      //             'Mappa megnyitása',
      //             style: TextStyle(color: Colors.white),
      //           ),
      //         ),
      //       ],
      //     ),
      //     backgroundColor: Colors.green,
      //     duration: Duration(seconds: 5),
      //   ),
      // );
    } else {
      if (mounted) {
        showError(context, 'Hiba történt az exportálás során!');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Hiba történt az exportálás során!'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    }
  }

  // Future<void> _exportProducts() async {
  //   String csv = 'Vonalkód;Termék neve;Ár (Ft);Csoport;Kedvenc;Készlet\n';

  //   for (var item in productList) {
  //     String barcode =
  //         item['barcode'].toString().isEmpty ? 'Nincs' : item['barcode'];
  //     String favorite = item['is_favorite'] ? 'Igen' : 'Nem';

  //     csv +=
  //         '"$barcode";"${item['name']}";${item['price'].toStringAsFixed(0)};';
  //     csv += '"${item['group']}";$favorite;${item['stock']}\n';
  //   }

  //   csv += '\n"Összes termék:";${productList.length} db;;;;';

  //   String filename =
  //       'termeklista_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.csv';

  //   bool success = await FileExportService.exportToCSV(filename, csv);

  //   if (success) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Row(
  //             children: [
  //               Icon(Icons.check_circle, color: Colors.white),
  //               SizedBox(width: 10),
  //               Text('Termékek exportálva: $filename'),
  //               Spacer(),
  //               TextButton(
  //                 onPressed: () => FileExportService.openExportFolder(),
  //                 child: Text(
  //                   'Mappa megnyitása',
  //                   style: TextStyle(color: Colors.white),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           backgroundColor: Colors.orange,
  //           duration: Duration(seconds: 5),
  //         ),
  //       );
  //     }
  //   }
  // }

  // Future<void> _exportCustomers() async {
  //   String csv =
  //       'Kártya ID;Név;Egyenleg (Ft);Tranzakciók száma;Összes költés (Ft);Regisztráció dátuma\n';
  //   double totalBalance = 0;
  //   double totalSpent = 0;

  //   for (var item in customerList) {
  //     csv +=
  //         '"${item['card_id']}";"${item['name']}";${item['balance'].toStringAsFixed(0)};';
  //     csv +=
  //         '${item['transaction_count']};${item['total_spent'].toStringAsFixed(0)};';
  //     csv += '${item['created_at'].toString().substring(0, 10)}\n';
  //     totalBalance += item['balance'];
  //     totalSpent += item['total_spent'];
  //   }

  //   csv += '\n"Összesítés:";;;;;\n';
  //   csv += '"Összes vásárló:";${customerList.length} fő;;;;\n';
  //   csv += '"Összes egyenleg:";${totalBalance.toStringAsFixed(0)} Ft;;;;\n';
  //   csv += '"Összes költés:";${totalSpent.toStringAsFixed(0)} Ft;;;;';

  //   String filename =
  //       'vasarlok_egyenlegek_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.csv';

  //   bool success = await FileExportService.exportToCSV(filename, csv);

  //   if (success) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Row(
  //             children: [
  //               Icon(Icons.check_circle, color: Colors.white),
  //               SizedBox(width: 10),
  //               Text('Vásárlók exportálva: $filename'),
  //               Spacer(),
  //               TextButton(
  //                 onPressed: () => FileExportService.openExportFolder(),
  //                 child: Text(
  //                   'Mappa megnyitása',
  //                   style: TextStyle(color: Colors.white),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           backgroundColor: Colors.purple,
  //           duration: Duration(seconds: 5),
  //         ),
  //       );
  //     }
  //   }
  // }

  //   Future<void> _exportReport() async {
  //     String csv = 'Termék,Darabszám,Bevétel (Ft)\n';
  //     double totalRevenue = 0;
  //
  //     for (var item in reportData) {
  //       csv += '${item['name']},${item['quantity']},${item['revenue'].toStringAsFixed(0)}\n';
  //       totalRevenue += item['revenue'];
  //     }
  //
  //     csv += '\nÖsszesen:,,${totalRevenue.toStringAsFixed(0)}';
  //
  //     _saveToFile('forgalmi_jelentes_${DateFormat('yyyyMMdd').format(selectedDate)}.csv', csv);
  //   }
  //
  //   Future<void> _exportProducts() async {
  //     String csv = 'Vonalkód,Termék neve,Ár (Ft),Csoport,Kedvenc,Készlet\n';
  //
  //     for (var item in productList) {
  //       csv +=
  //           '${item['barcode']},${item['name']},${item['price'].toStringAsFixed(0)},';
  //       csv +=
  //           '${item['group']},${item['is_favorite'] ? 'Igen' : 'Nem'},${item['stock']}\n';
  //     }
  //
  //     csv += '\nÖsszes termék: ${productList.length} db';
  //
  //     _saveToFile(
  //       'termeklista_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
  //       csv,
  //     );
  //   }
  //
  //   Future<void> _exportCustomers() async {
  //     String csv =
  //         'Kártya ID,Név,Egyenleg (Ft),Tranzakciók száma,Összes költés (Ft),Regisztráció\n';
  //     double totalBalance = 0;
  //
  //     for (var item in customerList) {
  //       csv +=
  //           '${item['card_id']},${item['name']},${item['balance'].toStringAsFixed(0)},';
  //       csv +=
  //           '${item['transaction_count']},${item['total_spent'].toStringAsFixed(0)},';
  //       csv += '${item['created_at'].toString().substring(0, 10)}\n';
  //       totalBalance += item['balance'];
  //     }
  //
  //     csv += '\nÖsszes vásárló: ${customerList.length} fő';
  //     csv += '\nÖsszes egyenleg: ${totalBalance.toStringAsFixed(0)} Ft';
  //
  //     _saveToFile(
  //       'vasarlok_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
  //       csv,
  //     );
  //   }
  //   void _saveToFile(String filename, String content) {
  //     // Windows fájl mentés szimulálása
  //     // Valós implementációban itt használható a path_provider és dart:io
  //     print('Fájl mentve: $filename');
  //     print('Tartalom:\n$content');
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Export sikeres: $filename'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Jelentések és Exportálás'),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 800,
          height: 600,
          child: _buildReportTab(),
          // Column(
          //   children: [
          //     TabBar(
          //       controller: _tabController,
          //       tabs: [
          //         Tab(text: 'Forgalmi jelentés', icon: Icon(Icons.trending_up)),
          //         Tab(text: 'Termékek', icon: Icon(Icons.inventory)),
          //         Tab(text: 'Vásárlók', icon: Icon(Icons.people)),
          //       ],
          //     ),
          //     Expanded(
          //       child: TabBarView(
          //         controller: _tabController,
          //         children: [
          //           // Forgalmi jelentés tab
          //           _buildReportTab(),
          //           // Termékek tab
          //           _buildProductsTab(),
          //           // Vásárlók tab
          //           _buildCustomersTab(),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ),
      ),
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
                label: Text('Napi'),
                onPressed: () {
                  setState(() {
                    reportType = "daily";
                    _loadReport();
                  });
                }),
            const SizedBox(width: 10),
            ActionChip(
                label: Text('Havi'),
                onPressed: () {
                  setState(() {
                    reportType = "monthly";
                    _loadReport();
                  });
                }),
            // SegmentedButton<String>(
            //   segments: [
            //     ButtonSegment(value: 'daily', label: Text('Napi')),
            //     ButtonSegment(value: 'monthly', label: Text('Havi')),
            //   ],
            //   selected: {reportType},
            //   onSelectionChanged: (Set<String> selected) {
            //     setState(() {
            //       reportType = selected.first;
            //       _loadReport();
            //     });
            //   },
            // ),
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
                  context: context,
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
            Spacer(),
            MaterialButton(
              color: Colors.green,
              child: Row(
                children: <Widget>[
                  Icon(Icons.file_download),
                  Text('Export CSV'),
                ],
              ),
              onPressed: _exportReport,
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
      ],
    );
  }

  void _loadReport() async {
    MySQL.Results results;
    if (reportType == "monthly")
      results = await app.db.loadReportMonthly(selectedDate);
    else if (reportType == "daily")
      results = await app.db.loadReportMonthly(selectedDate);

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

  // Widget _buildProductsTab() {
  //   return Column(
  //     children: [
  //       SizedBox(height: 10),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             'Összes termék: ${productList.length} db',
  //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //           ),
  //           ElevatedButton.icon(
  //             icon: Icon(Icons.download),
  //             label: Text('Termékek exportálása'),
  //             onPressed: _exportProducts,
  //             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
  //                 DataColumn(label: Text('Vonalkód')),
  //                 DataColumn(label: Text('Név')),
  //                 DataColumn(label: Text('Ár'), numeric: true),
  //                 DataColumn(label: Text('Csoport')),
  //                 DataColumn(label: Text('Kedvenc')),
  //                 DataColumn(label: Text('Készlet'), numeric: true),
  //               ],
  //               rows: productList
  //                   .map(
  //                     (item) => DataRow(
  //                       cells: [
  //                         DataCell(Text(item['barcode'])),
  //                         DataCell(Text(item['name'])),
  //                         DataCell(
  //                           Text('${item['price'].toStringAsFixed(0)} Ft'),
  //                         ),
  //                         DataCell(Text(item['group'])),
  //                         DataCell(
  //                           Icon(
  //                             item['is_favorite']
  //                                 ? Icons.star
  //                                 : Icons.star_border,
  //                             color: item['is_favorite']
  //                                 ? Colors.amber
  //                                 : Colors.grey,
  //                             size: 20,
  //                           ),
  //                         ),
  //                         DataCell(Text(item['stock'].toString())),
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
