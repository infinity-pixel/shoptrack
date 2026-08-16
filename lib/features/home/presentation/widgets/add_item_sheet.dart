import 'package:flutter/material.dart';
import '../../../../core/utils/pricing_calculator.dart';
import '../../../../models/shopping_item.dart';

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _showMoreOptions = false;
  String? _errorText;
  PricingMode _pricingMode = PricingMode.total;
  ShoppingUnit? _selectedUnit;
  ShoppingUnit? _selectedPriceBasis;
  PricingResult _calcResult = PricingResult.zero;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_updateCalculation);
    _priceController.addListener(_updateCalculation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateCalculation() {
    final qty = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    // Reset price basis if incompatible or not applicable
    if (_pricingMode == PricingMode.unit && _selectedUnit != null) {
      if (_selectedPriceBasis != null && !_selectedUnit!.isCompatibleWith(_selectedPriceBasis!)) {
        _selectedPriceBasis = null;
      }
    } else {
      _selectedPriceBasis = null;
    }

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

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Item name is required';
      });
      return;
    }

    final item = ShoppingItem(
      name: name,
      quantityValue: double.tryParse(_quantityController.text),
      priceValue: double.tryParse(_priceController.text),
      pricingMode: _pricingMode,
      shoppingUnit: _selectedUnit,
      priceBasis: _selectedPriceBasis,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    Navigator.pop(context, item);
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
                const Text(
                  'Add Item',
                  style: TextStyle(
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
              autofocus: true,
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
                    child: DropdownButtonFormField<ShoppingUnit>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ShoppingUnit.values.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value;
                          if (_selectedUnit != null && _selectedPriceBasis != null) {
                            if (!_selectedUnit!.isCompatibleWith(_selectedPriceBasis!)) {
                              _selectedPriceBasis = null;
                            }
                          }
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
                            '৳${_calcResult.totalPrice.toStringAsFixed(2)}',
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
                            '৳${_calcResult.unitPrice.toStringAsFixed(2)}/${_calcResult.priceBasisSymbol}',
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
            ElevatedButton(
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
