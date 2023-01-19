import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/ball.dart';
import 'package:flutter_application_1/button.dart';
import 'package:flutter_application_1/missile.dart';
import 'package:flutter_application_1/player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

enum direction { LEFT, RIGHT }

class _HomePageState extends State<HomePage> {
  //player variables
  static double playerX = 0;
  static double playerY = 1;

  //missile variables
  double missileX = playerX;
  double missileY = playerY;
  double missileHeight = 10;
  bool midShot = false;

  //timer
  int _seconds = 0;
  late Timer _timer;

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopTimer() {
    _timer.cancel();
  }

  //ball variables
  double ballX = 0.5;
  double ballY = 0;
  var ballDirection = direction.LEFT;

  Future<void> createDatabase() async {
    Database database = await openDatabase('my_database.db');

    try {
      await database.execute('''
        CREATE TABLE IF NOT EXISTS time_table (
          id INTEGER PRIMARY KEY,
          seconds INTEGER,
          name TEXT
        )
        ''');
      await database.execute("ALTER TABLE time_table ADD COLUMN name TEXT");
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> putDataInDatabase() async {
    // Connect to the database
    Database database = await openDatabase('my_database.db');
    int count = 0;
    try {
      for (int i = 0; i < _seconds; i++) {
        count++;
      }
      await database.rawInsert(
        'INSERT INTO time_table (seconds) VALUES (?)',
        [count],
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void moveLeft() {
    setState(() {
      if (playerX - 0.1 < -1) {
        //do nothing
      } else {
        playerX -= 0.1;
      }

      //only adjust the X coordinate when the same it isn't in the middle of a shot
      if (!midShot) {
        missileX = playerX;
      }
    });
  }

  void moveRight() {
    setState(() {
      if (playerX + 0.1 > 1) {
        //do nothing
      } else {
        playerX += 0.1;
      }
      //only adjust the X coordinate when the same it isn't in the middle of a shot
      if (!midShot) {
        missileX = playerX;
      }
    });
  }

  //converts height to a coordinate
  double heightToPosition(double height) {
    double totalHeight = MediaQuery.of(context).size.height * 3 / 4;
    double position = 1 - 2 * height / totalHeight;
    return position;
  }

  void fireMissile() {
    if (midShot == false) {
      Timer.periodic(Duration(milliseconds: 20), (timer) {
        //shots fired
        midShot = true;

        //missile grows til it hits the top of the screen
        setState(() {
          missileHeight += 10;
        });

        if (missileHeight > MediaQuery.of(context).size.height * 3 / 4) {
          //stop missile when the missile hits the surface
          resetMissile();
          timer.cancel();
        }

        //check if missile has hit the ball
        if (ballY > heightToPosition(missileHeight) &&
            (ballX - missileX).abs() < 0.03) {
          resetMissile();
          ballX = 5;
          timer.cancel();
        }
      });
    }
  }

  void jump() {
    setState(() {
      if (playerY - 0.1 < -1) {
        //do nothing
      } else {
        playerY -= 0.1;
      }

      if (!midShot) {
        missileY = playerY;
      }
    });
  }

  void down() {
    setState(() {
      if (playerY + 0.1 > 1) {
        //do nothing
      } else {
        playerY += 0.1;
      }

      if (!midShot) {
        missileY = playerY;
      }
    });
  }

  void startGame() {
    double time = 0;
    double height = 0;
    double velocity = 60; //how strong the jump is

    createDatabase();
    _startTimer();

    MaterialApp(
      routes: {
        '/second': (context) => HomePage(),
      },
    );
    Timer.periodic(const Duration(milliseconds: 10), (timer) {
      //quadratic equation that models a bounce (upside down parabola)
      height = -5 * time * time + velocity * time;

      //if the ball reaches the ground, reset the jump
      if (height < 0) {
        time = 0;
      }

      setState(() {
        ballY = heightToPosition(height);
      });

      time += 0.1;

      //if the ball hits the wall, then change direction to right
      if (ballX - 0.005 < -1) {
        ballDirection = direction.RIGHT;
      }
      //if the ball hits the wall, then change direction to left
      else if (ballX + 0.005 > 1) {
        ballDirection = direction.LEFT;
      }

      //move the ball in the correct direction
      if (ballDirection == direction.LEFT) {
        setState(() {
          ballX -= 0.005;
        });
      } else if (ballDirection == direction.RIGHT) {
        setState(() {
          ballX += 0.005;
        });
      }

      //check if the ball hits the player
      if (playerDies()) {
        timer.cancel();
        _stopTimer();
        _showDeadDialog();
        //putDataInDatabase();
      }

      time += 0.1;
    });
  }

  void _showDeadDialog() {
    String _name = "name";
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[700],
            title: Center(
                child: Column(
              children: <Widget>[
                Text("YOU ARE DEAD!", style: TextStyle(color: Colors.white)),
                Text("Elapsed time: $_seconds seconds",
                    style: TextStyle(color: Colors.white)),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _name = value;
                  },
                ),
              ],
            )),
            actions: <Widget>[
              ElevatedButton(
                child: Text('Submit', style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  // Insert the user's name and elapsed time into the database
                  Database database = await openDatabase('my_database.db');
                  await database.insert(
                    'time_table',
                    {'id': null, 'seconds': _seconds, 'name': _name},
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/mainpage');
                },
              ),
            ],
          );
        });
  }

  void resetMissile() {
    missileX = playerX;
    missileY = playerY;
    missileHeight = 10;
    midShot = false;
  }

  bool playerDies() {
    //if the ball position and the player position are the same, then player dies
    if ((ballX - playerX).abs() < 0.05 && ballY > 0.95) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
          moveLeft();
        } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
          moveRight();
        } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
          jump();
        } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
          down();
        }

        if (event.isKeyPressed(LogicalKeyboardKey.space)) {
          fireMissile();
        }
      },
      child: Column(children: [
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.pink[100],
            child: Center(
              child: Stack(
                children: [
                  MyBall(ballX: ballX, ballY: ballY),
                  MyMissile(
                    height: missileHeight,
                    missileX: missileX,
                    missileY: missileY,
                  ),
                  MyPlayer(
                    playerX: playerX,
                    playerY: playerY,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Text(
                      'Time: $_seconds seconds',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MyButton(
                  icon: Icons.play_arrow,
                  function: startGame,
                ),
                MyButton(
                  icon: Icons.arrow_back,
                  function: moveLeft,
                ),
                MyButton(
                  icon: Icons.space_bar,
                  function: fireMissile,
                ),
                // MyButton(
                //   icon: Icons.arrow_upward,
                //   function: jump,
                // ),
                // MyButton(
                //   icon: Icons.arrow_downward,
                //   function: down,
                // ),
                MyButton(
                  icon: Icons.arrow_forward,
                  function: moveRight,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
