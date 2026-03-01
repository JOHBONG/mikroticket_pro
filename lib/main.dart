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
  
  // --- NEW: ROUTER STATUS VARIABLES ---
  bool isConnected = false;
  String cpuUsage = "0%";
  int activeUsers = 0;

  // --- NEW: CONTROLLERS FOR SETUP ---
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('vouchers');
    if (stored != null) {
      setState(() {
        voucherVault = stored.map((item) {
          final parts = item.split('|');
          return {'pin': parts[0], 'status': parts[1], 'date': parts[2]};
        }).toList();
      });
    }
  }

  Future<void> _saveVoucher(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    voucherVault.insert(0, {'pin': pin, 'status': 'Generated', 'date': date});
    List<String> toStore = voucherVault.map((e) => "${e['pin']}|${e['status']}|${e['date']}").toList();
    await prefs.setStringList('vouchers', toStore);
    setState(() {});
  }

  // --- NEW: SETUP DIALOG ---
  void _showSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1D33),
        title: const Text("Router Connection"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _ipController, decoration: const InputDecoration(labelText: "Router IP (e.g. 192.168.88.1)")),
            TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isConnected = true; // Simulating connection for now
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
        children: [
          _buildHome(),
          _buildPlans(),
          _buildTickets(),
          _buildReport(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // --- UPDATED HOME TAB WITH MONITORING ---
  Widget _buildHome() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.public, color: Colors.blue),
                const SizedBox(width: 12),
                Text("JOHBONG", style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              CircleAvatar(radius: 6, backgroundColor: isConnected ? Colors.green : Colors.red),
            ]),
            const SizedBox(height: 30),
            
            // MONITORING CARDS
            Row(children: [
              Expanded(child: _miniMonitor("CPU USAGE", cpuUsage, Icons.memory)),
              const SizedBox(width: 15),
              Expanded(child: _miniMonitor("ACTIVE USERS", "$activeUsers", Icons.people)),
            ]),
            const SizedBox(height: 15),
            _glassCard(isConnected ? "SYSTEM ALIVE" : "OFFLINE", 
                       isConnected ? "Router connected perfectly." : "Please setup your router connection.", 
                       isConnected ? Colors.greenAccent : Colors.redAccent),
            
            const Spacer(),
            _actionButton("GENERATE VOUCHER", () => _showPrintOptions(context)),
            const SizedBox(height: 10),
            TextButton(onPressed: _showSetupDialog, child: const Text("Router Setup", style: TextStyle(color: Colors.white24))),
          ],
        ),
      ),
    );
  }

  Widget _miniMonitor(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ]),
    );
  }

  // --- REST OF THE TABS ---
  Widget _buildPlans() {
    return Scaffold(
      appBar: AppBar(title: const Text("Plans"), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _planCard("6hours", "Tsh 500", "10M/10M", "0d 06:00:00"),
          _planCard("1Day", "Tsh 1000", "10M/10M", "1d 00:00:00"),
          _planCard("3Days", "Tsh 2500", "10M/10M", "3d 00:00:00"),
        ],
      ),
    );
  }

  Widget _buildTickets() {
    return Scaffold(
      appBar: AppBar(title: const Text("Voucher Vault"), backgroundColor: Colors.transparent),
      body: voucherVault.isEmpty 
        ? const Center(child: Text("No vouchers found"))
        : ListView.builder(
            itemCount: voucherVault.length,
            itemBuilder: (context, i) => ListTile(
              title: Text("PIN: ${voucherVault[i]['pin']}"),
              subtitle: Text("Date: ${voucherVault[i]['date']}"),
              trailing: Text(voucherVault[i]['status']!, style: const TextStyle(color: Colors.orange)),
            ),
          ),
    );
  }

  Widget _buildReport() {
    return const Center(child: Text("Revenue Navigation Coming Next..."));
  }

  // --- UI HELPERS ---
  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1D33),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Generate A4 Voucher Grid", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _actionButton("GENERATE PDF", () => _generateA4Grid()),
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
      await _saveVoucher(pin);
    }
    pdf.addPage(pw.Page(build: (c) => pw.GridView(crossAxisCount: 5, children: newPins.map((p) => pw.Container(border: pw.Border.all(), child: pw.Center(child: pw.Text(p)))).toList())));
    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  Widget _glassCard(String title, String sub, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)),
      child: Column(children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accent)),
        Text(sub, style: const TextStyle(color: Colors.white38)),
      ]),
    );
  }

  Widget _planCard(String name, String price, String speed, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0A1D33), borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        const Icon(Icons.receipt, color: Colors.blueAccent),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name), Text(price, style: const TextStyle(color: Colors.blueAccent))]),
      ]),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Colors.blue, Colors.blueDark])),
        child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white24,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF020B18),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Plans"),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Tickets"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Revenue"),
      ],
    );
  }
}

// Add a dummy color for the gradient since Flutter doesn't have "blueDark"
extension on Colors { static const Color blueDark = Color(0xFF0D47A1); }
