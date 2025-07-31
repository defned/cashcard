import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/util/logging.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class DbRecordDataSource extends ChangeNotifier {
  List<DbRecordBalance> _dbBalanceRecords = [];
  List<DbRecordBalance> getBalanceRecords() => _dbBalanceRecords;
  List<DbRecordProduct> _dbProductRecords = [];
  List<DbRecordProduct> getProductRecords() => _dbProductRecords;

  void init(String searchTerm) async {
    _dbBalanceRecords = await app.db.getBalanceAll(searchTerm);
    _dbProductRecords = await app.db.getProductAll(searchTerm);
    notifyListeners();
  }

  void sort<T>(Comparable<T> getField(DbRecordBalance d), bool ascending) {
    _dbBalanceRecords.sort((DbRecordBalance a, DbRecordBalance b) {
      if (!ascending) {
        final DbRecordBalance c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }
}

enum DbExceptions {
  noRows,
  missingKeyInput,
  missingValueInput,
  tooManyRows,
  alreadyExist,
  negativeBalance,
  unknown
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
    this.name,
    this.priceHuf,
    this.favourite,
  );

  int id;
  String name;
  int priceHuf;
  bool favourite = false;

  @override
  String toString() => "$id;$name;$priceHuf;${favourite ? 1 : 0};";
}

// class DbRecordSales {
//   DbRecordSales(
//     this.id,
//     this.balanceId,
//     this.productId,
//     this.productName,
//     this.productPriceHuf,
//     this.productFavourite,
//   );

//   String id;
//   String balanceId;
//   String productId;
//   String productName;
//   int productPriceHuf;
//   bool productFavourite = false;
// }

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

  Future<List<DbRecordProduct>> getProductAll(String searchTerm) async {
    List<DbRecordProduct> res = [];
    try {
      await connect();
      var results = await _connection.query(
          'select id, name, price_huf, favourite from product where (name like ?) and del_sp = "0000-00-00"',
          ['%$searchTerm%']);
      for (int i = 0; i < results.length; i++)
        res.add(DbRecordProduct(
          results.elementAt(i)[0],
          results.elementAt(i)[1],
          results.elementAt(i)[2],
          (results.elementAt(i)[3] == 1) ? true : false,
        ));
    } finally {
      await disconnect();
    }
    return res;
  }

  Future register(String id) async {
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

  Future pay(String id, int amount) {
    if (!(amount != null && amount > 0)) throw DbExceptions.missingValueInput;
    return changeBalance(id, -1 * amount);
  }

  Future topUp(String id, int amount) {
    if (!(amount != null && amount > 0)) throw DbExceptions.missingValueInput;
    return changeBalance(id, amount);
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

  Future changeBalance(String id, int amount) async {
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
          var result = await _connection.query(
              'update balance set balance = balance + ? where id = ? and del_sp = "0000-00-00"',
              [amount, id]);
          log("Inserted rows (${result.affectedRows} record) id=$id amount=$amount");
        }
      }
    } finally {
      await disconnect();
    }
  }
}
