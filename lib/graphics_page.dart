import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


class GraphicsPage extends StatelessWidget {
  const GraphicsPage({super.key});

  static const kRose = Color(0xFFF297A0);
  static const kRoseLight = Color(0xFFF9D0CE);
  static const kOlive = Color(0xFFB6BB79);

  @override
  // Verifica el rol del usuario y muestra las gráficas si es médico
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _AccessDenied(message: 'Debes iniciar sesión');
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const _AccessDenied(message: 'Perfil no encontrado');
        }
        final data = snapshot.data!.data()!;
        final rol = (data['rol'] ?? 'paciente') as String;
        if (rol != 'médico') {
          return const _AccessDenied(message: 'Acceso denegado. Solo médicos.');
        }

        // Si es médico, muestra las gráficas (aunque no es necesario ya que no puedes ver el boton desde la vista del paciente)
        return ChangeNotifierProvider(
          create: (_) => GraphicsState(),
          child: const _GraphicsScaffold(),
        );
      },
    );
  }
}

// Widget para mostrar acceso denegado
class _AccessDenied extends StatelessWidget {
  final String message;
  const _AccessDenied({required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, style: GoogleFonts.nunito(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

/// Estado compartido para opciones de visualización
class GraphicsState extends ChangeNotifier {
  int months = 12; // últimos meses a mostrar (como un filtro ante los datos del medico)
  bool showLineChart = true;

  void setMonths(int m) {
    months = m;
    notifyListeners();
  }

  void toggleLine(bool v) {
    showLineChart = v;
    notifyListeners();
  }
}

class _GraphicsScaffold extends StatelessWidget {
  const _GraphicsScaffold();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GraphicsState>();
    return Scaffold(
      backgroundColor: GraphicsPage.kRoseLight.withOpacity(0.15),
      appBar: AppBar(
        title: Text('Gráficas Médicas', style: GoogleFonts.fredoka(fontWeight: FontWeight.w700)),
        actions: [
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GraphicsPage.kRoseLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<int>(
                value: state.months,
                dropdownColor: GraphicsPage.kRoseLight,
                iconEnabledColor: GraphicsPage.kRose,
                style: GoogleFonts.nunito(color: GraphicsPage.kRose, fontWeight: FontWeight.w600),
                items: const [6, 12, 24]
                    .map((m) => DropdownMenuItem(value: m, child: Text('Últimos $m meses')))
                    .toList(),
                onChanged: (v) => v != null ? state.setMonths(v) : null,
              ),
            ),
          ),
          Switch(
            value: state.showLineChart,
            onChanged: state.toggleLine,
            activeColor: GraphicsPage.kRose,
            activeTrackColor: GraphicsPage.kRoseLight,
          ),
        ],
      ),

      // Mostrar las gráficas en un layout adaptativo
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final children = <Widget>[
            _BarAppointmentsByMonth(),
            _PieCompletedVsCanceled(),
            if (state.showLineChart) _LinePatientsPerDoctor(),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: children
                        .map((w) => SizedBox(width: constraints.maxWidth / 2 - 24, child: w))
                        .toList(),
                  )
                : Column(
                    children: children
                        .map((w) => Padding(padding: const EdgeInsets.only(bottom: 16), child: w))
                        .toList(),
                  ),
          );
        },
      ),
    );
  }
}

/// Gráfica de barras (cantidad de citas creadas por mes)
class _BarAppointmentsByMonth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final months = context.watch<GraphicsState>().months;
    final fromDate = DateTime(DateTime.now().year, DateTime.now().month - (months - 1), 1);

    final q = FirebaseFirestore.instance
        .collection('citas')
        .where('start', isGreaterThan: Timestamp.fromDate(fromDate))
        .orderBy('start');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Citas creadas por mes', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Fuente: Firestore (citas.start)', style: GoogleFonts.nunito(color: Colors.grey[700])),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: q.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final counts = <String, int>{};
                  for (var i = 0; i < months; i++) {
                    final dt = DateTime(fromDate.year, fromDate.month + i, 1);
                    final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
                    counts[key] = 0;
                  }
                  for (final doc in snapshot.data?.docs ?? []) {
                    final start = (doc.data()['start'] as Timestamp?)?.toDate();
                    if (start == null) continue;
                    final key = '${start.year}-${start.month.toString().padLeft(2, '0')}';
                    if (counts.containsKey(key)) counts[key] = (counts[key] ?? 0) + 1;
                  }

                  final keys = counts.keys.toList();
                  final values = counts.values.toList();
                  final maxY = (values.isEmpty ? 1 : (values.reduce((a, b) => a > b ? a : b))).toDouble();

                  return BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: GraphicsPage.kRoseLight.withOpacity(0.3),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (v) => FlLine(
                          color: GraphicsPage.kRoseLight.withOpacity(0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, meta) {
                            return Text(v.toInt().toString(), style: GoogleFonts.nunito(fontSize: 10));
                          }),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                            final parts = keys[i].split('-');
                            final label = '${parts[1]}/${parts[0].substring(2)}';
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(label, style: GoogleFonts.nunito(fontSize: 10)),
                            );
                          }),
                        ),
                      ),
                      barGroups: List.generate(keys.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i].toDouble(),
                              color: GraphicsPage.kRose,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                      maxY: maxY + 1,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = keys[group.x.toInt()];
                            return BarTooltipItem(
                              '$label\n${rod.toY.toInt()} citas',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 400),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Gráfica de dona (citas completadas vs canceladas)
