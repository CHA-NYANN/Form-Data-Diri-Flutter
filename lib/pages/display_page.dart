import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;

import 'form_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Diri',
      routes: {
        '/': (context) => const DisplayPage(),
        '/form': (context) => const FormPage(),
      },
    );
  }
}

class DisplayPage extends StatefulWidget {
  final String? userNIM;

  const DisplayPage({Key? key, this.userNIM}) : super(key: key);

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  String? name;
  String? nim;
  String? fakultas;
  String? prodi;
  String? alamat;
  String? phoneNumber;
  String? photoPath;
  Uint8List? photoBytes;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      name = prefs.getString('name');
      nim = prefs.getString('nim');
      fakultas = prefs.getString('fakultas');
      prodi = prefs.getString('prodi');
      alamat = prefs.getString('alamat');
      phoneNumber = prefs.getString('phoneNumber');
      photoPath = prefs.getString('photoPath');

      if (kIsWeb) {
        final String? photoBytesString = prefs.getString('photoBytes');
        if (photoBytesString != null && photoBytesString.isNotEmpty) {
          try {
            photoBytes = base64Decode(photoBytesString);
          } catch (_) {
            photoBytes = null;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Diri'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            _buildProfileImage(),
            const SizedBox(height: 16),
            _buildText('Nama', name),
            _buildText('NIM', nim),
            _buildText('Fakultas', fakultas),
            _buildText('Prodi', prodi),
            _buildText('Alamat', alamat),
            _buildText('Nomor HP', phoneNumber),
            const SizedBox(height: 8),
            if (widget.userNIM != null)
              Text(
                'NIM (dari argumen): ${widget.userNIM}',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await Navigator.pushNamed(context, '/form');
                await loadData(); // Refresh setelah balik
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Edit Data',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: ${value ?? 'Tidak ada data'}',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (kIsWeb && photoBytes != null) {
      return _buildImageFromBytes(photoBytes!);
    } else if (!kIsWeb && photoPath != null && photoPath!.isNotEmpty) {
      return _buildImageFromPath(photoPath!);
    } else {
      return const Icon(Icons.photo, size: 150, color: Colors.grey);
    }
  }

  Widget _buildImageFromBytes(Uint8List imageBytes) {
    if (_isValidImage(imageBytes)) {
      return AspectRatio(
        aspectRatio: 2 / 3,
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return const Text(
        "Gambar tidak valid, gunakan format JPG/PNG",
        style: TextStyle(color: Colors.red),
      );
    }
  }

  Widget _buildImageFromPath(String path) {
    try {
      return Image.file(
        File(path),
        height: 150,
        width: 150,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return const Text("Gagal memuat gambar", style: TextStyle(color: Colors.red));
    }
  }

  bool _isValidImage(Uint8List bytes) {
    if (bytes.isEmpty) return false;

    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) return true;

    // JPEG
    if (bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[bytes.length - 2] == 0xFF &&
        bytes[bytes.length - 1] == 0xD9) return true;

    return false;
  }
}
