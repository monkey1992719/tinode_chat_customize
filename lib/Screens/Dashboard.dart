import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share/share.dart';
import 'package:tinode/Constants/color.dart';
import 'package:tinode/Models/messsage.dart';
import 'package:tinode/Screens/chat.dart';
import 'package:tinode/Screens/group_chat.dart';
import 'package:tinode/Screens/settings.dart';

import '../main.dart';

class MainScreen extends StatefulWidget {
  final String currentUserId;

  MainScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => MainScreenState(currentUserId: currentUserId);
}

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  MainScreenState({Key key, @required this.currentUserId});

  final String currentUserId;

  final GoogleSignIn googleSignIn = GoogleSignIn();
  AppLifecycleState _lastLifecycleState;
  bool isLoading = false;
  bool chat = true;
  String last;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final List<Message> messages = [];

  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    registerNotification();
  }

  void registerNotification() {
    _firebaseMessaging.onTokenRefresh.listen(sendTokenToServer);

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        final notification = message['notification'];
        setState(() {
          messages.add(Message(
              title: notification['title'], body: notification['body']));
        });
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");

        final notification = message['data'];
        setState(() {
          messages.add(Message(
            title: '${notification['title']}',
            body: '${notification['body']}',
          ));
        });
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );

    _firebaseMessaging.getToken().then((token) {
      print('token: $token');
      Firestore.instance
          .collection('users')
          .document(currentUserId)
          .updateData({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
  }

  void sendTokenToServer(String fcmToken) {
    print('Token: $fcmToken');
    // send key to your server to allow server to use
    // this token to send push notifications
  }

  @override
  void dispose() {
    if (_lastLifecycleState == AppLifecycleState.detached) {
      Firestore.instance
          .collection('users')
          .document(currentUserId)
          .updateData({
        'status': false,
        'leaveAt': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    }
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('this is the app life $state');
    setState(() {
      _lastLifecycleState = state;
    });
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Settings()));
    }
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.message, size: 25, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => GroupChatPage()))),
        title: Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.share,
                color: Colors.white,
                size: 25,
              ),
              onPressed: () {
                Share.share(
                    "Hey, \n I would like to invite you to Talk To Me. \nPlease click on below link and install the app first Android: \n (google Play Store Link) \n IOS:\n (App Store Link) ");
              }),
          PopupMenuButton<Choice>(
            onSelected: onItemMenuPress,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: primaryColor,
                        ),
                        Container(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                //alignment: Alignment.center,
                width: 200,
                padding: EdgeInsets.all(5),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 3,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            chat = true;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 40,
                          width: 100,
                          decoration: chat
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.blueAccent)
                              : BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      width: 2, color: Colors.blueAccent)),
                          child: Text(
                            'Chats',
                            style: chat
                                ? null
                                : TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            chat = false;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 40,
                          width: 100,
                          decoration: chat
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      width: 2, color: Colors.blueAccent))
                              : BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.blueAccent),
                          child: Text(
                            'Archive',
                            style: chat
                                ? TextStyle(color: Colors.blueAccent)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // List
            Expanded(
              flex: 10,
              child: Container(
                child: StreamBuilder(
                  stream: Firestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        padding: EdgeInsets.all(10.0),

                        itemBuilder: (context, index) =>
                            mainScreen(context, snapshot.data.documents[index]),
                        // buildItem(context, snapshot.data.documents[index]),
                        itemCount: snapshot.data.documents.length,
                      );
                    }
                  },
                ),
              ),
            ),

            // Loading
            Container(
              child: isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(themeColor)),
                      ),
                      color: Colors.white.withOpacity(0.8),
                    )
                  : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget mainScreen(context, DocumentSnapshot document) {
    if (document['id'] == currentUserId) {
      return Container();
    } else {
      return UserTile(
        currentUserId: widget.currentUserId,
        doc: document,
      );
    }
  }
}

class UserTile extends StatefulWidget {
  final DocumentSnapshot doc;
  final String currentUserId;
  UserTile({@required this.doc, @required this.currentUserId});
  @override
  _UserTileState createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  String last = '';
  String fromId = '';
  int seen;
  DateTime time;
  DateTime now = DateTime.now();
  @override
  Widget build(BuildContext context) {
    _fetch(widget.doc.documentID);

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Chat(
                      peerId: widget.doc.documentID,
                      peerAvatar: widget.doc['photoUrl'],
                      peername: widget.doc['nickname'],
                      fcm: widget.doc['pushToken'],
                    )));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Material(
                        child: widget.doc['photoUrl'] != null
                            ? CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        themeColor),
                                  ),
                                  width: 50.0,
                                  height: 50.0,
                                  padding: EdgeInsets.all(15.0),
                                ),
                                imageUrl: widget.doc['photoUrl'],
                                width: 60.0,
                                height: 60.0,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.account_circle,
                                size: 50.0,
                                color: greyColor,
                              ),
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        clipBehavior: Clip.hardEdge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: EdgeInsets.only(left: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${widget.doc['nickname']}',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text('$last',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fromId != widget.currentUserId && seen == 0
                            ? TextStyle(
                                color: Colors.blue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)
                            : null),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    time != null
                        ? '${time.hour}:${time.minute}:${time.second}'
                        : '',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  fromId != widget.currentUserId && seen == 0
                      ? CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 6,
                        )
                      : Container(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  _fetch(String userId) async {
    String groupChatId;

    if (userId.hashCode <= widget.currentUserId.hashCode) {
      groupChatId = '$userId-${widget.currentUserId}';
    } else {
      groupChatId = '${widget.currentUserId}-$userId';
    }

    // Wait for each single message to arrive
    final m = await Firestore.instance
        .collection('messages')
        .document(groupChatId)
        .collection(groupChatId)
        .getDocuments();

    if (m.documents.length > 0) {
      setState(() {
        last = m.documents.last.data['content'];
        fromId = m.documents.last.data['idFrom'];
        seen = m.documents.last.data['seen'];
        time = DateTime.fromMillisecondsSinceEpoch(
            int.parse(m.documents.last.data['timestamp']));
      });
      print('this is the message sjdbvsdkkkkkk--------- $last');
      print('this is the timeeeeeee sjdbvsdkkkkkk--------- $time');
      // return last;
    } else {
      setState(() {
        last = '';
        seen = 1;
        time = null;
      });
    }
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

class Order {
  final String lastMsg;
  final String timeStamp;
  final DocumentReference reference;

  Order.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(true),
        lastMsg = map['address'] ?? "",
        timeStamp = map['instructions'] ?? "";

  Order.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Order<$lastMsg:$timeStamp>";
}
