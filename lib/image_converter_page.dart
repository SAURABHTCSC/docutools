import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'utils.dart';
import 'common_converter_ui.dart'; // <-- IMPORT THE COMMON UI

class ImageConverterPage extends StatefulWidget {
  const ImageConverterPage({super.key});

  @override
  State<ImageConverterPage> createState() => _ImageConverterPageState();
}

class _ImageConverterPageState extends State<ImageConverterPage> {
  String? _fileName;
  Uint8List? _originalBytes;
  Uint8List? _convertedBytes;
  int _originalSize = 0;
  int _convertedSize = 0;
  bool _isConverting = false;

  // Format state
  final List<String> _formats = ['png', 'jpg', 'jpeg'];
  String _selectedFormat = 'png'; // Default to PNG

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );

    if (result != null) {
      final platformFile = result.files.single;
      Uint8List? bytes;
      int fileSize = 0;

      if (kIsWeb) {
        bytes = platformFile.bytes;
        fileSize = platformFile.size;
      } else {
        final file = File(platformFile.path!);
        bytes = await file.readAsBytes();
        fileSize = await file.length();
      }

      if (bytes != null) {
        setState(() {
          _fileName = platformFile.name;
          _originalBytes = bytes;
          _originalSize = fileSize;
          _convertedBytes = null;
          _convertedSize = 0;
        });
      } else {
        _showSnackbar('Could not read file.');
      }
    } else {
      _showSnackbar('No image selected.');
    }
  }

  // --- THIS IS REAL CONVERSION LOGIC ---
  Future<void> _convertImage() async {
    if (_originalBytes == null) return;
    setState(() { _isConverting = true; _convertedBytes = null; _convertedSize = 0; });

    try {
      Uint8List resultBytes;
      // Determine target format
      CompressFormat format;
      if (_selectedFormat == 'png') {
        format = CompressFormat.png;
      } else if (_selectedFormat == 'jpg' || _selectedFormat == 'jpeg') {
        format = CompressFormat.jpeg;
      } else {
        format = CompressFormat.png; // Default
      }

      // We use the 'format' parameter to convert
      resultBytes = await FlutterImageCompress.compressWithList(
        _originalBytes!,
        format: format,
        quality: 95, // Keep high quality for conversion
      );

      setState(() {
        _isConverting = false;
        _convertedBytes = resultBytes;
        _convertedSize = resultBytes.length;
      });
    } catch (e) {
      setState(() { _isConverting = false; });
      _showSnackbar('Conversion failed: ${e.toString()}');
    }
  }

  Future<void> _downloadFile() async {
    if (_convertedBytes == null) {
      _showSnackbar('No converted file to save.');
      return;
    }
    _showSnackbar('Downloading file...');

    try {
      String originalName = _fileName ?? 'image.jpg';
      String baseName = originalName.contains('.')
          ? originalName.substring(0, originalName.lastIndexOf('.'))
          : originalName;

      // Use the selected format for the new file name and extension
      String newExtension = _selectedFormat;
      String newFileName = 'Docutools-${baseName}_converted.$newExtension';

      MimeType mimeType = MimeType.png;
      String mimeTypeStr = 'image/png';
      if (newExtension == 'jpg' || newExtension == 'jpeg') {
        mimeType = MimeType.jpeg;
        mimeTypeStr = 'image/jpeg';
      }

      if (kIsWeb) {
        final blob = html.Blob([_convertedBytes!], mimeTypeStr);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", newFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        anchor.remove();
      } else {
        await FileSaver.instance.saveAs(
          name: newFileName,
          bytes: _convertedBytes!,
          fileExtension: newExtension,
          mimeType: mimeType,
        );
      }
      _showSnackbar('File saved successfully!');
    } catch (e) {
      _showSnackbar('Error saving file: $e');
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget preview = Container();
    if (_convertedBytes != null) {
      preview = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.memory(
          _convertedBytes!,
          fit: BoxFit.contain,
          height: 200,
        ),
      );
    }

    return CommonConverterUI(
      title: 'Image Converter',
      fileTypeName: 'Image',
      fileTypeIcon: Icons.image,
      onPickFile: _pickImage,
      onConvert: _convertImage,
      onDownload: _downloadFile,
      isConverting: _isConverting,
      originalSize: _originalSize,
      fileName: _fileName,
      convertedSize: _convertedSize,
      previewWidget: preview,
      availableFormats: _formats,
      selectedFormat: _selectedFormat,
      onFormatChanged: (value) {
        setState(() {
          _selectedFormat = value!;
        });
      },
    );
  }
}