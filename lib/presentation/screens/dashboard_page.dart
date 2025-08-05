import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../presentation/providers/product_provider.dart';
import '../../utils/fcm_test_helper.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final scrollPhysics =
        Theme.of(context).platform == TargetPlatform.iOS
            ? const BouncingScrollPhysics()
            : const ClampingScrollPhysics();

    final topProducts = provider.topConsumati();
    final categoryDist = provider.distribuzionePerCategoria();
    final monthlyExpense = provider.spesaMensile();
    final months = monthlyExpense.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body:
          provider.loading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                physics: scrollPhysics,
                slivers: [
                  const SliverAppBar(
                    backgroundColor: Color(0xFFF5F5F5),
                    elevation: 2,
                    floating: true,
                    pinned: true,
                    title: _AppBarTitle(),
                    toolbarHeight: 70,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          'Statistiche Magazzino',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _TopProductsChart(topProducts: topProducts),
                        const SizedBox(height: 24),
                        _CategoryChart(categoryDist: categoryDist),
                        const SizedBox(height: 24),
                        _MonthlyExpenseChart(
                          monthlyExpense: monthlyExpense,
                          months: months,
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 24),
                          _NotificationTestCard(),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.analytics_outlined, color: Color(0xFF009688), size: 28),
        SizedBox(width: 10),
        Text(
          'Cruscotto Analitico',
          style: TextStyle(
            color: Color(0xFF009688),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _TopProductsChart extends StatelessWidget {
  final List<dynamic> topProducts;
  const _TopProductsChart({required this.topProducts});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 prodotti consumati',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF009688),
              ),
            ),
            const SizedBox(height: 70),
            SizedBox(
              height: 220,
              child:
                  topProducts.isEmpty
                      ? const Center(
                        child: Text(
                          'Nessun dato disponibile',
                          style: TextStyle(color: Color(0xFF757575)),
                        ),
                      )
                      : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barGroups: [
                            for (int i = 0; i < topProducts.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: topProducts[i].consumati.toDouble(),
                                    color: Color.fromARGB(255, 58, 255, 235),
                                    width: 22,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                                showingTooltipIndicators: [0],
                              ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < topProducts.length) {
                                    String nome = topProducts[idx].nome;
                                    if (nome.length > 8) {
                                      nome = '${nome.substring(0, 8)}…';
                                    }
                                    return Transform.rotate(
                                      angle: -0.0, //
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          nome,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF757575),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }
                                  return Text('');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final Map<String, int> categoryDist;
  const _CategoryChart({required this.categoryDist});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribuzione per categoria',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF009688),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child:
                  categoryDist.isEmpty
                      ? const Center(
                        child: Text(
                          'Nessun dato disponibile',
                          style: TextStyle(color: Color(0xFF757575)),
                        ),
                      )
                      : PieChart(
                        PieChartData(
                          sections: [
                            for (final entry in categoryDist.entries)
                              PieChartSectionData(
                                value: entry.value.toDouble(),
                                title: entry.key,
                                color: Colors
                                    .primaries[categoryDist.keys
                                            .toList()
                                            .indexOf(entry.key) %
                                        Colors.primaries.length]
                                    .withValues(alpha: 0.85),
                                radius: 60,
                                titleStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                        ),
                      ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children:
                  categoryDist.keys.map((cat) {
                    final color = Colors
                        .primaries[categoryDist.keys.toList().indexOf(cat) %
                            Colors.primaries.length]
                        .withValues(alpha: 0.85);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyExpenseChart extends StatelessWidget {
  final Map<String, double> monthlyExpense;
  final List<String> months;
  const _MonthlyExpenseChart({
    required this.monthlyExpense,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spesa mensile totale',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF009688),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child:
                  months.isEmpty
                      ? const Center(
                        child: Text(
                          'Nessun dato disponibile',
                          style: TextStyle(color: Color(0xFF757575)),
                        ),
                      )
                      : LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < months.length; i++)
                                  FlSpot(
                                    i.toDouble(),
                                    monthlyExpense[months[i]] ?? 0,
                                  ),
                              ],
                              isCurved: true,
                              color: Color(0xFF009688),
                              barWidth: 5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: Color(0xFF009688),
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Color(
                                  0xFF009688,
                                ).withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      '${value.toStringAsFixed(0)}€',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF757575),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  return idx < months.length
                                      ? Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          months[idx],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF009688),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                      : Text('');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '${months[spot.x.toInt()]}\n${spot.y.toStringAsFixed(2)} €',
                                    const TextStyle(
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: 0,
                                color: Colors.grey.shade300,
                                strokeWidth: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTestCard extends StatelessWidget {
  const _NotificationTestCard();

  @override
  Widget build(BuildContext context) {
    final fcmTestHelper = FCMTestHelper();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.notifications_active,
                  color: Color(0xFF009688),
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'Test Notifiche Push',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Testa il sistema di notifiche push FCM per verificare che funzioni correttamente.',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await fcmTestHelper.sendTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Notifica di test inviata!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Errore: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Test Singola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await fcmTestHelper.sendMultipleTestNotifications();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Notifiche multiple inviate!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Errore: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test Multiple'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await fcmTestHelper.checkNotificationStatus();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✅ Stato verificato! Controlla i log.',
                              ),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Errore: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Verifica Stato'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF009688),
                      side: const BorderSide(color: Color(0xFF009688)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await fcmTestHelper.cleanupOldNotifications();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Pulizia completata!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Errore: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Pulizia'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF009688),
                      side: const BorderSide(color: Color(0xFF009688)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
