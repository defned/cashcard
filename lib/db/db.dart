import 'package:mysql1/mysql1.dart';

class Db {
  MySqlConnection connection;
  void connect(String host, int port, String userName, String password,
      String dbName) async {
    assert(connection == null);
    connection = await MySqlConnection.connect(new ConnectionSettings(
        host: host,
        port: port,
        user: userName,
        password: password,
        db: dbName));
    // host: 'localhost', port: 3306, user: 'root', password: 'admin', db: 'cashcard'));
  }

  void close() async {
    assert(connection != null);
    await connection.close();
  }

  Future get(String id, String name) async {
    // Insert some data
    var result = await connection
        .query('insert into balance (id, name) values (?, ?)', [id, name]);
    print("Inserted row id=${result.insertId}");

    // Query the database using a parameterized query
    var results = await connection
        .query('select id, name from balance where id = ?', [result.insertId]);
    for (var row in results) {
      print('Card ID: ${row[0]}, name: ${row[1]}');
    }
  }
}
