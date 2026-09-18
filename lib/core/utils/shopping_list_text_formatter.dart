import 'package:intl/intl.dart';

import '../../models/shopping_item.dart';
import '../../models/shopping_session.dart';
import 'number_formatter.dart';

class ShoppingListTextFormatter {
  const ShoppingListTextFormatter._();

  static String format(ShoppingSession session) {
    final output = StringBuffer(
      'ShopTrack — ${DateFormat('EEEE, d MMMM yyyy').format(session.date)}',
    );

    for (final list in session.orderedLists) {
      final items = session.itemsForList(list.id)
        ..sort((a, b) => a.position.compareTo(b.position));
      if (items.isEmpty) continue;

      output
        ..writeln()
        ..writeln()
        ..writeln(list.name);
      _writeSection(
        output,
        'To Buy',
        items.where((item) => !item.isPurchased),
        '☐',
      );
      _writeSection(
        output,
        'Purchased',
        items.where((item) => item.isPurchased),
        '☑',
      );
    }

    if (session.items.isEmpty) {
      output
        ..writeln()
        ..writeln()
        ..write('No items yet.');
      return output.toString();
    }

    final pendingTotal = session.items
        .where((item) => !item.isPurchased)
        .fold<double>(0, (sum, item) => sum + item.pricing.totalPrice);
    output
      ..writeln()
      ..writeln()
      ..writeln('Pending total: ${NumberFormatter.formatPrice(pendingTotal)}')
      ..write(
        'Purchased total: ${NumberFormatter.formatPrice(session.totalPurchasedAmount)}',
      );
    return output.toString();
  }

  static void _writeSection(
    StringBuffer output,
    String title,
    Iterable<ShoppingItem> items,
    String marker,
  ) {
    final section = items.toList(growable: false);
    if (section.isEmpty) return;
    output.writeln(title);
    for (final item in section) {
      output.writeln('$marker ${_itemLine(item)}');
      if (item.notes?.trim().isNotEmpty == true) {
        output.writeln('   Note: ${item.notes!.trim()}');
      }
    }
  }

  static String _itemLine(ShoppingItem item) {
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
      details.add(NumberFormatter.formatPrice(pricing.totalPrice));
    }
    return details.isEmpty
        ? item.name
        : '${item.name} — ${details.join(' — ')}';
  }
}
