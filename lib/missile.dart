import 'package:flutter/material.dart';

class MyMissile extends StatelessWidget {
  final missileX;
  final missileY;
  final height;

  MyMissile({this.height, this.missileX, this.missileY});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(missileX, missileY),
      child: Container(
        width: 2,
        height: height,
        color: Colors.grey,
      ),
    );
  }
}
