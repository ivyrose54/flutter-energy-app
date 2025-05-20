import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const ElectricityDashboardApp());
}

class ElectricityDashboardApp extends StatelessWidget {
  const ElectricityDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electricity Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        fontFamily: 'Arial',
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final List<dynamic> _data = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response =
          await http.get(Uri.parse('https://app-dev-backend.onrender.com/data'));
      if (response.statusCode == 200) {
        final List<dynamic> newData = json.decode(response.body);
        setState(() {
          _data.clear();
          _data.addAll(newData);
        });
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.orange),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = _data.isNotEmpty ? _data.first : null;
    final now = DateFormat('HH:mm:ss').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Monitor'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Metric cards
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoCard(Icons.flash_on, 'Current', latest != null ? '${latest['current']}A' : '--'),
                _buildInfoCard(Icons.electrical_services, 'Voltage', latest != null ? '${latest['voltage']}V' : '--'),
                _buildInfoCard(Icons.bolt, 'Power', latest != null ? '${latest['power']}kW' : '--'),
                _buildInfoCard(Icons.show_chart, 'Energy', latest != null ? '${latest['kwh']}kWh' : '--'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: $now',
              style: const TextStyle(color: Colors.blue, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Records',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _data.isNotEmpty
                  ? ListView.builder(
                      itemCount: _data.length < 5 ? _data.length : 5,
                      itemBuilder: (context, index) {
                        final entry = _data[index];
                        final time = DateFormat('HH:mm:ss').format(DateTime.parse(entry['timestamp']).toLocal());

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.access_time, color: Colors.amber),
                            title: Text(time),
                            subtitle: Text(
                              '${entry['voltage']}V | ${entry['current']}A | ${entry['power']}kW | ${entry['kwh']}kWh',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No data available.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
