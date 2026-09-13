import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/download_helper.dart';
import '../../../admin_management/data/models/student.dart';
import '../providers/admin_id_card_provider.dart';

/// Admin: Generate ID Card (`docs/production_roadmap.md` Phase L6,
/// `implementation_backlog.md` E21-F1) — pick a student (same
/// `Autocomplete<Student>` pattern `fee_form_dialog.dart` uses), then
/// generate+download the PDF. No preview step: the backend streams a
/// finished PDF directly, there's nothing to preview client-side.
class AdminIdCardScreen extends StatefulWidget {
  const AdminIdCardScreen({super.key});

  @override
  State<AdminIdCardScreen> createState() => _AdminIdCardScreenState();
}

class _AdminIdCardScreenState extends State<AdminIdCardScreen> {
  Student? _selectedStudent;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AdminIdCardProvider>();
    Future.microtask(() => provider.loadStudentOptions());
  }

  Future<void> _generate(BuildContext context, AdminIdCardProvider provider) async {
    if (_selectedStudent == null) return;
    final bytes = await provider.generateStudentIdCard(_selectedStudent!.id);
    if (!context.mounted) return;
    if (bytes != null) {
      await saveBytesOrNotify(context, bytes, 'id-card-${_selectedStudent!.admissionNumber}.pdf');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.generateError?.message ?? 'Failed to generate ID card')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminIdCardProvider>();

    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('ID Cards')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: accent.withValues(alpha: 0.14),
                      child: Icon(Icons.badge_outlined, color: accent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Pick a student to generate their ID card as a PDF.')),
                  ],
                ),
                const SizedBox(height: 20),
                Autocomplete<Student>(
                  displayStringForOption: (s) => '${s.fullName} (${s.admissionNumber})',
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return provider.studentOptions;
                    final query = value.text.toLowerCase();
                    return provider.studentOptions.where(
                      (s) => s.fullName.toLowerCase().contains(query) || s.admissionNumber.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (s) => setState(() => _selectedStudent = s),
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      prefixIcon: Icon(Icons.person_search_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    icon: provider.isGenerating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.badge_outlined),
                    label: const Text('Generate & Download'),
                    onPressed: (_selectedStudent == null || provider.isGenerating) ? null : () => _generate(context, provider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
