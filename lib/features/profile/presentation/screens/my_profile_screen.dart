import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/form_sheet.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/progress_overlay.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/my_profile.dart';
import '../providers/profile_provider.dart';

/// My Profile — every role. Shows the user's own record from their role's
/// "me" endpoint, and lets them edit their contact details, change their
/// photo (not Parent — see [MyProfile.canChangePhoto]) and change their
/// password.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    final role = context.read<AuthProvider>().role;
    final provider = context.read<ProfileProvider>();
    if (role != null) Future.microtask(() => provider.load(role));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final role = context.read<AuthProvider>().role;
    final profile = provider.profile;

    final Widget body;
    if (profile == null && provider.status == LoadStatus.error) {
      body = ErrorView(error: provider.error!, onRetry: role == null ? null : () => provider.load(role));
    } else if (profile == null) {
      body = const LoadingView(message: 'Loading your profile…');
    } else {
      body = RefreshIndicator(
        onRefresh: () => provider.load(profile.role, refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ProfileHeader(
              profile: profile,
              onChangePhoto: profile.canChangePhoto ? () => _changePhoto(context) : null,
            ),
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.contact_page_outlined,
              title: 'Contact details',
              trailing: TextButton.icon(
                onPressed: () => _editDetails(context, profile),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              child: _Rows(rows: _contactRows(profile)),
            ),
            if (profile.details.isNotEmpty) ...[
              const SizedBox(height: 14),
              SectionCard(
                icon: _detailsIcon(profile.role),
                title: _detailsTitle(profile.role),
                color: AppColors.success,
                child: _Rows(rows: profile.details),
              ),
            ],
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.lock_outline,
              title: 'Security',
              color: AppColors.accent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.password_outlined),
                title: const Text('Change password'),
                subtitle: Text('At least ${profile.minPasswordLength} characters'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePassword(context, profile),
              ),
            ),
          ],
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'My Profile'),
        body: body,
      ),
    );
  }

  static List<(String, String)> _contactRows(MyProfile p) => [
    ('Email', p.email.isEmpty ? '—' : p.email),
    ('Phone', p.phone ?? '—'),
    if (p.role != AppRole.admin) ('Address', p.address ?? '—'),
    if (p.role == AppRole.student) ('Date of birth', p.dob == null ? '—' : MyProfile.formatDate(p.dob!)),
    if (p.role == AppRole.parent) ('Occupation', p.occupation ?? '—'),
  ];

  static String _detailsTitle(AppRole role) => switch (role) {
    AppRole.teacher => 'Work details',
    AppRole.student => 'School details',
    AppRole.parent => 'Family',
    AppRole.admin => 'Details',
  };

  static IconData _detailsIcon(AppRole role) => switch (role) {
    AppRole.teacher => Icons.badge_outlined,
    AppRole.student => Icons.school_outlined,
    AppRole.parent => Icons.family_restroom_outlined,
    AppRole.admin => Icons.info_outline,
  };

  Future<void> _changePhoto(BuildContext context) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      _snack(context, 'Please choose a photo smaller than 5 MB.');
      return;
    }
    final error = await runWithProgress(
      context,
      () => context.read<ProfileProvider>().uploadPhoto(bytes, file.name),
      message: 'Uploading photo…',
    );
    if (context.mounted) _snack(context, error?.message ?? 'Profile photo updated');
  }

  Future<void> _editDetails(BuildContext context, MyProfile profile) async {
    final saved = await showFormSheet<bool>(
      context: context,
      builder: (_) => _EditDetailsSheet(profile: profile),
    );
    if (saved == true && context.mounted) _snack(context, 'Profile updated');
  }

  Future<void> _changePassword(BuildContext context, MyProfile profile) async {
    final saved = await showFormSheet<bool>(
      context: context,
      builder: (_) => _ChangePasswordSheet(profile: profile),
    );
    if (saved == true && context.mounted) _snack(context, 'Password changed');
  }

  static void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _ProfileHeader extends StatelessWidget {
  final MyProfile profile;
  final VoidCallback? onChangePhoto;

  const _ProfileHeader({required this.profile, required this.onChangePhoto});

  static String _roleLabel(AppRole role) => switch (role) {
    AppRole.admin => 'Administrator',
    AppRole.teacher => 'Teacher',
    AppRole.student => 'Student',
    AppRole.parent => 'Parent',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brand = context.readable(AppColors.primary);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(name: profile.fullName, photoUrl: profile.photoUrl, radius: 48),
                if (onChangePhoto != null)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Material(
                      color: AppColors.accent,
                      shape: CircleBorder(side: BorderSide(color: Theme.of(context).colorScheme.surface, width: 3)),
                      child: IconButton(
                        tooltip: 'Change photo',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
                        onPressed: onChangePhoto,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              profile.fullName.isEmpty ? _roleLabel(profile.role) : profile.fullName,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roleLabel(profile.role),
                style: textTheme.labelMedium?.copyWith(color: brand, fontWeight: FontWeight.w700),
              ),
            ),
            if (profile.schoolName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apartment_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      profile.schoolName!,
                      style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Round photo, or the user's initials on brand green when there's no
/// photo (or it fails to load).
class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;

  const ProfileAvatar({super.key, required this.name, required this.photoUrl, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    final initials = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        initialsFor(name),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: radius * 0.65),
      ),
    );
    final url = photoUrl;
    if (url == null) return initials;
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initials,
        loadingBuilder: (context, child, progress) => progress == null ? child : initials,
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  final List<(String, String)> rows;

  const _Rows({required this.rows});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(rows[i].$1, style: textTheme.bodyMedium?.copyWith(color: muted)),
              ),
              Expanded(
                child: Text(rows[i].$2, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EditDetailsSheet extends StatefulWidget {
  final MyProfile profile;

  const _EditDetailsSheet({required this.profile});

  @override
  State<_EditDetailsSheet> createState() => _EditDetailsSheetState();
}

class _EditDetailsSheetState extends State<_EditDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _email = TextEditingController(text: widget.profile.email);
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _address = TextEditingController(text: widget.profile.address ?? '');
  late final _occupation = TextEditingController(text: widget.profile.occupation ?? '');
  late DateTime? _dob = widget.profile.dob;
  bool _saving = false;
  AppException? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _address, _occupation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final role = widget.profile.role;
    final provider = context.read<ProfileProvider>();
    final error = await provider.updateDetails(
      fullName: _name.text.trim(),
      email: role == AppRole.admin ? _email.text.trim() : null,
      phone: _phone.text.trim(),
      address: role == AppRole.admin ? null : _address.text.trim(),
      dob: _dob,
      occupation: role == AppRole.parent ? _occupation.text.trim() : null,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    final saved = provider.profile;
    if (saved != null) {
      await context.read<AuthProvider>().updateIdentity(fullName: saved.fullName, email: saved.email);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 12),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.profile.role;
    return FormSheet(
      title: const Text('Edit details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
              ),
              if (role == AppRole.admin) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email', helperText: 'You log in with this email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              if (role != AppRole.admin) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
              if (role == AppRole.parent) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _occupation,
                  decoration: const InputDecoration(labelText: 'Occupation'),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
              if (role == AppRole.student) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(_dob == null ? 'Not set' : MyProfile.formatDate(_dob!)),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final MyProfile profile;

  const _ChangePasswordSheet({required this.profile});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  AppException? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<ProfileProvider>().changePassword(
      currentPassword: _current.text,
      newPassword: _new.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.profile.minPasswordLength;
    final toggle = IconButton(
      tooltip: _obscure ? 'Show passwords' : 'Hide passwords',
      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
    return FormSheet(
      title: const Text('Change password'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _current,
                obscureText: _obscure,
                decoration: InputDecoration(labelText: 'Current password', suffixIcon: toggle),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _new,
                obscureText: _obscure,
                decoration: InputDecoration(labelText: 'New password', helperText: 'At least $min characters'),
                validator: (v) {
                  if (v == null || v.length < min) return 'Use at least $min characters';
                  if (v == _current.text) return 'Must be different from your current password';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
                validator: (v) => v != _new.text ? 'Passwords do not match' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Change password'),
        ),
      ],
    );
  }
}
