// file_export_service.dart
// Ezt a kódot add hozzá a main.dart fájlhoz vagy külön fájlba

import 'dart:convert';
import 'dart:io';

// import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<String> get _exportPath async {
    // Windows Dokumentumok mappa elérése
    // final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('.');

    // Mappa létrehozása ha nem létezik
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir.path;
  }

  static Future<bool> exportToCSV(String filename, String content) async {
    try {
      final path = await _exportPath;
      final file = File('$path\\$filename');

      // UTF-8 BOM hozzáadása a magyar karakterek miatt
      final contentWithBOM = '\uFEFF$content';

      await file.writeAsString(
        contentWithBOM,
        encoding: Encoding.getByName('utf-8'),
      );

      print('Fájl sikeresen mentve: ${file.path}');
      return true;
    } catch (e) {
      print('Hiba a fájl mentésekor: $e');
      return false;
    }
  }

  static Future<void> openExportFolder() async {
    try {
      final path = await _exportPath;
      // Windows Explorer megnyitása
      await Process.run('explorer.exe', [path]);
    } catch (e) {
      print('Hiba a mappa megnyitásakor: $e');
    }
  }
}

// Bővített export funkciók további lehetőségekkel

class AdvancedExportService {
  // Részletes tranzakció export
  // static Future<String> exportDetailedTransactions(
  //     DateTime startDate, DateTime endDate) async {
  //   try {
  //     final conn = await DatabaseService.getConnection();

  //     var results = await conn.query('''
  //       SELECT
  //         s.transaction_id,
  //         s.eff_sp,
  //         s.id,
  //         c.balance_id,

  //         s.total_amount,
  //         p.product_name,
  //         p.product_code,
  //         ti.quantity,
  //         ti.unit_price,
  //         ti.subtotal,
  //         pg.name as group_name
  //       FROM sales s
  //       LEFT JOIN customers c ON t.customer_id = c.id
  //       LEFT JOIN products p ON ti.product_id = p.id
  //       LEFT JOIN product_groups pg ON p.group_id = pg.id
  //       WHERE DATE(t.eff_sp) BETWEEN ? AND ?
  //       ORDER BY t.eff_sp DESC, t.id, ti.id
  //     ''', [
  //       DateFormat('yyyy-MM-dd').format(startDate),
  //       DateFormat('yyyy-MM-dd').format(endDate)
  //     ]);

  //     String csv =
  //         'Tranzakció ID;Dátum;Időpont;Fizetési mód;Kártya ID;Vásárló;Termék;Vonalkód;Csoport;Mennyiség;Egységár;Részösszeg;Végösszeg\n';

  //     for (var row in results) {
  //       String paymentType =
  //           row['payment_type'] == 'card' ? 'Kártya' : 'Készpénz';
  //       String cardId = row['card_id'] ?? 'Készpénz';
  //       String customerName = row['customer_name'] ?? '-';
  //       String barcode = row['barcode'] ?? '-';
  //       String dateTime = row['transaction_date'].toString();
  //       String date = dateTime.substring(0, 10);
  //       String time = dateTime.substring(11, 19);

  //       csv += '${row['transaction_id']};$date;$time;$paymentType;';
  //       csv += '"$cardId";"$customerName";"${row['product_name']}";';
  //       csv += '"$barcode";"${row['group_name']}";${row['quantity']};';
  //       csv +=
  //           '${row['unit_price']};${row['subtotal']};${row['total_amount']}\n';
  //     }

  //     String filename =
  //         'reszletes_tranzakciok_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.csv';
  //     await ExportService.exportToCSV(filename, csv);

  //     return filename;
  //   } catch (e) {
  //     print('Részletes export hiba: $e');
  //     return '';
  //   }
  // }

  // // Egyenleg változások export
  // static Future<String> exportBalanceHistory(int? customerId) async {
  //   try {
  //     final conn = await DatabaseService.getConnection();

  //     String whereClause = customerId != null ? 'WHERE bl.customer_id = ?' : '';
  //     List<Object> params = customerId != null ? [customerId] : [];

  //     var results = await conn.query('''
  //       SELECT
  //         bl.*,
  //         c.card_id,
  //         c.name as customer_name
  //       FROM balance_log bl
  //       JOIN customers c ON bl.customer_id = c.id
  //       $whereClause
  //       ORDER BY bl.created_at DESC
  //     ''', params);

