import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/currency/currency_catalog.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/pricing_calculator.dart';
import '../../../../core/widgets/currency_picker_dialog.dart';
import '../../../../models/frequent_item_suggestion.dart';
import '../../../../models/shopping_item.dart';

class _UnitPickerChoice {
  final ShoppingUnit? unit;

  const _UnitPickerChoice(this.unit);
}

class AddItemSheet extends StatefulWidget {
  final int nextPosition;
  final ShoppingItem? initialItem;
  final List<FrequentItemSuggestion> frequentSuggestions;
  final FrequentItemSuggestion? initialSuggestion;
  final ValueChanged<FrequentItemSuggestion>? onRemoveFrequentSuggestion;
  final String defaultCurrencyCode;
  final List<String> recentCurrencyCodes;

  const AddItemSheet({
    super.key,
    required this.nextPosition,
    this.initialItem,
    this.frequentSuggestions = const [],
    this.initialSuggestion,
    this.onRemoveFrequentSuggestion,
    this.defaultCurrencyCode = CurrencyCatalog.defaultCode,
    this.recentCurrencyCodes = const [],
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;
  late final FocusNode _quantityFocusNode;
  late final FocusNode _unitFocusNode;
  final GlobalKey _unitPickerKey = GlobalKey();

  bool _showMoreOptions = false;
  String? _errorText;
  String? _priceErrorText;
  String? _quantityErrorText;
  String? _priceReferenceText;
  late PricingMode _pricingMode;
  late ShoppingUnit? _selectedUnit;
  late ShoppingUnit? _selectedPriceBasis;
  late String _selectedCurrencyCode;
  PricingResult _calcResult = PricingResult.zero;
  bool _isUnitMenuOpen = false;
  bool _openUnitMenuOnFocus = false;
  late List<FrequentItemSuggestion> _visibleSuggestions;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();

    final item = widget.initialItem;
    _visibleSuggestions = List<FrequentItemSuggestion>.from(
      widget.frequentSuggestions,
    );
    _nameController = TextEditingController(text: item?.name);
    _quantityController = TextEditingController(
      text: item?.quantityValue != null
          ? NumberFormatter.formatQuantity(
              item!.quantityValue!,
              enteredText: item.quantity,
            )
          : '',
    );
    _priceController = TextEditingController(
      text: item?.priceValue != null
          ? item!.priceValue!.toStringAsFixed(
              item.priceValue == item.priceValue!.roundToDouble() ? 0 : 2,
            )
          : '',
    );
    _notesController = TextEditingController(text: item?.notes);
    _quantityFocusNode = FocusNode();
    _unitFocusNode = FocusNode();
    _unitFocusNode.addListener(_handleUnitFocus);

    _pricingMode = item?.pricingMode ?? PricingMode.total;
    _selectedUnit = item?.shoppingUnit;
    _selectedPriceBasis = item?.priceBasis;
    _selectedCurrencyCode =
        item?.currencyCode ??
        CurrencyCatalog.normalizeDefaultCode(widget.defaultCurrencyCode);

    if (item != null &&
        (item.notes != null ||
            item.quantityValue != null ||
            item.priceValue != null)) {
      _showMoreOptions = true;
    }

    _quantityController.addListener(_updateCalculation);
    _priceController.addListener(_updateCalculation);

    if (widget.initialSuggestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applySuggestion(widget.initialSuggestion!);
      });
    }

