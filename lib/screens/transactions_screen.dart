import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/category_badge.dart';
import '../providers/category_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/screen_header.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../router.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final List<Map<String, dynamic>> _txs = [];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
          !_loadingMore && _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _txs.clear(); _page = 1; _hasMore = true; });
    try {
      final data = await context.read<ApiService>().getTransactions(page: 1, limit: 20);
      final list = (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() {
        _txs.addAll(list);
        _hasMore = list.length == 20;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final data = await context.read<ApiService>().getTransactions(page: _page + 1, limit: 20);
      final list = (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() {
        _page++;
        _txs.addAll(list);
        _hasMore = list.length == 20;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: ScreenHeader(
                title: 'Transactions',
                subtitle: '${_txs.length} record${_txs.length != 1 ? 's' : ''}',
                onBack: () => context.go(Routes.home),
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: c.accent))
                  : _txs.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: c.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No transactions yet', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                        ]))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: c.accent,
                          child: ListView.separated(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _txs.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              if (i == _txs.length) {
                                return Center(child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
                                ));
                              }
                              final tx = _txs[i];
                              final merchant = tx['merchant'] ?? 'Unknown';
                              final category = tx['category'] ?? 'Other';
                              final amount = (tx['amount'] as num).toDouble();
                              final type = tx['type'] ?? 'debit';
                              final date = tx['transaction_date'] as String? ?? '';
                              final isCredit = type == 'credit';
                              return GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: c.surfaceLight,
                                    ),
                                    child: Center(child: Text(_categoryIcon(category), style: const TextStyle(fontSize: 22))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(merchant, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      CategoryBadge(category: category),
                                      if (date.isNotEmpty) ...[ 
                                        const SizedBox(width: 8),
                                        Text(_formatDate(date), style: TextStyle(color: c.textSecondary, fontSize: 11)),
                                      ],
                                    ]),
                                  ])),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${isCredit ? '+' : '-'}₦${fmtNumber(amount.abs().round())}',
                                    style: AppTheme.monoSized(15, color: isCredit ? AppColors.success : AppColors.destructive),
                                  ),
                                ]),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _categoryIcon(String category) =>
      context.read<CategoryProvider>().forName(category).icon;
}
