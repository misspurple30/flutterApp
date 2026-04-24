import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/day_separator.dart';
import '../widgets/message_bubble.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _userService = UserService();
  final _storageService = StorageService();
  final _picker = ImagePicker();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _sending = false;
  bool _hasText = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _roomId =>
      ChatRoomModel.buildId(_uid, widget.otherUser.uid);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    // Marquer les messages comme lus à l'ouverture.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.markAsRead(
        currentUid: _uid,
        otherUid: widget.otherUser.uid,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _hasText = false;
      _sending = true;
    });
    try {
      await _chatService.sendMessage(
        senderId: _uid,
        receiverId: widget.otherUser.uid,
        content: text,
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Impossible d'envoyer le message.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _sending = true);
    try {
      late final String url;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        url = await _storageService.uploadChatImageFromBytes(
          roomId: _roomId,
          bytes: bytes,
        );
      } else {
        url = await _storageService.uploadChatImageFromFile(
          roomId: _roomId,
          file: File(file.path),
        );
      }
      await _chatService.sendMessage(
        senderId: _uid,
        receiverId: widget.otherUser.uid,
        content: url,
        type: MessageType.image,
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Impossible d'envoyer l'image.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: StreamBuilder<UserModel?>(
          stream: _userService.watchUser(widget.otherUser.uid),
          builder: (context, snap) {
            final user = snap.data ?? widget.otherUser;
            return Row(
              children: [
                UserAvatar(
                  photoUrl: user.photoUrl,
                  displayName: user.displayName,
                  radius: 18,
                  showOnlineIndicator: true,
                  isOnline: user.isOnline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.isOnline
                            ? 'En ligne'
                            : 'Vu ${DateFormatter.lastSeen(user.lastSeen)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: user.isOnline
                              ? Colors.green
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream:
                  _chatService.watchMessages(_uid, widget.otherUser.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return _EmptyChat(name: widget.otherUser.displayName);
                }

                // Marquer comme lu chaque fois qu'un message arrive pendant
                // qu'on est dans l'écran.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _chatService.markAsRead(
                    currentUid: _uid,
                    otherUid: widget.otherUser.uid,
                  );
                });

                // Les messages sont triés DESC ; on utilise reverse: true dans
                // la ListView pour que le plus récent soit en bas.
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _uid;

                    // Le message "plus ancien" est à l'index suivant puisqu'on
                    // est en reverse. Pour le séparateur de jour on compare
                    // avec le message qui tombe AVANT chronologiquement,
                    // c'est-à-dire messages[i + 1].
                    final older = i + 1 < messages.length
                        ? messages[i + 1]
                        : null;
                    final showDay = older == null ||
                        !_sameDay(older.timestamp, msg.timestamp);

                    // "Tail" : dernière bulle d'un groupe du même expéditeur.
                    final newer =
                        i - 1 >= 0 ? messages[i - 1] : null;
                    final showTail = newer == null ||
                        newer.senderId != msg.senderId;

                    return Column(
                      children: [
                        if (showDay) DaySeparator(date: msg.timestamp),
                        MessageBubble(
                          message: msg,
                          isMe: isMe,
                          showTail: showTail,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _ComposeBar(
            controller: _controller,
            sending: _sending,
            hasText: _hasText,
            onSend: _sendText,
            onPickImage: _sendImage,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ComposeBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  const _ComposeBar({
    required this.controller,
    required this.sending,
    required this.hasText,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(.08)
                  : Colors.black.withOpacity(.06),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: sending ? null : onPickImage,
              icon: const Icon(Icons.photo_outlined),
              color: AppColors.primary,
              tooltip: 'Envoyer une image',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Écrivez un message...',
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(.05)
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: hasText ? AppColors.primary : Colors.grey.shade400,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: (sending || !hasText) ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.waving_hand_outlined,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Dites bonjour à $name',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Envoyez un premier message pour démarrer la conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
