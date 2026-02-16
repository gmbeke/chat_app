import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/presence_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/online_indicator.dart';

class ChatView extends StatefulWidget {
  final UserModel me;
  final UserModel other;

  const ChatView({super.key, required this.me, required this.other});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = _chatService.getChatId(widget.me.uid, widget.other.uid);
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final message = MessageModel(
      id: '', // Firestore will generate this
      text: text,
      fromUid: widget.me.uid,
      toUid: widget.other.uid,
    );

    _chatService.sendMessage(_chatId, message);
    _ctrl.clear();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.other.photoUrl != null
                      ? NetworkImage(widget.other.photoUrl!)
                      : null,
                  child: widget.other.photoUrl == null
                      ? Text(
                          widget.other.displayName.isNotEmpty
                              ? widget.other.displayName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: StreamBuilder<bool>(
                    stream: _presenceService.isUserOnline(widget.other.uid),
                    builder: (context, snapshot) {
                      return OnlineIndicator(
                        isOnline: snapshot.data ?? widget.other.isOnline,
                        size: 10,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.other.displayName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  StreamBuilder<bool>(
                    stream: _presenceService.isUserOnline(widget.other.uid),
                    builder: (context, snapshot) {
                      final isOnline = snapshot.data ?? widget.other.isOnline;
                      return Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];

                // Mark incoming messages as read
                for (final msg in messages) {
                  if (msg.toUid == widget.me.uid && msg.readAt == null) {
                    _chatService.markAsRead(_chatId, msg.id);
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ChatBubble(
                      message: msg,
                      isMe: msg.fromUid == widget.me.uid,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue[700],
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
