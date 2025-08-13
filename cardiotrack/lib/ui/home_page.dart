import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../ui/journal_page.dart';
import '../ui/chart_page.dart';
import '../ui/export_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final _pages = const [
    JournalPage(),
    ChartPage(),
    ExportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CardioTrack'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset('assets/logo.svg'),
        ),
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Graphique'),
          NavigationDestination(icon: Icon(Icons.ios_share), label: 'Export'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}