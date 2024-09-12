import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditionally import `dart:html` for the web
import 'conditional_imports/web_import_stub.dart'
    if (dart.library.html) 'dart:html' show AnchorElement;

// Conditionally import `dart:io` for mobile platforms (iOS, Android)
import 'conditional_imports/io_import_stub.dart' if (dart.library.io) 'dart:io'
    show Platform, Directory;

class Storage extends StatefulWidget {
  const Storage({Key? key}) : super(key: key);

  @override
  State<Storage> createState() => _StorageState();
}

class _StorageState extends State<Storage> {
  final String baseUrl = 'http://korika.ddns.net:8000'; // Base URL for API
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ValueNotifier<Set<String>> _selectedImages =
      ValueNotifier<Set<String>>({});

  @override
  void dispose() {
    _selectedImages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Storage'),
        elevation: 0,
        automaticallyImplyLeading: false,
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
              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final imagePath = snapshot.data![index];
                        final imageUrl = '$baseUrl/images/$imagePath';
                        return ValueListenableBuilder<Set<String>>(
                          valueListenable: _selectedImages,
                          builder: (context, selectedImages, child) {
                            final isSelected =
                                selectedImages.contains(imagePath);
                            return GestureDetector(
                              onLongPress: () {
                                _toggleSelection(imagePath);
                              },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      appBar: AppBar(),
                                      body: PhotoView(
                                        imageProvider: NetworkImage(imageUrl),
                                        minScale:
                                            PhotoViewComputedScale.contained,
                                        maxScale:
                                            PhotoViewComputedScale.covered * 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      color: isSelected ? Colors.black54 : null,
                                      colorBlendMode:
                                          isSelected ? BlendMode.darken : null,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Align(
                                      alignment: Alignment.center,
                                      child: Icon(Icons.check,
                                          color: Colors.white, size: 50),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: _selectedImages,
                    builder: (context, selectedImages, child) {
                      if (selectedImages.isNotEmpty) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: _clearSelection,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Deselect All',
                            ),
                            ElevatedButton.icon(
                              onPressed: _showManageSelectedImagesModal,
                              icon: const Icon(Icons.more_horiz),
                              label: const Text('Manage Selected Images'),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
      floatingActionButton: ValueListenableBuilder<Set<String>>(
        valueListenable: _selectedImages,
        builder: (context, selectedImages, child) {
          if (selectedImages.isEmpty) {
            return FloatingActionButton(
              onPressed: () => pickImagesFromGallery(context),
              tooltip: 'Add images',
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink(); // Hide FAB when images are selected
        },
      ),
    );
  }

  void _toggleSelection(String imagePath) {
    if (_selectedImages.value.contains(imagePath)) {
      _selectedImages.value = Set.from(_selectedImages.value)
        ..remove(imagePath);
    } else {
      _selectedImages.value = Set.from(_selectedImages.value)..add(imagePath);
    }
  }

  void _clearSelection() {
    _selectedImages.value = {};
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
    bool uploadSuccessful = true;

    for (XFile image in images) {
      List<int> imageBytes = await image.readAsBytes();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/images'),
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
        uploadSuccessful = false;
        print('Error uploading image: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${response.statusCode}'),
          ),
        );
        break; // Exit the loop on error
      }
    }

    if (uploadSuccessful) {
      setState(() {});
    }
  }

  Future<List<String>> fetchImages(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> imagePath = jsonDecode(response.body);
        return imagePath.map((image) => image['path'] as String).toList();
      } else {
        throw Exception('Failed to load images');
      }
    } catch (e) {
      // Log or handle the error more specifically
      print('Error fetching images: $e');
      return []; // Return an empty list on error
    }
  }

  Future<void> _deleteSelectedImages() async {
    _showLoadingIndicator(context);
    final token = await _retrieveToken();
    bool deletionSuccessful = true;

    for (String imagePath in _selectedImages.value) {
      final response = await http.delete(
        Uri.parse('$baseUrl/images/$imagePath'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        print('Image deleted successfully');
      } else {
        deletionSuccessful = false;
        print('Error deleting image: ${response.statusCode}');
      }
    }

    Navigator.pop(context); // Close the loading indicator

    if (deletionSuccessful) {
      setState(() {
        _selectedImages.value.clear();
      });
    }
  }

  Future<void> _moveImagesToFolder(String folderName) async {
    final token = await _retrieveToken();
    bool moveSuccessful = true;

    for (String imagePath in _selectedImages.value) {
      final response = await http.post(
        Uri.parse('$baseUrl/images/change_folder'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'image_path': imagePath, 'folder': folderName}),
      );

      if (response.statusCode == 200) {
        print('Image moved to $folderName successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image moved to $folderName successfully')),
        );
      } else {
        moveSuccessful = false;
        print('Error moving image: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving image: ${response.statusCode}')),
        );
      }
    }

    if (moveSuccessful) {
      setState(() {
        _selectedImages.value.clear();
      });
    }
  }

  Future<String> _extractUserIdFromToken(String token) async {
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      String userId = decodedToken['user_id'].toString();
      return userId;
    } catch (e) {
      print('Error decoding token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to decode token'),
        ),
      );
      return '';
    }
  }

  Future<List<String>> fetchFolders() async {
    final token = await _retrieveToken();

    String userId = await _extractUserIdFromToken(token);
    final response = await http.get(
      Uri.parse('$baseUrl/folders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> folderData = jsonDecode(response.body);
      return folderData
          .where((folder) => folder['owner_id'].toString() == userId)
          .map((folder) => folder['name'] as String)
          .toList();
    } else {
      throw Exception('Failed to load folders');
    }
  }

  Future<void> _downloadSelectedImages() async {
    final token = await _retrieveToken();
    Dio dio = Dio();

    for (String imagePath in _selectedImages.value) {
      final imageUrl = '$baseUrl/images/$imagePath';

      try {
        if (kIsWeb) {
          // Web: Create an anchor element to trigger download
          AnchorElement anchorElement = AnchorElement(href: imageUrl);
          anchorElement.download = imagePath.split('/').last;
          anchorElement.target = '_blank';
          anchorElement.click();
          print('Web download triggered for $imageUrl');
        } else if (Platform.isAndroid || Platform.isIOS) {
          // Mobile platforms: Use app's document directory
          Directory directory =
              (await getApplicationDocumentsDirectory()) as Directory;
          final filePath = '${directory.path}/${imagePath.split('/').last}';

          // Download image using Dio
          await dio.download(
            imageUrl,
            filePath,
            options: Options(headers: {
              'Authorization': 'Bearer $token',
            }),
          );

          print('Downloaded image to $filePath');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded ${imagePath.split('/').last}')),
          );
        } else {
          throw UnsupportedError('Download is not supported on this platform.');
        }
      } catch (e) {
        print('Error downloading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: ${e.toString()}')),
        );
      }
    }
  }

  void _showManageSelectedImagesModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('Download Selected Images'),
              onTap: () async {
                Navigator.pop(context);
                await _downloadSelectedImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Selected Images'),
              onTap: () async {
                Navigator.pop(context);
                await _deleteSelectedImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move Selected Images to Folder'),
              onTap: () async {
                Navigator.pop(context);
                _showFolderSelectionDialog();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFolderSelectionDialog() async {
    List<String> folders = await fetchFolders();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Folder'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: folders.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(folders[index]),
                  onTap: () async {
                    Navigator.pop(context); // Close the dialog
                    await _moveImagesToFolder(folders[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
