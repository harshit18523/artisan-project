import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../widgets/add_product_card.dart';
import '../widgets/business_overview.dart';
import '../widgets/recent_orders.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = context.watch<DataProvider>();
    final s = app.strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddProductCard(
            title: s.addProductTitle,
            subtext: s.addProductSubtitle,
            buttonLabel: s.addButtonLabel,
          ),
          const SizedBox(height: 32),
          BusinessOverview(
            title: s.overview,
            salesLabel: s.salesLabel,
            salesValue: data.todaysSales,
            productsLabel: s.productsLabel,
            productsValue: data.activeProductCount.toString(),
          ),
          const SizedBox(height: 28),
          RecentOrders(
            title: s.recentOrders,
            language: app.language,
            orders: data.recentOrders,
            totalOrders: data.orders.length,
          ),
        ],
      ),
    );
  }
}
