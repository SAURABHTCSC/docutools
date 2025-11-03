import 'package:flutter/material.dart';
import 'utils.dart'; // Import the helper function

class CommonConverterUI extends StatelessWidget {
  final String title;
  final String fileTypeName;
  final IconData fileTypeIcon;
  final VoidCallback onPickFile;
  final VoidCallback onConvert;
  final VoidCallback onDownload;
  final bool isConverting;
  final int originalSize;
  final String? fileName;
  final int convertedSize;
  final Widget previewWidget; // The custom preview
  final String? selectedFormat;
  final ValueChanged<String?> onFormatChanged;
  final List<String> availableFormats;
  final bool showFormatDropdown;

  const CommonConverterUI({
    super.key,
    required this.title,
    required this.fileTypeName,
    required this.fileTypeIcon,
    required this.onPickFile,
    required this.onConvert,
    required this.onDownload,
    required this.isConverting,
    required this.originalSize,
    required this.fileName,
    required this.convertedSize,
    required this.previewWidget,
    this.selectedFormat,
    required this.onFormatChanged,
    required this.availableFormats,
    this.showFormatDropdown = true, // Show by default
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: Icon(fileTypeIcon),
              label: Text('Choose $fileTypeName'),
              onPressed: onPickFile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),

            if (originalSize > 0)
              _buildInfoCard(
                'Original File',
                fileName ?? 'Unknown File',
                originalSize,
              ),

            if (originalSize > 0) ...[
              const SizedBox(height: 24),

              // Only show dropdown if it's needed
              if (showFormatDropdown) ...[
                const Text('Select Target Format',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedFormat,
                  items: availableFormats.map((String format) {
                    return DropdownMenuItem<String>(
                      value: format,
                      child: Text(format.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: onFormatChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              ElevatedButton.icon(
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Convert'),
                onPressed: isConverting ? null : onConvert,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            if (isConverting)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (convertedSize > 0) ...[
              const SizedBox(height: 24),
              _buildInfoCard(
                'Converted File',
                'Preview shown below',
                convertedSize,
              ),
              const SizedBox(height: 16),

              // --- BUTTON IS NOW ABOVE PREVIEW ---
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download File'),
                onPressed: onDownload,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // This is where the custom Image/PDF/Video preview goes
              previewWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String fileName, int fileSize) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Text(fileName,
                style: const TextStyle(fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(
              'Size: ${formatBytes(fileSize)}',
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.blue.shade800),
            ),
          ],
        ),
      ),
    );
  }
}