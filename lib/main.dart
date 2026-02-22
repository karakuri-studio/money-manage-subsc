import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ShikakeApp());
}

// ─── テーマカラー定義 ───
class AppColors {
  static const sumi = Color(0xFF090806);
  static const sumi2 = Color(0xFF14120E);
  static const sumi3 = Color(0xFF1F1C16);
  static const washi = Color(0xFFF4EDD8);
  static const washi2 = Color(0xFFD8CEBC);
  static const kin = Color(0xFFC9A84C);
  static const kin2 = Color(0xFFE8C56A);
  static const beni = Color(0xFFC0392B);
  static const gin = Color(0xFF7A8480);
  static const midori = Color(0xFF4CAF88);
  static const border = Color(0x22C9A84C);
}

// ─── データモデル ───
class Subscription {
  final String id;
  final String name;
  final double amount;
  final String cycle;
  final DateTime date;
  final String icon;
  bool active;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.cycle,
    required this.date,
    required this.icon,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'cycle': cycle,
    'date': date.toIso8601String(),
    'icon': icon,
    'active': active,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      cycle: json['cycle'],
      date: DateTime.parse(json['date']),
      icon: json['icon'],
      active: json['active'] ?? true,
    );
  }
}

// ─── メインアプリ ───
class ShikakeApp extends StatelessWidget {
  const ShikakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '仕掛け帳',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.sumi,
        primaryColor: AppColors.kin,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.kin,
          surface: AppColors.sumi2,
          onSurface: AppColors.washi,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.notoSansJp().fontFamily,
      ),
      home: const MainScreen(),
    );
  }
}

// ─── メイン画面 ───
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<Subscription> _subs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('karakuri_subs_data');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        _subs = jsonList.map((e) => Subscription.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _subs = _defaultSubs();
        _isLoading = false;
      });
      _saveData();
    }
  }

  List<Subscription> _defaultSubs() => [
    Subscription(
      id: '1',
      name: 'Netflix',
      amount: 15.99,
      cycle: 'mo',
      date: DateTime(2026, 2, 22),
      icon: '🎬',
    ),
    Subscription(
      id: '2',
      name: 'Spotify',
      amount: 9.99,
      cycle: 'mo',
      date: DateTime(2026, 2, 28),
      icon: '🎵',
    ),
    Subscription(
      id: '3',
      name: 'Amazon Prime',
      amount: 139.0,
      cycle: 'yr',
      date: DateTime(2026, 6, 10),
      icon: '📦',
    ),
  ];

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_subs.map((e) => e.toJson()).toList());
    await prefs.setString('karakuri_subs_data', data);
  }

  void _addSubscription(Subscription sub) {
    setState(() => _subs.add(sub));
    _saveData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '仕掛けを追加しました: ${sub.name}',
          style: const TextStyle(color: AppColors.sumi),
        ),
        backgroundColor: AppColors.kin,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteSubscription(String id) {
    setState(() => _subs.removeWhere((s) => s.id == id));
    _saveData();
  }

  void _toggleActive(String id) {
    setState(() {
      final index = _subs.indexWhere((s) => s.id == id);
      if (index != -1) _subs[index].active = !_subs[index].active;
    });
    _saveData();
  }

  void _resetData() {
    setState(() => _subs = _defaultSubs());
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(subs: _subs),
      ListScreen(
        subs: _subs,
        onDelete: _deleteSubscription,
        onToggle: _toggleActive,
        onReset: _resetData,
      ),
      AddScreen(
        onAdd: (sub) {
          _addSubscription(sub);
          setState(() => _currentIndex = 0);
        },
      ),
      InsightsScreen(subs: _subs),
      CalendarScreen(subs: _subs),
    ];

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kin))
          : IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x22C9A84C))),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xE6090806),
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.kin,
          unselectedItemColor: AppColors.gin,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.shipporiMinchoB1(
            fontSize: 10,
            letterSpacing: 1,
          ),
          unselectedLabelStyle: GoogleFonts.shipporiMinchoB1(
            fontSize: 10,
            letterSpacing: 1,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'LIST'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 32),
              activeIcon: Icon(Icons.add_circle, size: 32),
              label: 'ADD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'DATA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'CAL',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 1. HOME SCREEN ───
