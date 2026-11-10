import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT Monitoring',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const DashboardPage(),
    );
  }
}

class Reading {
  final String time;
  final double temp;
  Reading(this.time, this.temp);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ===== DATA DUMMY =====
  bool connected = true;
  double temperature = 30.5;
  double humidity = 75;
  String lastUpdate = '10:15:30';
  final String broker = 'broker.hivemq.com';
  final String topic = 'kampus/iot/kelas1/sensor';
  final List<Reading> history = [
    Reading('10:00', 28),
    Reading('10:05', 29),
    Reading('10:10', 28.5),
    Reading('10:15', 30.5),
  ];
  final Random _rnd = Random();

  String _two(int n) => n.toString().padLeft(2, '0');

  // Simulasi data baru masuk (tombol Simulasi Data)
  void _simulateUpdate() {
    final now = DateTime.now();
    setState(() {
      temperature = double.parse((28 + _rnd.nextDouble() * 5).toStringAsFixed(1));
      humidity = (65 + _rnd.nextInt(20)).toDouble();
      lastUpdate = '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}';
      history.add(Reading('${_two(now.hour)}:${_two(now.minute)}', temperature));
      if (history.length > 6) history.removeAt(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _sensorCard(
                      title: 'Temperature',
                      value: '${temperature.toStringAsFixed(1)}°C',
                      sensor: 'Sensor DHT11',
                      icon: Icons.thermostat,
                      bg: const Color(0xFFE3F2FD),
                      fg: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sensorCard(
                      title: 'Humidity',
                      value: '${humidity.toStringAsFixed(0)}%',
                      sensor: 'Sensor DHT11',
                      icon: Icons.water_drop,
                      bg: const Color(0xFFE8F5E9),
                      fg: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _mqttCard(),
              const SizedBox(height: 16),
              _historyCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateUpdate,
        icon: const Icon(Icons.refresh),
        label: const Text('Simulasi Data'),
      ),
    );
  }

  // ===== HEADER + STATUS KONEKSI =====
  Widget _header() {
    final color = connected ? Colors.green : Colors.red;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IoT Monitoring',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Dashboard Monitoring Sensor',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        // Tap untuk ganti Connected / Disconnected (simulasi)
        GestureDetector(
          onTap: () => setState(() => connected = !connected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 6),
                Text(connected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===== KARTU SUHU / KELEMBAPAN =====
  Widget _sensorCard({
    required String title,
    required String value,
    required String sensor,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
          Text(value,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: fg)),
          const SizedBox(height: 4),
          Text(sensor, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  // ===== INFO MQTT =====
  Widget _mqttCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MQTT Connection',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _infoRow('Broker', broker),
          _infoRow('Topic', topic),
          _infoRow('Last Update', lastUpdate),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ===== GRAFIK + TABEL RIWAYAT =====
  Widget _historyCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monitoring History',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Dummy Data', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const Text('Temperature (°C)',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: _chart()),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                  child: Text('Time',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(
                  child: Text('Temperature',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ],
          ),
          const Divider(),
          for (final r in history.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(r.time, style: const TextStyle(fontSize: 13))),
                  Expanded(child: Text('${r.temp}°C', style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chart() {
    return LineChart(
      LineChartData(
        minY: 25,
        maxY: 35,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 5,
              getTitlesWidget: (v, meta) =>
                  Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (v != i.toDouble() || i < 0 || i >= history.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(history[i].time, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < history.length; i++)
                FlSpot(i.toDouble(), history[i].temp),
            ],
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}