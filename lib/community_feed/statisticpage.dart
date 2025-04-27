import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:robotic_app/shared/colors.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, double> diseaseCounts = {
    'Mildiou': 0,
    'Mineuse': 0,
    'Moniliose': 0,
  };

  @override
  void initState() {
    super.initState();
    fetchCases();
  }

  Future<void> fetchCases() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('cases').get();

      for (var doc in snapshot.docs) {
        String title = doc['title']?.toString().toLowerCase().trim() ?? '';

        if (title.contains('mildiou')) {
          diseaseCounts['Mildiou'] = diseaseCounts['Mildiou']! + 1;
        } else if (title.contains('mineeuse')) {
          diseaseCounts['Mineuse'] = diseaseCounts['Mineuse']! + 1;
        } else if (title.contains('moniliose')) {
          diseaseCounts['Moniliose'] = diseaseCounts['Moniliose']! + 1;
        }
      }

      setState(() {});
    } catch (e) {
      print('Erreur lors de la récupération des cas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      
        backgroundColor: Colors.white,
        title: const Text(
          'Statistiques des Maladies',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: diseaseCounts.values.every((value) => value == 0)
              ? const Text("Aucune donnée disponible.", style: TextStyle(fontSize: 18))
              : PieChart(
                  dataMap: diseaseCounts,
                  animationDuration: const Duration(milliseconds: 1200),
                  chartRadius: MediaQuery.of(context).size.width / 2,
                  colorList: [
                    mainColor,
                    secondaryColor,
                    Colors.orange,
                  ],
                  chartType: ChartType.disc,
                  ringStrokeWidth: 32,
                  legendOptions: const LegendOptions(
                    showLegends: true,
                    legendPosition: LegendPosition.bottom,
                  ),
                  chartValuesOptions: const ChartValuesOptions(
                    showChartValuesInPercentage: true,
                    showChartValues: true,
                    showChartValueBackground: false,
                  ),
                ),
        ),
      ),
    );
  }
}
