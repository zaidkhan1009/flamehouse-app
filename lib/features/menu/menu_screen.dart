import 'package:flutter/material.dart';
import 'menu_service.dart';
import 'menu_form_screen.dart';
import '../../data/models/menu_models.dart';
import '../ai/ai_assistant_sheet.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuService _menuService = MenuService();
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    final items = await _menuService.fetchMenuItems();
    setState(() {
      _menuItems = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Ask AI Copilot',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AIAssistantSheet(),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMenu,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.unitQuantity} ${item.unitType} | Costing: ${item.costingStatus.toUpperCase()}'),
                      trailing: Text('₹${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MenuFormScreen(item: item)),
                        );
                        if (result == true) {
                          _loadMenu();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuFormScreen()),
          );
          if (result == true) {
            _loadMenu();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
