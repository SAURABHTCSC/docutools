import 'package:flutter/material.dart';

// Import all the tool pages
import 'image_compressor_page.dart';
import 'pdf_compressor_page.dart';
import 'image_converter_page.dart';
import 'word_to_pdf_page.dart';
import 'pdf_to_excel_page.dart';
import 'pdf_merger_page.dart';
import 'word_merger_page.dart';
import 'pdf_maker_new_page.dart';
import 'pdf_maker_update_page.dart';

// This is the data for a single searchable tool
class _ToolData {
  final String title;
  final String description;
  final IconData icon;
  final Widget page;

  _ToolData({
    required this.title,
    required this.description,
    required this.icon,
    required this.page,
  });
}

class ToolSearchDelegate extends SearchDelegate {

  // This is the complete, UPDATED list of all tools in your app
  final List<_ToolData> _allTools = [
    _ToolData(
      title: 'Image Compressor',
      description: 'Compress .png, .jpg, .jpeg files',
      icon: Icons.image,
      page: const ImageCompressorPage(),
    ),
    _ToolData(
      title: 'PDF Compressor',
      description: 'Compress .pdf files using Ghostscript',
      icon: Icons.picture_as_pdf,
      page: const PdfCompressorPage(),
    ),
    _ToolData(
      title: 'Image Converter',
      description: 'Convert PNG, JPG, JPEG',
      icon: Icons.sync_rounded,
      page: const ImageConverterPage(),
    ),
    _ToolData(
      title: 'Word to PDF',
      description: 'Convert .docx files to .pdf',
      icon: Icons.description,
      page: const WordToPdfPage(),
    ),
    _ToolData(
      title: 'PDF to Excel',
      description: 'Extract tables from .pdf to .xlsx',
      icon: Icons.table_chart,
      page: const PdfToExcelPage(),
    ),
    _ToolData(
      title: 'PDF Merger',
      description: 'Merge multiple .pdf files into one',
      icon: Icons.merge_type,
      page: const PdfMergerPage(),
    ),
    _ToolData(
      title: 'Word Merger',
      description: 'Merge multiple .docx files into one',
      icon: Icons.merge_type,
      page: const WordMergerPage(),
    ),
    _ToolData(
      title: 'Create New PDF',
      description: 'Merge images into a new PDF',
      icon: Icons.add_to_photos,
      page: const PdfMakerNewPage(),
    ),
    _ToolData(
      title: 'Update Existing PDF',
      description: 'Add images to an existing PDF file',
      icon: Icons.add_circle,
      page: const PdfMakerUpdatePage(),
    ),
  ];

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Clear button
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // Back button
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // This shows the results after user presses "Enter"
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // This shows results as the user is typing
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = _allTools.where((tool) {
      final queryLower = query.toLowerCase();
      final titleLower = tool.title.toLowerCase();
      final descLower = tool.description.toLowerCase();

      return titleLower.contains(queryLower) || descLower.contains(queryLower);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final tool = results[index];
        return ListTile(
          leading: Icon(tool.icon),
          title: Text(tool.title),
          subtitle: Text(tool.description),
          onTap: () {
            // Close the search and go to the tool's page
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => tool.page),
            );
          },
        );
      },
    );
  }
}
