import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tool_search_delegate.dart';
import 'theme_provider.dart';
import 'about_page.dart';

// Import sub-pages
import 'compressor_page.dart';
import 'converter_page.dart';
import 'merger_page.dart';
import 'pdf_maker_hub_page.dart';
import 'image_compressor_page.dart';
import 'pdf_compressor_page.dart';
import 'image_converter_page.dart';
import 'word_to_pdf_page.dart';
import 'pdf_to_excel_page.dart';
import 'pdf_merger_page.dart';
import 'word_merger_page.dart';
import 'pdf_maker_new_page.dart';
import 'pdf_maker_update_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const DocuToolsApp(),
    ),
  );
}

class DocuToolsApp extends StatelessWidget {
  const DocuToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'DocuTools - Smart File Manager',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF90CAF9),
          secondary: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildDrawer(context, themeProvider),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9),
            elevation: 1,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.folder_special,
                    size: 40,
                    color: isDark ? Colors.white : const Color(0xFF212121),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DocuTools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                        isDark ? Colors.white : const Color(0xFF212121),
                      ),
                    ),
                    Text(
                      'A Smart File Manager',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.info_outline,
                      color:
                      isDark ? Colors.white : const Color(0xFF212121)),
                  tooltip: 'About App',
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutPage()));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.brightness_6_outlined,
                      color:
                      isDark ? Colors.white : const Color(0xFF212121)),
                  tooltip: 'Change Theme',
                  onPressed: () => _showThemeDialog(context),
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu,
                        color:
                        isDark ? Colors.white : const Color(0xFF212121),
                        size: 28),
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ],
            ),
          ),

          // BODY CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSearchBar(context),
                  const SizedBox(height: 24),
                  _buildToolGrid(context),
                ],
              ),
            ),
          ),

          // FOOTER
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 100),
                _buildFooter(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DRAWER ----------------
  Widget _buildDrawer(BuildContext context, ThemeProvider themeProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0D47A1)),
            child: Text('DocuTools',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AboutPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Change Theme'),
            onTap: () {
              Navigator.pop(context);
              _showThemeDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // ---------------- THEME DIALOG ----------------
  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (mode) => _setTheme(context, mode!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (mode) => _setTheme(context, mode!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (mode) => _setTheme(context, mode!),
            ),
          ],
        ),
      ),
    );
  }

  void _setTheme(BuildContext context, ThemeMode mode) {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    provider.setTheme(mode);
    Navigator.pop(context);
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFF212121),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Tools',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          _buildFooterCategoryRow(context, 'Compressor', [
            _footerLink(context, 'Image Compressor', const ImageCompressorPage()),
            _footerLink(context, 'PDF Compressor', const PdfCompressorPage()),
          ]),

          const SizedBox(height: 24),

          _buildFooterCategoryRow(context, 'Converter', [
            _footerLink(context, 'Image Converter', const ImageConverterPage()),
            _footerLink(context, 'Word to PDF', const WordToPdfPage()),
            _footerLink(context, 'PDF to Excel', const PdfToExcelPage()),
          ]),

          const SizedBox(height: 24),

          _buildFooterCategoryRow(context, 'Merger', [
            _footerLink(context, 'PDF Merger', const PdfMergerPage()),
            _footerLink(context, 'Word Merger', const WordMergerPage()),
          ]),

          const SizedBox(height: 24),

          _buildFooterCategoryRow(context, 'PDF Maker', [
            _footerLink(context, 'Create New PDF', const PdfMakerNewPage()),
            _footerLink(
                context, 'Update Existing PDF', const PdfMakerUpdatePage()),
          ]),

          const SizedBox(height: 40),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '@saurabh all rights reserved',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCategoryRow(
      BuildContext context, String title, List<Widget> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: links,
        ),
      ],
    );
  }

  Widget _footerLink(BuildContext context, String title, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            decoration: TextDecoration.underline),
      ),
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar(BuildContext context) {
    return InkWell(
      onTap: () => showSearch(context: context, delegate: ToolSearchDelegate()),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[500]),
            const SizedBox(width: 10),
            Text('Search files or tools...',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  // ---------------- TOOL GRID ----------------
  Widget _buildToolGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                context: context,
                title: 'Compressor',
                subtitle: 'Reduce file size of Images,Pdf',
                iconData: Icons.format_line_spacing,
                gradient: const LinearGradient(
                    colors: [Color(0xFF2962FF), Color(0xFF0D47A1)]),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CompressorPage())),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                context: context,
                title: 'Converter',
                subtitle: 'Change file format of Images(PNG,JPG,JPEG),Word,Pdf',
                iconData: Icons.sync_rounded,
                gradient: const LinearGradient(
                    colors: [Color(0xFFF50057), Color(0xFFD50000)]),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConverterPage())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                context: context,
                title: 'Merger',
                subtitle: 'Combine PDF or Word',
                iconData: Icons.link_rounded,
                gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00A152)]),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MergerPage())),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                context: context,
                title: 'PDF Maker',
                subtitle: 'Create or update PDF',
                iconData: Icons.add_to_photos,
                gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PdfMakerHubPage())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData iconData,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
