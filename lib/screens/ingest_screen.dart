import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_button.dart';
import 'package:provider/provider.dart';
import '../services/sms_service.dart';
import '../services/api_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/analytics_provider.dart';

class IngestScreen extends StatefulWidget {
  final void Function(bool)? onPickerActive;
  const IngestScreen({super.key, this.onPickerActive});

  @override
  State<IngestScreen> createState() => _IngestScreenState();
}

class _IngestScreenState extends State<IngestScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Import', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text('Sync transactions from SMS or file', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: c.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.borderDefault),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(10)),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: c.background,
                      unselectedLabelColor: c.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'SMS Detection'),
                        Tab(text: 'File Upload'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  const _SmsTab(),
                  _UploadTab(onPickerActive: widget.onPickerActive),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SMS Tab ───────────────────────────────────────────────────────────────────

class _SmsTab extends StatefulWidget {
  const _SmsTab();

  @override
  State<_SmsTab> createState() => _SmsTabState();
}

class _SmsTabState extends State<_SmsTab> {
  List<SmsMessage> _messages = [];
  final Set<int> _selected = {};
  bool _loading = false;
  bool _sending = false;
  String? _result;

  Future<void> _scan() async {
    setState(() { _loading = true; _result = null; _messages = []; _selected.clear(); });

    final status = await Permission.sms.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() { _loading = false; _result = 'SMS permission denied'; });
      return;
    }

    final msgs = await SmsService.getBankMessages();
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _selected.addAll(List.generate(msgs.length, (i) => i));
      _loading = false;
    });
  }

  void _invalidateProviders() {
    context.read<DashboardProvider>().invalidate();
    context.read<AnalyticsProvider>().invalidate();
    context.read<DashboardProvider>().load();
    context.read<AnalyticsProvider>().load('week');
  }

  Future<void> _send() async { 
    if (_selected.isEmpty) return;
    setState(() { _sending = true; _result = null; });
    final bodies = _selected.map((i) => _messages[i].body).toList();
    try {
      final res = await context.read<ApiService>().ingestSMSBatch(bodies);
      if (!mounted) return;
      final count = res['processed'] ?? bodies.length;
      setState(() { _result = 'Synced $count transaction${count != 1 ? 's' : ''}'; _sending = false; });
      if (count > 0) _invalidateProviders();
    } catch (e) {
      if (!mounted) return;
      setState(() { _result = e.toString().replaceFirst('Exception: ', ''); _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFA8FF3E).withValues(alpha: 0.1)),
                child: const Icon(Icons.message_outlined, size: 20, color: Color(0xFFA8FF3E)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bank SMS', style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Reads your inbox and filters bank alerts only', style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ])),
              const SizedBox(width: 12),
              _loading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent))
                  : GestureDetector(
                      onTap: _scan,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(10)),
                        child: Text('Scan', style: TextStyle(color: c.background, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
            ]),
          ),

          if (_result != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: Border.all(color: _result!.startsWith('Synced')
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.destructive.withValues(alpha: 0.3)),
              child: Row(children: [
                Icon(
                  _result!.startsWith('Synced') ? Icons.check_circle_outline : Icons.error_outline,
                  size: 16,
                  color: _result!.startsWith('Synced') ? AppColors.success : AppColors.destructive,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_result!, style: TextStyle(
                  color: _result!.startsWith('Synced') ? AppColors.success : AppColors.destructive,
                  fontSize: 13,
                ))),
              ]),
            ),
          ],

          if (_messages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_messages.length} bank message${_messages.length != 1 ? 's' : ''} found',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
              GestureDetector(
                onTap: () => setState(() {
                  if (_selected.length == _messages.length) {
                    _selected.clear();
                  } else {
                    _selected.addAll(List.generate(_messages.length, (i) => i));
                  }
                }),
                child: Text(
                  _selected.length == _messages.length ? 'Deselect all' : 'Select all',
                  style: TextStyle(color: c.accent, fontSize: 13),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final msg = _messages[i];
                  final selected = _selected.contains(i);
                  return GestureDetector(
                    onTap: () => setState(() => selected ? _selected.remove(i) : _selected.add(i)),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      border: Border.all(color: selected ? c.accent.withValues(alpha: 0.4) : c.borderDefault),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(
                          selected ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: selected ? c.accent : c.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(msg.address, style: TextStyle(color: c.accent, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(msg.body, style: TextStyle(color: c.textPrimary, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            '${msg.date.day}/${msg.date.month}/${msg.date.year}',
                            style: TextStyle(color: c.textSecondary, fontSize: 11),
                          ),
                        ])),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _sending
                ? Center(child: CircularProgressIndicator(color: c.accent))
                : PrimaryButton(
                    label: 'Sync ${_selected.length} Message${_selected.length != 1 ? 's' : ''}',
                    onTap: _selected.isEmpty ? null : _send,
                  ),
            const SizedBox(height: 100),
          ] else if (!_loading) ...[
            const Spacer(),
            Center(child: Column(children: [
              Icon(Icons.message_outlined, size: 48, color: c.textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('Tap Scan to read bank SMS', style: TextStyle(color: c.textSecondary, fontSize: 14)),
            ])),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

// ── Upload Tab ────────────────────────────────────────────────────────────────

class _UploadTab extends StatefulWidget {
  final void Function(bool)? onPickerActive;
  const _UploadTab({this.onPickerActive});

  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> with AutomaticKeepAliveClientMixin {
  File? _file;
  bool _uploading = false;
  String? _result;

  @override
  bool get wantKeepAlive => _uploading;

  Future<void> _pick() async {
    widget.onPickerActive?.call(true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'pdf', 'xlsx'],
    );
    widget.onPickerActive?.call(false);
    if (!mounted) return;
    if (result == null || result.files.single.path == null) return;
    setState(() { _file = File(result.files.single.path!); _result = null; });
  }

  Future<void> _upload() async {
    if (_file == null) return;
    setState(() { _uploading = true; _result = null; });
    final file = _file!;
    try {
      final res = await context.read<ApiService>().uploadStatement(file);
      if (!mounted) return;
      final count = res['processed'] ?? 0;
      setState(() { _result = 'Imported $count transaction${count != 1 ? 's' : ''}'; _uploading = false; _file = null; });
      if (count > 0) {
        context.read<DashboardProvider>().invalidate();
        context.read<AnalyticsProvider>().invalidate();
        context.read<DashboardProvider>().load();
        context.read<AnalyticsProvider>().load('week');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _result = e.toString().replaceFirst('Exception: ', ''); _uploading = false; });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = AppColors.of(context);
    final fileName = _file?.path.split('/').last;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Icon(Icons.upload_file_outlined, size: 40, color: c.accent),
                const SizedBox(height: 12),
                Text('Upload Bank Statement', style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Supports CSV, PDF and XLSX formats', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pick,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.accent.withValues(alpha: 0.4), style: BorderStyle.solid),
                      color: c.accent.withValues(alpha: 0.05),
                    ),
                    child: Column(children: [
                      Icon(Icons.folder_open_outlined, size: 24, color: c.accent),
                      const SizedBox(height: 6),
                      Text(fileName ?? 'Choose CSV, PDF or XLSX file', style: TextStyle(color: c.accent, fontSize: 14)),
                    ]),
                  ),
                ),
              ]),
            ),

            if (_file != null) ...[
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(14),
                border: Border.all(color: c.accent.withValues(alpha: 0.3)),
                child: Row(children: [
                  Icon(
                  fileName!.toLowerCase().endsWith('.pdf')
                      ? Icons.picture_as_pdf_outlined
                      : fileName!.toLowerCase().endsWith('.xlsx')
                          ? Icons.table_chart_outlined
                          : Icons.description_outlined,
                  size: 20,
                  color: c.accent,
                ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(fileName!, style: TextStyle(color: c.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  GestureDetector(
                    onTap: () => setState(() { _file = null; _result = null; }),
                    child: Icon(Icons.close, size: 18, color: c.textSecondary),
                  ),
                ]),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: Border.all(color: _result!.startsWith('Imported')
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.destructive.withValues(alpha: 0.3)),
                child: Row(children: [
                  Icon(
                    _result!.startsWith('Imported') ? Icons.check_circle_outline : Icons.error_outline,
                    size: 16,
                    color: _result!.startsWith('Imported') ? AppColors.success : AppColors.destructive,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_result!, style: TextStyle(
                    color: _result!.startsWith('Imported') ? AppColors.success : AppColors.destructive,
                    fontSize: 13,
                  ))),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            if (_uploading)
              Center(child: CircularProgressIndicator(color: c.accent))
            else if (_file != null)
              PrimaryButton(label: 'Upload & Import', onTap: _upload),

            const SizedBox(height: 24),

            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text('CSV & PDF format', style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Export your transaction history as CSV or PDF from your bank\'s app or internet banking portal (GTBank, Access, Zenith, UBA, Kuda, etc.) and upload here.',
                  style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  'CSV: date, amount, type (debit/credit), merchant\nPDF: standard bank statement format\nXLSX: exported from bank portal or Excel',
                  style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.5),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
