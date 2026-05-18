import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../services/api_service.dart';
import '../models/bank.dart';

class LinkedAccountsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LinkedAccountsScreen({super.key, required this.onBack});

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _loading = true;
  String? _syncingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getLinkedAccounts();
      final list = (data['accounts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() { _accounts = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncAccount(String id) async {
    setState(() => _syncingId = id);
    try {
      await ApiService.syncAccount(id);
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _syncingId = null);
  }

  Future<void> _removeAccount(String id) async {
    try {
      await ApiService.removeAccount(id);
      setState(() => _accounts.removeWhere((a) => a['id'] == id));
    } catch (_) {}
  }

  void _showAddSheet() {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.surfaceLight, c.surfaceDark]),
          border: Border.all(color: c.borderDefault),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: c.textSecondary.withValues(alpha: 0.3))),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Text('Connect a Bank', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Select your bank to get started', style: TextStyle(color: c.textSecondary, fontSize: 14))),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: 2.6, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: kSupportedBanks.map((b) => GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.surfaceDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.borderDefault),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: b.color),
                    child: Center(child: Text(b.initials, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b.name, style: TextStyle(color: c.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('Your credentials are never stored by Moninte', style: TextStyle(color: c.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              ScreenHeader(
                title: 'Linked Accounts',
                subtitle: '${_accounts.length} account${_accounts.length != 1 ? 's' : ''} connected',
                onBack: widget.onBack,
              ),
              const SizedBox(height: 20),

              ..._accounts.map((a) {
                final id = a['id'] ?? '';
                final bankName = a['bank_name'] ?? '';
                final accountType = a['account_type'] ?? '';
                final balance = (a['balance'] as num?)?.toDouble() ?? 0;
                final status = a['status'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.accent),
                        child: Center(child: Text(bankName.isNotEmpty ? bankName[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(bankName, style: TextStyle(color: c.textPrimary)),
                          const SizedBox(width: 8),
                          if (status == 'active')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: AppColors.success.withValues(alpha: 0.1)),
                              child: const Text('Synced', style: TextStyle(color: AppColors.success, fontSize: 10)),
                            ),
                        ]),
                        const SizedBox(height: 2),
                        Text(accountType, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('₦${balance.toStringAsFixed(0)}', style: TextStyle(color: c.textPrimary)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _syncAccount(id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceLight.withValues(alpha: 0.6), border: Border.all(color: c.borderDefault)),
                            child: _syncingId == id
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                                : Icon(Icons.refresh, size: 14, color: c.textSecondary),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: _showAddSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 2, strokeAlign: BorderSide.strokeAlignInside),
                  ),
                  child: Column(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.15)),
                      child: const Icon(Icons.add, size: 24, color: AppColors.accent),
                    ),
                    const SizedBox(height: 8),
                    const Text('Connect a bank account', style: TextStyle(color: AppColors.accent)),
                    const SizedBox(height: 4),
                    Text('Supports all major Nigerian banks', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
