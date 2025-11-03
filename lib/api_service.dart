import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ApiService {

  // --- This is the base URL of your Python server ---
  static const String baseUrl = 'http://localhost:8080';

  // --- A single function to handle all single-file processing ---
  static Future<Uint8List> processFile(
      String endpoint, Uint8List fileBytes, String fileName) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Attach the file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file', // This 'file' key must match request.files['file'] in Python
        fileBytes,
        filename: fileName,
      ),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        // Read the processed file bytes from the response
        return response.stream.toBytes();
      } else {
        // Handle server error
        final errorBody = await response.stream.bytesToString();
        throw Exception(
            'Server failed with status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      // Handle network error
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // --- A single function to handle all multi-file merging ---
  static Future<Uint8List> mergeFiles(
      String endpoint, List<PlatformFile> files) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Attach all the files
    for (var file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files', // This 'files' key must match request.files.getlist('files')
          file.bytes!,
          filename: file.name,
        ),
      );
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        return response.stream.toBytes();
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
            'Server failed with status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}