import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../services/account_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String parentKey;
  final String childId;
  final String childName;

  const AccountSettingsScreen({
    super.key,
    required this.parentKey,
    required this.childId,
    required this.childName,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  late AccountService _accountService;
  
  Account? _account;
  bool _loading = true;
  double _dailyRate = 0.0001; // Default 0.01% annually

  @override
  void initState() {
    super.initState();
    _accountService = AccountService(
      childId: widget.childId,
      parentKey: widget.parentKey,
    );
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await _accountService.getAccount();
      setState(() {
        _account = account;
        _dailyRate = account.dailyRate;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _updateDailyRate(double newRate) async {
    try {
      await _accountService.updateDailyRate(newRate);
      setState(() {
        _dailyRate = newRate;
        if (_account != null) {
          _account = _account!.copyWith(dailyRate: newRate);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ставка обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showEditRateDialog() {
    final controller = TextEditingController(text: (_dailyRate * 365 * 100).toStringAsFixed(3));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Годовая процентная ставка',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Текущая ставка: ${(_dailyRate * 365 * 100).toStringAsFixed(3)}% годовых',
              style: GoogleFonts.nunito(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Новая ставка (% годовых)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: '% ',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ежедневный доход: ~${(_dailyRate * 100).toStringAsFixed(4)}%',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(controller.text);
              if (newRate != null && newRate >= 0 && newRate <= 100) {
                final dailyRate = newRate / 365 / 100;
                _updateDailyRate(dailyRate);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректную ставку (0-100%)')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F6BF8),
        title: Text(
          'Настройки счета - ${widget.childName}',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountInfoCard(),
                  const SizedBox(height: 20),
                  _buildInterestRateCard(),
                  const SizedBox(height: 20),
                  _buildExplanationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Text(
                'Информация о счете',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Текущий баланс', '${_account?.balance.toStringAsFixed(2) ?? '0.00'}₽'),
          _buildInfoRow('Процентная ставка', '${(_dailyRate * 365 * 100).toStringAsFixed(3)}% годовых'),
          _buildInfoRow('Ежедневный процент', '${(_dailyRate * 100).toStringAsFixed(4)}%'),
          if (_account?.lastCalculatedAt != null)
            _buildInfoRow(
              'Последнее начисление',
              _formatDate(_account!.lastCalculatedAt!),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestRateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.percent, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              Text(
                'Управление ставкой',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Текущая годовая ставка: ${(_dailyRate * 365 * 100).toStringAsFixed(3)}%',
            style: GoogleFonts.nunito(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Это означает ежедневное начисление ${(_dailyRate * 100).toStringAsFixed(4)}% от текущего баланса',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showEditRateDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Изменить ставку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Text(
                'Как это работает?',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Проценты начисляются ежедневно в 00:00\n'
            '• Если приложение было закрыто, проценты за пропущенные дни начисляются при открытии\n'
            '• Расчет: Новый баланс = Текущий баланс × (1 + дневная ставка)\n'
            '• Все операции записываются в историю',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.blue.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}