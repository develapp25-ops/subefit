import 'package:flutter/material.dart';

class ExerciseAIChatScreen extends StatelessWidget {
  final List<ChatMessage> messages;
  final TextEditingController inputController;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final bool isListening;
  final bool isLoading;
  final PreferredSizeWidget? appBar; // Nuevo parámetro para la AppBar

  const ExerciseAIChatScreen({
    Key? key,
    required this.messages,
    required this.inputController,
    required this.onSend,
    required this.onMic,
    this.isListening = false,
    this.isLoading = false,
    this.appBar, // Lo añadimos al constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Chat IA Fitness'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8.0),
              reverse: true, // Muestra los mensajes más nuevos abajo
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? const Color(0xFF00E5FF)
                          : Colors.grey[850],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                          color: msg.isUser ? Colors.black : Colors.white),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
            ),
          ),
          if (isLoading)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator()),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    onSubmitted: (_) => onSend(),
                    textInputAction: TextInputAction.send,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu pregunta o mensaje...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
                  onPressed: isLoading ? null : onSend,
                ),
                IconButton(
                  icon: Icon(isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? Colors.red : Colors.white),
                  onPressed: onMic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
