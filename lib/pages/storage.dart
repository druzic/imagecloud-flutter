import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';

class Storage extends StatefulWidget {
  const Storage({Key? key}) : super(key: key);

  @override
  State<Storage> createState() => _StorageState();
}

class _StorageState extends State<Storage> {
  final String baseUrl = 'http://10.0.2.2:8000/images';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Storage'),
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<List<String>>(
          future: _retrieveToken().then((token) => fetchImages(token)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No images available.'));
            } else {
              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final imagePath = snapshot.data![index];
                  final imageUrl = baseUrl + '/' + imagePath;
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
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => pickImagesFromGallery(context),
        tooltip: 'Add images',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Storage',
          ),
        ],
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/login');
          }
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/storage');
          }
        },
      ),
    );
  }

  Future<String> _retrieveToken() async {
    return await _secureStorage.read(key: 'access_token') ?? '';
  }

  Future<void> pickImagesFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null) {
      final token = await _retrieveToken();
      await uploadPictures(images, token, context);
    }
  }

  Future<void> uploadPictures(
      List<XFile> images, String token, BuildContext context) async {
    for (XFile image in images) {
      List<int> imageBytes = await image.readAsBytes();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: image.name,
        ),
      );

      var response = await request.send();
      if (response.statusCode == 201) {
        print('Image uploaded successfully');
      } else {
        print('Error uploading image: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${response.statusCode}'),
          ),
        );
      }
    }
    setState(() {}); // Refresh the grid view after uploading images
  }

  Future<List<String>> fetchImages(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> imagePath = jsonDecode(response.body);
      return imagePath.map((image) => image['path'] as String).toList();
    } else {
      throw Exception('Failed to load images');
    }
  }
}
