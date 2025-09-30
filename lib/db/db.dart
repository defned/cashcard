import 'package:cashcard/util/cart.dart';
import 'package:cashcard/util/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

enum DbExceptions {
  noRows,
  missingKeyInput,
  missingValueInput,
  tooManyRows,
  alreadyExist,
  negativeBalance,
  unknown
}

class DbRecordCategory {
  DbRecordCategory(this.id, this.name, this.color);

  int id;
  String name;
  String color;

  bool selected = false;
}

class DbRecordBalance {
  DbRecordBalance(this.id, this.balance);

  String id;
  int balance;

  bool selected = false;
}

class DbRecordProduct {
  DbRecordProduct(
    this.id,
    this.code,
    this.name,
    this.priceHuf,
    this.favourite,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
  ) : category = DbRecordCategory(
          categoryId,
          categoryName,
          categoryColor,
        );

  int id;
  String name;
  int priceHuf;
  int categoryId;
  String categoryName;
  String categoryColor;
  String code;
  bool favourite = false;
  DbRecordCategory category;

  @override
  String toString() =>
      "$id;$name;$priceHuf;$categoryId;$code;${favourite ? 1 : 0};";
}

class DbRecordSales {
  DbRecordSales(
    this.id,
    this.balanceId,
    this.productId,
    this.productCode,
    this.productName,
    this.productFavourite,
    this.productCategory,
    this.productPriceHuf,
  );

  String id;
  String balanceId;
  String productId;
  String productCode;
  String productName;
  bool productFavourite = false;
  int productPriceHuf;
  int productCategory;
}

class Db {
  final String host;
  final int port;
  final String userName;
  final String password;
  final String dbName;

  MySqlConnection _connection;

  Db({this.host, this.port, this.userName, this.password, this.dbName});

  Future connect() async {
    assert(_connection == null);
    _connection = await MySqlConnection.connect(new ConnectionSettings(
        host: host,
        port: port,
        user: userName,
        password: password,
        db: dbName));
  }

  Future disconnect() async {
    assert(_connection != null);
    await _connection.close();
    _connection = null;
  }

  Future<List<DbRecordBalance>> getBalanceAll(String searchTerm) async {
    List<DbRecordBalance> res = [];
    try {
      await connect();
      var results = await _connection.query(
          'select id, balance from balance where (id like ?) and del_sp = "0000-00-00"',
          ['%$searchTerm%']);
      for (int i = 0; i < results.length; i++)
        res.add(
            DbRecordBalance(results.elementAt(i)[0], results.elementAt(i)[1]));
    } finally {
      await disconnect();
    }
    return res;
  }

  Future<List<DbRecordCategory>> getCategoriesAll(String searchTerm) async {
    List<DbRecordCategory> res = [];
    try {
      await connect();
      var results = await _connection.query(
          'select id, name, color from category where (name like ?) and del_sp = "0000-00-00"',
          ['%$searchTerm%']);
      for (int i = 0; i < results.length; i++)
        res.add(DbRecordCategory(
          results.elementAt(i)[0],
          results.elementAt(i)[1],
          results.elementAt(i)[2],
        ));
    } finally {
      await disconnect();
    }
    return res;
  }

  Future<List<DbRecordProduct>> getProductAll(String searchTerm) async {
    List<DbRecordProduct> res = [];
    try {
      await connect();
      var results = await _connection.query(
          'select p.id, p.code, p.name, p.price_huf, p.favourite, c.id as category_id, c.name as category_name, c.color as category_color from product p inner join category c on p.category_id = c.id and c.del_sp = "0000-00-00" where (p.name like ?) and p.del_sp = "0000-00-00"',
          ['%$searchTerm%']);
      for (int i = 0; i < results.length; i++)
        res.add(DbRecordProduct(
          results.elementAt(i)[0],
          results.elementAt(i)[1],
          results.elementAt(i)[2],
          results.elementAt(i)[3],
          (results.elementAt(i)[4] == 1) ? true : false,
          results.elementAt(i)[5],
          results.elementAt(i)[6],
          results.elementAt(i)[7],
        ));
    } finally {
      await disconnect();
    }
    return res;
  }

  Future registerBalance(String id) async {
    try {
      await connect();
      // Query the database using a parameterized query
      var results = await _connection.query(
          'select id from balance where id = ? and del_sp = "0000-00-00"',
          [id]);

      if (results.length != 0) throw DbExceptions.alreadyExist;
      // Insert some data
      var result =
          await _connection.query('insert into balance (id) values (?)', [id]);
      log("Inserted row (${result.affectedRows} record) ${[id]}");
    } finally {
      await disconnect();
    }
  }

