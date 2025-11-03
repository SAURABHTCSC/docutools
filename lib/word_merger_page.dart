import 'dart:io';
import 'dart:typed_data'; // <-- IMPORT THIS
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'api_service.dart'; // <-- IMPORT THE API SERVICE

class WordMergerPage extends StatefulWidget {
  const WordMergerPage({super.key});

  @override
  State<WordMergerPage> createState() => _WordMergerPageState();
}

class _WordMergerPageState extends State<WordMergerPage> {
  List<PlatformFile> _selectedFiles = [];
  Uint8List? _mergedBytes; // <-- Store the merged bytes
  bool _isMerging = false;

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickWords() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
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
      _showSnackbar('No files selected.');
    }
  }

  // --- THIS IS NOW ACTUAL MERGE LOGIC ---
  Future<void> _mergeWords() async {
    if (_selectedFiles.length < 2) return;
    setState(() {
      _isMerging = true;
      _mergedBytes = null;
    });

    try {
      // Send files to the backend
      final resultBytes = await ApiService.mergeFiles(
        'merge/word',
        _selectedFiles,
      );

      setState(() {
        _isMerging = false;
        _mergedBytes = resultBytes;
      });
      _showSnackbar('Files merged successfully!');
    } catch (e) {
      setState(() {
        _isMerging = false;
      });
      _showSnackbar('Error merging files: $e');
    }
  }

  Future<void> _downloadFile() async {
    if (_mergedBytes == null) return;
    _showSnackbar('Downloading file...');

    const newFileName = 'DocuTools-Merged-Word.docx';
    const mimeTypeStr =
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

    try {
      if (kIsWeb) {
        final blob = html.Blob([_mergedBytes!], mimeTypeStr);
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
          fileExtension: 'docx',
          mimeType: MimeType.other,
        );
      }
      _showSnackbar('File saved successfully!');
    } catch (e) {
      _showSnackbar('Error saving file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Merger'), // Removed (Simulated)
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.description),
              label: const Text('Select Word Files to Merge'),
              onPressed: _pickWords,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _selectedFiles.isEmpty
                  ? const Center(
                  child: Text(
                      'Select multiple .docx files.\nDrag to reorder.'))
                  : ReorderableListView.builder(
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];
                  return Card(
                    key: ValueKey(file.name + index.toString()),
                    child: ListTile(
                      leading: const Icon(Icons.description,
                          color: Colors.blue),
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
                onPressed: _selectedFiles.length < 2 ? null : _mergeWords,
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