import 'package:flutter/material.dart';

void main() => runApp(const MikroTicketFinal());

class MikroTicketFinal extends StatelessWidget {
  const MikroTicketFinal({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020D1C),
        primaryColor: const Color(0xFFD81B60),
      ),
      home: const MainAppShell(),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});
  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;
  bool isAdmin = false; // Controls access level

  // Global Business Settings
  String brandName = "MY WIFI NET";
  bool showQR = true;

  @override
  Widget build(BuildContext context) {
    // Navigation Logic
    final List<Widget> pages = [
      HomePage(onCreateTap: _showCreateTicketSheet),
      const PlansPage(),
      const TicketsPage(),
      const PrinterSetupPage(), // Path B Integration
      isAdmin ? const ReportPage() : AdminLockPage(onSuccess: () => setState(() => isAdmin = true)),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF041529),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Plans'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.print), label: 'Printer'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Revenue'),
        ],
      ),
    );
  }

  void _showCreateTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1D33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Generate New Ticket", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const TextField(decoration: InputDecoration(labelText: "Prefix", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            // The "Boss" Designer Tool
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Text(brandName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  if (showQR) const Icon(Icons.qr_code, color: Colors.black, size: 40),
                  const Text("PIN: 8821-0092", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: () => Navigator.pop(context),
              child: const Text("GENERATE & PRINT"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- ADMIN LOCK SCREEN ---
class AdminLockPage extends StatefulWidget {
  final VoidCallback onSuccess;
  const AdminLockPage({super.key, required this.onSuccess});
  @override
  State<AdminLockPage> createState() => _AdminLockPageState();
}

class _AdminLockPageState extends State<AdminLockPage> {
  String pin = "";
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, color: Colors.pinkAccent, size: 50),
        const Text("Admin Access Required"),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Icon(Icons.circle, size: 12, color: i < pin.length ? Colors.pinkAccent : Colors.white12))),
        const SizedBox(height: 20),
        // Simple numeric pad logic
        Wrap(spacing: 20, runSpacing: 20, children: List.generate(9, (index) => IconButton(
          onPressed: () {
            setState(() => pin += "${index + 1}");
            if (pin == "1234") widget.onSuccess();
            if (pin.length >= 4 && pin != "1234") setState(() => pin = "");
          },
          icon: CircleAvatar(child: Text("${index + 1}")),
        ))),
      ],
    );
  }
}

// --- HOME & REMAINING PAGES ---
class HomePage extends StatelessWidget {
  final VoidCallback onCreateTap;
  const HomePage({super.key, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 20),
            Row(children: [
              _stat(context, "17", "Active", Colors.green),
              _stat(context, "1.1k", "Tickets", Colors.blue),
              _stat(context, "5", "Plans", Colors.purple),
            ]),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60), minimumSize: const Size(double.infinity, 60)),
              onPressed: onCreateTap,
              child: const Text("+ Create tickets", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF0A1D33), borderRadius: BorderRadius.circular(15)),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("ROUTER STATUS", style: TextStyle(color: Colors.white38, fontSize: 10)),
      Text("Connected: 192.168.88.1", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      LinearProgressIndicator(value: 0.2, color: Colors.cyanAccent, backgroundColor: Colors.white10),
    ]),
  );

  Widget _stat(context, String v, String l, Color c) => Expanded(child: Container(
    margin: const EdgeInsets.all(4), padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(color: const Color(0xFF0A1D33), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Icon(Icons.circle, size: 8, color: c), Text(v, style: const TextStyle(fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(fontSize: 10, color: Colors.white54))]),
  ));
}

// STUBS FOR REMAINING PAGES
class PlansPage extends StatelessWidget { const PlansPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Plans"))); }
class TicketsPage extends StatelessWidget { const TicketsPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Vouchers"))); }
class PrinterSetupPage extends StatelessWidget { const PrinterSetupPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Printer Setup")), body: const Center(child: Text("Scanning for Bluetooth Printers..."))); }
class ReportPage extends StatelessWidget { const ReportPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Revenue Report")), body: const Center(child: Text("Total: Tsh 34,500", style: TextStyle(fontSize: 24, color: Colors.greenAccent)))); }
class FilesPage extends StatelessWidget { const FilesPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Files"))); }
