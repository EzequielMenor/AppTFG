import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  Future<void> _editDisplayName() async {
    final profile = context.read<ProfileProvider>();
    final controller = TextEditingController(text: profile.displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Nombre de usuario',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tu nombre',
            hintStyle: const TextStyle(color: AppTheme.textGrey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.neonGreen.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.neonGreen),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppTheme.neonGreen),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      await context.read<ProfileProvider>().updateDisplayName(result);
    }
  }

  Future<void> _toggleWeightUnit(String unit) async {
    await context.read<ProfileProvider>().setWeightUnit(unit);
  }

  Future<void> _importHevy() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;
    await context.read<ProfileProvider>().importCsv(result.files.single.path!);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          '¿Borrar todos los datos?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Se eliminarán todos tus entrenamientos. Esta acción no se puede deshacer.',
          style: TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Borrar todo',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    await context.read<ProfileProvider>().clearData();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final user = context.watch<AuthProvider>().user;
    final email = user?.email ?? '';
    final displayName = profile.displayName?.isNotEmpty == true ? profile.displayName! : null;
    final initial = (displayName ?? email).isNotEmpty
        ? (displayName ?? email)[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PERFIL'),
        backgroundColor: AppTheme.appBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Header ---
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _editDisplayName,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppTheme.neonGreen,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _editDisplayName,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName ?? 'Añadir nombre',
                        style: TextStyle(
                          color: displayName != null
                              ? Colors.white
                              : AppTheme.textGrey,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit,
                        size: 14,
                        color: AppTheme.textGrey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
          const _SectionHeader(title: 'Preferencias'),

          // --- Nombre de usuario ---
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Nombre de usuario',
            subtitle: displayName ?? 'Sin configurar',
            onTap: _editDisplayName,
          ),

          const SizedBox(height: 8),

          // --- Unidades de peso ---
          _UnitToggleTile(selected: profile.weightUnit, onSelect: _toggleWeightUnit),

          const SizedBox(height: 36),
          const _SectionHeader(title: 'Datos'),

          // --- Importar desde Hevy ---
          _SettingsTile(
            icon: Icons.upload_file,
            title: 'Importar desde Hevy',
            subtitle: 'Sube tu historial en formato CSV',
            onTap: profile.isImporting ? null : _importHevy,
            trailing: profile.isImporting ? const _LoadingIndicator() : null,
          ),

          const SizedBox(height: 8),

          // --- Limpiar todos los datos ---
          _SettingsTile(
            icon: Icons.delete_sweep_outlined,
            title: 'Limpiar todos los datos',
            subtitle: 'Borra todos los entrenamientos y la caché',
            onTap: profile.isClearing ? null : _clearAllData,
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            trailing: profile.isClearing ? const _LoadingIndicator() : null,
          ),

          // --- Feedback de estado ---
          if (profile.statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Row(
                children: [
                  Icon(
                    profile.isSuccess == true ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: profile.isSuccess == true
                        ? AppTheme.neonGreen
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profile.statusMessage!,
                      style: TextStyle(
                        color: profile.isSuccess == true
                            ? AppTheme.neonGreen
                            : Colors.redAccent,
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

          const SizedBox(height: 40),

          // --- Footer ---
          const Center(
            child: Text(
              'GymAnalytics v1.0.0',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- Widgets auxiliares ---

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
              trailing ??
                  const Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitToggleTile extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _UnitToggleTile({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, color: AppTheme.neonGreen, size: 22),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Unidades de peso',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _UnitButton(
            label: 'kg',
            selected: selected == 'kg',
            onTap: () => onSelect('kg'),
          ),
          const SizedBox(width: 8),
          _UnitButton(
            label: 'lb',
            selected: selected == 'lb',
            onTap: () => onSelect('lb'),
          ),
        ],
      ),
    );
  }
}

class _UnitButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.neonGreen : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppTheme.textGrey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppTheme.neonGreen,
      ),
    );
  }
}
