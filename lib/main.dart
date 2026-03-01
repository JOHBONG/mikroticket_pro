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
  
  String cpu = "0%";
  String ram = "0MB";
  String uptime = "Offline";
  int activeNow = 0;
  double salesToday = 0.0;
  List<Map<String, dynamic>> recentVouchers = [];

  final _ip = TextEditingController(text: "192.168.88.1");
  final _user = TextEditingController(text: "admin");
  final _pass = TextEditingController();

  Future<void> syncBeast() async {
    setState(() => _loading = true);
    final String auth = 'Basic ${base64Encode(utf8.encode('${_user.text}:${_pass.text}'))}';
    final String base = "http://${_ip.text}/rest";

    try {
      final res = await http.get(Uri.parse('$base/system/resource'), headers: {'Authorization': auth}).timeout(const Duration(seconds: 7));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sync Error: Verify Router Credentials")));
    }
  }

  Future<void> generateAndPrint(int count, String price) async {
    final pdf = pw.Document();
    List<String> codes = List.generate(count, (_) => (Random().nextInt(900000) + 100000).toString());
    
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.GridView(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        children: codes.map<pw.Widget>((c) => pw.Container(
          margin: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5),
          ),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(children: [
            pw.Text("JOHBONG NET", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 0.5),
            pw.Text("PIN: $c", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Spacer(),
            pw.Text("Price: Tsh $price", style: pw.TextStyle(fontSize: 8)),
          ])
        )).toList(),
      )
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent)) : _pages()[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        selectedItemColor: Colors.blueAccent,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Dash"),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: "Sales"),
          BottomNavigationBarItem(icon: Icon(Icons.print), label: "Print"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setup"),
        ],
      ),
    );
  }

  List<Widget> _pages() => [ _buildLive(), _buildSales(), _buildVouchers(), _buildSettings()];

  Widget _buildLive() => SafeArea(
    child: RefreshIndicator(
      onRefresh: syncBeast,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        _header("DASHBOARD", "Live hAP ax² Management"),
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
        _actionCard("ACTIVE STATUS", "Real-time communication active", Icons.check_circle, Colors.blueAccent),
      ]),
    ),
  );

  Widget _buildSales() => SafeArea(
    child: ListView(padding: const EdgeInsets.all(20), children: [
      _header("REVENUE", "Income Tracking"),
      const SizedBox(height: 20),
      _revenueCard(),
      const SizedBox(height: 30),
      const Text("RECENT VOUCHERS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 12)),
      ...recentVouchers.map((v) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.qr_code, color: Colors.white24),
        title: Text("User: ${v['user']}"),
        trailing: Text("Tsh ${v['price']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
      )).toList(),
    ]),
  );

  Widget _buildVouchers() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(children: [
        _header("GENERATOR", "Voucher Printing"),
        const Spacer(),
        _printButton("PRINT 500 TSH (40 PCS)", "500", Colors.orange),
        const SizedBox(height: 12),
        _printButton("PRINT 1,000 TSH (40 PCS)", "1000", Colors.blue),
        const SizedBox(height: 12),
        _printButton("PRINT 2,000 TSH (40 PCS)", "2000", Colors.green),
        const Spacer(),
      ]),
    ),
  );

  Widget _buildSettings() => Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(children: [
      _header("CONFIG", "Terminal Credentials"),
      const SizedBox(height: 20),
      TextField(controller: _ip, decoration: const InputDecoration(labelText: "Router IP Address")),
      TextField(controller: _user, decoration: const InputDecoration(labelText: "Admin User")),
      TextField(controller: _pass, decoration: const InputDecoration(labelText: "Admin Password"), obscureText: true),
      const SizedBox(height: 30),
      ElevatedButton(
        onPressed: syncBeast, 
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.blueAccent),
        child: const Text("SAVE & REFRESH DATA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    ]),
  );

  Widget _header(String t, String s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: GoogleFonts.orbitron(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
    Text(s, style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1.2)),
  ]);

  Widget _tile(String l, String v, IconData i, Color c) => Expanded(child: Container(
    margin: const EdgeInsets.all(6), padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(i, color: c, size: 22),
      const SizedBox(height: 12),
      Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(l, style: const TextStyle(fontSize: 9, color: Colors.white38)),
    ]),
  ));

  Widget _revenueCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.green.withOpacity(0.1))),
    child: Column(children: [
      const Text("TODAY'S ESTIMATED SALES", style: TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 10),
      Text("Tsh ${NumberFormat("#,###").format(salesToday)}", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
    ]),
  );

  Widget _printButton(String t, String p, Color c) => InkWell(
    onTap: () => generateAndPrint(40, p),
    child: Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: c.withOpacity(0.3))), child: Center(child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c)))),
  );

  Widget _actionCard(String t, String s, IconData i, Color c) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(i, color: c, size: 20), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)), Text(s, style: const TextStyle(fontSize: 10, color: Colors.white38))])]));
}
