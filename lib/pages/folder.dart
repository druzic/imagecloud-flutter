import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';

class Folder extends StatefulWidget {
  const Folder({super.key});

  @override
  State<Folder> createState() => _FolderState();
}

class _FolderState extends State<Folder> {
  final TextEditingController _folderNameController = TextEditingController();
  List<String> _folders = [];
  String? _selectedFolder;

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    try {
      final token = await _retrieveToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/folders'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
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
      return;
    }

    try {
      final token = await _retrieveToken();
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
      } else {
        throw Exception('Failed to create folder');
      }
    } catch (e) {
      print('Error creating folder: $e');
    }
  }

  Future<void> _deleteFolder(String folderName) async {
    try {
      final token = await _retrieveToken();
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/folders/$folderName'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        setState(() {
          _folders.remove(folderName);
          _selectedFolder = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder "$folderName" deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete folder');
      }
    } catch (e) {
      print('Error deleting folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting folder: $e')),
      );
    }
  }

  Future<String> _retrieveToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    return token ?? '';
  }

  void _shareFolder(String folderName) {
    //Share.share('Check out this folder: $folderName');
  }

  void _onFolderLongPress(String folderName) {
    setState(() {
      _selectedFolder = folderName;
    });

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Folder'),
              onTap: () async {
                Navigator.pop(context);
                await _deleteFolder(folderName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Folder'),
              onTap: () {
                Navigator.pop(context);
                _shareFolder(folderName);
              },
            ),
          ],
        );
      },
    );
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
                          final folderName = _folders[index];
                          return ListTile(
                            title: Text(folderName),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FolderDetail(folderName: folderName),
                                ),
                              );
                            },
                            onLongPress: () => _onFolderLongPress(folderName),
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

class FolderDetail extends StatefulWidget {
  final String folderName;

  const FolderDetail({required this.folderName, Key? key}) : super(key: key);

  @override
  _FolderDetailState createState() => _FolderDetailState();
}

class _FolderDetailState extends State<FolderDetail> {
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final token = await _retrieveToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/folders/${widget.folderName}'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          _images =
              jsonResponse.map((image) => image['path'].toString()).toList();
        });
      } else {
        throw Exception('Failed to load images');
      }
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  Future<String> _retrieveToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    return token ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Text(widget.folderName),
        elevation: 0,
      ),
      body: SafeArea(
        child: _images.isEmpty
            ? const Center(child: Text('No images in this folder'))
            : GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final imageUrl =
                      'http://10.0.2.2:8000/images/${_images[index]}'
                          .replaceAll(r'\', '/');
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(),
                            body: PhotoView(
                              imageProvider: NetworkImage(imageUrl),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 2,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
