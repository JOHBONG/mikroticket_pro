import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:router_os_client/router_os_client.dart'; // Real Router Engine

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // Load Vouchers, Revenue, and Plans from storage
    setState(() {
      // Logic to parse stored strings back to lists...
    });
  }

  // --- REAL ROUTER CONNECTION ---
  Future<void> _connectToRouter() async {
    try {
      final client = RouterOsClient(
        address: _ipController.text,
        user: _userController.text,
        password: _passController.text,
      );
      
      final connected = await client.connect();
      if (connected) {
        setState(() {
          isConnected = true;
          cpuUsage = "Connected"; 
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Router Link Established!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Link Failed: $e")));
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

  // --- HOME SCREEN ---
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
            _miniMonitor("SYSTEM STATUS", isConnected ? "ACTIVE" : "OFFLINE", Icons.dns),
            const SizedBox(height: 15),
            _glassCard(isConnected ? "ROUTER LIVE" : "ROUTER DISCONNECTED", "Manage your hotspot network.", isConnected ? Colors.greenAccent : Colors.redAccent),
            const Spacer(),
            _actionButton("GENERATE VOUCHERS", () => _showGenerateDialog()),
            const SizedBox(height: 10),
            TextButton(onPressed: _showSetupDialog, child: const Text("Router Setup", style: TextStyle(color: Colors.white24))),
          ],
        ),
      ),
    );
  }

  // --- PLANS SCREEN (The "Corner Plus" Design) ---
  Widget _buildPlans() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Service Plans"), backgroundColor: Colors.transparent, elevation: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddPlanDialog(),
      ),
      body: plans.isEmpty 
        ? const Center(child: Text("No plans yet. Tap + to start.", style: TextStyle(color: Colors.white24)))
        : ListView.builder(
            itemCount: plans.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(plans[i]['name']),
              subtitle: Text("${plans[i]['up']}/${plans[i]['down']} - ${plans[i]['users']} User"),
              trailing: Text("Tsh ${plans[i]['price']}", style: const TextStyle(color: Colors.greenAccent)),
            ),
          ),
    );
  }

  void _showAddPlanDialog() {
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final upC = TextEditingController();
    final downC = TextEditingController();
    final userC = TextEditingController();

    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0A1D33),
      title: const Text("Create New Plan"),
      content: SingleChildScrollView(
        child: Column(children: [
          TextField(controller: nameC, decoration: const InputDecoration(labelText: "Plan Name (e.g. 1 Hour)")),
          TextField(controller: priceC, decoration: const InputDecoration(labelText: "Price (Tsh)")),
          TextField(controller: upC, decoration: const InputDecoration(labelText: "Upload Speed (e.g. 1M)")),
          TextField(controller: downC, decoration: const InputDecoration(labelText: "Download Speed (e.g. 2M)")),
          TextField(controller: userC, decoration: const InputDecoration(labelText: "Users per Voucher")),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () {
          setState(() {
            plans.add({
              'name': nameC.text,
              'price': priceC.text,
              'up': upC.text,
              'down': downC.text,
              'users': userC.text,
            });
          });
          Navigator.pop(context);
        }, child: const Text("Save Plan")),
      ],
    ));
  }

  // --- UI HELPERS ---
  void _showSetupDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0A1D33),
      title: const Text("Router Connection"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _ipController, decoration: const InputDecoration(labelText: "IP (e.g. 192.168.88.1)")),
        TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username")),
        TextField(controller: _passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
      ]),
      actions: [ElevatedButton(onPressed: _connectToRouter, child: const Text("CONNECT"))],
    ));
  }

  void _showGenerateDialog() {
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Create a Plan first!")));
      return;
    }
    // Logic to select plan and generate PDF...
  }

  Widget _miniMonitor(String l, String v, IconData i) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)), child: Column(children: [Icon(i, color: Colors.blueAccent), const SizedBox(height: 10), Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(fontSize: 10, color: Colors.white38))]));
  Widget _glassCard(String t, String s, Color a) => Container(width: double.infinity, padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30)), child: Column(children: [Text(t, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: a)), Text(s, style: const TextStyle(color: Colors.white38))]));
  Widget _actionButton(String l, VoidCallback o) => InkWell(onTap: o, child: Container(height: 60, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Colors.blue, Color(0xFF0D47A1)])), child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)))));
  
  Widget _buildTickets() => Scaffold(appBar: AppBar(title: const Text("Vault"), backgroundColor: Colors.transparent), body: ListView.builder(itemCount: voucherVault.length, itemBuilder: (c, i) => ListTile(title: Text("PIN: ${voucherVault[i]['pin']}"), trailing: Text(voucherVault[i]['status']!))));
  Widget _buildReport() => Scaffold(appBar: AppBar(title: const Text("Revenue"), backgroundColor: Colors.transparent), body: const Center(child: Text("Revenue Tracking Active")));
  
  Widget _buildNavBar() => BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), selectedItemColor: Colors.blueAccent, unselectedItemColor: Colors.white24, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF020B18), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Plans"), BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Tickets"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Revenue")]);
}
