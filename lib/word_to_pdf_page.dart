import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'common_converter_ui.dart';
import 'api_service.dart'; // <-- IMPORT THE API SERVICE

class WordToPdfPage extends StatefulWidget {
  const WordToPdfPage({super.key});

  @override
  State<WordToPdfPage> createState() => _WordToPdfPageState();
}

class _WordToPdfPageState extends State<WordToPdfPage> {
  String? _fileName;
  Uint8List? _originalBytes;
  Uint8List? _convertedBytes;
  int _originalSize = 0;
  int _convertedSize = 0;
  bool _isConverting = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
      withData: true, // Force withData to true
    );

    if (result != null) {
      final platformFile = result.files.single;
      if (platformFile.bytes != null) {
        setState(() {
          _fileName = platformFile.name;
          _originalBytes = platformFile.bytes;
          _originalSize = platformFile.size;
          _convertedBytes = null;
          _convertedSize = 0;
        });
      } else {
        _showSnackbar('Could not read file bytes.');
      }
    } else {
      _showSnackbar('No Word file selected.');
    }
  }

  // --- THIS IS NOW ACTUAL CONVERSION LOGIC ---
  Future<void> _convertFile() async {
    if (_originalBytes == null) return;
    setState(() {
      _isConverting = true;
      _convertedBytes = null;
      _convertedSize = 0;
    });

    try {
      // Send file to the backend
      final resultBytes = await ApiService.processFile(
        'convert/word-to-pdf',
        _originalBytes!,
        _fileName ?? 'file.docx',
      );

      setState(() {
        _isConverting = false;
        _convertedBytes = resultBytes;
        _convertedSize = resultBytes.length;
      });
      _showSnackbar('Conversion successful!');
    } catch (e) {
      setState(() {
        _isConverting = false;
      });
      _showSnackbar('Error converting file: $e');
    }
  }

  Future<void> _downloadFile() async {
    if (_convertedBytes == null) {
      _showSnackbar('No converted file to save.');
      return;
    }
    _showSnackbar('Downloading file...');

    try {
      String originalName = _fileName ?? 'document.docx';
      String baseName =
      originalName.substring(0, originalName.lastIndexOf('.'));
      String newExtension = 'pdf';
      String newFileName = 'DocuTools-${baseName}_converted.$newExtension';

      MimeType mimeType = MimeType.pdf;
      String mimeTypeStr = 'application/pdf';

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
    if (_convertedSize > 0) {
      preview = Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
              SizedBox(height: 10),
              Text(
                'PDF Preview Not Available', // We can add a PDF preview later
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return CommonConverterUI(
      title: 'Word to PDF',
      fileTypeName: 'Word',
      fileTypeIcon: Icons.description,
      onPickFile: _pickFile,
      onConvert: _convertFile,
      onDownload: _downloadFile,
      isConverting: _isConverting,
      originalSize: _originalSize,
      fileName: _fileName,
      convertedSize: _convertedSize,
      previewWidget: preview,
      availableFormats: const [],
      selectedFormat: null,
      onFormatChanged: (value) {},
      showFormatDropdown: false,
    );
  }
}