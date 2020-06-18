import 'package:BWO/Entity/Entity.dart';
import 'package:flutter/material.dart';

class Tile extends Entity{
  int posX;
  int posY;
  int size = 15;
  Color color;
  int height = 255;

  Paint boxPaint = Paint();
  Rect boxRect;

  Tile(this.posX, this.posY, this.height, this.size, this.color) : super(posX, posY){
    boxRect = Rect.fromLTWH(
      posX.toDouble() * size.toDouble(),
      posY.toDouble() * size.toDouble(),
      size.toDouble(),
      size.toDouble(),
    );
    boxPaint.color = color != null ? color : Colors.white;
  }

  void draw(Canvas c){
    c.drawRect(boxRect, boxPaint);
  }
}