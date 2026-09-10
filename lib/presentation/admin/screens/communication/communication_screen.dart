import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/message_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../services/notification_service.dart';
import '../../../../data/models/user_model.dart';

class CommunicationCenterScreen extends StatefulWidget {
  const CommunicationCenterScreen({Key? key}) : super(key: key);

  @override
  State<CommunicationCenterScreen> createState() =>
      _CommunicationCenterScreenState();
}

class _CommunicationCenterScreenState extends State<CommunicationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MessageRepository _messageRepository = MessageRepository();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<LanguageProvider>(context).translate('communication_center')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: Provider.of<LanguageProvider>(context).translate('sent_messages')),
            Tab(text: Provider.of<LanguageProvider>(context).translate('templates')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendMessageDialog,
        icon: const Icon(Icons.send),
        label: Text(Provider.of<LanguageProvider>(context).translate('send_message')),
        backgroundColor: const Color(0xFFEC4899),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSentMessagesTab(isDark),
          _buildTemplatesTab(isDark),
        ],
      ),
    );
  }

  Widget _buildSentMessagesTab(bool isDark) {
    return Column(
      children: [
        // Summary Cards
        StreamBuilder<List<MessageModel>>(
          stream: _messageRepository.getSentMessagesStream('admin'),
          builder: (context, snapshot) {
            final messages = snapshot.data ?? [];
            final totalSent = messages.length;
            final readCount = messages.where((m) => m.isRead).length;
            final readRate = totalSent > 0 
                ? ((readCount / totalSent) * 100).toStringAsFixed(0)
                : '0';

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      Provider.of<LanguageProvider>(context).translate('total_sent'),
                      '$totalSent',
                      Icons.send,
                      AppColors.lightPrimary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      Provider.of<LanguageProvider>(context).translate('read_rate'),
                      '$readRate%',
                      Icons.visibility,
                      AppColors.lightSuccess,
                      isDark,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: Provider.of<LanguageProvider>(context).translate('search'),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        const SizedBox(height: 16),

        // Messages List
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _messageRepository.getSentMessagesStream('admin'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.lightError,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Provider.of<LanguageProvider>(context).translate('error_loading_messages'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Provider.of<LanguageProvider>(context).translate('no_messages_yet'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Provider.of<LanguageProvider>(context).translate('send_first_message'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              var messages = snapshot.data!;

              // Apply search
              if (_searchController.text.isNotEmpty) {
                final query = _searchController.text.toLowerCase();
                messages = messages
                    .where((msg) =>
                        msg.title.toLowerCase().contains(query) ||
                        msg.message.toLowerCase().contains(query))
                    .toList();
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: messages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildMessageCard(messages[index], isDark);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(MessageModel message, bool isDark) {
    final notificationType = message.notificationType;

    IconData typeIcon = Icons.notifications;
    Color typeColor = AppColors.lightInfo;
    String typeLabel = Provider.of<LanguageProvider>(context).translate('notification');

    if (notificationType == 'sms') {
      typeIcon = Icons.sms;
      typeColor = AppColors.lightSuccess;
      typeLabel = Provider.of<LanguageProvider>(context).translate('sms');
    } else if (notificationType == 'both') {
      typeIcon = Icons.send;
      typeColor = const Color(0xFFEC4899);
      typeLabel = Provider.of<LanguageProvider>(context).translate('both');
    }

    return InkWell(
      onTap: () => _showMessageDetails(message, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message.message,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(message.sentAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(message.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(message.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDetails(MessageModel message, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Status', message.status),
                _buildDetailRow('Type', message.notificationType),
                _buildDetailRow(
                  'Sent At',
                  DateFormat('dd MMM yyyy, hh:mm a').format(message.sentAt),
                ),
                if (message.isRead && message.readAt != null)
                  _buildDetailRow(
                    'Read At',
                    DateFormat('dd MMM yyyy, hh:mm a').format(message.readAt!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Provider.of<LanguageProvider>(context).translate('close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  Widget _buildTemplatesTab(bool isDark) {
    final templates = [
      {
        'title': 'Due Payment Reminder',
        'message':
            'Dear member, your monthly contribution is due. Please pay at your earliest convenience.',
        'category': 'Reminder',
      },
      {
        'title': 'Meeting Notification',
        'message':
            'Foundation meeting scheduled for [DATE] at [TIME]. Your presence is requested.',
        'category': 'Event',
      },
      {
        'title': 'Investment Update',
        'message':
            'Your investment in [PROJECT] has generated [RETURN]% return this month.',
        'category': 'Update',
      },
      {
        'title': 'Welcome Message',
        'message':
            'Welcome to our foundation! We are glad to have you as a member.',
        'category': 'Welcome',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template, isDark);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  template['category'],
                  style: const TextStyle(
                    color: AppColors.lightPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Use template functionality
                  _showSendMessageDialog(
                    title: template['title'],
                    message: template['message'],
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Provider.of<LanguageProvider>(context, listen: false).translate('using_template')),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template['title'],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            template['message'],
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return AppColors.lightInfo;
      case 'delivered':
        return AppColors.lightSuccess;
      case 'read':
        return AppColors.lightPrimary;
      default:
        return AppColors.lightWarning;
    }
  }

  void _showSendMessageDialog({String? title, String? message}) {
    showDialog(
      context: context,
      builder: (context) => SendMessageDialog(
        initialTitle: title,
        initialMessage: message,
      ),
    );
  }
}

class SendMessageDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialMessage;

  const SendMessageDialog({
    Key? key,
    this.initialTitle,
    this.initialMessage,
  }) : super(key: key);

  @override
  State<SendMessageDialog> createState() => _SendMessageDialogState();
}

class _SendMessageDialogState extends State<SendMessageDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  final UserRepository _userRepository = UserRepository();
  final MessageRepository _messageRepository = MessageRepository();
  final NotificationService _notificationService = NotificationService();

  String? _selectedUserId;
  String? _selectedUserPhone;
  String _notificationType = 'notification'; // notification, sms, both
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _messageController = TextEditingController(text: widget.initialMessage);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    if (_formKey.currentState!.validate()) {
      if (_selectedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.translate('select_user_error'))),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final message = MessageModel(
          id: '',
          senderId: 'admin',
          recipientId: _selectedUserId!,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          notificationType: _notificationType,
          status: 'sent',
          sentAt: DateTime.now(),
          isRead: false,
        );

        // 1. Send via App (Firestore) if type is notification or both
        if (_notificationType == 'notification' || _notificationType == 'both') {
          await _messageRepository.sendMessage(message);
        }

        // 2. Send via SMS if type is sms or both
        // SMS sending logic removed

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(languageProvider.translate('message_sent_success'))),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          if (errorMessage.contains('Could not launch SMS')) {
             errorMessage = languageProvider.translate('error_could_not_launch_sms');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${languageProvider.translate('error')}: $errorMessage')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return AlertDialog(
      title: Text(languageProvider.translate('send_message')),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Selector
                StreamBuilder<List<UserModel>>(
                  stream: _userRepository.getAllUsersStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    final users = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: languageProvider.translate('select_user_label'),
                        border: const OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: users.map((user) {
                        return DropdownMenuItem(
                          value: user.id,
                          child: Text(
                            '${user.name} (${user.phone})',
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                             _selectedUserPhone = user.phone;
                          },
                        );
                      }).toList(),
                      onChanged: (val) {
                         setState(() => _selectedUserId = val);
                      },
                      validator: (val) => val == null ? languageProvider.translate('required') : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('title_label'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) => val?.isEmpty ?? true ? languageProvider.translate('required') : null,
                ),
                const SizedBox(height: 16),
                
                // Message
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('message_label'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (val) => val?.isEmpty ?? true ? languageProvider.translate('required') : null,
                ),
                const SizedBox(height: 16),
                
                // Type Selector
                DropdownButtonFormField<String>(
                  initialValue: _notificationType,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('type_label'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'notification', child: Text(languageProvider.translate('app_notification'))),
                  ],
                  onChanged: (val) => setState(() => _notificationType = val!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(languageProvider.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSend,
          child: _isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              ) 
            : Text(languageProvider.translate('send')),
        ),
      ],
    );
  }
}
