import 'package:mysql1/mysql1.dart';

class DbRecord {
  String id;
  String name;
  int balance;
}

class Db {
  final String host;
  final int port;
  final String userName;
  final String password;
  final String dbName;

  MySqlConnection connection;

  Db({this.host, this.port, this.userName, this.password, this.dbName});

  Future connect() async {
    assert(connection == null);
    connection = await MySqlConnection.connect(new ConnectionSettings(
        host: host,
        port: port,
        user: userName,
        password: password,
        db: dbName));
    // host: 'localhost', port: 3306, user: 'root', password: 'admin', db: 'cashcard'));
  }

  Future close() async {
    assert(connection != null);
    await connection.close();
  }

  Future register(String id, String name) async {
    // Query the database using a parameterized query
    var results = await connection.query(
        'select id, name from balance where id = ? and del_sp is null', [id]);

    if (results.length != 0) throw ("Already exist");
    // Insert some data
    var result = await connection
        .query('insert into balance (id, name) values (?, ?)', [id, name]);
    print("Inserted row id=${result.insertId}");
  }

  Future delete(String id) async {
    // Query the database using a parameterized query
    var results = await connection.query(
        'select id, name from balance where id = ? and del_sp is null', [id]);

    if (results.length == 0) throw ("Does not exist");
    // Insert some data
    var result = await connection
        .query('insert into balance (id, del_sp) values (?, NOW())', [id]);
    print("Deleted row id=${result.insertId}");
  }

  Future<DbRecord> get(String id) async {
    // Query the database using a parameterized query
    var results = await connection.query(
        'select id, name from balance where id = ? and del_sp is null', [id]);

    if (results.length < 1)
      throw ("No such rows");
    else if (results.length > 1) throw ("Too many result");
    return DbRecord()
      ..id = results.first[0]
      ..name = results.first[1]
      ..balance = results.first[2];
  }

  Future pay(String id, int amount) {
    assert(amount != null && amount > 0);
    return changeBalance(id, amount);
  }

  Future topUp(String id, int amount) {
    assert(amount != null && amount > 0);
    return changeBalance(id, amount);
  }

  Future changeBalance(String id, int amount) async {
    assert(id != null && id.isNotEmpty && amount != null);
    // Query the database using a parameterized query
    var results = await connection.query(
        'select id, name, balance from balance where id = ? and del_sp is null',
        [id]);

    if (results.length < 1)
      throw ("No such rows");
    else if (results.length > 1)
      throw ("Too many result");
    else if (results.length == 1) {
      print(
          'Card ID: ${results.first[0]}, name: ${results.first[1]}, balance: ${results.first[2]}');

      int origBalance = results.first[2];
      // Less then zero, PAY is NOT allowed
      if (origBalance < 0 && amount < 0) {
        throw ("Pay is not allowed with negative balance");
      } else {
        print("Not enough");
        var result = await connection.query(
            'update balance set balance = balance + ? where id = ? and del_sp is null',
            [amount, id]);
        print("Inserted row id=${result.insertId}");
      }
    }
  }
}
