import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/operation.dart';
import '../services/analytics_service.dart';

class OperationHistoryScreen extends StatefulWidget {
  final String parentKey;
  final List<Map<String, dynamic>> childrenData;

  const OperationHistoryScreen({
    super.key,
    required this.parentKey,
    required this.childrenData,
  });

  @override
  State<OperationHistoryScreen> createState() => _OperationHistoryScreenState();
}

class _OperationHistoryScreenState extends State<OperationHistoryScreen> {
  String? _selectedChildId;
  String _selectedFilter = 'Все';
  List<Operation> _operations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.childrenData.isNotEmpty) {
      _selectedChildId = widget.childrenData.first['id'];
      _loadOperations();
    }
  }

  Future<void> _loadOperations() async {
    if (_selectedChildId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final operations = await _getChildOperations(_selectedChildId!);
      setState(() {
        _operations = operations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Operation>> _getChildOperations(String childId) async {
    // Use the analytics service to get operations
    final analyticsService = AnalyticsService();
    final childrenData = await analyticsService.getChildrenDashboardData(widget.parentKey);
    final childData = childrenData.firstWhere((c) => c['id'] == childId);
    return childData['operations'] as List<Operation>;
  }

  List<Operation> get _filteredOperations {
    if (_selectedFilter == 'Все') return _operations;
    
    return _operations.where((operation) {
      switch (_selectedFilter) {
        case 'Задачи':
          return operation.type == OperationType.task;
        case 'Проценты':
          return operation.type == OperationType.dailyInterest;
        case 'Бонусы':
          return operation.type == OperationType.bonus;
        case 'Переводы':
          return operation.type == OperationType.transfer;
        case 'Цели':
          return operation.type == OperationType.goalDeposit;
        default:
          return true;
      }
    }).toList();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String _getOperationTypeText(OperationType type) {
    switch (type) {
      case OperationType.task:
        return 'Задача';
      case OperationType.dailyInterest:
        return 'Проценты';
      case OperationType.bonus:
        return 'Бонус';
      case OperationType.transfer:
        return 'Перевод';
      case OperationType.goalDeposit:
        return 'Цель';
    }
  }

  Color _getOperationTypeColor(OperationType type) {
    switch (type) {
      case OperationType.task:
        return Colors.green;
      case OperationType.dailyInterest:
        return Colors.blue;
      case OperationType.bonus:
        return Colors.orange;
      case OperationType.transfer:
        return Colors.purple;
      case OperationType.goalDeposit:
        return Colors.red;
    }
  }

  IconData _getOperationTypeIcon(OperationType type) {
    switch (type) {
      case OperationType.task:
        return Icons.check_circle;
      case OperationType.dailyInterest:
        return Icons.percent;
      case OperationType.bonus:
        return Icons.card_giftcard;
      case OperationType.transfer:
        return Icons.swap_horiz;
      case OperationType.goalDeposit:
        return Icons.flag;
    }
  }

  Widget _buildOperationCard(Operation operation) {
    final isPositive = operation.amount > 0;
    final color = _getOperationTypeColor(operation.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getOperationTypeIcon(operation.type),
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getOperationTypeText(operation.type),
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : '-'}${operation.amount.abs().toInt()} ₽',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  operation.reason,
                  style: GoogleFonts.nunito(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(operation.timestamp),
                  style: GoogleFonts.nunito(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChildSelector() {
    if (widget.childrenData.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedChildId,
          isExpanded: true,
          items: widget.childrenData.map((child) {
            return DropdownMenuItem<String>(
              value: child['id'],
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      child['name'][0].toUpperCase(),
                      style: GoogleFonts.nunito(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      child['name'],
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedChildId = value;
            });
            _loadOperations();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.childrenData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных об операциях',
              style: GoogleFonts.nunito(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final filteredOperations = _filteredOperations;
    final totalIncome = filteredOperations
        .where((o) => o.amount > 0)
        .fold(0.0, (sum, o) => sum + o.amount);
    final totalExpense = filteredOperations
        .where((o) => o.amount < 0)
        .fold(0.0, (sum, o) => sum + o.amount.abs());

    return Column(
      children: [
        _buildChildSelector(),
        
        // Summary cards
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Доходы',
                        style: GoogleFonts.nunito(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalIncome.toInt()} ₽',
                        style: GoogleFonts.nunito(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Расходы',
                        style: GoogleFonts.nunito(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalExpense.toInt()} ₽',
                        style: GoogleFonts.nunito(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Filter chips
        Container(
          margin: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Все'),
                const SizedBox(width: 8),
                _buildFilterChip('Задачи'),
                const SizedBox(width: 8),
                _buildFilterChip('Проценты'),
                const SizedBox(width: 8),
                _buildFilterChip('Бонусы'),
                const SizedBox(width: 8),
                _buildFilterChip('Переводы'),
                const SizedBox(width: 8),
                _buildFilterChip('Цели'),
              ],
            ),
          ),
        ),
        
        // Operations list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredOperations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет операций',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Операции появятся здесь после начала использования',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredOperations.length,
                      itemBuilder: (context, index) {
                        return _buildOperationCard(filteredOperations[index]);
                      },
                    ),
        ),
      ],
    );
  }
}