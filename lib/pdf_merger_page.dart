import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'api_service.dart';
import 'utils.dart'; // <-- IMPORT UTILS

class PdfMergerPage extends StatefulWidget {
  const PdfMergerPage({super.key});

  @override
  State<PdfMergerPage> createState() => _PdfMergerPageState();
}

class _PdfMergerPageState extends State<PdfMergerPage> {
  List<PlatformFile> _selectedFiles = [];
  Uint8List? _mergedBytes;
  bool _isMerging = false;

  // --- UPDATED to use new function ---
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    // Call the new top snackbar function from utils.dart
    showTopSnackbar(context, message, isError: isError);
  }

  Future<void> _pickPdfs() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        _mergedBytes = null;
      });
      _showSnackbar('Selected ${_selectedFiles.length} files.');
    } else {
      _showSnackbar('No files selected.', isError: true);
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedFiles.length < 2) return;
    setState(() {
      _isMerging = true;
      _mergedBytes = null;
    });

    try {
      final resultBytes = await ApiService.mergeFiles(
        'merge/pdf',
        _selectedFiles,
      );

      setState(() {
        _isMerging = false;
        _mergedBytes = resultBytes;
      });
      // This is now a GREEN message at the TOP
      _showSnackbar('Files merged successfully!');
    } catch (e) {
      setState(() {
        _isMerging = false;
      });
      // This is now a RED message at the TOP
      _showSnackbar('Error merging files: $e', isError: true);
    }
  }

  Future<void> _downloadFile() async {
    if (_mergedBytes == null) return;
    _showSnackbar('Downloading file...');

    const newFileName = 'DocuTools-Merged-PDF.pdf';

    try {
      if (kIsWeb) {
        final blob = html.Blob([_mergedBytes!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", newFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        anchor.remove();
      } else {
        await FileSaver.instance.saveAs(
          name: newFileName,
          bytes: _mergedBytes!,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
      }
      _showSnackbar('File saved successfully!');
    } catch (e) {
      _showSnackbar('Error saving file: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Merger'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Select PDFs to Merge'),
              onPressed: _pickPdfs,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _selectedFiles.isEmpty
                  ? const Center(
                  child:
                  Text('Select multiple PDF files.\nDrag to reorder.'))
                  : ReorderableListView.builder(
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];
                  return Card(
                    key: ValueKey(file.name + index.toString()),
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf,
                          color: Colors.red),
                      title: Text(file.name),
                      subtitle: Text('File ${index + 1}'),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ),
                  );
                },
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final PlatformFile item =
                    _selectedFiles.removeAt(oldIndex);
                    _selectedFiles.insert(newIndex, item);
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            if (_isMerging) const Center(child: CircularProgressIndicator()),
            if (_mergedBytes != null && !_isMerging)
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download Merged File'),
                onPressed: _downloadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            if (_mergedBytes == null && !_isMerging)
              ElevatedButton.icon(
                icon: const Icon(Icons.merge_type),
                label: const Text('Merge Files'),
                onPressed: _selectedFiles.length < 2 ? null : _mergePdfs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
