import 'package:example_flutter/app/app.dart';
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

  void sort<T>(Comparable<T> getField(DbRecord d), bool ascending) {
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
  DataRow getRow(int index) {
    assert(index >= 0);
    if (index >= _dbRecords.length) return null;
    final DbRecord dbRecord = _dbRecords[index];
    return DataRow.byIndex(
      index: index,
      selected: dbRecord.selected,
      onSelectChanged: (bool value) {
        if (dbRecord.selected != value) {
          _selectedCount += value ? 1 : -1;
          assert(_selectedCount >= 0);
          dbRecord.selected = value;
          notifyListeners();
        }
      },
      cells: <DataCell>[
        DataCell(Text('${dbRecord.id}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        DataCell(Text('${dbRecord.name}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        DataCell(Text('${dbRecord.balance} HUF',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
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
    for (DbRecord dessert in _dbRecords) dessert.selected = checked;
    _selectedCount = checked ? _dbRecords.length : 0;
    notifyListeners();
  }
}

class DbRecord {
  DbRecord(this.id, this.name, this.balance);

  String id;
  String name;
  int balance;

  bool selected = false;
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
    // host: 'localhost', port: 3306, user: 'root', password: 'admin', db: 'cashcard'));
  }

  Future close() async {
    assert(_connection != null);
    await _connection.close();
  }

  Future getAll(String searchTerm) async {
    // Query the database using a parameterized query
    var results = await _connection.query(
        'select id, name, balance from balance where (name like ? or id like ?) and del_sp = "0000-00-00"',
        ['%$searchTerm%', '%$searchTerm%']);
    List<DbRecord> res = [];
    for (int i = 0; i < results.length; i++)
      res.add(DbRecord(results.elementAt(i)[0], results.elementAt(i)[1],
          results.elementAt(i)[2]));

    return res;
  }

  Future register(String id, String name) async {
    // Query the database using a parameterized query
    var results = await _connection.query(
        'select id, name from balance where id = ? and del_sp = "0000-00-00"',
        [id]);

    if (results.length != 0) throw ("alreadyExist");
    // Insert some data
    var result = await _connection
        .query('insert into balance (id, name) values (?, ?)', [id, name]);
    print("Inserted row (${result.affectedRows} record) ${[id, name]}");
  }

  Future<DbRecord> get(String id) async {
    // Query the database using a parameterized query
    var results = await _connection.query(
        'select id, name, balance from balance where id = ? and del_sp = "0000-00-00"',
        [id]);

    if (results.length < 1)
      throw ("noRows");
    else if (results.length > 1) throw ("tooManyResult");
    return DbRecord(results.first[0], results.first[1], results.first[2]);
  }

  Future pay(String id, int amount) {
    assert(amount != null && amount > 0);
    return changeBalance(id, -1 * amount);
  }

  Future topUp(String id, int amount) {
    assert(amount != null && amount > 0);
    return changeBalance(id, amount);
  }

  Future delete(List<String> ids) async {
    var result = await _connection.query(
        'update balance set del_sp = SYSDATE(), del_sp = SYSDATE() where id in (${List.generate(ids.length, (_) => "?").join(',')}) and del_sp = "0000-00-00"',
        ids);
    print("Deleted rows (${result.affectedRows} record) $ids");
  }

  Future import(List<DbRecord> records, {Function(double) onProgress}) async {
    int imported = 0;
    for (int i = 0; i < records.length; i++) {
      var result = await _connection.query(
          'insert into balance (id, name) values (?, ?) ON DUPLICATE KEY UPDATE name = ?, balance = 0',
          [
            records[i].id,
            records[i].name,
            records[i].name,
          ]);
      print("Imported row (${result.affectedRows} records) " +
          [records[i].id, records[i].name].toString());

      if (onProgress != null) imported++;
      onProgress(imported / records.length);
    }
    if (imported > 0) print("Imported rows ($imported records)");
  }

  Future changeBalance(String id, int amount) async {
    assert(id != null && id.isNotEmpty && amount != null);
    // Query the database using a parameterized query
    var results = await _connection.query(
        'select id, name, balance from balance where id = ? and del_sp = "0000-00-00"',
        [id]);

    if (results.length < 1)
      throw ("noRows");
    else if (results.length > 1)
      throw ("tooManyResult");
    else if (results.length == 1) {
      print(
          'Card ID: ${results.first[0]}, name: ${results.first[1]}, balance: ${results.first[2]}');

      int origBalance = results.first[2];
      // Less then zero, PAY is NOT allowed
      if (origBalance <= 0 && amount < 0) {
        throw ("negativeBalance");
      } else {
        var result = await _connection.query(
            'update balance set balance = balance + ? where id = ? and del_sp = "0000-00-00"',
            [amount, id]);
        print(
            "Inserted rows (${result.affectedRows} record) [${[id, amount]}]");
      }
    }
  }
}
