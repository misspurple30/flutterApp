import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showTail = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMe
        ? AppColors.primary
        : (isDark ? AppColors.darkBubbleOther : AppColors.lightBubbleOther);
    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : (showTail ? 4 : 18)),
      bottomRight: Radius.circular(isMe ? (showTail ? 4 : 18) : 18),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: message.type == MessageType.image
              ? const EdgeInsets.all(4)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.type == MessageType.image)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: message.content,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox(
                      width: 200,
                      height: 200,
                      child: Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                )
              else
                Text(
                  message.content,
                  style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
                ),
              const SizedBox(height: 4),
              Padding(
                padding: message.type == MessageType.image
                    ? const EdgeInsets.only(right: 6, bottom: 2)
                    : EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormatter.time(message.timestamp),
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(.85)
                            : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? Colors.lightBlueAccent.shade100
                            : Colors.white.withOpacity(.85),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
