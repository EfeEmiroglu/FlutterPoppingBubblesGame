import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';

class MyPlayer extends StatelessWidget {
  final playerX;
  final playerY;

  MyPlayer({this.playerX, this.playerY});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(playerX, playerY),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.deepPurple,
          height: 50,
          width: 50,
        ),
      ),
    );
  }
}
