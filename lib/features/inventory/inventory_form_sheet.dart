import 'package:flutter/material.dart';
import '../../data/models/inventory_models.dart';

class InventoryFormSheet extends StatefulWidget {
  final InventoryItem? item;
  final List<InventoryCategory> categories;
  final Future<bool> Function(String name, int quantity, int? inventoryTypeId) onSubmit;

  const InventoryFormSheet({
    super.key,
    this.item,
    required this.categories,
    required this.onSubmit,
  });

  @override
  State<InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends State<InventoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  int? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(text: widget.item?.quantity.toString() ?? '0');
    _selectedCategoryId = widget.item?.inventoryTypeId;
    
    // Check if the selected category still exists in the categories list
    if (_selectedCategoryId != null && !widget.categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final quantity = int.parse(_quantityController.text.trim());

    setState(() => _isSaving = true);
    final success = await widget.onSubmit(name, quantity, _selectedCategoryId);
    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        top: 24.0,
        left: 24.0,
        right: 24.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.item == null ? 'Add Stock Item' : 'Edit Stock Item',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a quantity';
                }
                final number = int.tryParse(value);
                if (number == null) {
                  return 'Please enter a valid number';
                }
                if (number < 0) {
                  return 'Quantity cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<int?>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('No Category'),
                ),
                ...widget.categories.map((c) {
                  return DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.item == null ? 'Create Stock Item' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
