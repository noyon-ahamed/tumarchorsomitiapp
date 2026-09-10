import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SendMessageScreen extends StatefulWidget {
  const SendMessageScreen({Key? key}) : super(key: key);

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _recipientType = 'all'; // all, individual, selected
  String? _selectedUser;
  String _notificationType = 'notification'; // notification, sms, both
  bool _isLoading = false;

  // TODO: Replace with StreamBuilder for real Firestore users
  final List<String> _users = [];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_formKey.currentState!.validate()) {
      if (_recipientType == 'individual' && _selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a user')),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Simulate sending
      Future.delayed(const Duration(seconds: 2), () {
        final message = {
          'id': 'MSG${DateTime.now().millisecondsSinceEpoch}',
          'recipient': _recipientType == 'all'
              ? 'All Users'
              : _selectedUser ?? 'Unknown',
          'recipientType': _recipientType,
          'title': _titleController.text,
          'message': _messageController.text,
          'sentAt': DateTime.now(),
          'notificationType': _notificationType,
          'status': 'Sent',
          'readCount': 0,
          'totalRecipients': _recipientType == 'all' ? 48 : 1,
        };

        Navigator.pop(context, message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Message Type Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose Delivery Method',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Send via Notification or SMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notification Type
              Text(
                'Delivery Method',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              _buildNotificationTypeOption(
                'notification',
                'In-App Notification',
                'Send free notification within the app',
                Icons.notifications,
                AppColors.lightInfo,
                'FREE',
              ),

              _buildNotificationTypeOption(
                'sms',
                'SMS Message',
                'Send SMS to user\'s phone number',
                Icons.sms,
                Colors.orange,
                'PAID',
              ),

              const SizedBox(height: 8),

              _buildNotificationTypeOption(
                'both',
                'Both (Notification + SMS)',
                'Send both in-app and SMS notification',
                Icons.all_inclusive,
                Colors.purple,
                'COMBO',
              ),

              const SizedBox(height: 24),

              // Recipient Selection
              Text(
                'Select Recipients',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              _buildRecipientOption(
                'all',
                'All Users',
                'Send to all active members',
                Icons.people,
              ),

              const SizedBox(height: 12),

              _buildRecipientOption(
                'individual',
                'Individual User',
                'Send to a specific user',
                Icons.person,
              ),

              if (_recipientType == 'individual') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedUser,
                  decoration: InputDecoration(
                    labelText: 'Select User',
                    prefixIcon: const Icon(Icons.person_search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _users.map((user) {
                    return DropdownMenuItem(
                      value: user,
                      child: Text(user),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUser = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Message Title
              Text(
                'Message Title',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter message title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Message Content
              Text(
                'Message Content',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter message content';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSend,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isLoading ? 'Sending...' : 'Send Message',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTypeOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String badge,
  ) {
    final isSelected = _notificationType == value;

    return InkWell(
      onTap: () {
        setState(() {
          _notificationType = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color : null,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _recipientType == value;

    return InkWell(
      onTap: () {
        setState(() {
          _recipientType = value;
          if (value == 'all') {
            _selectedUser = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightPrimary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.lightPrimary
                : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.lightPrimary : null,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.lightPrimary : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.lightPrimary,
              ),
          ],
        ),
      ),
    );
  }
}
