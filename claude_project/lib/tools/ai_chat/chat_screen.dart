import 'package:flutter/material.dart';
import '../../shared/widgets/common_app_bar.dart';
import 'models/chat_message.dart';
import 'services/api_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;

  // 从 Settings 读取的配置
  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';

  @override
  void initState() {
    super.initState();
    // TODO: 从 Hive 读取 saved API key 和 base url
    // For now, hardcode or read from provider (none used yet)
    _apiKey = ''; // Read from settings when implemented
    _baseUrl = 'https://api.openai.com/v1';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(ChatMessage(role: MessageRole.user, content: text));
      _loading = true;
    });
    _controller.clear();

    try {
      final client = ApiClient(apiKey: _apiKey, baseUrl: _baseUrl);
      final reply = await client.send(
        userMessage: text,
        history: _messages.where((m) => m.role != MessageRole.system).toList(),
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: MessageRole.assistant, content: reply));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _messages.add(ChatMessage(
            role: MessageRole.system,
            content: '⚠️ 请求失败: $e',
          ));
        });
      }
    }

    // Auto-scroll to bottom
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '有机交流电灯'),
      body: SafeArea(
        child: Column(
          children: [
            // Message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg.role == MessageRole.system) {
                    return SystemMessageChip(msg.content);
                  }
                  return MessageBubble(message: msg);
                },
              ),
            ),

            // Loading indicator
            if (_loading)
              Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerLeft,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),

            // Input bar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: '输入消息...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _loading ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isUser ? 48 : 8,
          right: isUser ? 8 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.content),
      ),
    );
  }
}

class SystemMessageChip extends StatelessWidget {
  final String content;
  const SystemMessageChip(this.content, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(content, style: TextStyle(color: Colors.orange[700])),
    );
  }
}
