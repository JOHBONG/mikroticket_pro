import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const JohbongProApp());

class JohbongProApp extends StatelessWidget {
  const JohbongProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF010811),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const JohbongMain(),
    );
  }
}

class JohbongMain extends StatefulWidget {
  const JohbongMain({super.key});
  @override
  State<JohbongMain> createState() => _JohbongMainState();
}

class _JohbongMainState extends State<JohbongMain> {
  int _tabIndex = 0;
  bool _loading = false;
  
  // Real-Time States
  String cpu = "0%";
  String ram = "0MB";
  String uptime = "Offline";
  int activeNow = 0;
  double salesToday = 0.0;
  List<Map<String, dynamic>> recentVouchers = [];

  final _ip = TextEditingController(text: "192.168.88.1");
  final _user = TextEditingController(text: "admin");
  final _pass = TextEditingController();

  // --- THE COMMAND ENGINE ---
  Future<void> syncBeast() async {
    setState(() => _loading = true);
    final String auth = 'Basic ${base64Encode(utf8.encode('${_user.text}:${_pass.text}'))}';
    final String base = "http://${_ip.text}/rest";

    try {
      final res = await http.get(Uri.parse('$base/system/resource'), headers: {'Authorization': auth});
      final act = await http.get(Uri.parse('$base/ip/hotspot/active'), headers: {'Authorization': auth});
      final vch = await http.get(Uri.parse('$base/ip/hotspot/user'), headers: {'Authorization': auth});

      if (res.statusCode == 200) {
        final rData = json.decode(res.body)[0];
        final aData = json.decode(act.body) as List;
        final vData = json.decode(vch.body) as List;

        double total = 0;
        recentVouchers.clear();
        for (var v in vData) {
          String priceRaw = v['comment'] ?? "0";
          double p = double.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          total += p;
          if(recentVouchers.length < 10) recentVouchers.add({'user': v['name'], 'price': p});
        }

        setState(() {
          cpu = "${rData['cpu-load']}%";
          ram = "${(int.parse(rData['free-memory']) / 1024 / 1024).toStringAsFixed(0)}MB";
          uptime = rData['uptime'];
          activeNow = aData.length;
          salesToday = total;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // --- VOUCHER GENERATOR & PRINTER ---
  Future<void> generateAndPrint(int count, String price, String profile) async {
    final pdf = pw.Document();
    List<String> codes = [];
    
    // 1. Create Codes in Router & PDF
    for(int i=0; i<count; i++) {
      String code = (Random().nextInt(900000) + 100000).toString();
      codes.add(code);
      // In a real production app, you would send an http.post here to /ip/hotspot/user
    }

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.GridView(
          crossAxisCount: 4,
          children: codes.map((c) => pw.Container(
            margin: const pw.EdgeInsets.all(5),
            border: pw.Border.all(width: 1),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(children: [
              pw.Text("JOHBONG NET", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text("PIN: $c", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text("Price: Tsh $price", style: pw.TextStyle(fontSize: 8)),
            ])
          )).toList(),
        );
      }
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const Center(child: CircularProgressIndicator()) : _pages()[_tabIndex],
      bottomNavigationBar: _buildNavBar(),
    );
  }

  List<Widget> _pages() => [ _buildLive(), _buildSales(), _buildVouchers(), _buildSettings()];

  Widget _buildLive() => SafeArea(
    child: RefreshIndicator(
      onRefresh: syncBeast,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        _header("DASHBOARD", "Live hAP ax² Status"),
        const SizedBox(height: 20),
        Row(children: [
          _tile("CLIENTS", "$activeNow", Icons.people, Colors.green),
          _tile("CPU", cpu, Icons.speed, Colors.orange),
        ]),
        Row(children: [
          _tile("RAM", ram, Icons.memory, Colors.purple),
          _tile("UPTIME", uptime, Icons.timer, Colors.blue),
        ]),
        const SizedBox(height: 30),
        _actionCard("NETWORK SECURE", "Firewall filtering active", Icons.security, Colors.blueAccent),
      ]),
    ),
  );

  Widget _buildSales() => SafeArea(
    child: ListView(padding: const EdgeInsets.all(20), children: [
      _header("REVENUE", "Income Analysis"),
      const SizedBox(height: 20),
      _revenueCard(),
      const SizedBox(height: 30),
      const Text("RECENT SALES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24)),
      ...recentVouchers.map((v) => ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.white24),
        title: Text("PIN: ${v['user']}"),
        trailing: Text("Tsh ${v['price']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
      )).toList(),
    ]),
  );

  Widget _buildVouchers() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(children: [
        _header("VOUCHERS", "Generator & Printer"),
        const Spacer(),
        _printButton("PRINT 500 TSH", "500", Colors.orange),
        const SizedBox(height: 10),
        _printButton("PRINT 1,000 TSH", "1000", Colors.blue),
        const SizedBox(height: 10),
        _printButton("PRINT 2,000 TSH", "2000", Colors.green),
        const Spacer(),
      ]),
    ),
  );

  Widget _buildSettings() => Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(children: [
      _header("SETTINGS", "Router Connection"),
      const SizedBox(height: 20),
      TextField(controller: _ip, decoration: const InputDecoration(labelText: "Router IP")),
      TextField(controller: _user, decoration: const InputDecoration(labelText: "Admin Username")),
      TextField(controller: _pass, decoration: const InputDecoration(labelText: "Admin Password"), obscureText: true),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: syncBeast, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("SYNC BEAST")),
    ]),
  );

  // --- UI COMPONENTS ---
  Widget _header(String t, String s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: GoogleFonts.orbitron(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
    Text(s, style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1.5)),
  ]);

  Widget _tile(String l, String v, IconData i, Color c) => Expanded(child: Container(
    margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(i, color: c, size: 24),
      const SizedBox(height: 10),
      Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(l, style: const TextStyle(fontSize: 9, color: Colors.white38)),
    ]),
  ));

  Widget _revenueCard() => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.withOpacity(0.2), Colors.transparent]), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.green.withOpacity(0.2))),
    child: Column(children: [
      const Text("TODAY'S REVENUE", style: TextStyle(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 10),
      Text("Tsh ${NumberFormat("#,###").format(salesToday)}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
    ]),
  );

  Widget _printButton(String t, String p, Color c) => InkWell(
    onTap: () => generateAndPrint(40, p, "default"),
    child: Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.5))), child: Center(child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c)))),
  );

  Widget _actionCard(String t, String s, IconData i, Color c) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(i, color: c), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 12)), Text(s, style: const TextStyle(fontSize: 10, color: Colors.white38))])]));

  Widget _buildNavBar() => BottomNavigationBar(currentIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i), selectedItemColor: Colors.blueAccent, type: BottomNavigationBarType.fixed, items: const [
    BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Dash"),
    BottomNavigationBarItem(icon: Icon(Icons.insights), label: "Sales"),
    BottomNavigationBarItem(icon: Icon(Icons.print), label: "Print"),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Config"),
  ]);
}
