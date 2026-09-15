import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SampleGetData extends StatefulWidget {
  const SampleGetData({super.key});

  @override
  State<SampleGetData> createState() => _SampleGetDataState();
}

class _SampleGetDataState extends State<SampleGetData> {
  List<dynamic> items = [];
  bool isLoading = true;
  String errorMessage = '';

  // NOTE: pick the right host for where you're running the app:
  // - Android emulator -> 10.0.2.2
  // - iOS simulator / Flutter web / desktop -> 127.0.0.1 (or localhost)
  // - Real physical device -> your computer's LAN IP, e.g. 192.168.1.23
  final String apiUrl = 'http://10.0.2.2:8000/data/api/';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          items = jsonDecode(response.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Django Data',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            isLoading = true;
            errorMessage = '';
          });
          return fetchData();
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? ListView(
                    // wrapped in ListView so pull-to-refresh still works on error
                    children: [
                      const SizedBox(height: 100),
                      Center(child: Text(errorMessage)),
                    ],
                  )
                : items.isEmpty
                    ? const Center(child: Text('No data found'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          if (item is Map) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: item.entries.map<Widget>((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '${entry.key}: ${entry.value}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }
                          // fallback if the API just returns a list of plain values
                          return ListTile(title: Text(item.toString()));
                        },
                      ),
      ),
    );
  }
}
