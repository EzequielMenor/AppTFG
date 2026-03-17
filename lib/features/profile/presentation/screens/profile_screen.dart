import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isImporting = false;
  bool _isPatching = false;
  String? _statusMessage;
  bool? _isSuccess;

  Future<void> _importHevy() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _isImporting = true;
      _statusMessage = null;
      _isSuccess = null;
    });

    try {
      final response = await ApiClient.postMultipart(
        '/api/import/hevy',
        filePath: result.files.single.path!,
        fieldName: 'file',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final int success = body['successCount'] ?? 0;
        final int failed = body['failedCount'] ?? 0;
        setState(() {
          _isSuccess = success > 0;
          _statusMessage = success > 0
              ? 'Importadas $success series correctamente. Fallos: $failed'
              : 'Nada importado. $failed filas fallaron — revisa el formato del CSV.';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _statusMessage = 'Error del servidor (${response.statusCode}). Inténtalo de nuevo.';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Error: ${e.runtimeType} → $e';
      });
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _patchEndTimes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _isPatching = true;
      _statusMessage = null;
      _isSuccess = null;
    });

    try {
      final response = await ApiClient.postMultipart(
        '/api/import/patch-end-times',
        filePath: result.files.single.path!,
        fieldName: 'file',
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final int updated = body['updated'] ?? 0;
        setState(() {
          _isSuccess = true;
          _statusMessage = updated > 0
              ? '$updated entrenamientos con duración corregida.'
              : 'No había duraciones que corregir (ya estaban actualizadas).';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _statusMessage = 'Error del servidor (${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() => _isPatching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.neonGreen,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Avatar y email ---
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.neonGreen,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
          const _SectionHeader(title: 'Datos'),

          // --- Importar desde Hevy ---
          _SettingsTile(
            icon: Icons.upload_file,
            title: 'Importar desde Hevy',
            subtitle: 'Sube tu historial en formato CSV',
            onTap: _isImporting ? null : _importHevy,
            trailing: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonGreen,
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 8),

          // --- Corregir duraciones ---
          _SettingsTile(
            icon: Icons.timer_outlined,
            title: 'Corregir duraciones',
            subtitle: 'Actualiza end_time de entrenamientos existentes',
            onTap: _isPatching ? null : _patchEndTimes,
            trailing: _isPatching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonGreen,
                    ),
                  )
                : null,
          ),

          // --- Feedback de importación ---
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Row(
                children: [
                  Icon(
                    _isSuccess == true ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: _isSuccess == true ? AppTheme.neonGreen : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccess == true ? AppTheme.neonGreen : Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 36),
          const _SectionHeader(title: 'Cuenta'),

          // --- Cerrar sesión ---
          _SettingsTile(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textGrey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppTheme.neonGreen, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
