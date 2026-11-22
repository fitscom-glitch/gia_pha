import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';

/// Danh bạ: số điện thoại, địa chỉ, email của các thành viên (theo thứ tự nhập).
class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  String _query = '';

  static bool _has(String? s) => s != null && s.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final family = ref.watch(familyProvider);
    return Scaffold(
      appBar: const GoldAppBar(title: 'Danh bạ'),
      body: PatternBackground(
        child: family.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (data) {
            final q = _query.trim().toLowerCase();
            final people = [
              for (final p in data.persons)
                if (q.isEmpty ||
                    p.fullName.toLowerCase().contains(q) ||
                    (p.phone ?? '').contains(q))
                  p,
            ];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.goldDark),
                      hintText: 'Tìm theo tên hoặc số điện thoại',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.gold),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.red, width: 1.6),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: people.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có thành viên nào.',
                            style: TextStyle(color: AppColors.goldDark),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
                          itemCount: people.length,
                          itemBuilder: (_, i) {
                            final p = people[i];
                            final lines = [
                              if (_has(p.phone)) p.phone!,
                              if (_has(p.address)) p.address!,
                            ];
                            return OrnateCard(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              padding: const EdgeInsets.all(10),
                              onTap: () => _showContact(context, p),
                              child: Row(
                                children: [
                                  PersonAvatar(p, radius: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.fullName,
                                          style: const TextStyle(
                                            fontFamily: 'serif',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        Text(
                                          lines.isEmpty
                                              ? 'Chưa có thông tin liên hệ'
                                              : lines.join('\n'),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: lines.isEmpty
                                                ? AppColors.goldDark
                                                : AppColors.redDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.edit, size: 18, color: AppColors.goldDark),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showContact(BuildContext context, Person p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      builder: (_) => _ContactSheet(person: p),
    );
  }
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.person});

  final Person person;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.person.phone ?? '');
    _address = TextEditingController(text: widget.person.address ?? '');
    _email = TextEditingController(text: widget.person.email ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    await ref.read(familyProvider.notifier).saveMember(
          widget.person.withContact(
            phone: _nullIfEmpty(_phone.text),
            address: _nullIfEmpty(_address.text),
            email: _nullIfEmpty(_email.text),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  Widget _field(TextEditingController c, String label, IconData icon, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.goldDark),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Sao chép',
            onPressed: () async {
              if (c.text.trim().isEmpty) return;
              await Clipboard.setData(ClipboardData(text: c.text.trim()));
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Đã sao chép')));
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                PersonAvatar(widget.person, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.person.fullName,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      color: AppColors.redDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field(_phone, 'Số điện thoại', Icons.phone, TextInputType.phone),
            _field(_address, 'Địa chỉ', Icons.home, TextInputType.streetAddress),
            _field(_email, 'Email', Icons.email, TextInputType.emailAddress),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Lưu')),
            ),
          ],
        ),
      ),
    );
  }
}
