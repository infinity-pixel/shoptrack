import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';

import '../currency/currency_catalog.dart';

Future<String?> showCurrencyPickerDialog(
  BuildContext context, {
  required String selectedCurrencyCode,
  required String defaultCurrencyCode,
  Iterable<String> recentCurrencyCodes = const [],
  String title = 'Choose Currency',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => CurrencyPickerDialog(
      selectedCurrencyCode: selectedCurrencyCode,
      defaultCurrencyCode: defaultCurrencyCode,
      recentCurrencyCodes: recentCurrencyCodes,
      title: title,
    ),
  );
}

class CurrencyPickerDialog extends StatefulWidget {
  const CurrencyPickerDialog({
    super.key,
    required this.selectedCurrencyCode,
    required this.defaultCurrencyCode,
    this.recentCurrencyCodes = const [],
    this.title = 'Choose Currency',
  });

  final String selectedCurrencyCode;
  final String defaultCurrencyCode;
  final Iterable<String> recentCurrencyCodes;
  final String title;

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  late final TextEditingController _searchController;
  late final String _selectedCode;
  late final String _defaultCode;
  late final List<String> _recentCodes;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedCode = CurrencyCatalog.normalizeItemCode(
      widget.selectedCurrencyCode,
    );
    _defaultCode = CurrencyCatalog.normalizeDefaultCode(
      widget.defaultCurrencyCode,
    );
    _recentCodes = CurrencyCatalog.sanitizeRecentCodes(
      widget.recentCurrencyCodes,
      defaultCurrencyCode: _defaultCode,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ShopCurrency currency) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return currency.code.toLowerCase().contains(query) ||
        currency.name.toLowerCase().contains(query) ||
        shopTr(context, currency.name).toLowerCase().contains(query) ||
        currency.country.toLowerCase().contains(query) ||
        currency.symbol.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ordered = CurrencyCatalog.prioritized(
      defaultCurrencyCode: _defaultCode,
      recentCurrencyCodes: _recentCodes,
    ).where(_matches).toList(growable: false);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: (screenHeight * .76).clamp(280, 620),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ShopText(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: shopTr(context, 'Close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                key: const ValueKey('currency_search_field'),
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: shopTr(context, 'Search currencies'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: shopTr(context, 'Clear search'),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close, size: 20),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ordered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 34,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              ShopText(
                                'No matching currency',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              ShopText(
                                'Try its three-letter code or full name.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Scrollbar(
                        child: ListView.separated(
                          key: const ValueKey('currency_result_list'),
                          padding: const EdgeInsets.only(bottom: 4),
                          itemCount: ordered.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: colors.outlineVariant.withValues(alpha: .55),
                          ),
                          itemBuilder: (context, index) {
                            final currency = ordered[index];
                            final isDefault = currency.code == _defaultCode;
                            final isRecent = _recentCodes.contains(
                              currency.code,
                            );
                            final isSelected = currency.code == _selectedCode;
                            final symbol = currency.symbol.isEmpty
                                ? currency.code
                                : currency.symbol;

                            return Semantics(
                              selected: isSelected,
                              button: true,
                              label:
                                  '${currency.code}, ${shopTr(context, currency.name)}${isDefault
                                      ? ', ${shopTr(context, 'default')}'
                                      : isRecent
                                      ? ', ${shopTr(context, 'recent')}'
                                      : ''}',
                              child: ListTile(
                                key: ValueKey(
                                  'currency_option_${currency.code}',
                                ),
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                selected: isSelected,
                                selectedTileColor: colors.primaryContainer
                                    .withValues(alpha: .42),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primary.withValues(alpha: .14)
                                        : colors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Text(
                                        symbol,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: isSelected
                                                  ? colors.primary
                                                  : colors.onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      currency.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (isDefault || isRecent) ...[
                                      const SizedBox(width: 7),
                                      Flexible(
                                        child: ShopText(
                                          isDefault ? '(default)' : 'Recent',
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: isDefault
                                                    ? colors.primary
                                                    : colors.onSurfaceVariant,
                                                fontWeight: FontWeight.w400,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: ShopText(
                                  currency.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check, color: colors.primary)
                                    : null,
                                onTap: () =>
                                    Navigator.pop(context, currency.code),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