  Future registerProduct(String code, String name, int priceHuf, bool favourite,
      int categoryId) async {
    try {
      await connect();
      // Query the database using a parameterized query
      var results = await _connection.query(
          'select id from product where name = ? and del_sp = "0000-00-00"',
          [name]);

      if (results.length != 0) throw DbExceptions.alreadyExist;
      // Insert some data
      var result = await _connection.query(
          'insert into product (code, name, price_huf, favourite, category_id) values (?, ?, ?, ?, ?)',
          [
            code,
            name,
            priceHuf,
            favourite ? 1 : 0,
            categoryId,
          ]);
      log("Inserted row (${result.affectedRows} record) ${[name]}");
    } finally {
      await disconnect();
    }
  }

  Future changeProductFavourite(int id, bool favourite) async {
    try {
      await connect();
      // Query the database using a parameterized query
      var results = await _connection.query(
          'select id from product where id = ? and del_sp = "0000-00-00"',
          [id]);

      if (results.length == 0) throw DbExceptions.noRows;
      // Insert some data
      var result = await _connection.query(
          'UPDATE product SET favourite = ? WHERE id = ?',
          [favourite ? 1 : 0, id]);
      log("Updated row (${result.affectedRows} record) ${[id]}");
    } finally {
      await disconnect();
    }
  }

  Future<DbRecordBalance> getBalance(String id) async {
    try {
      await connect();
      // Query the database using a parameterized query
      var results = await _connection.query(
          'select id, balance from balance where id = ? and del_sp = "0000-00-00"',
          [id]);

      if (results.length < 1)
        throw DbExceptions.noRows;
      else if (results.length > 1) throw DbExceptions.tooManyRows;
      return DbRecordBalance(results.first[0], results.first[1]);
    } finally {
      await disconnect();
    }
  }

  Future pay(String balanceId, List<CartItem> sales) async {
    if (!(sales != null && sales.length > 0))
      throw DbExceptions.missingValueInput;

    int amount = 0;
    for (var p in sales) {
      amount += p.product.priceHuf * p.quantity;
    }

    try {
      await connect();

      balanceId = balanceId == "" ? null : balanceId;

      if (balanceId != null) {
        // Query the database using a parameterized query
        var results = await _connection.query(
            'select id, balance from balance where id = ? and del_sp = "0000-00-00"',
            [balanceId]);

        if (results.length < 1)
          throw DbExceptions.noRows;
        else if (results.length > 1)
          throw DbExceptions.tooManyRows;
        else if (results.length == 1) {
          log('Card ID: ${results.first[0]}, balance: ${results.first[1]}');

          int origBalance = results.first[1];
          // Less then zero, PAY is NOT allowed
          if ((origBalance <= 0 && amount < 0) || origBalance - amount < 0) {
            throw DbExceptions.negativeBalance;
          }
        }
      }

      var uuid = Uuid().v4();
      List<List> params = [
        ...sales.fold([], (c, item) {
          for (var i = 0; i < item.quantity; i++) {
            c.add([
              uuid,
              balanceId,
              item.product.id,
              item.product.name,
              item.product.priceHuf
            ]);
          }
          return c;
        }).toList(),
      ];
      await _connection.transaction((conn) async {
        var results = await _connection.queryMulti(
            "INSERT INTO SALES (transaction_id, balance_id, product_id, product_name, product_price_huf) VALUES (?, ?, ?, ?, ?)",
            params);
        log("Inserted rows (${results.length} record) id=$balanceId $params");
        var result = await _connection.query(
            'INSERT INTO balance_log (id, amount) VALUES (?, ?)',
            [balanceId, -amount]);
        log("Inserted rows (${result.affectedRows} record) id=$balanceId amount=${-amount}");
      });
    } finally {
      await disconnect();
    }
  }

  Future topUp(String id, int amount, {int bonus}) async {
    if (!(amount != null && amount > 0)) throw DbExceptions.missingValueInput;
    if (bonus == null)
      return changeBalance(id, amount);
    else if (bonus > 0) {
      await changeBalance(id, amount);
      await changeBalance(id, bonus, isBonus: true);
    }
  }

