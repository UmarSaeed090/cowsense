import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message_model.dart';
import '../../models/user_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUserMessage;
  final UserModel otherUser;
  final Function(String) onImageTap;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUserMessage,
    required this.otherUser,
    required this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('h:mm a');
    final timeString = formatter.format(message.timestamp);

    return Align(
      alignment:
          isCurrentUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          left: isCurrentUserMessage ? 64 : 8,
          right: isCurrentUserMessage ? 8 : 64,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: isCurrentUserMessage
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message content
            if (message.type == MessageType.text)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUserMessage ? Colors.white : Colors.black,
                  ),
                ),
              )
            else if (message.type == MessageType.image)
              GestureDetector(
                onTap: () => onImageTap(message.mediaUrl ?? ''),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.mediaUrl ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.error,
                              color: Color(0xFFCB2213),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            else if (message.type == MessageType.call)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.content.contains('Video')
                          ? Icons.videocam
                          : Icons.call,
                      color: isCurrentUserMessage ? Colors.white : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.content,
                      style: TextStyle(
                        color:
                            isCurrentUserMessage ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

            // Time and read status
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4, left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUserMessage
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                  if (isCurrentUserMessage)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
