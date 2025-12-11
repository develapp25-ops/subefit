import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RutinasIaScreen extends StatefulWidget {
  const RutinasIaScreen({Key? key}) : super(key: key);

  @override
  State<RutinasIaScreen> createState() => _RutinasIaScreenState();
}

class _RutinasIaScreenState extends State<RutinasIaScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _response = '';

  Future<void> _generateRoutine() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una descripción')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
      
      if (apiKey.isEmpty) {
        throw Exception('OpenAI API key not configured');
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Generate a training routine for: ${_controller.text}. Provide a structured workout plan.'
            }
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _response = data['choices'][0]['message']['content'] ?? 'No response';
        });
      } else {
        setState(() {
          _response = 'Error: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Training Plans'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Describe your fitness goal...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateRoutine,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Routine'),
            ),
            const SizedBox(height: 24),
            if (_response.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(_response),
              ),
          ],
        ),
      ),
    );
  }
}
