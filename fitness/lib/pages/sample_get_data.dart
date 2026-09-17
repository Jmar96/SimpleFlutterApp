import 'dart:convert';

import 'package:fitness/pages/sample_crud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

class SampleGetData extends StatefulWidget {
  const SampleGetData({super.key});

  @override
  State<SampleGetData> createState() => _SampleGetDataState();
}

class _SampleGetDataState extends State<SampleGetData> {
  // myData in Django looks like {"1": {...}, "2": {...}} -- a Map, not a List
  List<MapEntry<String, dynamic>> items = [];
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
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          items = decoded.entries.toList();
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
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SampleCrud()),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xffF7F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/icons/dots.svg',
                height: 5,
                width: 5,
              ),
            ),
          ),
        ],
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
                  final entry = items[index];
                  final id = entry.key;
                  final value = entry.value;

                  if (value is Map) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: $id',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ...value.entries.map<Widget>((field) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8, top: 2),
                              child: Text(
                                '${field.key}: ${field.value}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }
                  // fallback if a value isn't a nested object
                  return ListTile(title: Text('$id: $value'));
                },
              ),
      ),
    );
  }
}