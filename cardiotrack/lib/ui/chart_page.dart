import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../domain/esc.dart';

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<List<Reading>>(
            stream: db.watchReadings(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              if (data.isEmpty) {
                return const Text('Ajoutez des mesures pour voir le graphique.');
              }
              // Prepare points
              data.sort((a, b) => a.takenAt.compareTo(b.takenAt));
              final base = data.first.takenAt;
              double toX(DateTime t) => t.difference(base).inHours.toDouble();

              final systolicSpots = data.map((r) => FlSpot(toX(r.takenAt), r.systolic.toDouble())).toList();
              final diastolicSpots = data.map((r) => FlSpot(toX(r.takenAt), r.diastolic.toDouble())).toList();

              final xLabels = <double, String>{};
              final fmt = DateFormat('dd/MM');
              for (final r in data) {
                final x = toX(r.takenAt);
                xLabels[x] = fmt.format(r.takenAt);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Evolution de la tension artérielle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                              final isSys = s.barIndex == 0;
                              final label = isSys ? 'PAS' : 'PAD';
                              return LineTooltipItem('$label: ${s.y.toInt()}', const TextStyle(fontWeight: FontWeight.bold));
                            }).toList(),
                          ),
                        ),
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                              final nearest = xLabels.keys.reduce((a, b) => (value - a).abs() < (value - b).abs() ? a : b);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(xLabels[nearest] ?? ''),
                              );
                            }),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        minX: 0,
                        maxX: toX(data.last.takenAt),
                        minY: 40,
                        maxY: 220,
                        lineBarsData: [
                          LineChartBarData(
                            spots: systolicSpots,
                            isCurved: true,
                            color: Colors.redAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                          LineChartBarData(
                            spots: diastolicSpots,
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(y: 90, color: EscClassification.color(EscCategory.hypertension).withOpacity(0.4), dashArray: [6, 6], strokeWidth: 2),
                            HorizontalLine(y: 140, color: EscClassification.color(EscCategory.hypertension).withOpacity(0.4), dashArray: [6, 6], strokeWidth: 2),
                            HorizontalLine(y: 85, color: EscClassification.color(EscCategory.highNormal).withOpacity(0.4), dashArray: [6, 6], strokeWidth: 2),
                            HorizontalLine(y: 130, color: EscClassification.color(EscCategory.highNormal).withOpacity(0.4), dashArray: [6, 6], strokeWidth: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 12,
                    children: [
                      _Legend(color: Colors.redAccent, label: 'PAS'),
                      _Legend(color: Colors.blueAccent, label: 'PAD'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}