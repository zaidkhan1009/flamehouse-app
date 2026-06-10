import 'package:flutter/material.dart';
import '../../data/models/inventory_models.dart';
import 'inventory_service.dart';
import 'category_form_sheet.dart';
import 'inventory_form_sheet.dart';
import '../ai/ai_assistant_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final InventoryService _inventoryService = InventoryService();

  List<InventoryItem> _items = [];
  List<InventoryCategory> _categories = [];
  
  bool _isLoadingItems = true;
  bool _isLoadingCategories = true;
  
  String _itemSearchQuery = '';
  String _categorySearchQuery = '';
  
  int? _selectedCategoryFilterId; // null means 'All'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Re-trigger FAB updates or other state adjustments on tab changes
      setState(() {});
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadItems(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadItems() async {
    setState(() => _isLoadingItems = true);
    final items = await _inventoryService.fetchItems();
    setState(() {
      _items = items;
      _isLoadingItems = false;
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    final categories = await _inventoryService.fetchCategories();
    setState(() {
      _categories = categories;
      _isLoadingCategories = false;
    });
  }

  // --- Category Operations ---
  void _openCategoryForm([InventoryCategory? category]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => CategoryFormSheet(
        category: category,
        onSubmit: (name, description) async {
          if (category == null) {
            final newCategory = await _inventoryService.createCategory(name, description);
            return newCategory != null;
          } else {
            return await _inventoryService.updateCategory(category.id, name, description);
          }
        },
      ),
    );

    if (result == true) {
      _loadAllData(); // Reload both since items display category names
    }
  }

  void _deleteCategory(InventoryCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"? Items using this category will be updated to "No Category".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _inventoryService.deleteCategory(category.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "${category.name}" deleted')),
          );
        }
        _loadAllData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete category')),
          );
        }
      }
    }
  }

  // --- Item Operations ---
  void _openItemForm([InventoryItem? item]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => InventoryFormSheet(
        item: item,
        categories: _categories,
        onSubmit: (name, quantity, inventoryTypeId) async {
          if (item == null) {
            final newItem = await _inventoryService.createItem(name, quantity, inventoryTypeId);
            return newItem != null;
          } else {
            return await _inventoryService.updateItem(item.id, name, quantity, inventoryTypeId);
          }
        },
      ),
    );

    if (result == true) {
      _loadItems();
    }
  }

  void _deleteItem(InventoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _inventoryService.deleteItem(item.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item "${item.name}" deleted')),
          );
        }
        _loadItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete item')),
          );
        }
      }
    }
  }

  // --- Getters for Filtered Lists ---
  List<InventoryItem> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_itemSearchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilterId == null || item.inventoryTypeId == _selectedCategoryFilterId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<InventoryCategory> get _filteredCategories {
    return _categories.where((category) {
      return category.name.toLowerCase().contains(_categorySearchQuery.toLowerCase()) ||
          (category.description?.toLowerCase().contains(_categorySearchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCategoryTab = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Stock Items'),
            Tab(icon: Icon(Icons.category), text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemsTab(theme),
          _buildCategoriesTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isCategoryTab ? () => _openCategoryForm() : () => _openItemForm(),
        tooltip: isCategoryTab ? 'Add Category' : 'Add Stock Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- UI Builders ---
  Widget _buildItemsTab(ThemeData theme) {
    if (_isLoadingItems) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search & Filter Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                onChanged: (value) {
                  setState(() {
                    _itemSearchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12.0),
              // Category chips filter
              SizedBox(
                height: 40.0,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: _selectedCategoryFilterId == null,
                        label: const Text('All'),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategoryFilterId = null);
                          }
                        },
                      ),
                    ),
                    ..._categories.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          selected: _selectedCategoryFilterId == c.id,
                          label: Text(c.name),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryFilterId = selected ? c.id : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            child: _filteredItems.isEmpty
                ? _buildEmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: _items.isEmpty
                        ? 'No items found. Tap "+" to add one!'
                        : 'No items match your filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isOutOfStock = item.quantity == 0;
                      final isLowStock = !isOutOfStock && item.quantity <= 5;
                      
                      Color quantityColor = Colors.green;
                      String stockText = 'In Stock';
                      if (isOutOfStock) {
                        quantityColor = Colors.red;
                        stockText = 'Out of Stock';
                      } else if (isLowStock) {
                        quantityColor = Colors.orange;
                        stockText = 'Low Stock';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  item.inventoryType?.name ?? 'No Category',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: quantityColor,
                                    ),
                                  ),
                                  Text(
                                    stockText,
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      color: quantityColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8.0),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openItemForm(item);
                                  } else if (value == 'delete') {
                                    _deleteItem(item);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
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
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(ThemeData theme) {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search categories...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
            onChanged: (value) {
              setState(() {
                _categorySearchQuery = value;
              });
            },
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            child: _filteredCategories.isEmpty
                ? _buildEmptyState(
                    icon: Icons.category_outlined,
                    message: _categories.isEmpty
                        ? 'No categories found. Tap "+" to add one!'
                        : 'No categories match your search.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          subtitle: category.description != null && category.description!.isNotEmpty
                              ? Text(category.description!)
                              : const Text('No description', style: TextStyle(fontStyle: FontStyle.italic)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openCategoryForm(category);
                              } else if (value == 'delete') {
                                _deleteCategory(category);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64.0, color: Colors.grey.shade400),
              const SizedBox(height: 16.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
