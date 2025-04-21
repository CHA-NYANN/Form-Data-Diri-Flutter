import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'display_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/db_cleo.dart';

class FormPage extends StatefulWidget {
  final String? userNIM;

  const FormPage({Key? key, this.userNIM}) : super(key: key);

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _fakultasController = TextEditingController();
  final _prodiController = TextEditingController();
  final _alamatController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _photoPath;
  Uint8List? _photoBytes;

  final DBCleo dbHelper = DBCleo();
  bool _isSaving = false;

  Future<void> saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'title': _nameController.text,
      'content': jsonEncode({
        'nim': _nimController.text,
        'fakultas': _fakultasController.text,
        'prodi': _prodiController.text,
        'alamat': _alamatController.text,
        'phoneNumber': _phoneController.text,
        'photoBytes': _photoBytes != null ? base64Encode(_photoBytes!) : null,
        'photoPath': _photoPath,
      }),
      'timestamp': DateTime.now().toIso8601String(),
      'userNIM': _nimController.text,
    };

    try {
      await dbHelper.insertNote(data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _nameController.text);
      await prefs.setString('nim', _nimController.text);
      await prefs.setString('fakultas', _fakultasController.text);
      await prefs.setString('prodi', _prodiController.text);
      await prefs.setString('alamat', _alamatController.text);
      await prefs.setString('phoneNumber', _phoneController.text);
      if (_photoPath != null) await prefs.setString('photoPath', _photoPath!);
      if (_photoBytes != null) await prefs.setString('photoBytes', base64Encode(_photoBytes!));

      _clearForm();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat menyimpan data')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();

      if (_isValidImage(imageBytes)) {
        setState(() {
          if (kIsWeb) {
            _photoBytes = imageBytes;
            _photoPath = null;
          } else {
            _photoPath = pickedFile.path;
            _photoBytes = null;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gambar tidak valid. Harap pilih JPG atau PNG')),
        );
        setState(() {
          _photoBytes = null;
          _photoPath = null;
        });
      }
    }
  }

  bool _isValidImage(Uint8List bytes) {
    if (bytes.isEmpty) return false;

    if (bytes[0] == 0x89 && bytes[1] == 0x50) return true; // PNG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true; // JPEG

    return false;
  }

  void _clearForm() {
    _nameController.clear();
    _nimController.clear();
    _fakultasController.clear();
    _prodiController.clear();
    _alamatController.clear();
    _phoneController.clear();
    _photoBytes = null;
    _photoPath = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Data Diri'),
        backgroundColor: Colors.teal,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildTextField('Nama', _nameController),
              _buildTextField('NIM', _nimController, TextInputType.number),
              _buildTextField('Fakultas', _fakultasController),
              _buildTextField('Prodi', _prodiController),
              _buildTextField('Alamat', _alamatController),
              _buildTextField('Nomor HP', _phoneController, TextInputType.phone),
              const SizedBox(height: 20),
              _photoBytes != null
                  ? Image.memory(_photoBytes!, height: 150, width: 150, fit: BoxFit.cover)
                  : (_photoPath != null && !kIsWeb)
                  ? Image.file(File(_photoPath!), height: 150, width: 150, fit: BoxFit.cover)
                  : Icon(Icons.photo, size: 150, color: Colors.grey),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.photo_library),
                label: Text('Pilih Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isSaving
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: saveData,
                child: Text('Simpan dan Lihat Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        validator: (value) => value == null || value.isEmpty ? '$label tidak boleh kosong' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.tealAccent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
        ),
      ),
    );
  }
}