  //     String csv = 'Dátum;Időpont;Kártya ID;Vásárló;Művelet;Összeg;Egyenleg előtte;Egyenleg utána;Megjegyzés\n';

  //     for (var row in results) {
  //       String dateTime = row['created_at'].toString();
  //       String date = dateTime.substring(0, 10);
  //       String time = dateTime.substring(11, 19);
  //       String operation = _translateOperation(row['operation_type']);
  //       String description = row['description'] ?? '-';
  //       String amount = row['amount'] > 0 ? '+${row['amount']}' : row['amount'].toString();

  //       csv += '$date;$time;"${row['card_id']}";"${row['customer_name']}";';
  //       csv += '"$operation";$amount;${row['balance_before']};${row['balance_after']};"$description"\n';
  //     }

  //     String filename = 'egyenleg_valtozasok_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
  //     await FileExportService.exportToCSV(filename, csv);

  //     return filename;
  //   } catch (e) {
  //     print('Egyenleg export hiba: $e');
  //     return '';
  //   }
  // }

  // static String _translateOperation(String? operation) {
  //   switch(operation) {
  //     case 'topup': return 'Feltöltés';
  //     case 'purchase': return 'Vásárlás';
  //     case 'refund': return 'Visszatérítés';
  //     case 'adjustment': return 'Korrekció';
  //     default: return 'Egyéb';
  //   }
  // }

  // // Statisztikai összesítő export
  // static Future<String> exportStatisticsSummary() async {
  //   try {
  //     final conn = await DatabaseService.getConnection();

  //     // Mai statisztikák
  //     var todayStats = await conn.query('''
  //       SELECT
  //         COUNT(DISTINCT id) as transactions,
  //         COALESCE(SUM(total_amount), 0) as revenue,
  //         COUNT(DISTINCT customer_id) as customers
  //       FROM transactions
  //       WHERE DATE(transaction_date) = CURDATE()
  //         AND cancelled = FALSE
  //     ''');

  //     // Havi statisztikák
  //     var monthStats = await conn.query('''
  //       SELECT
  //         COUNT(DISTINCT id) as transactions,
  //         COALESCE(SUM(total_amount), 0) as revenue,
  //         COUNT(DISTINCT customer_id) as customers
  //       FROM transactions
  //       WHERE MONTH(transaction_date) = MONTH(CURDATE())
  //         AND YEAR(transaction_date) = YEAR(CURDATE())
  //         AND cancelled = FALSE
  //     ''');

  //     // Top 10 termék
  //     var topProducts = await conn.query('''
  //       SELECT
  //         p.name,
  //         SUM(ti.quantity) as total_sold,
  //         SUM(ti.subtotal) as total_revenue
  //       FROM transaction_items ti
  //       JOIN products p ON ti.product_id = p.id
  //       JOIN transactions t ON ti.transaction_id = t.id
  //       WHERE t.cancelled = FALSE
  //         AND MONTH(t.transaction_date) = MONTH(CURDATE())
  //       GROUP BY p.id, p.name
  //       ORDER BY total_revenue DESC
  //       LIMIT 10
  //     ''');

  //     String csv = 'STATISZTIKAI ÖSSZESÍTŐ - ${DateFormat('yyyy.MM.dd').format(DateTime.now())}\n\n';

  //     csv += 'MAI ADATOK\n';
  //     csv += 'Tranzakciók;${todayStats.first['transactions']}\n';
  //     csv += 'Bevétel;${todayStats.first['revenue']} Ft\n';
  //     csv += 'Vásárlók;${todayStats.first['customers']}\n\n';

  //     csv += 'HAVI ADATOK\n';
  //     csv += 'Tranzakciók;${monthStats.first['transactions']}\n';
  //     csv += 'Bevétel;${monthStats.first['revenue']} Ft\n';
  //     csv += 'Vásárlók;${monthStats.first['customers']}\n\n';

  //     csv += 'TOP 10 TERMÉK (HAVI)\n';
  //     csv += 'Termék;Eladott mennyiség;Bevétel\n';
  //     for (var product in topProducts) {
  //       csv += '"${product['name']}";${product['total_sold']};${product['total_revenue']} Ft\n';
  //     }

  //     String filename = 'statisztika_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
  //     await FileExportService.exportToCSV(filename, csv);

  //     return filename;
  //   } catch (e) {
  //     print('Statisztika export hiba: $e');
  //     return '';
  //   }
  // }
}
