import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../models/shopping_item.dart';
import '../../models/shopping_list_group.dart';
import '../../models/shopping_session.dart';
import '../currency/currency_totals.dart';
import 'number_formatter.dart';

class ShoppingListTextFormatter {
  const ShoppingListTextFormatter._();

  static String format(
    ShoppingSession session, {
    Set<String>? listIds,
    Set<String>? itemIds,
    bool selectedItems = false,
  }) {
    final includedLists = session.orderedLists
        .where((list) {
          if (listIds != null && !listIds.contains(list.id)) return false;
          return session
              .itemsForList(list.id)
              .any((item) => itemIds == null || itemIds.contains(item.id));
        })
        .toList(growable: false);
    final includedItems = session.items
        .where((item) {
          final listId = item.listId ?? ShoppingListGroup.defaultId;
          return includedLists.any((list) => list.id == listId) &&
              (itemIds == null || itemIds.contains(item.id));
        })
        .toList(growable: false);
    final includeCurrencyCodes = CurrencyTotals.fromItems(
      includedItems,
    ).isMultiCurrency;

    final output = StringBuffer()
      ..writeln('ShopTrack')
      ..writeln(DateFormat('EEEE, d MMMM yyyy').format(session.date))
      ..write('============================');

    if (selectedItems) {
      output
        ..writeln()
        ..writeln()
        ..writeln('SELECTED ITEMS')
        ..write('==============');
    }

    for (final list in includedLists) {
      final items = includedItems.where((item) {
        return (item.listId ?? ShoppingListGroup.defaultId) == list.id;
      }).toList()..sort((a, b) => a.position.compareTo(b.position));

      output
        ..writeln()
        ..writeln()
        ..writeln(list.name)
        ..writeln(_underline(list.name));
      _writeSection(
        output,
        'TO BUY',
        items.where((item) => !item.isPurchased),
        '☐',
        includeCurrencyCodes: includeCurrencyCodes,
      );
      _writeSection(
        output,
        'PURCHASED',
        items.where((item) => item.isPurchased),
        '☑',
        includeCurrencyCodes: includeCurrencyCodes,
      );
      _writeTotals(output, items);
    }

    if (includedItems.isEmpty) {
      output
        ..writeln()
        ..writeln()
        ..write('No items yet.');
      return output.toString();
    }

    if (includedLists.length > 1) {
      output
        ..writeln()
        ..writeln()
        ..writeln('ALL LISTS')
        ..writeln('=========');
      _writeTotals(output, includedItems, divider: false);
    }
    return output.toString();
  }

  static void _writeSection(
    StringBuffer output,
    String title,
    Iterable<ShoppingItem> items,
    String marker, {
    required bool includeCurrencyCodes,
  }) {
    final section = items.toList(growable: false);
    if (section.isEmpty) return;
    output.writeln('$title (${section.length})');
    for (final item in section) {
      output.writeln(
        '$marker ${_itemLine(item, includeCurrencyCode: includeCurrencyCodes)}',
      );
      if (item.notes?.trim().isNotEmpty == true) {
        output.writeln('   Note: ${item.notes!.trim()}');
      }
    }
    output.writeln();
  }

  static void _writeTotals(
    StringBuffer output,
    Iterable<ShoppingItem> items, {
    bool divider = true,
  }) {
    final included = items.toList(growable: false);
    final pendingTotals = CurrencyTotals.fromItems(
      included,
      where: (item) => !item.isPurchased,
    );
    final purchasedTotals = CurrencyTotals.fromItems(
      included,
      where: (item) => item.isPurchased,
    );
    final allTotals = CurrencyTotals.fromItems(included);
    final singleCurrencyCode = allTotals.length == 1
        ? allTotals.values.single.currencyCode
        : null;
    if (divider) output.writeln('----------------------------');
    _writeTotalGroup(
      output,
      'Pending',
      pendingTotals,
      includeCurrencyCodes: allTotals.isMultiCurrency,
      fallbackCurrencyCode: singleCurrencyCode,
    );
    _writeTotalGroup(
      output,
      'Purchased',
      purchasedTotals,
      includeCurrencyCodes: allTotals.isMultiCurrency,
      fallbackCurrencyCode: singleCurrencyCode,
      trailingNewline: false,
    );
  }

  static void _writeTotalGroup(
    StringBuffer output,
    String label,
    CurrencyTotals totals, {
    required bool includeCurrencyCodes,
    String? fallbackCurrencyCode,
    bool trailingNewline = true,
  }) {
    if (!includeCurrencyCodes) {
      final value = totals.isEmpty ? 0.0 : totals.values.single.value;
      final code = totals.isEmpty
          ? fallbackCurrencyCode
          : totals.values.single.currencyCode;
      output.write(
        '$label total: ${NumberFormatter.formatPrice(value, currencyCode: code ?? 'BDT')}',
      );
      if (trailingNewline) output.writeln();
      return;
    }

    output.writeln('$label totals:');
    final values = totals.ordered();
    if (values.isEmpty) {
      output.write('  —');
    } else {
      for (var index = 0; index < values.length; index++) {
        final total = values[index];
        output.write(
          '  ${NumberFormatter.formatPrice(total.value, currencyCode: total.currencyCode, includeCode: true)}',
        );
        if (index != values.length - 1) output.writeln();
      }
    }
    if (trailingNewline) output.writeln();
  }

  static String _underline(String value) {
    return '-' * math.max(3, math.min(value.runes.length, 28));
  }

  static String _itemLine(
    ShoppingItem item, {
    required bool includeCurrencyCode,
  }) {
    final pricing = item.pricing;
    final details = <String>[];
    if (pricing.resolvedQuantity != null ||
        pricing.resolvedUnitSymbol != null) {
      details.add(
        '${NumberFormatter.formatQuantity(pricing.resolvedQuantity ?? 0, enteredText: item.quantity)} ${pricing.resolvedUnitSymbol ?? ''}'
            .trim(),
      );
    }
    if (pricing.totalPrice > 0) {
      details.add(
        NumberFormatter.formatPrice(
          pricing.totalPrice,
          currencyCode: item.currencyCode,
          includeCode: includeCurrencyCode,
        ),
      );
    }
    return details.isEmpty
        ? item.name
        : '${item.name} — ${details.join(' — ')}';
  }
}
