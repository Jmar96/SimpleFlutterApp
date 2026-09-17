import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SampleCrud extends StatefulWidget {
  const SampleCrud({super.key});

  @override
  State<SampleCrud> createState() => _SampleCrudState();
}

class _SampleCrudState extends State<SampleCrud> {
  // NOTE: pick the right host for where you're running the app:
  // - Android emulator -> 10.0.2.2
  // - iOS simulator / Flutter web / desktop -> 127.0.0.1 (or localhost)
  // - Real physical device -> your computer's LAN IP, e.g. 192.168.1.23
  final String baseUrl = 'http://10.0.2.2:8000/data/api/';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  List<MapEntry<String, dynamic>> records = [];
  bool isLoading = true;
  String errorMessage = '';

  // when null we're creating a new record; when set we're editing that id
  String? editingId;

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    super.dispose();
  }

  Future<void> fetchRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          records = decoded.entries.toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Server returned status ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> saveRecord() async {
    final name = nameController.text.trim();
    final role = roleController.text.trim();

    if (name.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Role are both required')),
      );
      return;
    }

    try {
      http.Response response;

      if (editingId == null) {
        // CREATE
        response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name, 'role': role}),
        );
      } else {
        // UPDATE
        response = await http.put(
          Uri.parse('$baseUrl$editingId/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name, 'role': role}),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        clearForm();
        fetchRecords();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl$id/'));
      if (response.statusCode == 200) {
        if (editingId == id) {
          clearForm();
        }
        fetchRecords();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void selectRecord(MapEntry<String, dynamic> entry) {
    final value = entry.value as Map;
    setState(() {
      editingId = entry.key;
      nameController.text = value['name']?.toString() ?? '';
      roleController.text = value['role']?.toString() ?? '';
    });
  }

  void clearForm() {
    setState(() {
      editingId = null;
      nameController.clear();
      roleController.clear();
    });
  }

  Widget _boxedField(String label, TextEditingController controller) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sample CRUD',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name / Role fields, side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _boxedField('Name:', nameController),
                const SizedBox(width: 20),
                _boxedField('Role:', roleController),
              ],
            ),
            const SizedBox(height: 25),

            // Save Button
            Center(
              child: GestureDetector(
                onTap: saveRecord,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    editingId == null ? 'Save Button' : 'Update Button',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            if (editingId != null)
              Center(
                child: TextButton(
                  onPressed: clearForm,
                  child: const Text('Cancel edit'),
                ),
              ),

            const SizedBox(height: 20),

            const Text(
              'Records',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Records box
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: RefreshIndicator(
                  onRefresh: fetchRecords,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage.isNotEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 40),
                                Center(child: Text(errorMessage)),
                              ],
                            )
                          : records.isEmpty
                              ? const Center(child: Text('No records yet'))
                              : ListView.separated(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: records.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final entry = records[index];
                                    final value = entry.value as Map;
                                    final isSelected = editingId == entry.key;

                                    return Material(
                                      color: isSelected
                                          ? Colors.black12
                                          : Colors.transparent,
                                      child: ListTile(
                                        onTap: () => selectRecord(entry),
                                        title: Text(
                                          '${value['name']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text('${value['role']}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () => deleteRecord(entry.key),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
