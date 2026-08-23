import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/pricing_calculator.dart';
import '../../../../models/frequent_item_suggestion.dart';
import '../../../../models/shopping_item.dart';

class AddItemSheet extends StatefulWidget {
  final int nextPosition;
  final ShoppingItem? initialItem;
  final List<FrequentItemSuggestion> frequentSuggestions;

  const AddItemSheet({
    super.key,
    required this.nextPosition,
    this.initialItem,
    this.frequentSuggestions = const [],
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;

  bool _showMoreOptions = false;
  String? _errorText;
  String? _priceErrorText;
  late PricingMode _pricingMode;
  late ShoppingUnit? _selectedUnit;
  late ShoppingUnit? _selectedPriceBasis;
  PricingResult _calcResult = PricingResult.zero;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?.name);
    _quantityController = TextEditingController(
      text: item?.quantityValue != null ? _formatQty(item!.quantityValue) : '',
    );
    _priceController = TextEditingController(
      text: item?.priceValue != null ? item!.priceValue!.toStringAsFixed(item.priceValue == item.priceValue!.roundToDouble() ? 0 : 2) : '',
    );
    _notesController = TextEditingController(text: item?.notes);
    
    _pricingMode = item?.pricingMode ?? PricingMode.total;
    _selectedUnit = item?.shoppingUnit;
    _selectedPriceBasis = item?.priceBasis;
    
    if (item != null && (item.notes != null || item.quantityValue != null || item.priceValue != null)) {
      _showMoreOptions = true;
    }

    _quantityController.addListener(_updateCalculation);
    _priceController.addListener(_updateCalculation);
    
    // Initial calculation if editing
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCalculation());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatQty(double? val) {
    if (val == null) return '';
    if (val == val.toInt()) return val.toInt().toString();
    return val.toString();
  }

  void _updateCalculation() {
    final qty = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    if (_pricingMode == PricingMode.unit && price != null && _selectedUnit == null) {
      if (mounted) {
        setState(() {
          _calcResult = PricingResult.zero;
          _priceErrorText = 'Unit required for Price per Unit';
        });
      }
      return;
    } else {
      if (_priceErrorText != null) {
        if (mounted) setState(() => _priceErrorText = null);
      }
    }

    if (mounted) {
      setState(() {
        _calcResult = PricingCalculator.calculate(
          quantity: qty,
          priceValue: price,
          mode: _pricingMode,
          unit: _selectedUnit,
          priceBasis: _selectedPriceBasis,
        );
      });
    }
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Item name is required';
      });
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (_pricingMode == PricingMode.unit && price != null && _selectedUnit == null) {
      setState(() {
        _priceErrorText = 'Unit required for Price per Unit';
      });
      return;
    }

    final item = ShoppingItem(
      id: widget.initialItem?.id ?? const Uuid().v4(),
      name: name,
      quantityValue: double.tryParse(_quantityController.text),
      priceValue: price,
      pricingMode: _pricingMode,
      shoppingUnit: _selectedUnit,
      priceBasis: _selectedPriceBasis,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      isPurchased: widget.initialItem?.isPurchased ?? false,
      position: widget.initialItem?.position ?? widget.nextPosition,
    );

    Navigator.pop(context, item);
  }

  void _applySuggestion(FrequentItemSuggestion suggestion) {
    final item = suggestion.latestItem;
    _nameController.text = item.name;
    _quantityController.text =
        item.quantityValue != null ? _formatQty(item.quantityValue) : '';
    _priceController.text = item.priceValue != null
        ? item.priceValue!.toStringAsFixed(
            item.priceValue == item.priceValue!.roundToDouble() ? 0 : 2)
        : '';
    _notesController.text = item.notes ?? '';

    setState(() {
      _errorText = null;
      _pricingMode = item.pricingMode;
      _selectedUnit = item.shoppingUnit;
      _selectedPriceBasis = item.priceBasis;
      _showMoreOptions = item.quantityValue != null ||
          item.priceValue != null ||
          (item.notes != null && item.notes!.isNotEmpty);
    });
    _updateCalculation();
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('Are you sure you want to delete this item?'),
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

    if (confirmed == true && mounted) {
      Navigator.pop(context, 'delete');
    }
  }

  void _updatePriceBasisDefault(ShoppingUnit? unit) {
    if (_pricingMode == PricingMode.unit && unit != null) {
      if (unit == ShoppingUnit.g || unit == ShoppingUnit.kg) {
        _selectedPriceBasis = ShoppingUnit.kg;
      } else if (unit == ShoppingUnit.ml || unit == ShoppingUnit.l) {
        _selectedPriceBasis = ShoppingUnit.l;
      } else {
        _selectedPriceBasis = unit;
      }
    } else {
      _selectedPriceBasis = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showBasisSelector = _pricingMode == PricingMode.unit &&
        _selectedUnit != null &&
        (_selectedUnit == ShoppingUnit.g || _selectedUnit == ShoppingUnit.ml);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Item' : 'Add Item',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. Eggs',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                if (_errorText != null && value.trim().isNotEmpty) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
            ),
            if (!_isEditing && widget.frequentSuggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Often bought',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.frequentSuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion.name),
                    onPressed: () => _applySuggestion(suggestion),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                setState(() {
                  _showMoreOptions = !_showMoreOptions;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      _showMoreOptions ? Icons.remove : Icons.add,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showMoreOptions ? 'Less options' : 'More options',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showMoreOptions) ...[
              const SizedBox(height: 16),
              SegmentedButton<PricingMode>(
                segments: const [
                  ButtonSegment(value: PricingMode.total, label: Text('Total Price')),
                  ButtonSegment(value: PricingMode.unit, label: Text('Price per Unit')),
                ],
                selected: {_pricingMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _pricingMode = newSelection.first;
                    _updatePriceBasisDefault(_selectedUnit);
                    _updateCalculation();
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<ShoppingUnit?>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<ShoppingUnit?>(
                          value: null,
                          child: Text('No unit'),
                        ),
                        ...ShoppingUnit.values.map((unit) {
                          return DropdownMenuItem<ShoppingUnit?>(
                            value: unit,
                            child: Text(unit.displayName),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value;
                          _updatePriceBasisDefault(_selectedUnit);
                          _updateCalculation();
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (showBasisSelector) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<ShoppingUnit>(
                  initialValue: _selectedPriceBasis,
                  decoration: InputDecoration(
                    labelText: 'Price basis',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ShoppingUnit.values
                      .where((u) => u.isCompatibleWith(_selectedUnit!))
                      .map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriceBasis = value;
                      _updateCalculation();
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _getPriceLabel(),
                  prefixText: '৳ ',
                  errorText: _priceErrorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_calcResult != PricingResult.zero)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 14)),
                          Text(
                            NumberFormatter.formatPrice(_calcResult.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _pricingMode == PricingMode.total
                                ? 'Price per unit'
                                : 'Price per ${_calcResult.priceBasisSymbol}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${NumberFormatter.formatPrice(_calcResult.unitPrice)}/${_calcResult.priceBasisSymbol}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPriceLabel() {
    if (_pricingMode == PricingMode.total) return 'Total Price';
    final basis = _selectedPriceBasis ?? _selectedUnit;
    if (basis != null) {
      return 'Price per ${basis.symbol}';
    }
    return 'Price per Unit';
  }
}
