import 'package:flutter/material.dart';
import '../../data/models/menu_models.dart';
import 'menu_service.dart';

class MenuFormScreen extends StatefulWidget {
  final MenuItem? item;

  const MenuFormScreen({super.key, this.item});

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuService _menuService = MenuService();

  late final TextEditingController _nameController;
  late final TextEditingController _unitQuantityController;
  late final TextEditingController _priceController;
  
  String _selectedUnitType = 'portion';
  String _selectedStatus = 'active';
  
  bool _isSaving = false;
  
  // Keep track of the active menu item id (from widget or created dynamically)
  int? _menuItemId;
  List<MenuVariant> _variants = [];
  bool _isLoadingVariants = false;

  final List<String> _unitTypes = ['portion', 'pcs', 'gm', 'ml', 'kg', 'plate', 'box'];
  final List<String> _statuses = ['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _unitQuantityController = TextEditingController(text: widget.item?.unitQuantity ?? '1');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '0');
    
    if (widget.item != null) {
      _menuItemId = widget.item!.id;
      _selectedStatus = widget.item!.status;
      if (_unitTypes.contains(widget.item!.unitType)) {
        _selectedUnitType = widget.item!.unitType;
      } else {
        _selectedUnitType = _unitTypes.first;
      }
      _loadVariants();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitQuantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadVariants() async {
    if (_menuItemId == null) return;
    setState(() => _isLoadingVariants = true);
    final variants = await _menuService.fetchVariants(_menuItemId!);
    setState(() {
      _variants = variants;
      _isLoadingVariants = false;
    });
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final unitQuantity = _unitQuantityController.text.trim();
    final price = double.parse(_priceController.text.trim());

    bool success;
    if (_menuItemId == null) {
      final newItem = await _menuService.createMenuItem(
        name: name,
        unitType: _selectedUnitType,
        unitQuantity: unitQuantity,
        price: price,
        status: _selectedStatus,
      );
      success = newItem != null;
      if (newItem != null) {
        _menuItemId = newItem.id;
      }
    } else {
      success = await _menuService.updateMenuItem(
        id: _menuItemId!,
        name: name,
        unitType: _selectedUnitType,
        unitQuantity: unitQuantity,
        price: price,
        status: _selectedStatus,
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.item == null ? 'Menu item created successfully!' : 'Menu item updated!')),
      );
      
      // If we just created the item, we stay on the screen in Edit mode so they can add variants.
      // Otherwise, we pop back.
      if (widget.item == null) {
        setState(() {}); // Refreshes to show Variants manager since _menuItemId is now not null
        _loadVariants();
      } else {
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save menu item')),
      );
    }
  }

  // --- Variant Dialogs & CRUD ---
  void _openVariantDialog([MenuVariant? variant]) async {
    if (_menuItemId == null) return;

    final nameController = TextEditingController(text: variant?.variantName ?? '');
    final servingPriceController = TextEditingController(text: variant?.servingPrice.toString() ?? '0');
    final deliveryPriceController = TextEditingController(text: variant?.deliveryPrice.toString() ?? '0');
    bool isActive = variant?.isActive ?? true;

    final dialogKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(variant == null ? 'Add Variant' : 'Edit Variant'),
              content: Form(
                key: dialogKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Variant Name (e.g. Half, Full)', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: servingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Serving Price (₹)', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a serving price';
                          final val = double.tryParse(value);
                          if (val == null) return 'Enter a valid number';
                          if (val < 0) return 'Price cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: deliveryPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Delivery Price (₹)', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a delivery price';
                          final val = double.tryParse(value);
                          if (val == null) return 'Enter a valid number';
                          if (val < 0) return 'Price cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      SwitchListTile(
                        title: const Text('Is Active'),
                        value: isActive,
                        onChanged: (val) {
                          setDialogState(() => isActive = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (!dialogKey.currentState!.validate()) return;
                    
                    final name = nameController.text.trim();
                    final servingPrice = double.parse(servingPriceController.text.trim());
                    final deliveryPrice = double.parse(deliveryPriceController.text.trim());

                    bool success;
                    if (variant == null) {
                      final newVariant = await _menuService.createVariant(
                        menuId: _menuItemId!,
                        variantName: name,
                        servingPrice: servingPrice,
                        deliveryPrice: deliveryPrice,
                        isActive: isActive,
                      );
                      success = newVariant != null;
                    } else {
                      success = await _menuService.updateVariant(
                        variantId: variant.id,
                        variantName: name,
                        servingPrice: servingPrice,
                        deliveryPrice: deliveryPrice,
                        isActive: isActive,
                      );
                    }

                    if (context.mounted) {
                      Navigator.pop(context, success);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _loadVariants();
    }
  }

  void _deleteVariant(MenuVariant variant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Variant?'),
        content: Text('Are you sure you want to delete the variant "${variant.variantName}"?'),
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
      final success = await _menuService.deleteVariant(variant.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Variant "${variant.variantName}" deleted')),
          );
        }
        _loadVariants();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete variant')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = _menuItemId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null && !isEditMode ? 'Create Menu Item' : 'Edit Menu Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Core Details Section ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Details',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter an item name' : null,
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _unitQuantityController,
                              decoration: const InputDecoration(
                                labelText: 'Unit Quantity',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.scale_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter unit qty';
                                }
                                final trimVal = value.trim();
                                final number = double.tryParse(trimVal);
                                if (number != null) {
                                  if (number <= 0) return 'Must be positive';
                                  return null;
                                }
                                final parts = trimVal.split('/');
                                if (parts.length == 2) {
                                  final n1 = double.tryParse(parts[0].trim());
                                  final n2 = double.tryParse(parts[1].trim());
                                  if (n1 != null && n2 != null && n1 > 0 && n2 > 0) {
                                    return null;
                                  }
                                }
                                return 'Enter positive number or fraction (e.g. 1.5, 1/2)';
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnitType,
                              decoration: const InputDecoration(
                                labelText: 'Unit Type',
                                border: OutlineInputBorder(),
                              ),
                              items: _unitTypes.map((u) {
                                return DropdownMenuItem(value: u, child: Text(u));
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedUnitType = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Base Price (₹)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Enter a price';
                                final parsed = double.tryParse(value);
                                if (parsed == null) return 'Enter valid price';
                                if (parsed < 0) return 'Price cannot be negative';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: _statuses.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedStatus = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(widget.item == null && !isEditMode ? 'Create Menu Item' : 'Save Details'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              
              // --- Variants Management Section (Only visible in Edit Mode) ---
              if (isEditMode) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Menu Variants',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _openVariantDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Variant'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        
                        if (_isLoadingVariants)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_variants.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No price variants added for this item yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _variants.length,
                            itemBuilder: (context, index) {
                              final variant = _variants[index];
                              return Card(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  title: Text(
                                    variant.variantName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Serving: ₹${variant.servingPrice.toStringAsFixed(2)} | Delivery: ₹${variant.deliveryPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13.0),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                        decoration: BoxDecoration(
                                          color: variant.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          variant.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.bold,
                                            color: variant.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4.0),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _openVariantDialog(variant),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                        onPressed: () => _deleteVariant(variant),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
