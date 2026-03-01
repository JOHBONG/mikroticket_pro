import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:router_os_client/router_os_client.dart'; // The Engine

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
  bool isConnected = false;

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // --- THE FIXED ENGINE LOGIC ---
  Future<void> _connectToRouter() async {
    try {
      // FIX: Changed RouterOsClient to RouterOSClient (Capital OS)
      final client = RouterOSClient(
        address: _ipController.text,
        user: _userController.text,
        password: _passController.text,
        useSsl: false,
      );
      
      // FIX: Using .login() as required by this package version
      final bool success = await client.login();
      
      if (success) {
        setState(() => isConnected = true);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("JOHBONG PRO: Link Established!")),
        );
        client.close(); // Clean up the connection after check
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Link Failed: $e")),
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
            const SizedBox(height: 50),
            Icon(Icons.router, size: 80, color: isConnected ? Colors.blue : Colors.white10),
            const SizedBox(height: 20),
            Text(isConnected ? "SYSTEM ACTIVE" : "SYSTEM OFFLINE", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            _actionButton("GENERATE VOUCHERS", () => _generateA4Grid()),
            const SizedBox(height: 10),
            TextButton(onPressed: _showSetupDialog, child: const Text("Router Setup", style: TextStyle(color: Colors.white24))),
          ],
        ),
      ),
    );
  }

  // --- PLANS TAB (CORNER PLUS) ---
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
        ? const Center(child: Text("No plans yet. Tap + to start.")) 
        : ListView.builder(
            itemCount: plans.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(plans[i]['name']),
              subtitle: Text("Price: Tsh ${plans[i]['price']}"),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
    );
  }

  void _showAddPlanDialog() {
    final n = TextEditingController();
    final p = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0A1D33),
      title: const Text("Add New Plan"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: "Plan Name")),
        TextField(controller: p, decoration: const InputDecoration(labelText: "Price (Tsh)")),
      ]),
      actions: [ElevatedButton(onPressed: () {
        setState(() => plans.add({'name': n.text, 'price': p.text}));
        Navigator.pop(context);
      }, child: const Text("Save"))],
    ));
  }

  Future<void> _generateA4Grid() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text("JOHBONG VOUCHERS"))));
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

  Widget _actionButton(String l, VoidCallback o) => InkWell(onTap: o, child: Container(height: 60, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Colors.blue, Color(0xFF0D47A1)])), child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)))));
  Widget _buildTickets() => const Center(child: Text("Vault"));
  Widget _buildReport() => const Center(child: Text("Revenue"));
  Widget _buildNavBar() => BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), selectedItemColor: Colors.blueAccent, unselectedItemColor: Colors.white24, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF020B18), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Plans"), BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Tickets"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Revenue")]);
}
