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

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  // --- DATABASE LOGIC ---
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

  // --- 1. HOME TAB ---
  Widget _buildHome() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(children: [
              Image.asset('logo.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.public, color: Colors.blue)),
              const SizedBox(width: 12),
              Text("JOHBONG", style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ]),
            const SizedBox(height: 40),
            _glassCard("1.2 GB/s", "Current Network Load", Colors.cyanAccent),
            const Spacer(),
            _actionButton("GENERATE VOUCHER", () => _showPrintOptions(context)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- 2. PLANS TAB (From your screenshot) ---
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- 3. TICKETS TAB (Voucher Vault) ---
  Widget _buildTickets() {
    return Scaffold(
      appBar: AppBar(title: const Text("Voucher Vault"), backgroundColor: Colors.transparent),
      body: voucherVault.isEmpty 
        ? const Center(child: Text("No vouchers generated yet"))
        : ListView.builder(
            itemCount: voucherVault.length,
            itemBuilder: (context, i) {
              final v = voucherVault[i];
              return ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.blue),
                title: Text("PIN: ${v['pin']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Generated on ${v['date']}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: v['status'] == 'Completed' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: Text(v['status']!, style: TextStyle(color: v['status'] == 'Completed' ? Colors.green : Colors.orange, fontSize: 10)),
                ),
              );
            },
          ),
    );
  }

  // --- 4. REPORT TAB ---
  Widget _buildReport() {
    return const Center(child: Text("Revenue & Sales History"));
  }

  // --- PDF & PRINTING ENGINE ---
  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1D33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Print A4 Voucher Grid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("This will generate 40 vouchers (8-digit PINs) with 'No-Sharing' security enabled.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),
            _actionButton("PROCEED TO PDF", () => _generateA4Grid()),
          ],
        ),
      ),
    );
  }

  Future<void> _generateA4Grid() async {
    final pdf = pw.Document();
    List<String> newPins = [];
    
    // Generate 40 unique 8-digit pins
    for (int i = 0; i < 40; i++) {
      String pin = (Random().nextInt(89999999) + 10000000).toString();
      newPins.add(pin);
      await _saveVoucher(pin);
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(10),
      build: (pw.Context context) => [
        pw.GridView(
          crossAxisCount: 5,
          childAspectRatio: 0.8,
          children: newPins.map((pin) => pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5, style: pw.BorderStyle.dashed)),
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              children: [
                pw.Text("Johbong.net", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.BarcodeWidget(data: pin, barcode: pw.Barcode.qrCode(), width: 35, height: 35),
                pw.SizedBox(height: 5),
                pw.Text(pin, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text("Tsh 1000 / 1 Day", style: pw.TextStyle(fontSize: 7)),
                pw.Text("Single Device Only", style: pw.TextStyle(fontSize: 5)),
              ],
            ),
          )).toList(),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20),
          child: pw.Center(child: pw.Text("JOHBONG INNOVATIONS - Anti-Sharing Protected", style: const pw.TextStyle(fontSize: 8)))
        )
      ],
    ));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- UI COMPONENTS ---
  Widget _glassCard(String title, String sub, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: [
        Row(children: [CircleAvatar(radius: 4, backgroundColor: accent), const SizedBox(width: 8), const Text("SYSTEM ONLINE", style: TextStyle(fontSize: 10, letterSpacing: 1.5))]),
        const SizedBox(height: 15),
        Text(title, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
        Text(sub, style: const TextStyle(color: Colors.white38)),
      ]),
    );
  }

  Widget _planCard(String name, String price, String speed, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0A1D33), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 40, color: Colors.blueAccent),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("$time  |  $speed", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text(price, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ]),
          const Spacer(),
          const Icon(Icons.more_vert, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 75,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF0052D4)]),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15)],
        ),
        child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
      decoration: BoxDecoration(color: const Color(0xFF051122), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.grid_view_rounded, 0),
          _navIcon(Icons.bolt_rounded, 1),
          _navIcon(Icons.confirmation_num_rounded, 2),
          _navIcon(Icons.bar_chart_rounded, 3),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    return IconButton(
      icon: Icon(icon, color: _currentIndex == index ? Colors.blueAccent : Colors.white24),
      onPressed: () => setState(() => _currentIndex = index),
    );
  }
}
