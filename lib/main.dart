import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<Map<String, dynamic>> plans = [];
  bool isConnected = false;
  
  // Stats placeholders for hAP ax2
  String cpuLoad = "0%";
  String uptime = "0h 0m";
  int activeUsersCount = 0;
  String freeMem = "0MB";

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // --- WEB-FRIENDLY CONNECTION (PORT 80) ---
  Future<void> _connectToRouter() async {
    setState(() => cpuLoad = "Searching...");
    
    try {
      // This simulates a successful handshake via HTTP/Web Port
      // In the next version, we add the real HTTP Request logic
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        isConnected = true;
        cpuLoad = "3%"; 
        uptime = "Stable";
        activeUsersCount = 14; 
        freeMem = "612MB";
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("JOHBONG PRO: Linked via Web Port!"), backgroundColor: Colors.blueAccent),
      );
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

  // --- DASHBOARD UI ---
  Widget _buildHome() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("JOHBONG PRO", style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const Text("hAP ax2 Management", style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                Icon(Icons.shield_outlined, color: isConnected ? Colors.blueAccent : Colors.redAccent),
              ],
            ),
            const SizedBox(height: 30),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _statCard("CPU LOAD", cpuLoad, Icons.bolt, Colors.orange),
                _statCard("UPTIME", uptime, Icons.timer_outlined, Colors.blue),
                _statCard("CLIENTS", "$activeUsersCount", Icons.devices, Colors.green),
                _statCard("RAM FREE", freeMem, Icons.memory_outlined, Colors.purple),
              ],
            ),
            
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isConnected ? Colors.green : Colors.red, width: 0.3),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: isConnected ? Colors.green : Colors.red, size: 16),
                  const SizedBox(width: 10),
                  Text(isConnected ? "SECURE WEB LINK ACTIVE" : "NO LINKED ROUTER", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(height: 40),
            _actionButton("GENERATE VOUCHERS", () => _generateA4Grid()),
            const SizedBox(height: 15),
            Center(child: TextButton(onPressed: _showSetupDialog, child: const Text("Configure Router", style: TextStyle(color: Colors.white24, fontSize: 12)))),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38, letterSpacing: 1)),
        ],
      ),
    );
  }

  // --- PLANS TAB ---
  Widget _buildPlans() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Service Plans"), backgroundColor: Colors.transparent, elevation: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _showAddPlanDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: plans.isEmpty 
        ? const Center(child: Text("No plans yet. Tap +", style: TextStyle(color: Colors.white24))) 
        : ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: plans.length,
            itemBuilder: (c, i) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                title: Text(plans[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${plans[i]['down']} Down / ${plans[i]['up']} Up"),
                trailing: Text("Tsh ${plans[i]['price']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
    );
  }

  void _showAddPlanDialog() {
    final n = TextEditingController();
    final p = TextEditingController();
    final d = TextEditingController();
    final u = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0A1D33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Create Plan"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: "Plan Name (1HR)")),
        TextField(controller: p, decoration: const InputDecoration(labelText: "Price (Tsh)")),
        TextField(controller: d, decoration: const InputDecoration(labelText: "Download (2M)")),
        TextField(controller: u, decoration: const InputDecoration(labelText: "Upload (1M)")),
      ])),
      actions: [ElevatedButton(onPressed: () {
        setState(() => plans.add({'name': n.text, 'price': p.text, 'down': d.text, 'up': u.text}));
        Navigator.pop(context);
      }, child: const Text("SAVE"))],
    ));
  }

  void _showSetupDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0A1D33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Router Config"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _ipController, decoration: const InputDecoration(labelText: "IP (e.g. 192.168.88.1)")),
        TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username")),
        TextField(controller: _passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
      ]),
      actions: [ElevatedButton(onPressed: _connectToRouter, child: const Text("CONNECT"))],
    ));
  }

  Future<void> _generateA4Grid() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text("JOHBONG PRO VOUCHERS"))));
    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  Widget _actionButton(String l, VoidCallback o) => InkWell(onTap: o, child: Container(height: 55, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.blueAccent), child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)))));
  Widget _buildTickets() => const Center(child: Text("Tickets"));
  Widget _buildReport() => const Center(child: Text("Reports"));
  Widget _buildNavBar() => BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), selectedItemColor: Colors.blueAccent, unselectedItemColor: Colors.white24, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF020B18), items: const [BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"), BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Plans"), BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: "Vault"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Sales")]);
}
