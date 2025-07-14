import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false; // Track if the opponent is typing

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add('You: ${_controller.text}');
      });
      _controller.clear();

      // Send user message to Gemini for response
      Content userMessage = Content(parts: [Part.text(_messages.last)], role: 'user');
      Content modelMessage = Content(parts: [Part.text("Thinking...")], role: 'model'); // Placeholder for model's response

      // Perform multi-turn chat
      Gemini.instance.chat([userMessage, modelMessage]).then((response) {
        if (response?.output != null) {
          setState(() {
            _messages.add('Gemini: ${response!.output}');
          });
        }
      }).catchError((e) {
        setState(() {
          _messages.add('Error: $e');
        });
      });
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.teal.shade700 : Colors.teal,
        title: const Text('Chat with Gemini'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: _messages[index].startsWith('You:')
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                      decoration: BoxDecoration(
                        color: _messages[index].startsWith('You:')
                            ? isDarkMode ? Colors.teal.shade600 : Colors.teal.shade100
                            : isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _messages[index],
                        style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: isDarkMode ? Colors.white : Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Scroll to the bottom when a new message is added
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }
}
