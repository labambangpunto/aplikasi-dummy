import 'package:flutter/material.dart';

import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatat Keuangan',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _transaksi = [];
  double _totalSaldo = 0.0;

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  String _jenisTransaksi = 'Pemasukan';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Mengambil data dari SQLite dan menghitung ulang saldo
  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getSemuaTransaksi();
    double saldo = 0.0;

    for (var item in data) {
      if (item['jenis'] == 'Pemasukan') {
        saldo += item['jumlah'];
      } else {
        saldo -= item['jumlah'];
      }
    }

    setState(() {
      _transaksi = data;
      _totalSaldo = saldo;
    });
  }

  // Menyimpan data ke SQLite
  Future<void> _tambahTransaksi() async {
    if (_judulController.text.isEmpty || _jumlahController.text.isEmpty) return;

    final transaksiBaru = {
      'judul': _judulController.text,
      'jumlah': double.parse(_jumlahController.text),
      'jenis': _jenisTransaksi,
      'tanggal': DateTime.now().toIso8601String(),
    };

    await DatabaseHelper.instance.insertTransaksi(transaksiBaru);

    _judulController.clear();
    _jumlahController.clear();

    if (!mounted) return;
    Navigator.of(context).pop();

    _refreshData();
  }

  Future<void> _hapusTransaksi(int id) async {
    await DatabaseHelper.instance.deleteTransaksi(id);
    _refreshData();
  }

  void _tampilkanDialogTambah() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Transaksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul (cth: Gaji, Makan)',
                ),
              ),
              TextField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _jenisTransaksi,
                items: ['Pemasukan', 'Pengeluaran']
                    .map(
                      (jenis) =>
                          DropdownMenuItem(value: jenis, child: Text(jenis)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _jenisTransaksi = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _tambahTransaksi,
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buku Kas')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Saldo', style: TextStyle(fontSize: 18)),
                Text(
                  'Rp ${_totalSaldo.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _transaksi.length,
              itemBuilder: (context, index) {
                final item = _transaksi[index];
                final isPemasukan = item['jenis'] == 'Pemasukan';
                return ListTile(
                  leading: Icon(
                    isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isPemasukan ? Colors.green : Colors.red,
                  ),
                  title: Text(item['judul']),
                  subtitle: Text(item['tanggal'].substring(0, 10)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isPemasukan ? '+' : '-'} Rp ${item['jumlah'].toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isPemasukan ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _hapusTransaksi(item['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tampilkanDialogTambah,
        child: const Icon(Icons.add),
      ),
    );
  }
}
