import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/delivery_task.dart';
import '../services/courier_mock_data.dart';
import '../widgets/delivery_card.dart';

class ActiveDeliveriesScreen extends StatefulWidget {
  const ActiveDeliveriesScreen({super.key});

  @override
  State<ActiveDeliveriesScreen> createState() => _ActiveDeliveriesScreenState();
}

class _ActiveDeliveriesScreenState extends State<ActiveDeliveriesScreen> {
  late List<DeliveryTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = CourierMockData.deliveryTasks;
  }

  @override
  Widget build(BuildContext context) {
    final activeCount =
        _tasks.where((t) => t.status != DeliveryStatus.delivered).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Active Deliveries ($activeCount)',
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.cube_box,
                      size: 56, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  const Text(
                    'No active deliveries',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick up items first to start delivering',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: _tasks
                    .map((task) => DeliveryCard(
                          task: task,
                          onDeliver: () =>
                              context.push('/courier/deliver/${task.id}'),
                        ))
                    .toList(),
              ),
            ),
    );
  }
}
