import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vownote/services/backup_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vownote/utils/branding_utils.dart';
import 'package:vownote/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Dynamic Background
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              children: [
                _buildSectionTitle(
                  'Data Backup & Restore',
                ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05),
                _buildBackupSection()
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                _buildSectionTitle(
                  'Global Persistence',
                ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05),
                _buildStorageStatusSection()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                _buildSectionTitle(
                  'App',
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                _buildAppSection()
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Color(0xFFD4AF37),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AUTHENTIC PRODUCT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'VowNote Professional v1.8',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const GitHubWatermark(compact: true),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black12,
                child: const Center(child: CupertinoActivityIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              CupertinoIcons.share_up,
              color: CupertinoColors.activeBlue,
            ),
            title: Text(
              'Export Backup',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Share backup file to Drive/WhatsApp',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () async {
              setState(() => _isLoading = true);
              try {
                final path = await _backupService.exportBackup();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Backup Saved to: $path\n(Also opened in Share Sheet)',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Save your backup file to a safe location (e.g. Google Drive, Email) to prevent data loss if you uninstall the app.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            color: Theme.of(context).dividerTheme.color,
          ),
          ListTile(
            leading: const Icon(
              CupertinoIcons.arrow_down_doc,
              color: CupertinoColors.activeGreen,
            ),
            title: Text(
              'Import Backup',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Restore from a backup file',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () async {
              final confirm = await showCupertinoDialog(
                context: context,
                builder: (c) => CupertinoAlertDialog(
                  title: const Text('Restore Backup?'),
                  content: const Text(
                    'This will overwrite unsaved changes. Continue?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(c, false),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Import'),
                      onPressed: () => Navigator.pop(c, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                setState(() => _isLoading = true);
                try {
                  int count = await _backupService.importBackup();
                  if (count >= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restored $count bookings successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Import Failed: $e')));
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStatusSection() {
    return FutureBuilder<bool>(
      future: Permission.manageExternalStorage.isGranted,
      builder: (context, snapshot) {
        final isGranted = snapshot.data ?? false;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  isGranted ? Icons.verified_user : Icons.warning_amber_rounded,
                  color: isGranted ? Colors.blue : Colors.orange,
                ),
                title: Text(
                  isGranted
                      ? 'Global Storage Active'
                      : 'Global Storage Inactive',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(
                  isGranted
                      ? 'Saved in: /Documents/VowNote'
                      : 'Permission required for persistence after app deletion',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: !isGranted
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Enable'),
                        onPressed: () async {
                          await _backupService.requestStoragePermission();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              CupertinoIcons.moon_stars,
              color: CupertinoColors.systemIndigo,
            ),
            title: Text(
              'Dark Mode',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: AnimatedBuilder(
              animation: themeService,
              builder: (context, _) => CupertinoSwitch(
                value: themeService.isDarkMode,
                onChanged: (v) => themeService.toggleTheme(v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
