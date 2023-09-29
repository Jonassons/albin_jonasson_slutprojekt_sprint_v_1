// ignore_for_file: prefer_const_constructors_in_immutables, library_private_types_in_public_api, use_key_in_widget_constructors, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomName;

  ChatPage({required this.chatRoomName});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
  }

  void _subscribeToMessages() {
    _firestore
        .collection('chat_rooms/${widget.chatRoomName}/messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      // Handle new messages received from Firestore
      List<Map<String, dynamic>> messages = snapshot.docs
          .map((doc) => {
                'text': doc.data()['text'].toString(),
                'sender': doc.data()['sender'].toString(),
                'timestamp': doc.data()['timestamp'] as Timestamp,
              })
          .toList();

      // Update the chat messages in the UI
      setState(() {
        messagesList = messages;
      });
    });
  }

  List<Map<String, dynamic>> messagesList = [];

  void _sendMessage() async {
    final String messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      final User? user = _auth.currentUser;

      if (user != null) {
        final String senderEmail = user.email ?? 'Unknown';
        final timestamp = FieldValue.serverTimestamp();

        await _firestore
            .collection('chat_rooms/${widget.chatRoomName}/messages')
            .add({
          'text': messageText,
          'sender': senderEmail,
          'timestamp': timestamp,
        });

        _messageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoomName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messagesList.length,
              itemBuilder: (context, index) {
                final message = messagesList[index];
                final String sender = message['sender'];
                final String text = message['text'];
                final Timestamp timestamp = message['timestamp'];

                final formattedTimestamp =
                    _formatTimestamp(timestamp.toDate());

                return ListTile(
                  title: Text('$sender: $text'),
                  subtitle: Text('Sent at: $formattedTimestamp'),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final formattedDate = '${dateTime.year}-${dateTime.month}-${dateTime.day}';
    final formattedTime = '${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
    return '$formattedDate $formattedTime';
  }
}

