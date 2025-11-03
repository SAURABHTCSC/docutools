import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'utils.dart';
import 'common_compressor_ui.dart'; // <-- IMPORT THE COMMON UI

class ImageCompressorPage extends StatefulWidget {
  const ImageCompressorPage({super.key});

  @override
  State<ImageCompressorPage> createState() => _ImageCompressorPageState();
}

class _ImageCompressorPageState extends State<ImageCompressorPage> {
  // --- All state variables are kept here ---
  String? _fileName;
  Uint8List? _originalBytes;
  Uint8List? _compressedBytes;
  int _originalSize = 0;
  int _compressedSize = 0;
  double _sliderCompression = 10;
  bool _isCompressing = false;
  final _sizeController = TextEditingController();
  String _selectedUnit = 'KB';
  final List<String> _units = ['KB', 'MB', 'GB'];

  // --- All logic methods are kept here ---
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
          _compressedBytes = null;
          _compressedSize = 0;
          _sizeController.clear();
          _sliderCompression = 10;
          _selectedUnit = 'KB';
        });
      } else {
        _showSnackbar('Could not read file.');
      }
    } else {
      _showSnackbar('No image selected.');
    }
  }

  Future<void> _compressImage() async {
    if (_originalBytes == null) return;
    setState(() { _isCompressing = true; _compressedBytes = null; _compressedSize = 0; });

    try {
      int? targetValue = int.tryParse(_sizeController.text);
      Uint8List resultBytes;

      if (targetValue != null && targetValue > 0) {
        int targetBytes = 0;
        int value = targetValue - 1;
        if (value <= 0) value = 1;

        if (_selectedUnit == 'KB') {
          targetBytes = value * 1024;
        } else if (_selectedUnit == 'MB') {
          targetBytes = value * 1024 * 1024;
        } else if (_selectedUnit == 'GB') {
          targetBytes = value * 1024 * 1024 * 1024;
        }

        int quality = 95;
        resultBytes = await FlutterImageCompress.compressWithList(
          _originalBytes!,
          quality: quality,
        );
        while (resultBytes.length > targetBytes && quality > 10) {
          quality -= 10;
          resultBytes = await FlutterImageCompress.compressWithList(
            _originalBytes!,
            quality: quality,
          );
        }
      } else {
        final int quality = (100 - _sliderCompression).round();
        resultBytes = await FlutterImageCompress.compressWithList(
          _originalBytes!,
          quality: quality,
        );
      }
      setState(() {
        _isCompressing = false;
        _compressedBytes = resultBytes;
        _compressedSize = resultBytes.length;
      });
    } catch (e) {
      setState(() { _isCompressing = false; });
      _showSnackbar('Compression failed: ${e.toString()}');
    }
  }

  Future<void> _downloadFile() async {
    if (_compressedBytes == null) {
      _showSnackbar('No compressed file to save.');
      return;
    }
    _showSnackbar('Downloading file...');

    try {
      String originalName = _fileName ?? 'image.jpg';
      String extension = 'jpg';
      String baseName = originalName;

      if (originalName.contains('.')) {
        extension = originalName.split('.').last;
        baseName = originalName.substring(0, originalName.lastIndexOf('.'));
      }
      String newFileName = 'Docutools-${baseName}_compressed.$extension';

      MimeType mimeType = MimeType.jpeg;
      String mimeTypeStr = 'image/jpeg';
      if (extension.toLowerCase() == 'png') {
        mimeType = MimeType.png;
        mimeTypeStr = 'image/png';
      } else if (extension.toLowerCase() == 'gif') {
        mimeType = MimeType.gif;
        mimeTypeStr = 'image/gif';
      }

      if (kIsWeb) {
        final blob = html.Blob([_compressedBytes!], mimeTypeStr);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", newFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        anchor.remove();
      } else {
        await FileSaver.instance.saveAs(
          name: newFileName,
          bytes: _compressedBytes!,
          fileExtension: extension,
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
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Define the specific preview widget for this page ---
    Widget preview = Container();
    if (_compressedBytes != null) {
      preview = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.memory(
          _compressedBytes!,
          fit: BoxFit.contain,
          height: 200,
        ),
      );
    }

    // --- Return the common UI, passing in all state and logic ---
    return CommonCompressorUI(
      title: 'Image Compressor',
      fileTypeName: 'Image',
      fileTypeIcon: Icons.image,
      onPickFile: _pickImage,
      onCompress: _compressImage,
      onDownload: _downloadFile,
      isCompressing: _isCompressing,
      originalSize: _originalSize,
      fileName: _fileName,
      compressedSize: _compressedSize,
      previewWidget: preview, // Pass the custom preview
      sliderCompression: _sliderCompression,
      onSliderChanged: (value) {
        setState(() {
          _sliderCompression = value;
          _sizeController.clear();
        });
      },
      sizeController: _sizeController,
      selectedUnit: _selectedUnit,
      onUnitChanged: (value) {
        setState(() {
          _selectedUnit = value!;
        });
      },
      units: _units,
    );
  }
}