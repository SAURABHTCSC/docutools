import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils.dart'; // Import the helper function

class CommonCompressorUI extends StatelessWidget {
  final String title;
  final String fileTypeName;
  final IconData fileTypeIcon;
  final VoidCallback onPickFile;
  final VoidCallback onCompress;
  final VoidCallback onDownload;
  final bool isCompressing;
  final int originalSize;
  final String? fileName;
  final int compressedSize;
  final Widget previewWidget; // The custom preview
  final double sliderCompression;
  final ValueChanged<double> onSliderChanged;
  final TextEditingController sizeController;
  final String selectedUnit;
  final ValueChanged<String?> onUnitChanged;
  final List<String> units;

  const CommonCompressorUI({
    super.key,
    required this.title,
    required this.fileTypeName,
    required this.fileTypeIcon,
    required this.onPickFile,
    required this.onCompress,
    required this.onDownload,
    required this.isCompressing,
    required this.originalSize,
    required this.fileName,
    required this.compressedSize,
    required this.previewWidget,
    required this.sliderCompression,
    required this.onSliderChanged,
    required this.sizeController,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.units,
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
              const Text('Compress by Amount (Slider)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10% (Low)', style: TextStyle(color: Colors.grey[700])),
                    Text('50% (Med)', style: TextStyle(color: Colors.grey[700])),
                    Text('100% (High)', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              Slider(
                value: sliderCompression,
                min: 10,
                max: 100,
                divisions: 9,
                label: '${sliderCompression.round()}% Compression',
                onChanged: onSliderChanged,
              ),
              const SizedBox(height: 20),
              const Text('OR Compress to Target Size',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: sizeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Enter size',
                        helperText: 'Targets 1 unit less',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit,
                      items: units.map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: onUnitChanged,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.compress),
                label: const Text('Compress'),
                onPressed: isCompressing ? null : onCompress,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            if (isCompressing)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (compressedSize > 0) ...[
              const SizedBox(height: 24),
              _buildInfoCard(
                'Compressed File',
                'Preview shown below',
                compressedSize,
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

  // This helper widget is now part of the common UI
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