class _PieCompletedVsCanceled extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final months = context.watch<GraphicsState>().months;
    final fromDate = DateTime(DateTime.now().year, DateTime.now().month - (months - 1), 1);
    final q = FirebaseFirestore.instance
        .collection('citas')
        .where('start', isGreaterThan: Timestamp.fromDate(fromDate))
        .orderBy('start');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completadas vs Canceladas', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Distribución de estados', style: GoogleFonts.nunito(color: Colors.grey[700])),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: q.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  int done = 0, canceled = 0;
                  for (final d in snapshot.data?.docs ?? []) {
                    final raw = d.data()['status'];
                    final status = (raw is String ? raw : raw?.toString())?.toLowerCase().trim();
                    if (status == 'done' || status == 'completed' || status == 'completada') {
                      done++;
                    } else if (status == 'canceled' || status == 'cancelled' || status == 'cancelada' || status == 'cancelado') {
                      canceled++;
                    }
                  }
                  final total = (done + canceled).clamp(1, 999999);
                  final sections = [
                    PieChartSectionData(
                      value: done.toDouble(),
                      title: '${(done / total * 100).round()}%',
                      color: GraphicsPage.kRose,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: canceled.toDouble(),
                      title: '${(canceled / total * 100).round()}%',
                      color: GraphicsPage.kRoseLight,
                      radius: 80,
                    ),
                  ];
                  return Column(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 48,
                            sections: sections,
                            pieTouchData: PieTouchData(enabled: true),
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 400),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _LegendDot(color: GraphicsPage.kRose, label: 'Completadas'),
                          SizedBox(width: 12),
                          _LegendDot(color: GraphicsPage.kRoseLight, label: 'Canceladas'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completadas: '+done.toString()+',  Canceladas: '+canceled.toString(),
                        style: GoogleFonts.nunito(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfica de líneas (pacientes atendidos por médico) aunque puede ser cambiado por citas completadas por médico
class _LinePatientsPerDoctor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final months = context.watch<GraphicsState>().months;
    final fromDate = DateTime(DateTime.now().year, DateTime.now().month - (months - 1), 1);
    final q = FirebaseFirestore.instance
        .collection('citas')
        .where('start', isGreaterThan: Timestamp.fromDate(fromDate))
        .orderBy('start');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pacientes atendidos por médico', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Zoom con gesto y tooltips', style: GoogleFonts.nunito(color: Colors.grey[700])),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: q.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  // Agrupar por doctor y mes
                  final byDoctor = <String, Map<String, int>>{}; // doctor -> monthKey -> count
                  for (final d in snapshot.data?.docs ?? []) {
                    final docData = d.data();
                    final doctorName = (docData['doctorName'] ?? 'N/A') as String;
                    final start = (docData['start'] as Timestamp?)?.toDate();
                    final status = docData['status'] as String?;
                    if (start == null || status != 'done') continue;
                    final key = '${start.year}-${start.month.toString().padLeft(2, '0')}';
                    byDoctor.putIfAbsent(doctorName, () => {});
                    byDoctor[doctorName]![key] = (byDoctor[doctorName]![key] ?? 0) + 1;
                  }

                  // Limitar a los 3 doctores con más atenciones
                  final sortedDoctors = byDoctor.keys.toList()
                    ..sort((a, b) {
                      final ca = byDoctor[a]!.values.fold<int>(0, (p, c) => p + c);
                      final cb = byDoctor[b]!.values.fold<int>(0, (p, c) => p + c);
                      return cb.compareTo(ca);
                    });
                  final topDoctors = sortedDoctors.take(3).toList();

                  // Eje X (meses)
                  final monthKeys = List.generate(months, (i) {
                    final dt = DateTime(fromDate.year, fromDate.month + i, 1);
                    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
                  });

                  final series = <CartesianSeries<String, num>>[];
                  final roseColors = [GraphicsPage.kRose, GraphicsPage.kRoseLight, GraphicsPage.kRose.withOpacity(0.6)];
                  var idx = 0;
                  for (final doctor in topDoctors) {
                    final points = monthKeys.map((k) => byDoctor[doctor]?[k] ?? 0).toList();
                    series.add(LineSeries<String, num>(
                      dataSource: List.generate(monthKeys.length, (i) => monthKeys[i]),
                      xValueMapper: (_, i) => i.toDouble(),
                      yValueMapper: (_, i) => points[i],
                      name: doctor,
                      color: roseColors[idx % roseColors.length],
                      markerSettings: const MarkerSettings(isVisible: true),
                      dataLabelSettings: const DataLabelSettings(isVisible: false),
                    ));
                    idx++;
                  }

                  return SfCartesianChart(
                    primaryXAxis: CategoryAxis(
                      labelRotation: -45,
                      title: AxisTitle(text: 'Mes'),
                    ),
                    primaryYAxis: NumericAxis(title: AxisTitle(text: 'Pacientes')),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    zoomPanBehavior: ZoomPanBehavior(enablePinching: true, enablePanning: true),
                    legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                    series: series,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar un punto en la leyenda con color y texto 
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.nunito()),
      ],
    );
  }
}