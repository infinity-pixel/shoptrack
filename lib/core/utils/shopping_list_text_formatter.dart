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
    String Function(String value)? translate,
    String defaultListLabel = 'My List',
    String Function(int value)? formatCount,
    String? dateLabel,
    String Function(String value)? formatNumberText,
  }) {
    final tr = translate ?? (value) => value;
    final countText = formatCount ?? (value) => '$value';
    final numberText = formatNumberText ?? (value) => value;
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
      ..writeln(
        dateLabel ?? DateFormat('EEEE, d MMMM yyyy').format(session.date),
      )
      ..write('============================');

    if (selectedItems) {
      output
        ..writeln()
        ..writeln()
        ..writeln(tr('SELECTED ITEMS'))
        ..write('=' * tr('SELECTED ITEMS').runes.length);
    }

    for (final list in includedLists) {
      final items = includedItems.where((item) {
        return (item.listId ?? ShoppingListGroup.defaultId) == list.id;
      }).toList()..sort((a, b) => a.position.compareTo(b.position));

      final listTitle =
          list.id == ShoppingListGroup.defaultId &&
              list.name == ShoppingListGroup.defaultList.name
          ? defaultListLabel
          : list.name;
      output
        ..writeln()
        ..writeln()
        ..writeln(listTitle)
        ..writeln(_underline(listTitle));
      _writeSection(
        output,
        'TO BUY',
        items.where((item) => !item.isPurchased),
        '☐',
        translate: tr,
        formatCount: countText,
        numberText: numberText,
        includeCurrencyCodes: includeCurrencyCodes,
      );
      _writeSection(
        output,
        'PURCHASED',
        items.where((item) => item.isPurchased),
        '☑',
        translate: tr,
        formatCount: countText,
        numberText: numberText,
        includeCurrencyCodes: includeCurrencyCodes,
      );
      _writeTotals(output, items, translate: tr, numberText: numberText);
    }

    if (includedItems.isEmpty) {
      output
        ..writeln()
        ..writeln()
        ..write(tr('No items yet.'));
      return output.toString();
    }

    if (includedLists.length > 1) {
      output
        ..writeln()
        ..writeln()
        ..writeln(tr('ALL LISTS'))
        ..writeln('=' * tr('ALL LISTS').runes.length);
      _writeTotals(
        output,
        includedItems,
        divider: false,
        translate: tr,
        numberText: numberText,
      );
    }
    return output.toString();
  }

  static void _writeSection(
    StringBuffer output,
    String title,
    Iterable<ShoppingItem> items,
    String marker, {
    required String Function(String) translate,
    required String Function(int) formatCount,
    required String Function(String) numberText,
    required bool includeCurrencyCodes,
  }) {
    final section = items.toList(growable: false);
    if (section.isEmpty) return;
    output.writeln('${translate(title)} (${formatCount(section.length)})');
    for (final item in section) {
      output.writeln(
        '$marker ${_itemLine(item, includeCurrencyCode: includeCurrencyCodes, numberText: numberText)}',
      );
      if (item.notes?.trim().isNotEmpty == true) {
        output.writeln('   ${translate('Note')}: ${item.notes!.trim()}');
      }
    }
    output.writeln();
  }

  static void _writeTotals(
    StringBuffer output,
    Iterable<ShoppingItem> items, {
    bool divider = true,
    required String Function(String) translate,
    required String Function(String) numberText,
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
      translate: translate,
      numberText: numberText,
      includeCurrencyCodes: allTotals.isMultiCurrency,
      fallbackCurrencyCode: singleCurrencyCode,
    );
    _writeTotalGroup(
      output,
      'Purchased',
      purchasedTotals,
      translate: translate,
      numberText: numberText,
      includeCurrencyCodes: allTotals.isMultiCurrency,
      fallbackCurrencyCode: singleCurrencyCode,
      trailingNewline: false,
    );
  }

  static void _writeTotalGroup(
    StringBuffer output,
    String label,
    CurrencyTotals totals, {
    required String Function(String) translate,
    required String Function(String) numberText,
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
        '${translate(label)} ${translate('total')}: ${numberText(NumberFormatter.formatPrice(value, currencyCode: code ?? 'BDT'))}',
      );
      if (trailingNewline) output.writeln();
      return;
    }

    output.writeln('${translate(label)} ${translate('totals')}:');
    final values = totals.ordered();
    if (values.isEmpty) {
      output.write('  —');
    } else {
      for (var index = 0; index < values.length; index++) {
        final total = values[index];
        output.write(
          '  ${numberText(NumberFormatter.formatPrice(total.value, currencyCode: total.currencyCode, includeCode: true))}',
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
    required String Function(String) numberText,
  }) {
    final pricing = item.pricing;
    final details = <String>[];
    if (pricing.resolvedQuantity != null ||
        pricing.resolvedUnitSymbol != null) {
      details.add(
        '${numberText(NumberFormatter.formatQuantity(pricing.resolvedQuantity ?? 0, enteredText: item.quantity))} ${pricing.resolvedUnitSymbol ?? ''}'
            .trim(),
      );
    }
    if (pricing.totalPrice > 0) {
      details.add(
        numberText(
          NumberFormatter.formatPrice(
            pricing.totalPrice,
            currencyCode: item.currencyCode,
            includeCode: includeCurrencyCode,
          ),
        ),
      );
    }
    return details.isEmpty
        ? item.name
        : '${item.name} — ${details.join(' — ')}';
  }
}
