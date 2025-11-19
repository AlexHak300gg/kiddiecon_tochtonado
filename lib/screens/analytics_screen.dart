import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final String parentKey;
  final List<Map<String, dynamic>> childrenData;

  const AnalyticsScreen({
    super.key,
    required this.parentKey,
    required this.childrenData,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsService _analyticsService;
  String? _selectedChildId;
  String _selectedPeriod = 'Неделя';
  List<Map<String, dynamic>> _balanceHistory = [];
  List<Map<String, dynamic>> _weeklyIncome = [];
  List<Map<String, dynamic>> _goalProgress = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService();
    if (widget.childrenData.isNotEmpty) {
      _selectedChildId = widget.childrenData.first['id'];
      _loadAnalyticsData();
    }
  }

  Future<void> _loadAnalyticsData() async {
    if (_selectedChildId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final balanceHistory = await _analyticsService.getBalanceHistory(_selectedChildId!, _selectedPeriod);
      final weeklyIncome = await _analyticsService.getWeeklyIncome(_selectedChildId!, _selectedPeriod);
      final goalProgress = await _analyticsService.getGoalProgressHistory(_selectedChildId!, null);

      setState(() {
        _balanceHistory = balanceHistory;
        _weeklyIncome = weeklyIncome;
        _goalProgress = goalProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['День', 'Неделя', 'Месяц', 'Квартал'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadAnalyticsData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: isSelected ? Colors.orange : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChildSelector() {
    if (widget.childrenData.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            _loadAnalyticsData();
          },
        ),
      ),
    );
  }

  Widget _buildBalanceChart() {
    if (_balanceHistory.isEmpty) {
      return _buildEmptyChart('Нет данных о балансе');
    }

    final maxBalance = _balanceHistory.map((d) => d['balance'] as double).reduce((a, b) => a > b ? a : b);
    final minBalance = _balanceHistory.map((d) => d['balance'] as double).reduce((a, b) => a < b ? a : b);
    final range = maxBalance - minBalance > 0 ? (maxBalance - minBalance).toDouble() : 1.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Динамика баланса',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _balanceHistory.length == 1
                ? Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_balanceHistory.first['balance'].toInt()} ₽',
                          style: GoogleFonts.nunito(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: LineChartPainter(
                      data: _balanceHistory,
                      max: maxBalance,
                      min: minBalance,
                      range: range,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Мин: ${minBalance.toInt()} ₽',
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                'Макс: ${maxBalance.toInt()} ₽',
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeChart() {
    if (_weeklyIncome.isEmpty) {
      return _buildEmptyChart('Нет данных о доходах');
    }

    final maxIncome = _weeklyIncome.map((d) => d['income'] as double).reduce((a, b) => a > b ? a : b);
    final range = maxIncome > 0 ? maxIncome : 1.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Еженедельные доходы',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _weeklyIncome.length == 1
                ? Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_weeklyIncome.first['income'].toInt()} ₽',
                          style: GoogleFonts.nunito(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: BarChartPainter(
                      data: _weeklyIncome,
                      max: maxIncome,
                      range: range,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'Средний доход: ${(_weeklyIncome.map((d) => d['income'] as double).reduce((a, b) => a + b) / _weeklyIncome.length).toInt()} ₽/нед',
            style: GoogleFonts.nunito(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
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
              Icons.analytics,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных для аналитики',
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

    return Column(
      children: [
        _buildChildSelector(),
        _buildPeriodSelector(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildBalanceChart(),
                      _buildIncomeChart(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// Custom painters for charts
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double max;
  final double min;
  final double range;

  LineChartPainter({
    required this.data,
    required this.max,
    required this.min,
    required this.range,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.orange.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final stepX = width / (data.length - 1);

    // Start from left bottom
    fillPath.moveTo(0, height);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final value = data[i]['balance'] as double;
      final y = height - ((value - min) / range) * (height - 20) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = Colors.orange,
      );
    }

    // Complete fill path
    fillPath.lineTo(width, height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double max;
  final double range;

  BarChartPainter({
    required this.data,
    required this.max,
    required this.range,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final barWidth = width / data.length * 0.6;
    final stepX = width / data.length;

    for (int i = 0; i < data.length; i++) {
      final value = data[i]['income'] as double;
      final barHeight = (value / range) * (height - 20);
      final x = i * stepX + (stepX - barWidth) / 2;
      final y = height - barHeight - 10;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}