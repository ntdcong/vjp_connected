import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/message_provider.dart';
import 'dart:async';
import 'dart:io';
import 'chat/chat_app_bar.dart';
import 'chat/chat_message_list.dart';
import 'chat/chat_input_field.dart';
import 'chat/chat_settings.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _settingsScrollController = ScrollController();
  
  bool _scrollToNewMessages = true;
  late TabController _tabController;
  
  DateTime _lastUserActivity = DateTime.now();
  Timer? _userActivityTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      messageProvider.fetchMessages(widget.userId).then((_) {
        _scrollToBottomImmediately();
      });
      
      if (!messageProvider.isPollingActive) {
        messageProvider.startPolling();
      }
      
      messageProvider.updateLastActivity();
    });
    
    _scrollController.addListener(_scrollListener);
    _setupUserActivityTimer();
  }

  void _scrollToBottomImmediately() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }
  
  void _setupUserActivityTimer() {
    _userActivityTimer?.cancel();
    
    _userActivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      final timeSinceLastActivity = now.difference(_lastUserActivity);
      
      if (timeSinceLastActivity > const Duration(minutes: 2)) {
        // Không cần cập nhật gì ở đây vì MessageProvider sẽ tự động điều chỉnh tốc độ
      }
    });
  }
  
  void _updateUserActivity() {
    _lastUserActivity = DateTime.now();
    Provider.of<MessageProvider>(context, listen: false).updateLastActivity();
  }
  
  void _scrollListener() {
    _updateUserActivity();
    
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      _scrollToNewMessages = (maxScroll - currentScroll) < 50;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _updateUserActivity();
        if (!messageProvider.isPollingActive) {
          messageProvider.startPolling();
        }
        messageProvider.fetchMessages(widget.userId);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _settingsScrollController.dispose();
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _userActivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _sendMessage() async {
    _updateUserActivity();
    
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    await messageProvider.sendMessage(widget.userId, content: messageText);

    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _updateUserActivity,
      child: Scaffold(
        appBar: ChatAppBar(
          userId: widget.userId,
          userName: widget.userName,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      Consumer<MessageProvider>(
                        builder: (context, messageProvider, child) {
                          final messages = messageProvider.messages;
                          return ChatMessageList(
                            messages: messages,
                            scrollController: _scrollController,
                            scrollToNewMessages: true,
                          );
                        },
                      ),
                      ChatInputField(
                        messageController: _messageController,
                        onSendMessage: _sendMessage,
                        onSendImage: (File image) async {
                          _updateUserActivity();
                          final messageProvider = Provider.of<MessageProvider>(context, listen: false);
                          await messageProvider.sendMessage(widget.userId, image: image);
                        },
                      ),
                    ],
                  ),
                  Consumer<MessageProvider>(
                    builder: (context, messageProvider, child) {
                      final mediaMessages = messageProvider.messages
                          .where((message) => message.image != null || message.imageUrl != null)
                          .toList();
                      return ChatSettings(
                        settingsScrollController: _settingsScrollController,
                        mediaMessages: mediaMessages,
                      );
                    },
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