import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';
import '../screens/operation_history_screen.dart';
import 'analytics_screen.dart';
import 'invite_dialog_screen.dart';
import 'setup_security_screen.dart';
import 'role_selection_screen.dart';

class EnhancedParentDashboardScreen extends StatefulWidget {
  final String parentName;
  final String parentKey;

  const EnhancedParentDashboardScreen({
    super.key,
    required this.parentName,
    required this.parentKey,
  });

  @override
  State<EnhancedParentDashboardScreen> createState() => _EnhancedParentDashboardScreenState();
}

class _EnhancedParentDashboardScreenState extends State<EnhancedParentDashboardScreen>
    with TickerProviderStateMixin {
  late AnalyticsService _analyticsService;
  List<Map<String, dynamic>> _childrenData = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService();
    _tabController = TabController(length: 3, vsync: this);
    _loadChildrenData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChildrenData() async {
   try {
     final childrenData = await _analyticsService.getChildrenDashboardData(widget.parentKey);
     if (!mounted) return;
     setState(() {
       _childrenData = childrenData;
       _isLoading = false;
     });
   } catch (e) {
     if (!mounted) return;
     setState(() {
       _isLoading = false;
     });
   }
  }

  Future<void> _logout() async {
   final confirmed = await showDialog<bool>(
     context: context,
     builder: (context) => AlertDialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       title: Text(
         'Выход',
         style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
       ),
       content: Text(
         'Вы уверены, что хотите выйти?',
         style: GoogleFonts.nunito(),
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context, false),
           child: const Text('Отмена'),
         ),
         ElevatedButton(
           onPressed: () => Navigator.pop(context, true),
           style: ElevatedButton.styleFrom(
             backgroundColor: Colors.red,
           ),
           child: const Text('Выход'),
         ),
       ],
     ),
   );

   if (confirmed == true && mounted) {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove('userRole');
     await prefs.remove('firstLoginDone');

     if (!mounted) return;
     Navigator.pushReplacement(
       context,
       MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
     );
   }
  }

  Future<void> _changePIN() async {
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (_) => SetupSecurityScreen(
         userRole: 'parent',
         isFirstTime: false,
       ),
     ),
   );
  }

  void _addChild() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InviteDialogScreen(parentName: widget.parentName),
      ),
    ).then((_) {
      _loadChildrenData();
    });
  }

  void _showAddBonusDialog(Map<String, dynamic> childData) {
    final amountController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Добавить бонус',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ребенок: ${childData['name']}',
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Сумма (₽)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Комментарий',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.comment),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Отмена',
              style: GoogleFonts.nunito(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              final comment = commentController.text.trim();
              
              if (amount > 0 && comment.isNotEmpty) {
                try {
                  await _analyticsService.addBonus(
                    childData['id'],
                    amount,
                    comment,
                    widget.parentKey,
                  );
                  Navigator.of(context).pop();
                  _loadChildrenData(); // Refresh data
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Бонус успешно добавлен!',
                        style: GoogleFonts.nunito(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ошибка при добавлении бонуса',
                        style: GoogleFonts.nunito(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Добавить',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyRateDialog(Map<String, dynamic> childData) {
    final rateController = TextEditingController(
      text: (childData['dailyRate'] * 365 * 100).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Настройки процентной ставки',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ребенок: ${childData['name']}',
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Годовая ставка (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.percent),
                helperText: 'Текущая: ${(childData['dailyRate'] * 365 * 100).toStringAsFixed(2)}%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Отмена',
              style: GoogleFonts.nunito(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final annualRate = double.tryParse(rateController.text) ?? 0;
              final dailyRate = annualRate / 365 / 100;
              
              if (annualRate >= 0) {
                try {
                  await _analyticsService.updateDailyRate(
                    childData['id'],
                    dailyRate,
                  );
                  Navigator.of(context).pop();
                  _loadChildrenData(); // Refresh data
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ставка успешно обновлена!',
                        style: GoogleFonts.nunito(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ошибка при обновлении ставки',
                        style: GoogleFonts.nunito(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Сохранить',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> childData) {
    final activeGoal = childData['activeGoal'] as Map<String, dynamic>?;
    final progress = activeGoal != null 
        ? (activeGoal['progress'] / activeGoal['target']).clamp(0, 1).toDouble()
        : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child name and settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    childData['name'],
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'add_bonus') {
                      _showAddBonusDialog(childData);
                    } else if (value == 'settings') {
                      _showDailyRateDialog(childData);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_bonus',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Добавить бонус'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Настройки'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Balance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Баланс',
                    style: GoogleFonts.nunito(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${childData['balance'].toInt()} ₽',
                    style: GoogleFonts.nunito(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Goal progress
            if (activeGoal != null) ...[
              Text(
                'Текущая цель',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activeGoal['name'],
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${activeGoal['progress'].toInt()} ₽',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Нет активной цели',
                    style: GoogleFonts.nunito(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Цели',
                  '${childData['completedGoals']}/${childData['totalGoals']}',
                  Icons.flag,
                  Colors.green,
                ),
                _buildStatItem(
                  'Ставка',
                  '${(childData['dailyRate'] * 365 * 100).toStringAsFixed(2)}%',
                  Icons.percent,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: color,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddChildButton({EdgeInsetsGeometry? padding, double fontSize = 14}) {
    return ElevatedButton.icon(
      onPressed: _addChild,
      icon: const Icon(Icons.person_add_alt_1, size: 18),
      label: Text(
        'Добавить ребенка',
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
       backgroundColor: Colors.transparent,
       elevation: 0,
       centerTitle: true,
       title: Text(
         'Кабинет родителя',
         style: GoogleFonts.nunito(
           fontWeight: FontWeight.bold,
           color: Colors.black87,
         ),
       ),
       iconTheme: const IconThemeData(color: Colors.black),
       actions: [
         PopupMenuButton<String>(
           onSelected: (value) {
             if (value == 'change_pin') {
               _changePIN();
             } else if (value == 'logout') {
               _logout();
             }
           },
           itemBuilder: (context) => [
             PopupMenuItem(
               value: 'change_pin',
               child: Row(
                 children: [
                   const Icon(Icons.lock, color: Colors.blue),
                   const SizedBox(width: 8),
                   Text(
                     'Изменить PIN',
                     style: GoogleFonts.nunito(),
                   ),
                 ],
               ),
             ),
             PopupMenuItem(
               value: 'logout',
               child: Row(
                 children: [
                   const Icon(Icons.logout, color: Colors.red),
                   const SizedBox(width: 8),
                   Text(
                     'Выход',
                     style: GoogleFonts.nunito(),
                   ),
                 ],
               ),
             ),
           ],
         ),
       ],
      ),
      body: Column(
        children: [
          // Welcome message
          Container(
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
            child: Row(
              children: [
                Icon(Icons.family_restroom, color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Добро пожаловать!',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.parentName,
                        style: GoogleFonts.nunito(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_childrenData.length} ${_getChildrenWord(_childrenData.length)}',
                    style: GoogleFonts.nunito(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.orange,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Text(
                    'Дети',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
                Tab(
                  child: Text(
                    'Аналитика',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
                Tab(
                  child: Text(
                    'История',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Children tab
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _childrenData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.child_care,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Нет подключенных детей',
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildAddChildButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  fontSize: 16,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ваши дети',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    _buildAddChildButton(),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 280,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _childrenData.length,
                                  itemBuilder: (context, index) {
                                    return _buildChildCard(_childrenData[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                
                // Analytics tab
                AnalyticsScreen(
                  parentKey: widget.parentKey,
                  childrenData: _childrenData,
                ),
                
                // History tab
                OperationHistoryScreen(
                  parentKey: widget.parentKey,
                  childrenData: _childrenData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChildrenWord(int count) {
    if (count == 1) return 'ребенок';
    if (count >= 2 && count <= 4) return 'ребенка';
    return 'детей';
  }
}