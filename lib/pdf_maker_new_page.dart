import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // For the preview
import 'utils.dart'; // For the top snackbar

class PdfMakerNewPage extends StatefulWidget {
  const PdfMakerNewPage({super.key});

  @override
  State<PdfMakerNewPage> createState() => _PdfMakerNewPageState();
}

class _PdfMakerNewPageState extends State<PdfMakerNewPage> {
  List<PlatformFile> _selectedImageFiles = [];
  Uint8List? _generatedPdfBytes;
  bool _isMerging = false;

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    // Use the top snackbar
    showTopSnackbar(context, message, isError: isError);
  }

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _generatedPdfBytes = null;
        _selectedImageFiles = result.files;
      });
      _showSnackbar('Selected ${_selectedImageFiles.length} images.');
    } else {
      _showSnackbar('No images selected.', isError: true);
    }
  }

  Future<void> _mergeImages() async {
    if (_selectedImageFiles.isEmpty) return;
    setState(() { _isMerging = true; _generatedPdfBytes = null; });

    try {
      final doc = pw.Document();

      for (var file in _selectedImageFiles) {
        final imgBytes = file.bytes!;
        final image = pw.MemoryImage(imgBytes);

        doc.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(0),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final bytes = await doc.save();
      setState(() {
        _generatedPdfBytes = bytes;
        _isMerging = false;
      });
      _showSnackbar('PDF created successfully!'); // Green top message
    } catch (e) {
      setState(() { _isMerging = false; });
      _showSnackbar('Error creating PDF: $e', isError: true);
    }
  }

  Future<void> _downloadFile() async {
    if (_generatedPdfBytes == null) return;
    _showSnackbar('Downloading file...');

    try {
      const String newFileName = 'DocuTools-New-PDF.pdf';
      if (kIsWeb) {
        final blob = html.Blob([_generatedPdfBytes!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", newFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        anchor.remove();
      } else {
        await FileSaver.instance.saveAs(
          name: newFileName,
          bytes: _generatedPdfBytes!,
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
        title: const Text('Create New PDF from Images'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Select Images'),
                  onPressed: _isMerging ? null : _pickImages,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Convert to PDF'),
                  onPressed: _isMerging || _selectedImageFiles.isEmpty
                      ? null
                      : _mergeImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (_isMerging)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          // --- Preview and Reorder List ---
          if (_generatedPdfBytes == null && !_isMerging && _selectedImageFiles.isNotEmpty)
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedImageFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedImageFiles[index];
                  return Card(
                    key: ValueKey(file.name + index.toString()),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Image.memory(
                        file.bytes!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Page ${index + 1}'),
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
                    final PlatformFile item = _selectedImageFiles.removeAt(oldIndex);
                    _selectedImageFiles.insert(newIndex, item);
                  });
                },
              ),
            ),

          // --- PDF Preview and Download ---
          if (_generatedPdfBytes != null)
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: Column(
                  children: [
                    // --- BUTTON IS NOW ABOVE PREVIEW ---
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download New PDF'),
                        onPressed: _downloadFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PdfPreview(
                        build: (format) => _generatedPdfBytes!,
                        useActions: false, // Hide default print/share
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}