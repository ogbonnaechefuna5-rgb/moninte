import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../models/linked_account.dart';
import '../models/bank.dart';

class LinkedAccountsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LinkedAccountsScreen({super.key, required this.onBack});

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  final List<LinkedAccount> _accounts = [
    LinkedAccount(id: 'gtb-1', bank: 'GTBank', fullName: 'Guaranty Trust Bank', accountType: 'Current Account', maskedNum: '****7843', color: Color(0xFF006B3C), initials: 'GT', balance: '₦125,430.50', lastSynced: '2 mins ago', status: 'synced'),
    LinkedAccount(id: 'kuda-1', bank: 'Kuda', fullName: 'Kuda Microfinance Bank', accountType: 'Savings Account', maskedNum: '****2291', color: Color(0xFF6231AF), initials: 'KB', balance: '₦48,200.00', lastSynced: '15 mins ago', status: 'synced'),
    LinkedAccount(id: 'opay-1', bank: 'OPay', fullName: 'OPay Digital Services', accountType: 'Digital Wallet', maskedNum: '****5512', color: Color(0xFF00B140), initials: 'OP', balance: '₦12,750.00', lastSynced: '2 hours ago', status: 'error'),
  ];
  String? _syncingId;

  static final _availableBanks = kSupportedBanks.where((b) =>
    !['GTBank', 'Kuda', 'OPay'].contains(b.name)).toList();

  void _syncAccount(String id) {
    setState(() => _syncingId = id);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        final i = _accounts.indexWhere((a) => a.id == id);
        if (i != -1) {
          _accounts[i] = _accounts[i].copyWith(status: 'synced', lastSynced: 'just now');
        }
        _syncingId = null;
      });
    });
  }

  void _showDetail(LinkedAccount account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(account: account, onSync: () {
        Navigator.pop(context);
        _syncAccount(account.id);
      }, onRemove: () {
        setState(() => _accounts.removeWhere((a) => a.id == account.id));
        Navigator.pop(context);
      }),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddSheet(banks: _availableBanks, onSelect: () => Navigator.pop(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            ScreenHeader(
              title: 'Linked Accounts',
              subtitle: '${_accounts.length} account${_accounts.length != 1 ? 's' : ''} connected',
              onBack: widget.onBack,
            ),
            const SizedBox(height: 20),

            // Summary
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total across accounts', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('₦186,380.50', style: AppTheme.monoSized(22, color: AppColors.accent)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Last full sync', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('Today, 9:41 AM', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Accounts
            ..._accounts.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                onTap: () => _showDetail(a),
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  _bankLogo(a.color, a.initials, 48),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(a.bank, style: const TextStyle(color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      _statusChip(a.status, _syncingId == a.id),
                    ]),
                    const SizedBox(height: 2),
                    Text('${a.accountType} · ${a.maskedNum}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(a.lastSynced, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(a.balance, style: const TextStyle(color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _syncAccount(a.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceLight.withValues(alpha: 0.6), border: Border.all(color: AppColors.borderDefault)),
                        child: _syncingId == a.id
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                            : const Icon(Icons.refresh, size: 14, color: AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ]),
              ),
            )),

            const SizedBox(height: 8),

            // Add Account
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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.15), border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
                    child: const Icon(Icons.add, size: 24, color: AppColors.accent),
                  ),
                  const SizedBox(height: 8),
                  const Text('Connect a bank account', style: TextStyle(color: AppColors.accent)),
                  const SizedBox(height: 4),
                  const Text('Supports all major Nigerian banks', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Security notice
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.accent.withValues(alpha: 0.1)),
                  child: const Icon(Icons.wifi, size: 16, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Read-only access', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Spendalt uses read-only access to your accounts. We never store your banking credentials and cannot initiate any transactions.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
                ])),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _bankLogo(Color color, String initials, double size) => Container(
  width: size, height: size,
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]),
  child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
);

Widget _statusChip(String status, bool syncing) {
  if (syncing) return _chip('Syncing…', AppColors.warning, Icons.sync);
  switch (status) {
    case 'synced': return _chip('Synced', AppColors.success, Icons.check_circle);
    case 'error': return _chip('Error', AppColors.destructive, Icons.error_outline);
    default: return const SizedBox.shrink();
  }
}

Widget _chip(String text, Color color, IconData icon) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: color.withValues(alpha: 0.1)),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 10, color: color),
    const SizedBox(width: 4),
    Text(text, style: TextStyle(color: color, fontSize: 10)),
  ]),
);

// ── Bottom Sheets ──

class _DetailSheet extends StatelessWidget {
  final LinkedAccount account;
  final VoidCallback onSync, onRemove;
  const _DetailSheet({required this.account, required this.onSync, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.surfaceLight, AppColors.surfaceDark]),
        border: Border.all(color: AppColors.borderDefault),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: 0.2))),
        const SizedBox(height: 20),
        Row(children: [
          _bankLogo(account.color, account.initials, 56),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(account.fullName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(account.accountType, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ])),
        ]),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _row('Account Number', account.maskedNum),
            const SizedBox(height: 12),
            _row('Balance', account.balance),
            const SizedBox(height: 12),
            _row('Last Synced', account.lastSynced),
            const SizedBox(height: 12),
            _row('Sync Status', account.status == 'synced' ? '✓ Connected' : '⚠ Reconnect needed',
                valueColor: account.status == 'synced' ? AppColors.success : AppColors.destructive),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: onSync,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Sync Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent, foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Remove Account'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.destructive,
            side: BorderSide(color: AppColors.destructive.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontSize: 14)),
    ],
  );
}

class _AddSheet extends StatelessWidget {
  final List<Bank> banks;
  final VoidCallback onSelect;
  const _AddSheet({required this.banks, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.surfaceLight, AppColors.surfaceDark]),
        border: Border.all(color: AppColors.borderDefault),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: 0.2))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Connect a Bank', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceDark.withValues(alpha: 0.6), border: Border.all(color: AppColors.borderDefault)),
                child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerLeft, child: Text('Select your bank to get started', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: 2.6, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: banks.map((b) => GestureDetector(
              onTap: onSelect,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: b.color),
                    child: Center(child: Text(b.initials, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Your credentials are never stored by Spendalt', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
