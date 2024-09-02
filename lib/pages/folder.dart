import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class Folder extends StatefulWidget {
  const Folder({super.key});

  @override
  State<Folder> createState() => _FolderState();
}

Future<String> _extractUserIdFromToken(String token) async {
  try {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    String userId = decodedToken['user_id'].toString();
    return userId;
  } catch (e) {
    print('Error decoding token: $e');
    return '';
  }
}

class _FolderState extends State<Folder> with SingleTickerProviderStateMixin {
  final TextEditingController _folderNameController = TextEditingController();
  List<String> _myFolders = [];
  List<String> _sharedFolders = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _fetchFolders();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _fetchFolders() async {
    try {
      final token = await _retrieveToken();
      String userId = await _extractUserIdFromToken(token);
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/folders'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        print(jsonResponse);
        setState(() {
          _myFolders = jsonResponse
              .where((folder) => folder['owner_id'].toString() == userId)
              .map<String>((folder) => folder['name'].toString())
              .toList();
          _sharedFolders = jsonResponse
              .where((folder) => folder['owner_id'].toString() != userId)
              .map<String>((folder) => folder['name'].toString())
              .toList();
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
          _myFolders.add(folderName);
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
          _myFolders.remove(folderName);
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController emailController = TextEditingController();

        return AlertDialog(
          title: const Text('Share Folder'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Enter email address',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text;
                if (email.isNotEmpty) {
                  try {
                    final token = await _retrieveToken();
                    final response = await http.post(
                      Uri.parse('http://10.0.2.2:8000/folders/share'),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode(<String, String>{
                        'email': email,
                        'folder': folderName,
                      }),
                    );

                    if (response.statusCode == 201) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Folder shared with $email successfully'),
                        ),
                      );
                    } else {
                      throw Exception('Failed to share folder');
                    }
                  } catch (e) {
                    print('Error sharing folder: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sharing folder: $e')),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  void _onFolderLongPress(String folderName) {
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

  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            controller: _folderNameController,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _folderNameController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createFolder();
              },
              child: const Text('Create'),
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
        title: const Text('Folders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Folders'),
            Tab(text: 'Shared With Me'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFolderList(_myFolders),
          _buildFolderList(_sharedFolders),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFolderDialog,
        tooltip: 'Create Folder',
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }

  Widget _buildFolderList(List<String> folders) {
    return folders.isEmpty
        ? const Center(child: Text('No folders available'))
        : ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folderName = folders[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
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
                ),
              );
            },
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
  List<String> _folders = [];

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _fetchFolders();
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

  Future<void> _fetchFolders() async {
    try {
      final token = await _retrieveToken();
      String userId = await _extractUserIdFromToken(token);
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/folders'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          _folders = jsonResponse
              .where((folder) => folder['owner_id'].toString() == userId)
              .map((folder) => folder['name'].toString())
              .toList();
        });
      } else {
        throw Exception('Failed to load folders');
      }
    } catch (e) {
      print('Error fetching folders: $e');
    }
  }

  Future<void> _moveImageToFolder(String imagePath, String targetFolder) async {
    try {
      final token = await _retrieveToken();
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/images/change_folder'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'image_path': imagePath, 'folder': targetFolder}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _images.remove(imagePath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image moved to $targetFolder successfully')),
        );
      } else {
        throw Exception('Failed to move image');
      }
    } catch (e) {
      print('Error moving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving image: $e')),
      );
    }
  }

  Future<void> _deleteImage(String imagePath) async {
    try {
      final token = await _retrieveToken();
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/images/$imagePath'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        setState(() {
          _images.remove(imagePath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete image');
      }
    } catch (e) {
      print('Error deleting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting image: $e')),
      );
    }
  }

  Future<String> _retrieveToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    return token ?? '';
  }

  void _onImageLongPress(String imagePath) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move to Folder'),
              onTap: () async {
                Navigator.pop(context);
                _showFolderSelectionDialog(imagePath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Image'),
              onTap: () async {
                Navigator.pop(context);
                await _deleteImage(imagePath);
              },
            ),
          ],
        );
      },
    );
  }

  void _showFolderSelectionDialog(String imagePath) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Folder'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _folders.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_folders[index]),
                  onTap: () async {
                    Navigator.pop(context); // Close the dialog
                    await _moveImageToFolder(imagePath, _folders[index]);
                  },
                );
              },
            ),
          ),
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
                    onLongPress: () => _onImageLongPress(_images[index]),
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