    // Initial calculation if editing
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCalculation());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _quantityFocusNode.dispose();
    _unitFocusNode.removeListener(_handleUnitFocus);
    _unitFocusNode.dispose();
    super.dispose();
  }

  String _formatQty(double? val, {String? enteredText}) {
    if (val == null) return '';
    return NumberFormatter.formatQuantity(val, enteredText: enteredText);
  }

  void _updateCalculation() {
    final qty = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    if (_pricingMode == PricingMode.unit &&
        price != null &&
        _selectedUnit == null) {
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

    final quantityText = _quantityController.text.trim();
    final quantity = double.tryParse(quantityText);
    if (quantityText.isNotEmpty &&
        (quantity == null ||
            !quantity.isFinite ||
            quantity < 0 ||
            quantity > 999999.99)) {
      setState(() => _quantityErrorText = 'Enter a quantity below 1,000,000');
      return;
    }
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    if (priceText.isNotEmpty &&
        (price == null ||
            !price.isFinite ||
            price > 99999999.99 ||
            !RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(priceText))) {
      setState(
        () => _priceErrorText =
            'Enter a price below 100 million with up to 2 decimals',
      );
      return;
    }
    if (_calcResult.totalPrice > 999999999999.99) {
      setState(() => _priceErrorText = 'The calculated total is too large');
      return;
    }
    if (_pricingMode == PricingMode.unit &&
        price != null &&
        _selectedUnit == null) {
      setState(() {
        _priceErrorText = 'Unit required for Price per Unit';
      });
      return;
    }

    final item = ShoppingItem(
      id: widget.initialItem?.id ?? const Uuid().v4(),
      name: name,
      quantity: _quantityController.text.trim().isEmpty
          ? null
          : _quantityController.text.trim(),
      quantityValue: quantity,
      priceValue: price,
      currencyCode: _selectedCurrencyCode,
      pricingMode: _pricingMode,
      shoppingUnit: _selectedUnit,
      priceBasis: _selectedPriceBasis,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      isPurchased: widget.initialItem?.isPurchased ?? false,
      position: widget.initialItem?.position ?? widget.nextPosition,
      listId: widget.initialItem?.listId,
    );

    Navigator.pop(context, item);
  }

  Widget _buildPreviewAmount(
    String label,
    String amount, {
    bool emphasized = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Text(
            amount,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
              color: emphasized
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  void _applySuggestion(FrequentItemSuggestion suggestion) {
    FocusManager.instance.primaryFocus?.unfocus();
    final item = suggestion.latestItem;
    _nameController.text = item.name;
    _quantityController.text = item.quantityValue != null
        ? _formatQty(item.quantityValue, enteredText: item.quantity)
        : '';
    _priceController.text = item.priceValue != null
        ? item.priceValue!.toStringAsFixed(
            item.priceValue == item.priceValue!.roundToDouble() ? 0 : 2,
          )
        : '';
    _notesController.text = item.notes ?? '';

    setState(() {
      _errorText = null;
      _pricingMode = item.pricingMode;
      _selectedUnit = item.shoppingUnit;
      _selectedPriceBasis = item.priceBasis;
      _selectedCurrencyCode = item.currencyCode;
      _showMoreOptions =
          item.quantityValue != null ||
          item.priceValue != null ||
          (item.notes != null && item.notes!.isNotEmpty);

      if (item.priceValue != null) {
        _priceReferenceText =
            'Last used price: ${NumberFormatter.formatPrice(item.priceValue!, currencyCode: item.currencyCode)}';
      } else {
        _priceReferenceText = null;
      }
    });
    _updateCalculation();
  }

  Future<void> _chooseCurrency() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showCurrencyPickerDialog(
      context,
      selectedCurrencyCode: _selectedCurrencyCode,
      defaultCurrencyCode: widget.defaultCurrencyCode,
      recentCurrencyCodes: widget.recentCurrencyCodes,
    );
    if (!mounted || selected == null || selected == _selectedCurrencyCode) {
      return;
    }
    setState(() => _selectedCurrencyCode = selected);
  }

  Future<void> _showSuggestionMenu(
    FrequentItemSuggestion suggestion,
    LongPressStartDetails details,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      overlay.size.width - details.globalPosition.dx,
      overlay.size.height - details.globalPosition.dy,
    );
    final action = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 8),
              Text('Remove'),
            ],
          ),
        ),
      ],
    );
    if (action != 'remove' || !mounted) return;
    setState(() => _visibleSuggestions.remove(suggestion));
    widget.onRemoveFrequentSuggestion?.call(suggestion);
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
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

  void _moveToUnitPicker() {
    _openUnitMenuOnFocus = true;
    FocusScope.of(context).requestFocus(_unitFocusNode);
  }

  void _handleUnitFocus() {
    if (mounted) setState(() {});
    if (_unitFocusNode.hasFocus && _openUnitMenuOnFocus) {
      _openUnitMenuOnFocus = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openUnitPicker());
    }
  }

  Future<void> _openUnitPicker() async {
    if (!mounted || _isUnitMenuOpen) return;
    final pickerContext = _unitPickerKey.currentContext;
    final box = pickerContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    setState(() => _isUnitMenuOpen = true);
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final choice = await showMenu<_UnitPickerChoice>(
      context: context,
      position: RelativeRect.fromRect(
        origin & box.size,
        Offset.zero & overlay.size,
      ),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem(
          value: _UnitPickerChoice(null),
          child: Text('No Unit'),
        ),
        ...ShoppingUnit.values.map(
          (unit) => PopupMenuItem(
            value: _UnitPickerChoice(unit),
            child: Text(unit.displayName),
          ),
        ),
      ],
    );

    if (!mounted) return;
    _openUnitMenuOnFocus = false;
    _unitFocusNode.unfocus();
    setState(() => _isUnitMenuOpen = false);
    if (choice != null) {
      setState(() {
        _selectedUnit = choice.unit;
        _updatePriceBasisDefault(_selectedUnit);
        _updateCalculation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool showBasisSelector =
        _pricingMode == PricingMode.unit &&
        _selectedUnit != null &&
        (_selectedUnit == ShoppingUnit.g || _selectedUnit == ShoppingUnit.ml);

    return _KeyboardInset(
      child: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Item' : 'Add Item',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g. Eggs',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).inputDecorationTheme.fillColor
                      : colors.surfaceContainerLow,
                ),
                onChanged: (value) {
                  if (_errorText != null && value.trim().isNotEmpty) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
                onSubmitted: (_) => _quantityFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantityController,
                      focusNode: _quantityFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        errorText: _quantityErrorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) {
                        if (_quantityErrorText != null) {
                          setState(() => _quantityErrorText = null);
                        }
                      },
                      onSubmitted: (_) => _moveToUnitPicker(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Focus(
                      focusNode: _unitFocusNode,
                      child: InkWell(
                        key: _unitPickerKey,
                        onTap: () {
                          if (_unitFocusNode.hasFocus) {
                            _openUnitPicker();
                          } else {
                            _openUnitMenuOnFocus = false;
                            FocusScope.of(context).requestFocus(_unitFocusNode);
                            _openUnitPicker();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          isFocused: _unitFocusNode.hasFocus,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedUnit?.displayName ?? 'No Unit',
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isEditing && _visibleSuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Often Bought',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _visibleSuggestions.map((suggestion) {
                      return GestureDetector(
                        onLongPressStart: (details) =>
                            _showSuggestionMenu(suggestion, details),
                        child: Semantics(
                          button: true,
                          label: suggestion.name,
                          hint: 'Long press to remove this suggestion',
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(suggestion.name),
                              onPressed: () => _applySuggestion(suggestion),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showMoreOptions ? 'Fewer Options' : 'More Options',
                        style: TextStyle(
                          color: colors.primary,
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
                    ButtonSegment(
                      value: PricingMode.total,
                      label: Text('Total Price'),
                    ),
                    ButtonSegment(
                      value: PricingMode.unit,
                      label: Text('Price per Unit'),
                    ),
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
                        })
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPriceBasis = value;
                        _updateCalculation();
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _currencyButtonWidth(context),
                      child: Semantics(
                        button: true,
                        label: 'Currency, $_selectedCurrencyCode',
                        hint: 'Double tap to change currency',
                        child: InkWell(
                          key: const ValueKey('item_currency_button'),
                          onTap: _chooseCurrency,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 17,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _currencyLabel(_selectedCurrencyCode),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 1),
                                const Icon(Icons.arrow_drop_down, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('item_price_field'),
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) =>
                                RegExp(
                                  r'^\d*(?:\.\d{0,2})?$',
                                ).hasMatch(newValue.text)
                                ? newValue
                                : oldValue,
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: _getPriceLabel(),
                          errorText: _priceErrorText,
                          helperText: _priceReferenceText,
                          helperStyle: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_calcResult != PricingResult.zero)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildPreviewAmount(
                          'Total',
                          NumberFormatter.formatPrice(
                            _calcResult.totalPrice,
                            currencyCode: _selectedCurrencyCode,
                          ),
                          emphasized: true,
                        ),
                        const SizedBox(height: 4),
                        _buildPreviewAmount(
                          _pricingMode == PricingMode.total
                              ? 'Price per unit'
                              : 'Price per ${_calcResult.priceBasisSymbol}',
                          '${NumberFormatter.formatPrice(_calcResult.unitPrice, currencyCode: _selectedCurrencyCode)}/${_calcResult.priceBasisSymbol}',
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
                    labelStyle: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                    ),
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
                          foregroundColor: colors.error,
                          side: BorderSide(color: colors.error),
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
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
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

  String _currencyLabel(String code) {
    final currency = CurrencyCatalog.resolve(code);
    return currency.symbol.isEmpty
        ? currency.code
        : '${currency.code} ${currency.symbol}';
  }

  double _currencyButtonWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: _currencyLabel(_selectedCurrencyCode),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: double.infinity);
    final desired = painter.width + 20 + 1 + 20;
    painter.dispose();
    final available = MediaQuery.sizeOf(context).width - 64;
    return desired.clamp(96.0, available * .46).toDouble();
  }
}

/// Keyboard metrics rebuild this small wrapper instead of the whole form.
class _KeyboardInset extends StatelessWidget {
  const _KeyboardInset({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: child,
  );
}
