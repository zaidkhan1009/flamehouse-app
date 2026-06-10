import 'package:flutter/material.dart';
import '../../data/models/costing_models.dart';
import 'menu_costing_service.dart';

class MenuCostingWizardScreen extends StatefulWidget {
  final int menuItemId;
  final String menuItemName;
  final int? costingId;

  const MenuCostingWizardScreen({
    super.key,
    required this.menuItemId,
    required this.menuItemName,
    this.costingId,
  });

  @override
  State<MenuCostingWizardScreen> createState() => _MenuCostingWizardScreenState();
}

class _MenuCostingWizardScreenState extends State<MenuCostingWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuCostingService _costingService = MenuCostingService();
  
  int _currentStep = 0;
  bool _isLoading = true;
  int? _costingId;
  
  // Input Controller Lists
  final List<PrepInput> _prepInputs = [];
  final List<OverheadInput> _overheadInputs = [];
  final List<PackingInput> _packingInputs = [];
  
  // Final costing inputs
  final _profitMarginController = TextEditingController(text: '0');
  final _commissionController = TextEditingController(text: '0');
  final _deliveryFeeController = TextEditingController(text: '0');
  final _otherDescController = TextEditingController();
  final _otherServingCostController = TextEditingController(text: '0');
  final _otherDeliveryCostController = TextEditingController(text: '0');
  
  // Calculation results
  double? _calculatedServingPrice;
  double? _calculatedDeliveryPrice;
  bool _isFinalSaved = false;
  bool _isSavingStep = false;

  final List<String> _overheadTypes = ['Gas', 'Water', 'Electricity', 'Labour', 'Other'];

  @override
  void initState() {
    super.initState();
    _costingId = widget.costingId;
    _initializeSession();
  }

  @override
  void dispose() {
    for (var i in _prepInputs) {
      i.dispose();
    }
    for (var i in _overheadInputs) {
      i.dispose();
    }
    for (var i in _packingInputs) {
      i.dispose();
    }
    _profitMarginController.dispose();
    _commissionController.dispose();
    _deliveryFeeController.dispose();
    _otherDescController.dispose();
    _otherServingCostController.dispose();
    _otherDeliveryCostController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);
    
    if (_costingId == null) {
      // Create session first
      final id = await _costingService.createCostingSession(widget.menuItemId);
      if (id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to initialize costing session.')),
          );
          Navigator.pop(context);
        }
        return;
      }
      _costingId = id;
    }

    // Load session details
    final costing = await _costingService.getCosting(_costingId!);
    if (costing != null) {
      _loadDataIntoControllers(costing);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load costing details.')),
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isLoading = false);
  }

  void _loadDataIntoControllers(MenuCosting costing) {
    // 1. Prep
    _prepInputs.clear();
    for (var item in costing.prepItems) {
      _prepInputs.add(PrepInput(
        description: item.description,
        servingCost: item.servingCost,
        deliveryCost: item.deliveryCost,
        notes: item.notes ?? '',
      ));
    }
    if (_prepInputs.isEmpty) {
      _prepInputs.add(PrepInput()); // Add one empty row
    }

    // 2. Overhead
    _overheadInputs.clear();
    for (var item in costing.overheadItems) {
      _overheadInputs.add(OverheadInput(
        costType: _overheadTypes.contains(item.costType) ? item.costType : 'Gas',
        description: item.description ?? '',
        servingCost: item.servingCost,
        deliveryCost: item.deliveryCost,
      ));
    }
    if (_overheadInputs.isEmpty) {
      _overheadInputs.add(OverheadInput(costType: 'Gas'));
    }

    // 3. Packing
    _packingInputs.clear();
    for (var item in costing.packingItems) {
      _packingInputs.add(PackingInput(
        description: item.description,
        servingCost: item.servingCost,
        deliveryCost: item.deliveryCost,
      ));
    }
    if (_packingInputs.isEmpty) {
      _packingInputs.add(PackingInput());
    }

    // 4. Final
    if (costing.finalCosting != null) {
      final f = costing.finalCosting!;
      _profitMarginController.text = f.profitMarginPct.toString();
      _commissionController.text = f.commissionPct.toString();
      _deliveryFeeController.text = f.deliveryFee.toString();
      _otherDescController.text = f.otherDescription ?? '';
      _otherServingCostController.text = f.otherServingCost.toString();
      _otherDeliveryCostController.text = f.otherDeliveryCost.toString();
      _calculatedServingPrice = costing.servingPrice;
      _calculatedDeliveryPrice = costing.deliveryPrice;
      _isFinalSaved = true;
    }
  }

  double _parseField(String text) {
    return double.tryParse(text) ?? 0.0;
  }

  // --- Step Save Actions ---
  Future<bool> _saveCurrentStep() async {
    if (_costingId == null) return false;
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    setState(() => _isSavingStep = true);
    
    bool success = false;
    
    if (_currentStep == 0) {
      final items = _prepInputs
          .where((i) => i.descriptionController.text.trim().isNotEmpty)
          .map((i) => CostingPrepItem(
                description: i.descriptionController.text.trim(),
                servingCost: _parseField(i.servingCostController.text),
                deliveryCost: _parseField(i.deliveryCostController.text),
                notes: i.notesController.text.trim().isEmpty ? null : i.notesController.text.trim(),
              ))
          .toList();
      success = await _costingService.savePrep(_costingId!, items);
    } else if (_currentStep == 1) {
      final items = _overheadInputs
          .where((i) => i.descriptionController.text.trim().isNotEmpty || i.servingCostController.text.trim().isNotEmpty)
          .map((i) => CostingOverheadItem(
                costType: i.costType,
                description: i.descriptionController.text.trim().isEmpty ? null : i.descriptionController.text.trim(),
                servingCost: _parseField(i.servingCostController.text),
                deliveryCost: _parseField(i.deliveryCostController.text),
              ))
          .toList();
      success = await _costingService.saveOverhead(_costingId!, items);
    } else if (_currentStep == 2) {
      final items = _packingInputs
          .where((i) => i.descriptionController.text.trim().isNotEmpty)
          .map((i) => CostingPackingItem(
                description: i.descriptionController.text.trim(),
                servingCost: _parseField(i.servingCostController.text),
                deliveryCost: _parseField(i.deliveryCostController.text),
              ))
          .toList();
      success = await _costingService.savePacking(_costingId!, items);
    } else if (_currentStep == 3) {
      final finalCosting = CostingFinal(
        profitMarginPct: _parseField(_profitMarginController.text),
        commissionPct: _parseField(_commissionController.text),
        deliveryFee: _parseField(_deliveryFeeController.text),
        otherDescription: _otherDescController.text.trim().isEmpty ? null : _otherDescController.text.trim(),
        otherServingCost: _parseField(_otherServingCostController.text),
        otherDeliveryCost: _parseField(_otherDeliveryCostController.text),
      );
      success = await _costingService.saveFinal(_costingId!, finalCosting);
      if (success) {
        // Fetch calculations
        final costing = await _costingService.getCosting(_costingId!);
        if (costing != null) {
          setState(() {
            _calculatedServingPrice = costing.servingPrice;
            _calculatedDeliveryPrice = costing.deliveryPrice;
            _isFinalSaved = true;
          });
        }
      }
    }

    setState(() => _isSavingStep = false);
    return success;
  }

  void _handleContinue() async {
    final success = await _saveCurrentStep();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save costing step data. Check input values.')),
        );
      }
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    }
  }

  void _handleCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _approveCosting() async {
    if (_costingId == null) return;
    setState(() => _isSavingStep = true);
    
    final result = await _costingService.approveCosting(_costingId!);
    setState(() => _isSavingStep = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Approved! Prices updated: Serving ₹${result['serving_price']}, Delivery ₹${result['delivery_price']}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Pop back to reload overview
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve costing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Costing: ${widget.menuItemName}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Costing: ${widget.menuItemName}')),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
        onStepContinue: _handleContinue,
        onStepCancel: _handleCancel,
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (_isSavingStep)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(isLastStep ? 'Compute Costs' : 'Save & Continue'),
                  ),
                  const SizedBox(width: 12.0),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ]
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Prep Cost (Ingredients)'),
            content: _buildPrepStep(theme),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Overhead Cost'),
            content: _buildOverheadStep(theme),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : (_currentStep == 1 ? StepState.editing : StepState.indexed),
          ),
          Step(
            title: const Text('Packing & Serving'),
            content: _buildPackingStep(theme),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : (_currentStep == 2 ? StepState.editing : StepState.indexed),
          ),
          Step(
            title: const Text('Final Price Computation'),
            content: _buildFinalStep(theme),
            isActive: _currentStep >= 3,
            state: _currentStep == 3 ? StepState.editing : StepState.indexed,
          ),
        ],
      ),
    );
  }

  // --- Step UI Builders ---
  Widget _buildPrepStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'List raw ingredients, sauces, or prep works used specifically for this menu item.',
          style: TextStyle(fontSize: 13.0, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _prepInputs.length,
          itemBuilder: (context, index) {
            final input = _prepInputs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: input.descriptionController,
                      decoration: const InputDecoration(hintText: 'Ingredient description', border: OutlineInputBorder()),
                      validator: (val) {
                        final desc = val ?? '';
                        final hasServing = input.servingCostController.text.trim().isNotEmpty;
                        final hasDelivery = input.deliveryCostController.text.trim().isNotEmpty;
                        if ((hasServing || hasDelivery) && desc.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextFormField(
                      controller: input.servingCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Serv. (₹)', border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) return 'Invalid';
                        if (parsed < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextFormField(
                      controller: input.deliveryCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Deliv. (₹)', border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) return 'Invalid';
                        if (parsed < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (_prepInputs.length > 1) {
                          final removed = _prepInputs.removeAt(index);
                          removed.dispose();
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _prepInputs.add(PrepInput());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Prep Ingredient'),
        ),
      ],
    );
  }

  Widget _buildOverheadStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select and allocate fixed costs (Gas, Electricity, Water, Labor, etc.) to this item.',
          style: TextStyle(fontSize: 13.0, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _overheadInputs.length,
          itemBuilder: (context, index) {
            final input = _overheadInputs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: input.costType,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                      items: _overheadTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          input.costType = val;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextFormField(
                      controller: input.descriptionController,
                      decoration: const InputDecoration(hintText: 'Details (e.g. Gas cylinder share)', border: OutlineInputBorder()),
                      validator: (val) {
                        final desc = val ?? '';
                        final hasServing = input.servingCostController.text.trim().isNotEmpty;
                        final hasDelivery = input.deliveryCostController.text.trim().isNotEmpty;
                        if ((hasServing || hasDelivery) && desc.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextFormField(
                      controller: input.servingCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Serv. (₹)', border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) return 'Invalid';
                        if (parsed < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextFormField(
                      controller: input.deliveryCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Deliv. (₹)', border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) return 'Invalid';
                        if (parsed < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (_overheadInputs.length > 1) {
                          final removed = _overheadInputs.removeAt(index);
                          removed.dispose();
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _overheadInputs.add(OverheadInput(costType: 'Gas'));
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Overhead Cost'),
        ),
      ],
    );
  }

  Widget _buildPackingStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Provide packaging, plates, napkins, cutlery, or box shares costing for serving and delivery.',
          style: TextStyle(fontSize: 13.0, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _packingInputs.length,
          itemBuilder: (context, index) {
            final input = _packingInputs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: input.descriptionController,
                      decoration: const InputDecoration(hintText: 'Packaging details', border: OutlineInputBorder()),
                      validator: (val) {
                        final desc = val ?? '';
                        final hasServing = input.servingCostController.text.trim().isNotEmpty;
                        final hasDelivery = input.deliveryCostController.text.trim().isNotEmpty;
                        if ((hasServing || hasDelivery) && desc.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextFormField(
                      controller: input.servingCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Serv. (₹)', border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) return 'Invalid';
                        if (parsed < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextFormField(
                      controller: input.deliveryCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Deliv. (₹)', border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) return 'Invalid';
                        if (parsed < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (_packingInputs.length > 1) {
                          final removed = _packingInputs.removeAt(index);
                          removed.dispose();
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _packingInputs.add(PackingInput());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Packing Material'),
        ),
      ],
    );
  }

  Widget _buildFinalStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Markup and Fees Configuration', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _profitMarginController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Profit Margin (%)', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: TextFormField(
                        controller: _commissionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Commission (%)', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _deliveryFeeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Delivery Fee (₹)', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: TextFormField(
                        controller: _otherDescController,
                        decoration: const InputDecoration(labelText: 'Other description', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otherServingCostController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Other Serv. Cost (₹)', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: TextFormField(
                        controller: _otherDeliveryCostController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Other Deliv. Cost (₹)', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        
        if (_isFinalSaved && _calculatedServingPrice != null && _calculatedDeliveryPrice != null) ...[
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Computed Pricing Results', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Serving Price', style: TextStyle(fontSize: 12.0)),
                          Text(
                            '₹${_calculatedServingPrice!.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Delivery Price', style: TextStyle(fontSize: 12.0)),
                          Text(
                            '₹${_calculatedDeliveryPrice!.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton.icon(
                    onPressed: _approveCosting,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Approve & Apply to Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Click "Compute Costs" above to run margins and display recommended prices.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }
}

// --- Disposable Wizard Inputs ---
class PrepInput {
  final TextEditingController descriptionController;
  final TextEditingController servingCostController;
  final TextEditingController deliveryCostController;
  final TextEditingController notesController;

  PrepInput({
    String description = '',
    double servingCost = 0.0,
    double deliveryCost = 0.0,
    String notes = '',
  })  : descriptionController = TextEditingController(text: description),
        servingCostController = TextEditingController(text: servingCost == 0.0 ? '' : servingCost.toString()),
        deliveryCostController = TextEditingController(text: deliveryCost == 0.0 ? '' : deliveryCost.toString()),
        notesController = TextEditingController(text: notes);

  void dispose() {
    descriptionController.dispose();
    servingCostController.dispose();
    deliveryCostController.dispose();
    notesController.dispose();
  }
}

class OverheadInput {
  String costType;
  final TextEditingController descriptionController;
  final TextEditingController servingCostController;
  final TextEditingController deliveryCostController;

  OverheadInput({
    required this.costType,
    String description = '',
    double servingCost = 0.0,
    double deliveryCost = 0.0,
  })  : descriptionController = TextEditingController(text: description),
        servingCostController = TextEditingController(text: servingCost == 0.0 ? '' : servingCost.toString()),
        deliveryCostController = TextEditingController(text: deliveryCost == 0.0 ? '' : deliveryCost.toString());

  void dispose() {
    descriptionController.dispose();
    servingCostController.dispose();
    deliveryCostController.dispose();
  }
}

class PackingInput {
  final TextEditingController descriptionController;
  final TextEditingController servingCostController;
  final TextEditingController deliveryCostController;

  PackingInput({
    String description = '',
    double servingCost = 0.0,
    double deliveryCost = 0.0,
  })  : descriptionController = TextEditingController(text: description),
        servingCostController = TextEditingController(text: servingCost == 0.0 ? '' : servingCost.toString()),
        deliveryCostController = TextEditingController(text: deliveryCost == 0.0 ? '' : deliveryCost.toString());

  void dispose() {
    descriptionController.dispose();
    servingCostController.dispose();
    deliveryCostController.dispose();
  }
}
