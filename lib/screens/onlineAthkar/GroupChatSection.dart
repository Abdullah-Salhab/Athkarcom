import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupChatSection extends StatefulWidget {
  final String groupId;
  final String userName;

  const GroupChatSection({
    Key? key,
    required this.groupId,
    required this.userName,
  }) : super(key: key);

  @override
  State<GroupChatSection> createState() => _GroupChatSectionState();
}

class _GroupChatSectionState extends State<GroupChatSection> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPicker = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sends a message to Firestore
  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'senderName': widget.userName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ أثناء إرسال الرسالة: $e',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Formats Firebase Timestamp into a readable Arabic time format
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();

    final String hour = dateTime.hour > 12
        ? '${dateTime.hour - 12}'
        : dateTime.hour == 0
            ? '12'
            : '${dateTime.hour}';
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'م' : 'ص';
    final String timeStr = '$hour:$minute $period';

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return timeStr;
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.subtract(const Duration(days: 1)).day) {
      return 'أمس، $timeStr';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}، $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF15222E), const Color(0xFF0F1A24)] // Premium deep slate/navy
              : [const Color(0xFFF5F7FB), const Color(0xFFEBF0F6)], // Elegant soft white/grey
        ),
      ),
      child: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: isDark ? Colors.teal.shade300 : Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'لا توجد رسائل بعد\nابدأ بكتابة رسالة لتشجيع أعضاء المجموعة! ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16.0,
                            color: Colors.grey,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final List<DocumentSnapshot> docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> data =
                        docs[index].data() as Map<String, dynamic>;

                    final String sender = data['senderName'] as String? ?? 'مجهول';
                    final String text = data['text'] as String? ?? '';
                    final Timestamp? timestamp = data['timestamp'] as Timestamp?;

                    final bool isMe = sender == widget.userName;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment:
                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Other members' avatar
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.teal.shade300,
                              child: Text(
                                sender.isNotEmpty ? sender[0] : '؟',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                          ],

                          // Message Body Container
                          Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Username header for other members
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                                  child: Text(
                                    sender,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.teal.shade200 : Colors.teal.shade700,
                                    ),
                                  ),
                                ),

                              // Text Bubble
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.70,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isMe
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.teal.shade400,
                                            Colors.teal.shade600,
                                          ],
                                        )
                                      : null,
                                  color: isMe
                                      ? null
                                      : (isDark
                                          ? const Color(0xFF202A35) // Elegant slate card
                                          : Colors.white),
                                  border: isMe
                                      ? null
                                      : Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.08)
                                              : Colors.grey.shade200,
                                          width: 1.0,
                                        ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20.0),
                                    topRight: const Radius.circular(20.0),
                                    bottomLeft: isMe
                                        ? const Radius.circular(20.0)
                                        : Radius.zero,
                                    bottomRight: isMe
                                        ? Radius.zero
                                        : const Radius.circular(20.0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Text content
                                    Text(
                                      text,
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 15.5,
                                        color: isMe
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : Colors.black87),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Time Indicator
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.check,
                                          size: 11,
                                          color: isMe
                                              ? Colors.white60
                                              : Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTimestamp(timestamp),
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 10.0,
                                            color: isMe
                                                ? Colors.white60
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Own Avatar
                          if (isMe) ...[
                            const SizedBox(width: 8.0),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.teal.shade600,
                              child: Text(
                                sender.isNotEmpty ? sender[0] : 'أ',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_showEmojiPicker) _buildEmojiBar(isDark),
          // Floating Input Panel
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2832) : Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 16.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    // Sentiment icon (emoji toggle)
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker ? Icons.keyboard_rounded : Icons.sentiment_satisfied_alt_rounded,
                        color: _showEmojiPicker ? Colors.teal : Colors.grey.shade500,
                        size: 26,
                      ),
                      onPressed: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                    ),
                    
                    // TextField Input
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15.0,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة تشجيعية...',
                          hintStyle: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14.0,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    
                    // Send Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.shade400,
                            Colors.teal.shade600,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 8.0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiBar(bool isDark) {
    final List<String> emojis = [
      '✨',
      '🔥',
      '👍',
      '👏',
      '🎉',
      '❤️',
      '🤲',
      '🕌',
      '⭐',
      '🌸',
      '😊',
      '💡',
      '🌟',
      '💪'
    ];
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2832) : Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          final String emoji = emojis[index];
          return GestureDetector(
            onTap: () {
              final String currentText = _messageController.text;
              final int selectionIndex = _messageController.selection.baseOffset;

              if (selectionIndex >= 0) {
                final String prefix = currentText.substring(0, selectionIndex);
                final String suffix = currentText.substring(selectionIndex);
                _messageController.text = prefix + emoji + suffix;
                _messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: selectionIndex + emoji.length),
                );
              } else {
                _messageController.text = currentText + emoji;
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          );
        },
      ),
    );
  }

}
