import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class Storage extends StatelessWidget {
  const Storage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Your pictures'),
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Item 1'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Text('Item 2'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child:
            PictureGrid(), // Remove FutureBuilder and directly use PictureGrid
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pickImagesFromGallery();
        },
        tooltip: 'Add images',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String> _retrieveToken() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    print(token);
    return token ??
        ''; // Vraćanje tokena, ili praznog niza ako token nije dostupan
  }

  Future pickImagesFromGallery() async {
    // Implementacija funkcije za odabir slika iz galerije
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    final token = await _retrieveToken();
    await uploadPictures(images, token);
  }

  Future uploadPictures(List<XFile> images, String token) async {
    for (XFile image in images) {
      List<int> imageBytes = await image.readAsBytes();

      // Create a multipart request
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.0.2.2:8000/images'));
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file to the request
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes,
          filename: 'image.jpg'));

      // Send the request
      var response = await request.send();

      // Check the response
      if (response.statusCode == 201) {
        print('Image uploaded successfully');
      } else {
        print('Error uploading image: ${response.statusCode}');
      }
    }
  }
}

class PictureGrid extends StatelessWidget {
  const PictureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          fetchImages(), // Implement fetchImages to get images from your backend
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final List<String> images = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: images.length,
            itemBuilder: (BuildContext context, int index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
              );
            },
          );
        }
      },
    );
  }

  Future<List<String>> fetchImages() async {
    // Implement fetching images from your backend
    // Return a list of image URLs
    return [];
  }
}
