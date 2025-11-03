import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_service.dart'; // We need this to call the merge endpoint
import 'utils.dart'; // For the top snackbar

class PdfMakerUpdatePage extends StatefulWidget {
  const PdfMakerUpdatePage({super.key});

  @override
  State<PdfMakerUpdatePage> createState() => _PdfMakerUpdatePageState();
}

class _PdfMakerUpdatePageState extends State<PdfMakerUpdatePage> {
  PlatformFile? _basePdfFile;
  List<PlatformFile> _newImageFiles = [];
  Uint8List? _mergedPdfBytes;
  bool _isMerging = false;

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    // Use the top snackbar
    showTopSnackbar(context, message, isError: isError);
  }

  Future<void> _pickBasePdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _basePdfFile = result.files.single;
        _mergedPdfBytes = null; // Clear old result
      });
    } else {
      _showSnackbar('No PDF selected.', isError: true);
    }
  }

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _newImageFiles = result.files;
        _mergedPdfBytes = null; // Clear old result
      });
      _showSnackbar('Selected ${_newImageFiles.length} images.');
    } else {
      _showSnackbar('No images selected.', isError: true);
    }
  }

  Future<void> _updatePdf() async {
    if (_basePdfFile == null || _newImageFiles.isEmpty) {
      _showSnackbar('Please select a base PDF and at least one image.', isError: true);
      return;
    }

    setState(() { _isMerging = true; _mergedPdfBytes = null; });

    try {
      final doc = pw.Document();
      for (var imageFile in _newImageFiles) {
        final imageBytes = imageFile.bytes!;
        final image = pw.MemoryImage(imageBytes);
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
      final imagesAsPdfBytes = await doc.save();

      final imagePdfFile = PlatformFile(
        name: 'new_images.pdf',
        bytes: imagesAsPdfBytes,
        size: imagesAsPdfBytes.length,
      );

      final List<PlatformFile> filesToMerge = [_basePdfFile!, imagePdfFile];

      final resultBytes = await ApiService.mergeFiles(
        'merge/pdf',
        filesToMerge,
      );

      setState(() {
        _isMerging = false;
        _mergedPdfBytes = resultBytes;
      });
      _showSnackbar('PDF updated successfully!');
    } catch (e) {
      setState(() { _isMerging = false; });
      _showSnackbar('Error updating PDF: $e', isError: true);
    }
  }

  Future<void> _downloadFile() async {
    if (_mergedPdfBytes == null) return;
    _showSnackbar('Downloading file...');

    try {
      String originalName = _basePdfFile?.name ?? 'document.pdf';
      String baseName = originalName.substring(0, originalName.lastIndexOf('.'));
      final String newFileName = 'DocuTools-${baseName}_updated.pdf';

      if (kIsWeb) {
        final blob = html.Blob([_mergedPdfBytes!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", newFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        anchor.remove();
      } else {
        await FileSaver.instance.saveAs(
          name: newFileName,
          bytes: _mergedPdfBytes!,
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
        title: const Text('Update Existing PDF'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(_basePdfFile == null ? '1. Select Base PDF' : '1. PDF Selected'),
                  onPressed: _isMerging ? null : _pickBasePdf,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _basePdfFile != null ? Colors.grey.shade600 : Colors.blue.shade700,
                      foregroundColor: Colors.white
                  ),
                ),
                if (_basePdfFile != null)
                  Center(child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(_basePdfFile!.name, style: const TextStyle(fontStyle: FontStyle.italic)),
                  )),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(_newImageFiles.isEmpty ? '2. Select Images to Add' : '2. Images Selected'),
                  onPressed: _isMerging ? null : _pickImages,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _newImageFiles.isNotEmpty ? Colors.grey.shade600 : Colors.blue.shade700,
                      foregroundColor: Colors.white
                  ),
                ),
                if (_newImageFiles.isNotEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('${_newImageFiles.length} images selected.', style: const TextStyle(fontStyle: FontStyle.italic)),
                  )),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.merge_type),
                  label: const Text('3. Merge and Update PDF'),
                  onPressed: _isMerging || _basePdfFile == null || _newImageFiles.isEmpty
                      ? null
                      : _updatePdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          if (_isMerging)
            const Expanded(child: Center(child: CircularProgressIndicator())),

          // --- Step 4: Preview and Download ---
          if (_mergedPdfBytes != null)
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
                        label: const Text('Download Updated PDF'),
                        onPressed: _downloadFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PdfPreview(
                        build: (format) => _mergedPdfBytes!,
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