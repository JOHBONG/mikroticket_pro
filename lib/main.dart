import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:router_os_client/router_os_client.dart';

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
  List<Map<String, dynamic>> plans = [];
  Map<String, int> dailyRevenue = {};
  
  bool isConnected = false;
  String cpuUsage = "0%";
  int activeUsers = 0;

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // --- REAL ROUTER CONNECTION LOGIC ---
  Future<void> _connectToRouter() async {
    try {
      // Corrected class name and initialization
      final client = RouterOsClient(
        address: _ipController.text,
        user: _userController.text,
        password: _passController.text,
      );
      
      final bool connected = await client.connect();
      
      if (connected) {
        setState(() {
          isConnected = true;
          cpuUsage = "Connected";
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("JOHBONG PRO: Link Established!")),
        );
      } else {
        throw Exception("Authentication Failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: $e")),
      );
    }
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
            _miniMonitor("ROUTER LINK", isConnected ? "ONLINE" : "OFFLINE", Icons.settings_input_component),
            const SizedBox(height: 15),
            _glassCard(isConnected ? "CONNECTED" : "NOT CONNECTED", 
                       isConnected ? "Live monitoring active." : "Enter router details in setup.", 
                       isConnected ? Colors.greenAccent : Colors.redAccent),
            const Spacer(),
            _actionButton("GENERATE VOUCHERS", () {
              if(plans.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please create a plan first!")));
              } else {
                _generateA4Grid();
              }
            }),
            const SizedBox(height: 10),
            TextButton(onPressed: _showSetupDialog, child: const Text("Router Setup", style: TextStyle(color: Colors.white24))),
          ],
        ),
      ),
    );
  }

  // --- PLANS TAB ---
  Widget _buildPlans() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Service Plans"), backgroundColor: Colors.transparent),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _showAddPlanDialog,
        child: const Icon(Icons.add),
      ),
      body: plans.isEmpty 
        ? const Center(child: Text("No plans. Tap + to create.")) 
        : ListView.builder(
            itemCount: plans.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(plans[i]['name']),
              subtitle: Text("Limit: ${plans[i]['down']}/${plans[i]['up']}"),
              trailing: Text("Tsh ${plans[i]['price']}"),
            ),
          ),
    );
  }

  void _showAddPlanDialog() {
    final n = TextEditingController();
    final p = TextEditingController();
    final u = TextEditingController();
    final d = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0A1D33),
      title: const Text("New Plan"),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: "Name")),
        TextField(controller: p, decoration: const InputDecoration(labelText: "Price")),
        TextField(controller: d, decoration: const InputDecoration(labelText: "Download (e.g. 2M)")),
        TextField(controller: u, decoration: const InputDecoration(labelText: "Upload (e.g. 1M)")),
      ])),
      actions: [ElevatedButton(onPressed: () {
        setState(() => plans.add({'name': n.text, 'price': p.text, 'down': d.text, 'up': u.text}));
        Navigator.pop(context);
      }, child: const Text("Save"))],
    ));
  }

  // --- PDF GENERATOR FIX ---
  Future<void> _generateA4Grid() async {
    final pdf = pw.Document();
    List<String> newPins = [];
    for (int i = 0; i < 40; i++) {
      String pin = (Random().nextInt(89999999) + 10000000).toString();
      newPins.add(pin);
    }

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.GridView(
        crossAxisCount: 5,
        childAspectRatio: 1.5,
        children: newPins.map<pw.Widget>((p) => pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          padding: const pw.EdgeInsets.all(5),
          child: pw.Center(child: pw.Text(p, style: const pw.TextStyle(fontSize: 12))),
        )).toList(),
      ),
    ));
    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  void _showSetupDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0A1D33),
      title: const Text("Router Setup"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _ipController, decoration: const InputDecoration(labelText: "IP Address")),
        TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username")),
        TextField(controller: _passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
      ]),
      actions: [ElevatedButton(onPressed: _connectToRouter, child: const Text("CONNECT"))],
    ));
  }

  Widget _miniMonitor(String l, String v, IconData i) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)), child: Column(children: [Icon(i, color: Colors.blueAccent), const SizedBox(height: 10), Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(fontSize: 10, color: Colors.white38))]));
  Widget _glassCard(String t, String s, Color a) => Container(width: double.infinity, padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30)), child: Column(children: [Text(t, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: a)), Text(s, style: const TextStyle(color: Colors.white38))]));
  Widget _actionButton(String l, VoidCallback o) => InkWell(onTap: o, child: Container(height: 60, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Colors.blue, Color(0xFF0D47A1)])), child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)))));
  
  Widget _buildTickets() => Scaffold(appBar: AppBar(title: const Text("Vault"), backgroundColor: Colors.transparent), body: const Center(child: Text("Tickets will appear here.")));
  Widget _buildReport() => Scaffold(appBar: AppBar(title: const Text("Revenue"), backgroundColor: Colors.transparent), body: const Center(child: Text("Revenue tracking active.")));
  
  Widget _buildNavBar() => BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), selectedItemColor: Colors.blueAccent, unselectedItemColor: Colors.white24, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF020B18), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Plans"), BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Tickets"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Revenue")]);
}
