import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/share_helper.dart';
import '../menu/menu_screen.dart';
import '../menu/menu_service.dart';
import '../menu_costing/menu_costing_overview_screen.dart';
import '../inventory/inventory_screen.dart';
import '../inventory/inventory_service.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../ai/ai_assistant_sheet.dart';
import '../../data/models/menu_models.dart';
import '../../data/models/inventory_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MenuService _menuService = MenuService();
  final InventoryService _inventoryService = InventoryService();

  List<MenuItem> _menuItems = [];
  List<InventoryItem> _inventoryItems = [];
  
  bool _isLoading = true;
  int _lowStockThreshold = 5;

  @override
  void initState() {
    super.initState();
    _loadConfigAndData();
  }

  Future<void> _loadConfigAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lowStockThreshold = prefs.getInt('low_stock_threshold') ?? 5;
    });
    await _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _menuService.fetchMenuItems(),
        _inventoryService.fetchItems(),
        _inventoryService.fetchCategories(),
      ]);

      setState(() {
        _menuItems = results[0] as List<MenuItem>;
        _inventoryItems = results[1] as List<InventoryItem>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync data with server.')),
        );
      }
    }
  }

  void _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showThresholdSettings() {
    showDialog(
      context: context,
      builder: (context) {
        int tempThreshold = _lowStockThreshold;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Dashboard Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Low Stock Alert Threshold:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$tempThreshold units',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: tempThreshold > 1
                                ? () => setDialogState(() => tempThreshold--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          IconButton(
                            onPressed: () => setDialogState(() => tempThreshold++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: tempThreshold.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '$tempThreshold',
                    onChanged: (val) {
                      setDialogState(() {
                        tempThreshold = val.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('low_stock_threshold', tempThreshold);
                    setState(() {
                      _lowStockThreshold = tempThreshold;
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Settings'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Refactored to core helper

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute metrics
    final activeMenuCount = _menuItems.where((item) => item.status == 'active').length;
    final outOfStockCount = _inventoryItems.where((item) => item.quantity == 0).length;
    final lowStockCount = _inventoryItems.where((item) => item.quantity > 0 && item.quantity <= _lowStockThreshold).length;
    
    final costingApprovedCount = _menuItems.where((item) => item.costingStatus == 'approved').length;
    final double costingCoverage = _menuItems.isEmpty 
        ? 0.0 
        : (costingApprovedCount / _menuItems.length) * 100;

    final activeMenuItemsList = _menuItems.where((item) => item.status == 'active').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viral Bytes Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _showThresholdSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => _logout(context),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('Viral Bytes Operations', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('Console Operator', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: true,
              selectedColor: const Color(0xFF4F46E5),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Manage Menu'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Inventory & Stock'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Menu Costing'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuCostingOverviewScreen()));
              },
            ),
            if (Theme.of(context).platform == TargetPlatform.android) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share App'),
                onTap: () {
                  Navigator.pop(context);
                  shareAppApk(context);
                },
              ),
            ],
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Welcome Banner ---
                    Text(
                      'Welcome Back, Operator',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your operations summary sync. Low Stock Threshold is set to $_lowStockThreshold units.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // --- KPI Grid ---
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      childAspectRatio: 1.45,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildKpiCard(
                          title: 'Active Menu',
                          value: '$activeMenuCount items',
                          icon: Icons.restaurant_rounded,
                          color: const Color(0xFF4F46E5),
                          subtitle: 'Items serving customers',
                        ),
                        _buildKpiCard(
                          title: 'Out of Stock',
                          value: '$outOfStockCount items',
                          icon: Icons.dangerous_outlined,
                          color: outOfStockCount > 0 ? const Color(0xFFEF4444) : Colors.green,
                          subtitle: 'Require immediate reorder',
                        ),
                        _buildKpiCard(
                          title: 'Low Stock Alert',
                          value: '$lowStockCount items',
                          icon: Icons.warning_amber_rounded,
                          color: lowStockCount > 0 ? Colors.orange : Colors.grey.shade600,
                          subtitle: 'Below $_lowStockThreshold units',
                        ),
                        _buildKpiCard(
                          title: 'Costing Coverage',
                          value: '${costingCoverage.toStringAsFixed(0)}%',
                          icon: Icons.task_alt_outlined,
                          color: costingCoverage >= 80 ? Colors.green : const Color(0xFF0EA5E9),
                          subtitle: '$costingApprovedCount of ${_menuItems.length} approved',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- Active Menu Table List Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Active Menu Table',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${activeMenuItemsList.length}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen()));
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (activeMenuItemsList.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No active menu items available currently.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeMenuItemsList.length,
                        itemBuilder: (context, index) {
                          final item = activeMenuItemsList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Row(
                                  children: [
                                    _buildCostingStatusBadge(item.costingStatus),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.unitQuantity} ${item.unitType}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  if (item.costingStatus == 'approved' && item.servingPrice != null)
                                    Text(
                                      'Serv: ₹${item.servingPrice!.toStringAsFixed(0)} | Del: ₹${item.deliveryPrice!.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MenuCostingOverviewScreen()),
                                );
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AIAssistantSheet(),
          );
        },
        tooltip: 'Ask AI Copilot',
        child: const Icon(Icons.psychology),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.0, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostingStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String displayLabel = status.toUpperCase();

    switch (status) {
      case 'approved':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case 'complete':
        bgColor = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0369A1);
        break;
      case 'draft':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        displayLabel = 'NONE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        displayLabel,
        style: TextStyle(
          fontSize: 9.0,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
