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
  bool isAdmin = false; 

  // Global Business Settings
  String brandName = "MY WIFI NET";
  bool showQR = true;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(onCreateTap: _showCreateTicketSheet),
      const PlansPage(),
      const TicketsPage(),
      const PrinterSetupPage(), 
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
              child: const Text("GENERATE & PRINT
