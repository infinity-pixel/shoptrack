import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../models/shopping_session.dart';

class SessionCard extends StatelessWidget {
  final ShoppingSession session;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('d MMMM yyyy').format(session.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    NumberFormatter.formatPrice(session.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (onDelete != null || onEdit != null) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'delete' && onDelete != null) {
                          onDelete!();
                        } else if (val == 'edit' && onEdit != null) {
                          onEdit!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_calendar_outlined, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit Date'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                      ],
                      child: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (session.isFuture)
                    _buildStatusPill(
                      '${session.plannedCount} Item${session.plannedCount == 1 ? '' : 's'} Planned',
                      Colors.purple,
                    )
                  else ...[
                    if (session.purchasedCount > 0)
                      _buildStatusPill(
                        '${session.purchasedCount} Item${session.purchasedCount == 1 ? '' : 's'} Purchased',
                        Colors.green,
                      ),
                    if (session.pendingCount > 0)
                      _buildStatusPill(
                        '${session.pendingCount} Item${session.pendingCount == 1 ? '' : 's'} Pending',
                        Colors.red,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
