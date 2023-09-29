// ChatRoomPage.dart
// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter5/chat_page.dart';

class ChatRoomPage extends StatefulWidget {
  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Rooms'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                // Navigate back to the login or authentication screen
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              } catch (e) {
                print('Error logging out: $e');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore.collection('chat_rooms').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Loading indicator
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Text('No chat rooms available'); // No chat rooms found
          }

          final chatRooms = snapshot.data!.docs;

          List<Widget> chatRoomListTiles = [];
          for (var chatRoom in chatRooms) {
            final Map<String, dynamic> chatRoomData =
                chatRoom.data() as Map<String, dynamic>;

            final String? chatRoomName = chatRoomData['name'] as String?;
            if (chatRoomName != null && chatRoomName.isNotEmpty) {
              chatRoomListTiles.add(
                ListTile(
                  title: Text(chatRoomName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatPage(chatRoomName: chatRoomName),
                      ),
                    );
                  },
                ),
              );
            }
          }

          return ListView(
            children: chatRoomListTiles,
          );
        },
      ),
    );
  }
}