  Future insertBalances(List<DbRecordBalance> records,
      {Function(double) onProgress}) async {
    try {
      await connect();
      int imported = 0;
      for (int i = 0; i < records.length; i++) {
        var result = await _connection.query(
            'insert into balance (id) values (?) ON DUPLICATE KEY UPDATE balance = 0',
            [records[i].id]);
        log("Imported row (${result.affectedRows} records) " +
            [records[i].id].toString());

        if (onProgress != null) {
          imported++;
          onProgress(imported / records.length);
        }
      }
      if (imported > 0) log("Imported rows ($imported records)");
    } finally {
      await disconnect();
    }
  }

  Future changeBalance(String id, int amount, {bool isBonus = false}) async {
    if (!(id != null && id.isNotEmpty && amount != null))
      throw DbExceptions.missingKeyInput;

    try {
      await connect();
      // Query the database using a parameterized query
      var results = await _connection.query(
          'select id, balance from balance where id = ? and del_sp = "0000-00-00"',
          [id]);

      if (results.length < 1)
        throw DbExceptions.noRows;
      else if (results.length > 1)
        throw DbExceptions.tooManyRows;
      else if (results.length == 1) {
        log('Card ID: ${results.first[0]}, balance: ${results.first[1]}');

        int origBalance = results.first[1];
        // Less then zero, PAY is NOT allowed
        if ((origBalance <= 0 && amount < 0) || origBalance + amount < 0) {
          throw DbExceptions.negativeBalance;
        } else {
          await _connection.transaction((conn) async {
            var result = await _connection.query(
                'UPDATE balance SET balance = balance + ? where id = ? and del_sp = "0000-00-00"',
                [amount, id]);
            log("Updated rows (${result.affectedRows} record) id=$id amount=$amount");
            result = await _connection.query(
                'INSERT INTO balance_log (id, bonus, amount) VALUES (?, ?, ?)',
                [id, isBonus ? 1 : 0, amount]);
            log("Inserted rows (${result.affectedRows} record) id=$id amount=$amount");
          });
        }
      }
    } finally {
      await disconnect();
    }
  }

  Future<Results> loadReportDaily(DateTime selectedDate) async {
    try {
      await connect();
      String query = '''
          SELECT product_name, COUNT(product_id) as total_quantity, SUM(product_price_huf) as total_revenue
          FROM sales
          WHERE DATE(eff_sp) = ?
          GROUP BY product_id
          ORDER BY total_revenue DESC
        ''';

      return await _connection
          .query(query, [DateFormat('yyyy-MM-dd').format(selectedDate)]);
    } catch (e) {
      log('Jelentés betöltési hiba: $e');
    } finally {
      await disconnect();
    }

    return null;
  }

  Future<Results> loadReportMonthly(DateTime selectedDate) async {
    try {
      await connect();
      String query = '''
          SELECT product_name, COUNT(product_id) as total_quantity, SUM(product_price_huf) as total_revenue
          FROM sales
          WHERE YEAR(eff_sp) = ? AND MONTH(eff_sp) = ?
          GROUP BY product_id
          ORDER BY total_revenue DESC
        ''';

      return await _connection
          .query(query, [selectedDate.year, selectedDate.month]);
    } catch (e) {
      log('Jelentés betöltési hiba: $e');
    } finally {
      await disconnect();
    }

    return null;
  }

  Future<Results> loadBonusReportDaily(DateTime selectedDate) async {
    try {
      await connect();
      String query = '''
          SELECT id, COUNT(id) as total_quantity, SUM(amount) as total_revenue
          FROM balance_log
          WHERE DATE(eff_sp) = ? AND bonus = 1
          GROUP BY id
          ORDER BY total_revenue DESC
        ''';

      return await _connection
          .query(query, [DateFormat('yyyy-MM-dd').format(selectedDate)]);
    } catch (e) {
      log('Jelentés betöltési hiba: $e');
    } finally {
      await disconnect();
    }

    return null;
  }

  Future<Results> loadBonusReportMonthly(DateTime selectedDate) async {
    try {
      await connect();
      String query = '''
          SELECT id, COUNT(id) as total_quantity, SUM(amount) as total_revenue
          FROM balance_log
          WHERE YEAR(eff_sp) = ? AND MONTH(eff_sp) = ? AND bonus = 1
          GROUP BY id
          ORDER BY total_revenue DESC
        ''';

      return await _connection
          .query(query, [selectedDate.year, selectedDate.month]);
    } catch (e) {
      log('Jelentés betöltési hiba: $e');
    } finally {
      await disconnect();
    }

    return null;
  }
}
