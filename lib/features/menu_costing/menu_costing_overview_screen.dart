import 'package:flutter/material.dart';
import 'menu_costing_service.dart';
import '../../data/models/menu_models.dart';
import 'menu_costing_wizard_screen.dart';

class MenuCostingOverviewScreen extends StatefulWidget {
  const MenuCostingOverviewScreen({super.key});

  @override
  State<MenuCostingOverviewScreen> createState() => _MenuCostingOverviewScreenState();
}

class _MenuCostingOverviewScreenState extends State<MenuCostingOverviewScreen> {
  final MenuCostingService _costingService = MenuCostingService();
  List<MenuCostingOverviewItem> _items = [];
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    final items = await _costingService.fetchOverview();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _startCosting(MenuCostingOverviewItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuCostingWizardScreen(
          menuItemId: item.menuItemId,
          menuItemName: item.menuItemName,
          costingId: item.costingId,
        ),
      ),
    );
    if (result == true) {
      _loadOverview();
    }
  }

  void _approveCosting(MenuCostingOverviewItem item) async {
    if (item.costingId == null) return;
    
    setState(() => _isActionLoading = true);
    final result = await _costingService.approveCosting(item.costingId!);
    setState(() => _isActionLoading = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Costing approved for ${item.menuItemName}! Menu updated: Serving ₹${result['serving_price']}, Delivery ₹${result['delivery_price']}',
          ),
          backgroundColor: Colors.green.shade800,
        ),
      );
      _loadOverview();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve costing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Costing Wizard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOverview,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOverview,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Section: Title & Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.menuItemName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Current Menu Price: ₹${item.currentMenuPrice.toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0),
                                    ),
                                  ],
                                ),
                              ),
                              _buildCostingStatusBadge(item.costingStatus, item.stepsComplete),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),

                          // Middle Section: Calculation summary if exists
                          if (item.servingPrice != null || item.deliveryPrice != null) ...[
                            Row(
                              children: [
                                if (item.servingPrice != null)
                                  Expanded(
                                    child: _buildPriceBox(
                                      label: 'Serving Price (Recommended)',
                                      value: '₹${item.servingPrice!.toStringAsFixed(2)}',
                                      color: const Color(0xFF4F46E5),
                                    ),
                                  ),
                                if (item.servingPrice != null && item.deliveryPrice != null)
                                  const SizedBox(width: 12.0),
                                if (item.deliveryPrice != null)
                                  Expanded(
                                    child: _buildPriceBox(
                                      label: 'Delivery Price (Recommended)',
                                      value: '₹${item.deliveryPrice!.toStringAsFixed(2)}',
                                      color: const Color(0xFF0EA5E9),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                          ] else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No costing step information saved yet.',
                                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 13.0),
                              ),
                            ),

                          // Bottom Section: Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Edit / Start costing
                              OutlinedButton.icon(
                                onPressed: _isActionLoading ? null : () => _startCosting(item),
                                icon: Icon(item.costingStatus == 'none' ? Icons.play_arrow_rounded : Icons.edit_note_rounded),
                                label: Text(item.costingStatus == 'none' ? 'Start Costing' : 'Edit Steps'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              
                              // Approve Costing action
                              if (item.stepsComplete == 4 && item.costingId != null)
                                ElevatedButton.icon(
                                  onPressed: _isActionLoading ? null : () => _approveCosting(item),
                                  icon: Icon(item.costingStatus == 'approved' ? Icons.check_circle : Icons.offline_pin_outlined),
                                  label: Text(item.costingStatus == 'approved' ? 'Re-Approve' : 'Approve & Apply'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: item.costingStatus == 'approved' ? Colors.green.shade600 : const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildPriceBox({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4.0),
          Text(value, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCostingStatusBadge(String status, int steps) {
    Color bgColor;
    Color textColor;
    String labelText;

    switch (status) {
      case 'approved':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        labelText = 'APPROVED';
        break;
      case 'complete':
        bgColor = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0369A1);
        labelText = 'COMPLETE';
        break;
      case 'draft':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        labelText = 'DRAFT ($steps/4)';
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        labelText = 'NOT STARTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        labelText,
        style: TextStyle(
          fontSize: 10.0,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
