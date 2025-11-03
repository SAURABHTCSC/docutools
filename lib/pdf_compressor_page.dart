import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'package:printing/printing.dart'; // For PDF Preview
import 'utils.dart';
import 'common_compressor_ui.dart';
import 'api_service.dart'; // <-- IMPORT THE API SERVICE

class PdfCompressorPage extends StatefulWidget {
  const PdfCompressorPage({super.key});

  @override
  State<PdfCompressorPage> createState() => _PdfCompressorPageState();
}

class _PdfCompressorPageState extends State<PdfCompressorPage> {
  String? _fileName;
  Uint8List? _originalBytes;
  Uint8List? _compressedBytes;

  int _originalSize = 0;
  int _compressedSize = 0;
  double _sliderCompression = 10; // Note: Server doesn't use this yet
  bool _isCompressing = false;
  final _sizeController = TextEditingController(); // Note: Server doesn't use this yet
  String _selectedUnit = 'KB';
  final List<String> _units = ['KB', 'MB', 'GB'];

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Force withData to true
    );

    if (result != null) {
      final platformFile = result.files.single;
      if (platformFile.bytes != null) {
        setState(() {
          _fileName = platformFile.name;
          _originalBytes = platformFile.bytes;
          _originalSize = platformFile.size;
          _compressedBytes = null;
          _compressedSize = 0;
          _sizeController.clear();
          _sliderCompression = 10;
          _selectedUnit = 'KB';
        });
      } else {
        _showSnackbar('Could not read file bytes.');
      }
    } else {
      _showSnackbar('No PDF selected.');
    }
  }

  // --- THIS IS NOW ACTUAL BACKEND COMPRESSION ---
  Future<void> _compressPdf() async {
    if (_originalBytes == null) return;
    setState(() {
      _isCompressing = true;
      _compressedBytes = null;
      _compressedSize = 0;
    });

    try {
      // Send file to the backend
      // Note: The simple backend doesn't use the slider/size values yet.
      // It applies a default PyPDF2 compression.
      final resultBytes = await ApiService.processFile(
        'compress/pdf',
        _originalBytes!,
        _fileName ?? 'file.pdf',
      );

      setState(() {
        _isCompressing = false;
        _compressedBytes = resultBytes;
        _compressedSize = resultBytes.length;
      });
      _showSnackbar('Compression successful!');
    } catch (e) {
      setState(() {
        _isCompressing = false;
      });
      _showSnackbar('Error compressing file: $e');
    }
  }

  Future<void> _downloadFile() async {
    if (_compressedBytes == null) {
      _showSnackbar('No compressed file to save.');
      return;
    }
    _showSnackbar('Downloading file...');

    try {
      String originalName = _fileName ?? 'document.pdf';
      String baseName =
      originalName.substring(0, originalName.lastIndexOf('.'));
      String newFileName = 'DocuTools-${baseName}_compressed.pdf';

      MimeType mimeType = MimeType.pdf;

      if (kIsWeb) {
        final blob = html.Blob([_compressedBytes!], 'application/pdf');
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
          fileExtension: 'pdf',
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
    Widget preview = Container();
    if (_compressedBytes != null) {
      // We can still use PdfPreview on the new compressed bytes!
      preview = Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: PdfPreview(
            build: (format) => _compressedBytes!,
            useActions: false,
          ));
    }

    return CommonCompressorUI(
      title: 'PDF Compressor',
      fileTypeName: 'PDF',
      fileTypeIcon: Icons.picture_as_pdf,
      onPickFile: _pickPdf,
      onCompress: _compressPdf,
      onDownload: _downloadFile,
      isCompressing: _isCompressing,
      originalSize: _originalSize,
      fileName: _fileName,
      compressedSize: _compressedSize,
      previewWidget: preview,
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