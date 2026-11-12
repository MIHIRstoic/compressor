import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageCompressorApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImageCompressorApp extends StatefulWidget {
  @override
  _ImageCompressorAppState createState() => _ImageCompressorAppState();
}

class _ImageCompressorAppState extends State<ImageCompressorApp> {
  File? _selectedImage;
  File? _compressedImage;
  bool _isCompressing = false;
  String? _error;

  // Function to pick an image from the gallery.
  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _compressedImage = null;
          _error = null;
          _isCompressing = true;
        });
        await compressImage(_selectedImage!);
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking image: $e';
        _isCompressing = false;
      });
    }
  }

  // Function to compress the selected image.
  Future<void> compressImage(File image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_image.jpg';

      var result = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: 85,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        if (await compressedFile.exists()) {
          final originalSize = await image.length();
          final compressedSize = await compressedFile.length();

          setState(() {
            _compressedImage = compressedFile;
            _isCompressing = false;
            _error = null;
          });

          print(
              'Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
          print(
              'Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        } else {
          throw Exception('Compressed file not found at path: $targetPath');
        }
      } else {
        throw Exception('Compression returned null path');
      }
    } catch (e) {
      setState(() {
        _error = 'Error compressing image: $e';
        _isCompressing = false;
      });
      print('Error compressing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GFG Image Compression'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ElevatedButton: Used to select images from the gallery.
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isCompressing
                    ? null
                    : pickImage, // Disable when compressing.
                child: Text(_isCompressing
                    ? 'Compressing...' // Show progress message.
                    : 'Pick and Compress Image'),
              ),

              const SizedBox(height: 32),

              // Display original image if selected
              if (_selectedImage != null) ...[
                const Text(
                  'Original Image:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Image.file(
                  _selectedImage!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 32),
              ],

              // Display compressed image if available
              if (_compressedImage != null) ...[
                const Text(
                  'Compressed Image:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Image.file(
                  _compressedImage!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 32),
              ],

              // Error Container: Display the error wrapped in a container
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  // Background color for error message.
                  color: Colors.red.shade100,
                  child: Text(
                    _error!,
                    // Red text color.
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}