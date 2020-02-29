import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:tinode/Constants/color.dart';
import 'package:tinode/Models/user_data_model.dart';

class GroupChatPage extends StatefulWidget {
  GroupChatPage({Key key}) : super(key: key);

  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  int _color = 0xff203152;
  final message = TextEditingController();
  bool me = false;
  final ScrollController listScrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    message.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

// App Bar srart
        appBar: AppBar(
          title: Text(
            "Group Chat",
            style: TextStyle(color: Color(_color)),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Color(_color),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[],
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              children: <Widget>[
                Container(
                  height: MediaQuery.of(context).size.height / 1.3,
                  width: MediaQuery.of(context).size.width,
                  child: StreamBuilder(
                    stream: getData(),
                    builder: (BuildContext context, snapshot) {
                      if (snapshot.data == null) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        return ListView.builder(
                            
                            
                            itemCount: snapshot.data.documents.length,
                            itemBuilder: (BuildContext contxt, int index, ) {
                              DocumentSnapshot ds =
                                  snapshot.data.documents[index];
                              //checking(ds);
                              return ds['from'] == User.userData.id
                                  ? _messages(ds)
                                  : _friendMessage(ds);
                            },
                            controller: listScrollController,
                            reverse: true,
                            );
                      }
                    },
                  ),
                ),
// text type
                Container(
                  height: 50,
                  margin: EdgeInsets.only(left: 20, top: 10, right: 20),
                  padding: EdgeInsets.only(left: 20, right: 20),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20)),
                  child: TextField(
                    controller: message,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter Message',
                      suffixIcon: InkWell(
                          onTap: () {
                            if (message.text == "" || message.text == null) {
                              Fluttertoast.showToast(msg: 'Nothing to send');
                            } else {
                              _sendMessage(message.text);

                              // FocusScope.of(context).requestFocus(FocusNode());
                            }
                          },
                          child: Icon(
                            Icons.near_me,
                            color: Colors.white,
                          )),
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _friendMessage(DocumentSnapshot data) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 10,
          ),
          Row(
            children: <Widget>[
              SizedBox(
                width: 10,
              ),
              CircleAvatar(
                radius: 20,
                backgroundImage: data['photoUrl'] == ""
                    ? AssetImage('datafolder/boy.png')
                    : NetworkImage(data['photoUrl']),
              ),
              SizedBox(
                width: 5,
              ),
              Column(
                children: <Widget>[
                  Container(
                    width: 180,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          data['name'],
                          style: TextStyle(
                              color: greyColor,
                              fontSize: 8.0,
                              fontStyle: FontStyle.italic),
                        ),
                        Text(
                          DateFormat('dd MMM kk:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  int.parse(data['time']))),
                          style: TextStyle(
                              color: greyColor,
                              fontSize: 8.0,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: Text(
                      data['text'],
                      style: TextStyle(color: Colors.black),
                    ),
                    padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                    width: 200.0,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10))),
                    margin: EdgeInsets.only(left: 10.0),
                  )
                ],
              )
            ],
          )
        ]);
  }

  Widget _messages(DocumentSnapshot data) {
    return Column(
        // mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                data['text'],
                style: TextStyle(color: Colors.white),
              ),
              padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
              width: 200.0,
              decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10))),
              margin: EdgeInsets.only(bottom: 10.0, right: 10.0, top: 10),
            )
          ])
        ]);
  }

  _sendMessage(String content) {
    if (content.trim() != "") {
      setState(() {
        message.clear();
      });
      Firestore.instance.collection('groupChat').document().setData({
        'text': content,
        'from': User.userData.id,
        'name': User.userData.firstName,
        'time': DateTime.now().millisecondsSinceEpoch.toString(),
        'photoUrl': User.userData.photo,
      });
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  Stream getData() {
    Stream stream1 =
        Firestore.instance.collection('groupChat').orderBy('time',descending: true).snapshots();
    return stream1;
  }
}
