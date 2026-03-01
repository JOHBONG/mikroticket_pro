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
      home: const JohbongShell(),
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
  Map<String, int> dailyRevenue = {}; // Stores { '2026-03-01': 20000 }
  
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

  // --- DATABASE: LOAD VOUCHERS & REVENUE ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Vouchers
    final List<String>? storedVouchers = prefs.getStringList('vouchers');
    if (storedVouchers != null) {
      voucherVault = storedVouchers.map((item) {
        final parts = item.split('|');
        return {'pin': parts[0], 'status': parts[1], 'date': parts[2]};
      }).toList();
    }

    // Load Revenue History
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
    
    // Save Voucher
    voucherVault.insert(0, {'pin': pin, 'status': 'Generated', 'date': date});
    List<String> toStore = voucherVault.map((e) => "${e['pin']}|${e['status']}|${e['date']}").toList();
    await prefs.setStringList('vouchers', toStore);

    // Save Revenue
    dailyRevenue[date] = (dailyRevenue[date] ?? 0) + price;
    List<String> revToStore = dailyRevenue.entries.map((e) => "${e.key}|${e.value}").toList();
    await prefs.setStringList('revenue_history', revToStore);
    
    setState(() {});
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1D33),
        title: const Text("Router Connection"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _ipController, decoration: const InputDecoration(labelText: "Router IP")),
            TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isConnected = true;
                cpuUsage = "${Random().nextInt(15) + 5}%";
                activeUsers = Random().nextInt(30);
              });
              Navigator.pop(context);
            },
            child: const Text("CONNECT"),
          ),
        ],
      ),
    );
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

  // --- HOME TAB ---
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
            _glassCard(isConnected ? "SYSTEM ALIVE" : "OFFLINE", 
                       isConnected ? "Router connected." : "Setup connection below.", 
                       isConnected ? Colors.greenAccent : Colors.redAccent),
            const Spacer(),
            _actionButton("GENERATE VOUCHERS", () => _showPrintOptions(context)),
            const SizedBox(height: 10),
            TextButton(onPressed: _showSetupDialog, child: const Text("Router Setup", style: TextStyle(color: Colors.white24))),
          ],
        ),
      ),
    );
  }

  // --- REVENUE REPORT TAB (NEW & FUNCTIONAL) ---
  Widget _buildReport() {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int todaySales = dailyRevenue[today] ?? 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Revenue History", style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _summaryCard("TODAY'S SALES", "Tsh $todaySales", Colors.blueAccent),
            const SizedBox(height: 20),
            const Text("PREVIOUS DAYS", style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: ListView.builder(
                itemCount: dailyRevenue.length,
                itemBuilder: (context, index) {
                  String dateKey = dailyRevenue.keys.elementAt(index);
                  if (dateKey == today) return const SizedBox.shrink();
                  return ListTile(
                    title: Text(dateKey),
                    trailing: Text("Tsh ${dailyRevenue[dateKey]}", style: const TextStyle(color: Colors.greenAccent)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _summaryCard(String title, String val, Color col) => Container(
    padding: const EdgeInsets.all(25),
    width: double.infinity,
    decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(25), border: Border.all(color: col.withOpacity(0.5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 10, letterSpacing: 1.2)),
      Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _miniMonitor(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      Icon(icon, color: Colors.blueAccent, size: 20),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
    ]),
  );

  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1D33),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Generate 40 Vouchers (Tsh 500 each)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _actionButton("GENERATE & PRINT PDF", () => _generateA4Grid()),
          ],
        ),
      ),
    );
  }

  Future<void> _generateA4Grid() async {
    final pdf = pw.Document();
    List<String> newPins = [];
    for (int i = 0; i < 40; i++) {
      String pin = (Random().nextInt(89999999) + 10000000).toString();
      newPins.add(pin);
      await _saveVoucher(pin, 500); // Saves Tsh 500 per voucher
    }
    pdf.addPage(pw.Page(build: (c) => pw.GridView(crossAxisCount: 5, children: newPins.map((p) => pw.Container(border: pw.Border.all(), child: pw.Center(child: pw.Text(p)))).toList())));
    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  Widget _buildPlans() => Scaffold(appBar: AppBar(title: const Text("Plans"), backgroundColor: Colors.transparent), body: const Center(child: Text("Plan Editor Active")));
  Widget _buildTickets() => Scaffold(appBar: AppBar(title: const Text("Voucher Vault"), backgroundColor: Colors.transparent), body: ListView.builder(itemCount: voucherVault.length, itemBuilder: (c, i) => ListTile(title: Text("PIN: ${voucherVault[i]['pin']}"), trailing: Text(voucherVault[i]['status']!))));
  Widget _actionButton(String label, VoidCallback onTap) => InkWell(onTap: onTap, child: Container(height: 60, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Colors.blue, Color(0xFF0D47A1)])), child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)))));
  Widget _glassCard(String t, String s, Color a) => Container(width: double.infinity, padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30)), child: Column(children: [Text(t, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: a)), Text(s, style: const TextStyle(color: Colors.white38))]));
  Widget _buildNavBar() => BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), selectedItemColor: Colors.blueAccent, unselectedItemColor: Colors.white24, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF020B18), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Plans"), BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Tickets"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Revenue")]);
}
