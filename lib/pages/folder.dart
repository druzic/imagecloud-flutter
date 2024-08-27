import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Folder extends StatefulWidget {
  const Folder({super.key});

  @override
  State<Folder> createState() => _FolderState();
}

class _FolderState extends State<Folder> {
  final TextEditingController _folderNameController = TextEditingController();
  List<String> _folders = [];

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    print('Fetching folders...');
    try {
      final token = await _retrieveToken();
      print('Token retrieved: $token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/folders'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Assuming the response is a list of maps, each with a 'name' field
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          _folders =
              jsonResponse.map((folder) => folder['name'].toString()).toList();
        });
      } else {
        throw Exception('Failed to load folders');
      }
    } catch (e) {
      print('Error fetching folders: $e');
    }
  }

  Future<void> _createFolder() async {
    final folderName = _folderNameController.text;
    if (folderName.isEmpty) {
      print('Folder name is empty.');
      return;
    }

    try {
      final token = await _retrieveToken();
      print('Token retrieved: $token');
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/folders'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{'name': folderName}),
      );

      if (response.statusCode == 201) {
        setState(() {
          _folders.add(folderName);
          _folderNameController.clear();
        });
        print("Created folder: $folderName");
      } else {
        throw Exception('Failed to create folder');
      }
    } catch (e) {
      print('Error creating folder: $e');
    }
  }

  Future<String> _retrieveToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    print('Token in storage: $token');
    return token ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Folder'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _folderNameController,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                ),
                onPressed: _createFolder,
                child: const Text('Create Folder'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _folders.isEmpty
                    ? const Center(child: Text('No folders available'))
                    : ListView.builder(
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_folders[index]),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FolderDetail(folderName: _folders[index]),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolderDetail extends StatelessWidget {
  final String folderName;

  const FolderDetail({required this.folderName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Text(folderName),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Text('Details for folder: $folderName'),
        ),
      ),
    );
  }
}
