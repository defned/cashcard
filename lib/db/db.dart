import 'package:cashcard/app/app.dart';
import 'package:cashcard/util/logging.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class DbRecordDataSource extends DataTableSource {
  List<DbRecord> _dbRecords = [];
  List<DbRecord> getRecords() => _dbRecords;

  void init(String searchTerm) async {
    _selectedCount = 0;
    _dbRecords = await app.db.getAll(searchTerm);
    notifyListeners();
  }

  void sort<T>(Comparable<T> Function(DbRecord d) getField, bool ascending) {
    _dbRecords.sort((DbRecord a, DbRecord b) {
      if (!ascending) {
        final DbRecord c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }

  int _selectedCount = 0;

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);
    if (index >= _dbRecords.length) return null;
    final DbRecord dbRecord = _dbRecords[index];
    return DataRow.byIndex(
      index: index,
      selected: dbRecord.selected,
      onSelectChanged: (bool? value) {
        if (dbRecord.selected != value) {
          _selectedCount += value == true ? 1 : -1;
          assert(_selectedCount >= 0);
          if (value != null) dbRecord.selected = value;
          notifyListeners();
        }
      },
      cells: <DataCell>[
        DataCell(Text(dbRecord.id,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        DataCell(Text('${dbRecord.balance} HUF',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ],
    );
  }

  @override
  int get rowCount => _dbRecords.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;

  void selectAll(bool checked) {
    for (DbRecord dessert in _dbRecords) {
      dessert.selected = checked;
    }
    _selectedCount = checked ? _dbRecords.length : 0;
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

class DbRecord {
  DbRecord(this.id, this.balance);

  String id;
  int balance;

  bool selected = false;
}

class Db {
  final String host;
  final int port;
  final String userName;
  final String password;
  final String dbName;

  late MySqlConnection _connection;

  Db(
      {required this.host,
      required this.port,
      required this.userName,
      required this.password,
      required this.dbName});

  Future connect() async {
    _connection = await MySqlConnection.connect(ConnectionSettings(
        host: host,
        port: port,
        user: userName,
        password: password,
        db: dbName));
    // host: 'localhost', port: 3306, user: 'root', password: 'admin', db: 'cashcard'));
  }

  Future disconnect() async {
    // assert(_connection != null);
    await _connection.close();
    // _connection = null;
  }

  Future getAll(String searchTerm) async {
    // Query the database using a parameterized query
    List<DbRecord> res = [];
    try {
      await connect();
      var results = await _connection.query(
          'select id, balance from balance where (id like ?) and del_sp = "0000-00-00"',
          ['%$searchTerm%']);
      for (int i = 0; i < results.length; i++) {
        res.add(DbRecord(results.elementAt(i)[0], results.elementAt(i)[1]));
      }
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

      if (results.isNotEmpty) throw DbExceptions.alreadyExist;
      // Insert some data
      var result =
          await _connection.query('insert into balance (id) values (?)', [id]);
      log("Inserted row (${result.affectedRows} record) ${[id]}");
    } finally {
      await disconnect();
    }
  }

  Future<DbRecord> get(String id) async {
    try {
      await connect();
      // Query the database using a parameterized query
      var results = await _connection.query(
          'select id, balance from balance where id = ? and del_sp = "0000-00-00"',
          [id]);

      if (results.isEmpty) {
        throw DbExceptions.noRows;
      } else if (results.length > 1) {
        throw DbExceptions.tooManyRows;
      }
      return DbRecord(results.first[0], results.first[1]);
    } finally {
      await disconnect();
    }
  }

  Future pay(String id, int amount) {
    if (!(amount > 0)) throw DbExceptions.missingValueInput;
    return changeBalance(id, -1 * amount);
  }

  Future topUp(String id, int amount) {
    if (!(amount > 0)) throw DbExceptions.missingValueInput;

    return changeBalance(id, amount);
  }

  Future delete(List<String> ids) async {
    try {
      await connect();
      var result = await _connection.query(
          'update balance set del_sp = SYSDATE(), del_sp = SYSDATE() where id in (${List.generate(ids.length, (_) => "?").join(',')}) and del_sp = "0000-00-00"',
          ids);
      log("Deleted rows (${result.affectedRows} record) $ids");
    } finally {
      await disconnect();
    }
  }

  Future import(List<DbRecord> records, {Function(double)? onProgress}) async {
    try {
      await connect();
      int imported = 0;
      for (int i = 0; i < records.length; i++) {
        var result = await _connection.query(
          'insert into balance (id) values (?) ON DUPLICATE KEY UPDATE balance = 0',
          [records[i].id],
        );
        log("Imported row (${result.affectedRows} records) ${[records[i].id]}");

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
    if (!(id.isNotEmpty)) {
      throw DbExceptions.missingKeyInput;
    }

    try {
      await connect();
      // Query the database using a parameterized query
      var results = await _connection.query(
          'select id, balance from balance where id = ? and del_sp = "0000-00-00"',
          [id]);

      if (results.isEmpty) {
        throw DbExceptions.noRows;
      } else if (results.length > 1) {
        throw DbExceptions.tooManyRows;
      } else if (results.length == 1) {
        log('Card ID: ${results.first[0]}, balance: ${results.first[1]}');

        int origBalance = results.first[1];
        // Less then zero, PAY is NOT allowed
        if ((origBalance <= 0 && amount < 0) || origBalance + amount < 0) {
          throw DbExceptions.negativeBalance;
        } else {
          var result = await _connection.query(
              'update balance set balance = balance + ? where id = ? and del_sp = "0000-00-00"',
              [amount, id]);
          log("Inserted rows (${result.affectedRows} record) [${[
            id,
            amount
          ]}]");
        }
      }
    } finally {
      await disconnect();
    }
  }
}
