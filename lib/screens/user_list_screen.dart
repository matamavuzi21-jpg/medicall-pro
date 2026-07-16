import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import 'add_edit_user_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = UserService.instance.getAllUsers();
  }

  void _reload() {
    setState(() => _future = UserService.instance.getAllUsers());
  }

  Future<void> _toggleActive(AppUser user) async {
    await UserService.instance.setActive(user.id, !user.actif);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddEditUserScreen()),
          );
          if (created == true) _reload();
        },
        backgroundColor: AppColors.bleuMedical,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Nouvel utilisateur',
            style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur de chargement : ${snapshot.error}'),
            );
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('Aucun utilisateur enregistré.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _UserTile(
              user: users[i],
              onToggleActive: () => _toggleActive(users[i]),
              onEdit: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddEditUserScreen(existingUser: users[i]),
                  ),
                );
                if (updated == true) _reload();
              },
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;

  const _UserTile({
    required this.user,
    required this.onToggleActive,
    required this.onEdit,
  });

  Color get _roleColor {
    switch (user.role) {
      case UserRole.directeur:
        return AppColors.bleuMedical;
      case UserRole.superviseur:
        return AppColors.vertEmeraude;
      case UserRole.agent:
        return AppColors.grisAnthracite;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: _roleColor.withValues(alpha: 0.12),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(color: _roleColor, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${user.email} · ${user.role.label}'
            '${user.service != null ? ' · ${user.service}' : ''}'),
        trailing: Switch(
          value: user.actif,
          activeThumbColor: AppColors.vertEmeraude,
          onChanged: (_) => onToggleActive(),
        ),
      ),
    );
  }
}
