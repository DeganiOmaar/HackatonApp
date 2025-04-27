import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:robotic_app/statistique/rendement_model.dart';
import 'package:robotic_app/statistique/rendement_service.dart';
import 'package:uuid/uuid.dart';

class RendementStatisticsScreen extends StatefulWidget {
  const RendementStatisticsScreen({super.key});

  @override
  State<RendementStatisticsScreen> createState() => _RendementStatisticsScreenState();
}

class _RendementStatisticsScreenState extends State<RendementStatisticsScreen> {
  late Future<List<RendementModel>> _yieldFuture;

  final Map<String, Color> cultureColors = {
    'Fruit': Colors.green,
    'Légumineuses': Colors.orange,
    'Oliviers': Colors.purple,
    'Blé': Colors.blue,
    'Pommes de terre': Colors.red,
  };

  final List<String> cultures = [
    'Fruit',
    'Légumineuses',
    'Oliviers',
    'Blé',
    'Pommes de terre',
  ];

  @override
  void initState() {
    super.initState();
    _refreshYields();
  }

  void _refreshYields() {
    setState(() {
      _yieldFuture = RendementService.getRendements();
    });
  }

  double _calculateMaxY(List<RendementModel> yields) {
    final maxQuantite = yields.map((e) => e.quantite).reduce((a, b) => a > b ? a : b);
    return (maxQuantite / 500).ceil() * 500;
  }

  List<LineChartBarData> _generateLineBars(List<RendementModel> yields) {
    Map<String, List<RendementModel>> groupedByCulture = {};

    for (var rendement in yields) {
      groupedByCulture.putIfAbsent(rendement.culture, () => []).add(rendement);
    }

    List<LineChartBarData> bars = [];

    groupedByCulture.forEach((culture, rendements) {
      rendements.sort((a, b) => a.annee.compareTo(b.annee));

      bars.add(LineChartBarData(
        spots: rendements.map((r) => FlSpot(r.annee.toDouble(), r.quantite)).toList(),
        isCurved: true,
        color: cultureColors[culture] ?? Colors.black,
        barWidth: 3,
        dotData: FlDotData(show: true),
      ));
    });

    return bars;
  }

  Future<void> _showAddYieldDialog() async {
    String? selectedCulture;
    final TextEditingController anneeController = TextEditingController();
    final TextEditingController quantiteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter Rendement'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedCulture,
                decoration: const InputDecoration(labelText: 'Culture'),
                items: cultures.map((culture) {
                  return DropdownMenuItem(
                    value: culture,
                    child: Text(culture),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCulture = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: anneeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Année'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantiteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantité (kg)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Ajouter'),
            onPressed: () async {
              if (selectedCulture == null ||
                  anneeController.text.isEmpty ||
                  quantiteController.text.isEmpty) {
                return;
              }

              final rendement = RendementModel(
                id: const Uuid().v4(),
                culture: selectedCulture!,
                annee: int.parse(anneeController.text.trim()),
                quantite: double.parse(quantiteController.text.trim()),
              );

              await RendementService.addRendement(rendement);
              Navigator.pop(context);
              _refreshYields();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistiques de Rendement"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<RendementModel>>(
        future: _yieldFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun rendement enregistré.'));
          }

          final yields = snapshot.data!;
          final maxY = _calculateMaxY(yields);
          final lineBars = _generateLineBars(yields);

          // Culture documentation only for the cultures with data
          final culturesWithData = lineBars.map((line) {
            return cultures.firstWhere(
                (culture) => cultureColors[culture] == line.color,
                orElse: () => '');
          }).where((culture) => culture.isNotEmpty);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Évolution du Rendement par Année",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Documentation of cultures with data
                if (culturesWithData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: culturesWithData.map((culture) {
                        return Row(
                          children: [
                            Container(
                              width: 20,
                              height: 2,
                              color: cultureColors[culture],
                            ),
                            const SizedBox(width: 5),
                            Text(
                              culture,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 500,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()} kg', style: const TextStyle(fontSize: 5));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}-', style: const TextStyle(fontSize: 3));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(),
                          bottom: BorderSide(),
                        ),
                      ),
                      lineBarsData: lineBars,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: _showAddYieldDialog,
      ),
    );
  }
}
