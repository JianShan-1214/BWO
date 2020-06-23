import 'dart:ui';

import 'package:BWO/Entity/Entity.dart';
import 'package:BWO/Entity/Player.dart';
import 'package:BWO/Map/ground.dart';
import 'package:BWO/Map/tree.dart';
import 'package:BWO/game_controller.dart';
import 'package:fast_noise/fast_noise.dart';
import 'package:flutter/material.dart';
import 'package:BWO/Map/tile.dart';

class MapController {
  final Map<int, Map<int, Map<int, Tile>>> map = {};

  double widthViewPort;
  double heightViewPort;

  double posX = 0;
  double posY = 0;

  List<Entity> entityList = [];
  List<Entity> entitysOnViewport = [];
  int treesGenerated = 0;
  int tilesGenerated = 0;
  int _lastTreePosX = 0;

  int safeY = 0;
  int safeYmax = 0;
  int safeX = 0;
  int safeXmax = 0;

  double cameraSpeed = 5;

  var terrainNoise = new SimplexNoise(
    frequency: 0.004,
    gain: .9,
    lacunarity: 2.6,
    octaves: 3,
    fractalType: FractalType.FBM,
  );

  var treeNoise = new PerlinNoise(
    frequency: 0.3,
    gain: 1.1,
    lacunarity: 1,
    octaves: 1,
    fractalType: FractalType.FBM,
  );

  MapController(this.widthViewPort, this.heightViewPort);

  void drawMap(Canvas c, double moveX, double moveY, Rect screenSize,
      {int tileSize = 15, border = 4, int movimentType = MovimentType.MOVE}) {
    var borderSize = (border * tileSize);

    this.widthViewPort =
        (screenSize.width / tileSize).roundToDouble() + (border * 2);
    this.heightViewPort =
        (screenSize.height / tileSize).roundToDouble() + (border * 2);

    // move camera
    if (movimentType == MovimentType.MOVE) {
      this.posX += moveX.roundToDouble();
      this.posY += moveY.roundToDouble();
    } else if (movimentType == MovimentType.FOLLOW) {
      this.posX = lerpDouble(
              posX,
              (-moveX.roundToDouble() + screenSize.width / 2) +
                  border * tileSize,
              GameController.deltaTime * cameraSpeed)
          .roundToDouble();
      this.posY = lerpDouble(
              posY,
              (-moveY.roundToDouble() + screenSize.height / 2) +
                  border * tileSize,
              GameController.deltaTime * cameraSpeed)
          .roundToDouble();
    }

    c.save();
    c.translate(posX - borderSize, posY - borderSize);

    Rect viewPort = Rect.fromLTRB(
      -posX / tileSize,
      -posY / tileSize,
      widthViewPort - posX / tileSize,
      heightViewPort - posY / tileSize,
    );

    safeY = (viewPort.top).toInt();
    safeYmax = (viewPort.bottom).toInt()+7;
    safeX = (viewPort.left).toInt();
    safeXmax = (viewPort.right).toInt();

    for (int y = safeY; y < safeYmax; y++) {
      for (int x = safeX; x < safeXmax; x++) {
        bool isSafeLine = map[y] != null ? map[y][x] != null : false;

        if (isSafeLine) {
          //check if tile already exist, if yes, draw, otherwise create it
          int safeZmax = map[y][x].length;
          for (int z = 0; z < safeZmax; z++) {
            map[y][x][z].draw(c);
          }
        } else {
          var tileHeight =
              ((terrainNoise.getSimplexFractal2(x.toDouble(), y.toDouble()) *
                          128) +
                      127)
                  .toInt();

          if (map[y] == null) {
            map[y] = {x: null}; //initialize line
          }
          if (map[y][x] == null) {
            map[y][x] = {0: null}; //initialize line
          }
          map[y][x][0] = Ground(x, y, tileHeight, tileSize, null);
          tilesGenerated++;

          //TREE
          if (tileHeight > 130 &&
              tileHeight < 180 &&
              ((y % 4 == 0 && x % 3 == 1) ||
                  (y % 7 == 0 && x % 9 == 1) ||
                  (y % 12 == 0 && x % 15 == 0))) {
            var treeHeight =
                ((treeNoise.getPerlin2(x.toDouble(), y.toDouble()) * 128) + 127)
                    .toInt();

            if (treeHeight > 160 && (_lastTreePosX - x).abs() > 8) {
              //170
              treesGenerated++;
              _lastTreePosX = x;

              if (y % 5 == 0) {
                entityList.add(Tree(x, y, tileSize, "tree04"));
              } else if (y % 6 == 0) {
                entityList.add(Tree(x, y, tileSize, "tree02"));
              } else if (y % 7 == 0) {
                entityList.add(Tree(x, y, tileSize, "tree03"));
              } else {
                entityList.add(Tree(x, y, tileSize, "tree01"));
              }
            }
          }
        }
      }
    }

    //Organize List to show Entity elements (Players, Trees) on correct Y-Index order
    _findEntitysOnViewport();
    entitysOnViewport.sort((a, b) => a.y.compareTo(b.y));
    
    for (var entity in entitysOnViewport) {
      entity.draw(c);
    }

    c.restore();
  }

  void addEntity(Entity obj) {
    entityList.add(obj);
  }


  bool _isEntityInsideViewport(Entity entity) {
    return (entity.posX > safeX &&
        entity.posY > safeY &&
        entity.posX < safeXmax &&
        entity.posY < safeYmax);
  }

  void _findEntitysOnViewport(){
    entitysOnViewport.clear();

    for (int i = 0; i < entityList.length; i++) {
      if (entityList[i] is Player ||
          _isEntityInsideViewport(entityList[i])) {
            entitysOnViewport.add(entityList[i]);
      }
    }
  }
}

class MovimentType {
  static const int None = 0;
  static const int MOVE = 1;
  static const int FOLLOW = 2;
}