class HomeScreen extends StatefulWidget {
  final List<Subscription> subs;
  const HomeScreen({super.key, required this.subs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _period = 'mo';

  @override
  Widget build(BuildContext context) {
    final activeSubs = widget.subs.where((s) => s.active).toList();

    double totalMonthly = 0;
    for (var s in activeSubs) {
      totalMonthly += s.cycle == 'yr' ? s.amount / 12 : s.amount;
    }
    double displayTotal = _period == 'mo' ? totalMonthly : totalMonthly * 12;

    final now = DateTime.now();
    final upcoming = activeSubs.map((s) {
      DateTime nextDate;
      if (s.cycle == 'mo') {
        nextDate = DateTime(now.year, now.month, s.date.day);
        if (nextDate.isBefore(DateTime(now.year, now.month, now.day))) {
          nextDate = DateTime(now.year, now.month + 1, s.date.day);
        }
      } else {
        nextDate = DateTime(now.year, s.date.month, s.date.day);
        if (nextDate.isBefore(DateTime(now.year, now.month, now.day))) {
          nextDate = DateTime(now.year + 1, s.date.month, s.date.day);
        }
      }
      return {
        'sub': s,
        'nextDate': nextDate,
        'days': nextDate.difference(now).inDays,
      };
    }).toList()..sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Header(title: '仕掛け帳', subtitle: 'OVERVIEW'),
            const SizedBox(height: 16),
            Row(
              children: [
                _PeriodBtn(
                  label: 'Monthly',
                  isActive: _period == 'mo',
                  onTap: () => setState(() => _period = 'mo'),
                ),
                const SizedBox(width: 10),
                _PeriodBtn(
                  label: 'Yearly',
                  isActive: _period == 'yr',
                  onTap: () => setState(() => _period = 'yr'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.sumi3, AppColors.sumi2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL COST',
                    style: GoogleFonts.shipporiMinchoB1(
                      color: AppColors.gin,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        r'$',
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.kin,
                          fontSize: 28,
                        ),
                      ),
                      Text(
                        displayTotal.toStringAsFixed(2),
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.washi,
                          fontSize: 56,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/$_period',
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.gin,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Coming Up'),
            SizedBox(
              height: 140,
              child: upcoming.isEmpty
                  ? const Center(
                      child: Text(
                        "No upcoming payments",
                        style: TextStyle(color: AppColors.gin),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: upcoming.length > 5 ? 5 : upcoming.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) {
                        final item = upcoming[i];
                        final sub = item['sub'] as Subscription;
                        final days = item['days'] as int;
                        final isUrgent = days < 5;
                        return Container(
                          width: 130,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUrgent
                                ? AppColors.beni.withOpacity(0.1)
                                : AppColors.sumi2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUrgent
                                  ? AppColors.beni.withOpacity(0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const Spacer(),
                              Text(
                                sub.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cormorantGaramond(
                                  color: AppColors.washi,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isUrgent
                                    ? (days == 0 ? 'Today' : '$days days')
                                    : DateFormat(
                                        'MMM d',
                                      ).format(item['nextDate'] as DateTime),
                                style: GoogleFonts.shipporiMinchoB1(
                                  color: isUrgent
                                      ? AppColors.beni
                                      : AppColors.gin,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${sub.amount}',
                                style: GoogleFonts.cormorantGaramond(
                                  color: AppColors.kin2,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Active Subs'),
            if (activeSubs.isEmpty)
              const Center(
                child: Text(
                  "No active subscriptions",
                  style: TextStyle(color: AppColors.gin),
                ),
              )
            else
              ...activeSubs
                  .take(3)
                  .map((s) => SubListItem(sub: s, readOnly: true)),
          ],
        ),
      ),
    );
  }
}

// ─── 2. LIST SCREEN ───
class ListScreen extends StatefulWidget {
  final List<Subscription> subs;
  final Function(String) onDelete;
  final Function(String) onToggle;
  final VoidCallback onReset;

  const ListScreen({
    super.key,
    required this.subs,
    required this.onDelete,
    required this.onToggle,
    required this.onReset,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  bool _isEdit = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Header(
                    title: '登録一覧',
                    subtitle: 'ALL ITEMS',
                    padding: EdgeInsets.zero,
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isEdit = !_isEdit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isEdit ? AppColors.kin : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: _isEdit ? AppColors.kin.withOpacity(0.1) : null,
                      ),
                      child: Text(
                        _isEdit ? 'Done' : 'Edit',
                        style: GoogleFonts.shipporiMinchoB1(
                          color: _isEdit ? AppColors.kin : AppColors.gin,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.subs.isEmpty
                  ? const Center(
                      child: Text(
                        "List is empty",
                        style: TextStyle(color: AppColors.gin),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.subs.length,
                      itemBuilder: (ctx, i) => SubListItem(
                        sub: widget.subs[i],
                        isEdit: _isEdit,
                        onDelete: () => _confirmDelete(context, widget.subs[i]),
                        onTap: () => widget.onToggle(widget.subs[i].id),
                      ),
                    ),
            ),
            if (widget.subs.isNotEmpty)
              TextButton(
                onPressed: () => _confirmReset(context),
                child: Text(
                  'Reset Demo Data',
                  style: GoogleFonts.shipporiMinchoB1(
                    color: AppColors.gin,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.gin,
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Subscription sub) {
    showDialog(
      context: context,
      builder: (_) => CustomDialog(
        title: 'Delete?',
        desc: 'This mechanism will be removed.',
        onConfirm: () => widget.onDelete(sub.id),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomDialog(
        title: 'Reset?',
        desc: 'All data will be reset to default.',
        onConfirm: widget.onReset,
      ),
    );
  }
}

// ─── 3. ADD SCREEN ───
class AddScreen extends StatefulWidget {
  final Function(Subscription) onAdd;
  const AddScreen({super.key, required this.onAdd});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _icons = [
    '🎬',
    '🎵',
    '☁️',
    '📱',
    '💻',
    '🏋️',
    '🎮',
    '🍔',
    '💡',
    '🔧',
    '🧠',
    '🎨',
  ];
  String _selectedIcon = '🎬';
  String _cycle = 'mo';
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();

  void _submit() {
    final name = _nameController.text;
    final amount = double.tryParse(_amountController.text);
    if (name.isEmpty || amount == null) return;

    final newSub = Subscription(
      id: (DateTime.now().millisecondsSinceEpoch + Random().nextInt(1000))
          .toString(),
      name: name,
      amount: amount,
      cycle: _cycle,
      date: _date,
      icon: _selectedIcon,
    );

    widget.onAdd(newSub);

    _nameController.clear();
    _amountController.clear();
    setState(() {
      _cycle = 'mo';
      _selectedIcon = '🎬';
      _date = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Header(
              title: '新規追加',
              subtitle: 'NEW ENTRY',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            Text('ICON', style: _labelStyle),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _icons.length,
              itemBuilder: (ctx, i) {
                final icon = _icons[i];
                final isSel = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.kin.withOpacity(0.2)
                          : AppColors.sumi2,
                      border: Border.all(
                        color: isSel ? AppColors.kin : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildTextField('NAME', _nameController, 'Service Name'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    'AMOUNT',
                    _amountController,
                    '0.00',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CYCLE', style: _labelStyle),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.sumi2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _cycle,
                            dropdownColor: AppColors.sumi2,
                            isExpanded: true,
                            style: GoogleFonts.cormorantGaramond(
                              color: AppColors.washi,
                              fontSize: 18,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'mo',
                                child: Text('Monthly'),
                              ),
                              DropdownMenuItem(
                                value: 'yr',
                                child: Text('Yearly'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _cycle = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('BILLING DATE', style: _labelStyle),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.kin,
                        onPrimary: AppColors.sumi,
                        surface: AppColors.sumi2,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sumi2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  DateFormat('yyyy/MM/dd').format(_date),
                  style: GoogleFonts.cormorantGaramond(
                    color: AppColors.washi,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kin,
                foregroundColor: AppColors.sumi,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ADD MECHANISM',
                style: GoogleFonts.notoSansJp(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.washi,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.gin.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.sumi2,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kin),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle get _labelStyle => GoogleFonts.shipporiMinchoB1(
    color: AppColors.kin,
    fontSize: 10,
    letterSpacing: 2,
  );
}

// ─── 4. INSIGHTS SCREEN ───
class InsightsScreen extends StatelessWidget {
  final List<Subscription> subs;
  const InsightsScreen({super.key, required this.subs});

  @override
  Widget build(BuildContext context) {
    final activeSubs = subs.where((s) => s.active).toList();
    double total = 0;
    for (var s in activeSubs) {
      total += s.cycle == 'yr' ? s.amount / 12 : s.amount;
    }

    final sorted = List<Subscription>.from(activeSubs)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Header(
                title: '分析',
                subtitle: 'ANALYSIS',
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: DonutChartPainter(total: total),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${total.toStringAsFixed(0)}',
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.washi,
                          fontSize: 42,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Monthly',
                        style: GoogleFonts.shipporiMinchoB1(
                          color: AppColors.gin,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sorted.length,
                itemBuilder: (ctx, i) =>
                    SubListItem(sub: sorted[i], readOnly: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 5. CALENDAR SCREEN ───
class CalendarScreen extends StatelessWidget {
  final List<Subscription> subs;
  const CalendarScreen({super.key, required this.subs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7;

    const monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    final calSubs = subs.where((s) {
      if (!s.active) return false;
      if (s.cycle == 'mo') return true;
      return s.date.month == month;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Header(
                title: '支払い暦',
                subtitle: 'SCHEDULE',
                padding: EdgeInsets.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Text(
                '${monthNames[month - 1]} $year',
                style: GoogleFonts.shipporiMinchoB1(color: AppColors.gin),
              ),
            ),
            // 曜日ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: GoogleFonts.shipporiMinchoB1(
                              color: AppColors.gin,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 4),
            // カレンダーグリッド（高さを固定）
            SizedBox(
              height: 210,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 42,
                  itemBuilder: (ctx, i) {
                    if (i < firstWeekday || i >= firstWeekday + daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final day = i - firstWeekday + 1;
                    final isToday = day == now.day;
                    final hasPay = calSubs.any((s) => s.date.day == day);

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.sumi2,
                        borderRadius: BorderRadius.circular(4),
                        border: isToday
                            ? Border.all(color: AppColors.kin)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.cormorantGaramond(
                              color: isToday ? AppColors.kin : AppColors.washi2,
                              fontSize: 11,
                            ),
                          ),
                          if (hasPay)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.beni,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader(title: 'This Month'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: calSubs
                    .map((s) => SubListItem(sub: s, readOnly: true))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS ───

class Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final EdgeInsets padding;
  const Header({
    super.key,
    required this.title,
    required this.subtitle,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: GoogleFonts.shipporiMinchoB1(
              color: AppColors.kin,
              fontSize: 10,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.shipporiMinchoB1(
              color: AppColors.washi,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.shipporiMinchoB1(
              color: AppColors.kin,
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 1,
            color: AppColors.border,
          ),
        ],
      ),
    );
  }
}

class SubListItem extends StatelessWidget {
  final Subscription sub;
  final bool readOnly;
  final bool isEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SubListItem({
    super.key,
    required this.sub,
    this.readOnly = false,
    this.isEdit = false,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sumi2,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: sub.active ? 1.0 : 0.5,
                    child: Text(sub.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: GoogleFonts.cormorantGaramond(
                          color: sub.active ? AppColors.washi : AppColors.gin,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sub.cycle == 'mo' ? 'Monthly' : 'Yearly'} • ${DateFormat('MM/dd').format(sub.date)}',
                        style: GoogleFonts.shipporiMinchoB1(
                          color: AppColors.gin,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isEdit ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${sub.amount}',
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.kin2,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sub.active
                                  ? AppColors.midori
                                  : AppColors.gin,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sub.active ? 'Active' : 'Paused',
                            style: GoogleFonts.shipporiMinchoB1(
                              color: AppColors.gin,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isEdit)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.beni,
                    ),
                    onPressed: onDelete,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _PeriodBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.kin : AppColors.border,
          ),
          color: isActive ? AppColors.kin.withOpacity(0.15) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.shipporiMinchoB1(
            color: isActive ? AppColors.kin2 : AppColors.gin,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class CustomDialog extends StatelessWidget {
  final String title;
  final String desc;
  final VoidCallback onConfirm;
  const CustomDialog({
    super.key,
    required this.title,
    required this.desc,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.sumi2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                color: AppColors.washi,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: GoogleFonts.notoSansJp(color: AppColors.gin, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.gin),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.beni,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DONUT CHART PAINTER ───
class DonutChartPainter extends CustomPainter {
  final double total;
  DonutChartPainter({required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 20.0;

    final bgPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = (min(total, 500) / 500) * 2 * pi;

    final fgPaint = Paint()
      ..color = AppColors.kin
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
