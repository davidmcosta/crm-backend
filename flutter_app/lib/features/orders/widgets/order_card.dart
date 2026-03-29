import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt');
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
              if (order.customer != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16,
                        color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      order.customer!.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(order.totalAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
              if (order.expectedDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14,
                        color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Prevista: ${dateFormat.format(order.expectedDate!)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
