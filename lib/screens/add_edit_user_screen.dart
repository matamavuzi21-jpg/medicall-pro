import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class AddEditUserScreen extends StatefulWidget {
  final AppUser? existingUser;
  const AddEditUserScreen({super.key, this.existingUser});

  bool get isEditing => existingUser != null;

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  UserRole _role = UserRole.agent;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.existingUser;
    if (u != null) {
      _nameCtrl.text = u.fullName;
      _emailCtrl.text = u.email;
      _serviceCtrl.text = u.service ?? '';
      _role = u.role;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom et l\'e-mail sont obligatoires.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isEditing) {
        await UserService.instance.updateUser(
          widget.existingUser!.copyWith(
            fullName: _nameCtrl.text.trim(),
            role: _role,
            service: _serviceCtrl.text.trim().isEmpty
                ? null
                : _serviceCtrl.text.trim(),
          ),
        );
      } else {
        if (_passCtrl.text.trim().length < 6) {
          setState(() =>
              _error = 'Le mot de passe doit contenir au moins 6 caractères.');
          setState(() => _saving = false);
          return;
        }
        await UserService.instance.createUser(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
          role: _role,
          service: _serviceCtrl.text.trim().isEmpty
              ? null
              : _serviceCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Échec de l\'enregistrement. Réessayez.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? 'Modifier l\'utilisateur'
            : 'Nouvel utilisateur'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _emailCtrl,
                enabled: !widget.isEditing, // L'e-mail ne se modifie pas ici.
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse e-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe temporaire',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _serviceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Service d\'affectation (optionnel)',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Rôle', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: UserRole.values.map((r) {
                  final selected = r == _role;
                  return ChoiceChip(
                    label: Text(r.label),
                    selected: selected,
                    selectedColor: AppColors.bleuMedical,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.grisAnthracite,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _role = r),
                  );
                }).toList(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.erreur)),
              ],
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.isEditing ? 'Enregistrer' : 'Créer le compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
