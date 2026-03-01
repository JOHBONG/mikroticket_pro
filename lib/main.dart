import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const JohbongProApp());

class JohbongProApp extends StatelessWidget {
  const JohbongProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020B18),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('logo.png', height: 100, errorBuilder: (c, e, s) => const Icon(Icons.public, size: 80, color: Colors.blue)),
              const SizedBox(height: 20),
              Text("JOHBONG PRO", style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)),
              const Text("Network Administration Suite", style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 60),
              _socialButton("Sign in with Google", Colors.white, Colors.black, () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const JohbongShell()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String label, Color bg, Color text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
        child: Center(child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

class JohbongShell extends StatefulWidget {
  const JohbongShell({super.key});
  @override
  State<JohbongShell> createState() => _JohbongShellState();
}

class _JohbongShellState extends State<JohbongShell> {
  int _currentIndex = 0;
  List<Map<String, String>> voucherVault = [];
  Map<String, int> dailyRevenue = {};
  
  bool isConnected = false;
  String cpuUsage = "0%";
  int activeUsers = 0;

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedVouchers = prefs.getStringList('vouchers');
    if (storedVouchers != null) {
      voucherVault = storedVouchers.map((item) {
        final parts = item.split('|');
        return {'pin': parts[0], 'status': parts[1], 'date': parts[2]};
      }).toList();
    }
    final List<String>? storedRev = prefs.getStringList('revenue_history');
    if (storedRev != null) {
      for (var entry in storedRev) {
        final parts = entry.split('|');
        dailyRevenue[parts[0]] = int.parse(parts[1]);
      }
    }
    setState(() {});
  }

  Future<void> _saveVoucher(String pin, int price) async {
    final prefs = await SharedPreferences.getInstance();
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    voucherVault.insert(0, {'pin': pin, 'status': 'Generated', 'date': date});
    await prefs.setStringList('vouchers', voucherVault.map((e) => "${e['pin']}|${e['status']}|${e['date']}").toList());
    dailyRevenue[date] = (dailyRevenue[date] ?? 0) + price;
    await prefs.setStringList('revenue_history', dailyRevenue.entries.map((e) => "${e.key}|${e.value}").toList());
    setState(() {});
  }

  Future<void> _generateA4Grid() async {
    final pdf = pw.Document();
    List<String> newPins = [];
    for (int i = 0; i < 40; i++) {
      String pin = (Random().nextInt(89999999) + 10000000).toString();
      newPins.add(pin);
      await _saveVoucher(pin, 500);
    }

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.GridView(
          crossAxisCount: 5,
          children: newPins.map<pw.Widget>((p) => pw.Container(
            border: pw.Border.all(width: 0.5),
            padding: const pw.EdgeInsets.all(5),
            child: pw.Center(child: pw.Text(p, style: const pw.TextStyle(fontSize: 10))),
          )).toList(),
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [_buildHome(), _buildPlans(), _buildTickets(), _buildReport()],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildHome() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("JOHBONG", style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold)),
              CircleAvatar(radius: 6, backgroundColor: isConnected ? Colors.green : Colors.red),
            ]),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: _miniMonitor("CPU", cpuUsage, Icons.memory)),
              const SizedBox(width: 15),
              Expanded(child: _miniMonitor("USERS", "$activeUsers", Icons.people)),
            ]),
            const SizedBox(height: 15),
            _glassCard(isConnected ? "SYSTEM ALIVE" : "OFFLINE", isConnected ? "Router connected." : "Setup connection below.", isConnected ? Colors.greenAccent : Colors.redAccent),
            const Spacer(),
            _actionButton("GENERATE VOUCHERS", () => _generateA4Grid()),
            const SizedBox(height: 10),
            TextButton(onPressed: _showSetupDialog, child: const Text("Router Setup", style: TextStyle(color: Colors.white24))),
          ],
        ),
      ),
    );
  }

  void _showSetupDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0A1D33),
      title: const Text("Connection"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _ipController, decoration: const InputDecoration(labelText: "IP")),
        TextField(controller: _userController, decoration: const InputDecoration(labelText: "User")),
        TextField(controller: _passController, decoration: const InputDecoration(labelText: "Pass"), obscureText: true),
      ]),
      actions: [ElevatedButton(onPressed: () { setState(() { isConnected = true; cpuUsage = "12%"; activeUsers = 8; }); Navigator.pop(context); }, child: const Text("CONNECT"))],
    ));
  }

  Widget _miniMonitor(String l, String v, IconData i) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)), child: Column(children: [Icon(i, color: Colors.blueAccent), const SizedBox(height: 10), Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(fontSize: 10, color: Colors.white38))]));
  Widget _glassCard(String t, String s, Color a) => Container(width: double.infinity, padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30)), child: Column(children: [Text(t, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: a)), Text(s, style: const TextStyle(color: Colors.white38))]));
  Widget _actionButton(String l, VoidCallback o) => InkWell(onTap: o, child: Container(height: 60, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Colors.blue, Color(0xFF0D47A1)])), child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)))));
  
  Widget _buildPlans() => Scaffold(appBar: AppBar(title: const Text("Plans"), backgroundColor: Colors.transparent), body: const Center(child: Text("Manage Speeds & Prices")));
  Widget _buildTickets() => Scaffold(appBar: AppBar(title: const Text("Vault"), backgroundColor: Colors.transparent), body: ListView.builder(itemCount: voucherVault.length, itemBuilder: (c, i) => ListTile(title: Text("PIN: ${voucherVault[i]['pin']}"), trailing: Text(voucherVault[i]['status']!))));
  Widget _buildReport() => Scaffold(appBar: AppBar(title: const Text("Revenue"), backgroundColor: Colors.transparent), body: Center(child: Text("Today: Tsh ${dailyRevenue[DateFormat('yyyy-MM-dd').format(DateTime.now())] ?? 0}")));
  
  Widget _buildNavBar() => BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), selectedItemColor: Colors.blueAccent, unselectedItemColor: Colors.white24, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF020B18), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Plans"), BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Tickets"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Revenue")]);
}
