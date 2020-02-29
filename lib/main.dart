import 'package:flutter/material.dart';
import 'Screens/Tic_Tac_Toe/game.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: Game(),
       routes: <String, WidgetBuilder> {
        'singleGame' : (BuildContext context) =>  Game(),
        'multiplayerGame' : (BuildContext context) =>  Game(),       
      },
    );
  }
}

class LocalNotificationWidget {
}
