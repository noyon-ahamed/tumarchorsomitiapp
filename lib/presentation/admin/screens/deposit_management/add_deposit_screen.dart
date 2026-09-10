import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/deposit_model.dart';
import '../../../../data/repositories/deposit_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/repositories/message_repository.dart';
import '../../../../services/notification_service.dart';

class AddDepositScreen extends StatefulWidget {
  final DepositModel? deposit;
  const AddDepositScreen({Key? key, this.deposit}) : super(key: key);

  @override
  State<AddDepositScreen> createState() => _AddDepositScreenState();
}

class _AddDepositScreenState extends State<AddDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _userRepository = UserRepository();
  final _depositRepository = DepositRepository();

  String _selectedUserId = '';
  String _selectedUserName = '';
  String _selectedMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _methods = [
    'Cash',
    'Bank Transfer',
    'Mobile Banking',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    
    if (widget.deposit != null) {
      _selectedUserId = widget.deposit!.userId;
      _selectedUserName = widget.deposit!.userName;
      _amountController.text = widget.deposit!.amount.toString();
      _selectedMethod = widget.deposit!.method;
      _referenceController.text = widget.deposit!.reference;
      _selectedDate = widget.deposit!.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  final _messageRepository = MessageRepository();
  final _notificationService = NotificationService();

  void _handleSubmit() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      if (_selectedUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('please_select_user')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final deposit = DepositModel(
          id: widget.deposit?.id ?? '', // Use existing ID if editing
          userId: _selectedUserId,
          userName: _selectedUserName,
          amount: double.parse(_amountController.text),
          method: _selectedMethod,
          reference: _referenceController.text,
          status: 'completed',
          addedBy: 'admin',
          date: _selectedDate,
          createdAt: widget.deposit?.createdAt ?? DateTime.now(),
          description: 'Deposit by admin for $_selectedUserName',
        );

        if (widget.deposit != null) {
          await _depositRepository.updateDeposit(deposit.id, deposit);
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lang.translate('deposit_updated_success')),
                backgroundColor: AppColors.lightSuccess,
              ),
            );
          }
        } else {
          await _depositRepository.addDeposit(deposit);
          
          // Local Notification for Admin
          await _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Deposit Added',
            body: 'Deposit of ৳${deposit.amount} added for $_selectedUserName',
          );

          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${lang.translate('deposit_added_for')} $_selectedUserName'),
                backgroundColor: AppColors.lightSuccess,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${lang.translate('error')}: $e'),
              backgroundColor: Colors.red,
            ),
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
    final lang = Provider.of<LanguageProvider>(context);

    // Map methods to localized strings
    final localizedMethods = Map.fromEntries(_methods.map((m) => 
      MapEntry(m, lang.translate(m.toLowerCase().replaceAll(' ', '_')))
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deposit != null 
            ? lang.translate('edit_deposit') 
            : lang.translate('add_deposit')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightInfo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightInfo),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.lightInfo,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          lang.translate('add_deposit_subtitle'),
                        style: TextStyle(
                          color: AppColors.lightInfo.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Select User
              Text(
                lang.translate('select_user'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: _userRepository.getAllUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(lang.translate('loading_users')),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${lang.translate('error_loading_users')}: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(lang.translate('no_users_found')),
                    );
                  }

                  final users = snapshot.data!
                      .where((u) => u.status.toLowerCase() == 'active')
                      .toList();

                  if (users.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(lang.translate('no_active_users')),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedUserId.isEmpty ? null : _selectedUserId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    hint: Text(lang.translate('select_user_hint')),
                    isExpanded: true,
                    items: users.map((user) {
                      return DropdownMenuItem(
                        value: user.id,
                        child: Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final selectedUser =
                            users.firstWhere((u) => u.id == value);
                        setState(() {
                          _selectedUserId = value;
                          _selectedUserName = selectedUser.name;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang.translate('please_select_user');
                      }
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // Amount
              Text(
                lang.translate('amount'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: lang.translate('enter_amount'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang.translate('please_enter_amount');
                  }
                  if (double.tryParse(value) == null) {
                    return lang.translate('please_enter_valid_amount');
                  }
                  if (double.parse(value) <= 0) {
                    return lang.translate('amount_must_be_greater_than_zero');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Payment Method
              Text(
                lang.translate('payment_method'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMethod,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _methods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(lang.translate(method.toLowerCase().replaceAll(' ', '_'))),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Reference Number
              Text(
                lang.translate('reference_number'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.tag),
                  hintText: lang.translate('enter_reference'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang.translate('please_enter_reference');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Date
              Text(
                lang.translate('date_label'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

               // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightSuccess,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.deposit != null 
                              ? lang.translate('update_deposit') 
                              : lang.translate('add_deposit_btn'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}