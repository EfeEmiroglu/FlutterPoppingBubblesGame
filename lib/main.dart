import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

import 'homepage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
      routes: {
        '/second': (context) => HomePage(),
        '/mainpage': (context) => MyHomePage(),
      },
    );
  }
}

class DeleteButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('Reset Highscores'),
      onPressed: () async {
        var db = await openDatabase('my_database.db');
        await db.execute('DELETE FROM time_table');
        await db.close();
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  Future<List<Map>> retrieveDataFromDatabase() async {
    // Connect to the database
    Database database = await openDatabase('my_database.db');

    List<Map> result = await database.rawQuery(
        'SELECT name FROM sqlite_master WHERE type = "table" AND name = "time_table"');
    if (result.isNotEmpty) {
      print("time_table exists");
      // Retrieve data from the table
      List<Map> results = await database.rawQuery(
          'SELECT seconds,name FROM time_table ORDER BY seconds DESC LIMIT 5');
      return results;
    } else {
      print("time_table does not exist");
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          child: Center(
            child: Text('WELCOME TO POPPING BUBBLES',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
      body: Container(
        color: Colors.pink[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/second');
                  },
                  child: Text(
                    'PLAY',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              // Add the DeleteButton here
              DeleteButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        // ignore: sort_child_properties_last
        child: Container(
          height: 400.0,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 20,
                left: MediaQuery.of(context).size.width / 2 - 50,
                child: Text('Highscores\n-------------------'),
              ),
              Positioned(
                top: 50,
                left: MediaQuery.of(context).size.width / 2 - 100,
                child: FutureBuilder<List<Map>>(
                  future: retrieveDataFromDatabase(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return DataTable(
                        columns: const <DataColumn>[
                          DataColumn(
                            label: Text('Name'),
                          ),
                          DataColumn(
                            label: Text('Seconds'),
                          ),
                        ],
                        rows: snapshot.data
                                ?.map((result) => DataRow(
                                      cells: <DataCell>[
                                        DataCell(result['name'] != null
                                            ? Text(result['name'])
                                            : Text("No name")),
                                        DataCell(
                                            Text(result['seconds'].toString())),
                                      ],
                                    ))
                                .toList() ??
                            [],
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        color: Colors.white,
      ),
    );
  }
}
