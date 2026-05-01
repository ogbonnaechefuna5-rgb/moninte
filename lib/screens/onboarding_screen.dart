import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_toggle.dart';
import '../models/bank.dart';
import '../utils/formatters.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 6;

  // Step 1: Name
  final _nameController = TextEditingController();
  String _initials = '';

  // Step 2: Photo
  File? _photoFile;
  final _picker = ImagePicker();

  // Step 3: Banks
  final Set<String> _selectedBanks = {};

  // Step 4: Budget
  double _monthlyBudget = 200000;
  static const _quickPicks = [100000.0, 200000.0, 300000.0, 500000.0];

  // Step 5: Notifications
  final Map<String, bool> _notifs = {
    'Transaction Alerts': true,
    'Budget Warnings': true,
    'AI Insights': true,
    'Weekly Digest': false,
    'Savings Reminders': true,
  };

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => _photoFile = File(picked.path));
  }

  void _updateInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      _initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      _initials = parts[0][0].toUpperCase();
    } else {
      _initials = '';
    }
  }

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep = step);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_currentStep < _totalSteps - 1) {
      _goTo(_currentStep + 1);
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(children: [
                Row(children: [
                  if (_currentStep > 0)
                    GestureDetector(
                      onTap: () => _goTo(_currentStep - 1),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
                    )
                  else
                    const SizedBox(width: 22),
                  const Spacer(),
                  if (_currentStep < _totalSteps - 1)
                    GestureDetector(
                      onTap: widget.onComplete,
                      child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 3,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _NameStep(
                    controller: _nameController,
                    initials: _initials,
                    onChanged: (v) => setState(() => _updateInitials(v)),
                  ),
                  _PhotoStep(
                    initials: _initials,
                    photoFile: _photoFile,
                    onPickPhoto: _pickPhoto,
                    onRemovePhoto: () => setState(() => _photoFile = null),
                  ),
                  _BankStep(
                    selectedBanks: _selectedBanks,
                    onToggleBank: (name) => setState(() {
                      _selectedBanks.contains(name)
                          ? _selectedBanks.remove(name)
                          : _selectedBanks.add(name);
                    }),
                  ),
                  _BudgetStep(
                    monthlyBudget: _monthlyBudget,
                    quickPicks: _quickPicks,
                    onBudgetChanged: (v) => setState(() => _monthlyBudget = v),
                  ),
                  _NotifStep(
                    notifs: _notifs,
                    onToggle: (key) => setState(() => _notifs[key] = !_notifs[key]!),
                    onToggleAll: () => setState(() {
                      final allOn = _notifs.values.every((v) => v);
                      for (final k in _notifs.keys) {
                        _notifs[k] = !allOn;
                      }
                    }),
                  ),
                  _SuccessStep(
                    name: _nameController.text,
                    selectedBanksCount: _selectedBanks.length,
                    monthlyBudget: _monthlyBudget,
                    enabledNotifsCount: _notifs.values.where((v) => v).length,
                    onComplete: widget.onComplete,
                  ),
                ],
              ),
            ),
            if (_currentStep < _totalSteps - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Name ──

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  final String initials;
  final ValueChanged<String> onChanged;

  const _NameStep({required this.controller, required this.initials, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Text('What should we\ncall you?', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        const Text("This is how you'll appear in the app", style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 88, height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.primaryGreen],
              ),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.background),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'e.g. Emmanuel Adeyemi',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ),
      ]),
    );
  }
}

// ── Step 2: Profile Photo ──

class _PhotoStep extends StatelessWidget {
  final String initials;
  final File? photoFile;
  final Future<void> Function(ImageSource) onPickPhoto;
  final VoidCallback onRemovePhoto;

  const _PhotoStep({
    required this.initials,
    required this.photoFile,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Text('Add a profile\nphoto', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        const Text('Or keep your initials — totally up to you', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 48),
        Center(
          child: GestureDetector(
            onTap: () => onPickPhoto(ImageSource.gallery),
            child: Stack(children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: photoFile == null
                      ? const LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppColors.accent, AppColors.primaryGreen])
                      : null,
                ),
                child: photoFile != null
                    ? ClipOval(child: Image.file(photoFile!, fit: BoxFit.cover, width: 120, height: 120))
                    : Center(
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.background),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.accent,
                    border: Border.all(color: AppColors.background, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.background, size: 20),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _PhotoOption(icon: Icons.camera_alt_rounded, label: 'Camera', onTap: () => onPickPhoto(ImageSource.camera)),
          const SizedBox(width: 16),
          _PhotoOption(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: () => onPickPhoto(ImageSource.gallery)),
        ]),
        if (photoFile != null) ...[
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: onRemovePhoto,
              child: const Text('Remove photo', style: TextStyle(color: AppColors.destructive, fontSize: 14)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Step 3: Bank Linking ──

class _BankStep extends StatelessWidget {
  final Set<String> selectedBanks;
  final ValueChanged<String> onToggleBank;

  const _BankStep({required this.selectedBanks, required this.onToggleBank});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Text('Link your\nbank accounts', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        const Text('Tap to connect. You can always add more later.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: kSupportedBanks.take(8).map((b) {
              final selected = selectedBanks.contains(b.name);
              return GestureDetector(
                onTap: () => onToggleBank(b.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.accent.withValues(alpha: 0.6) : AppColors.borderDefault,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: b.color),
                      child: Center(
                        child: Text(b.initials,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(b.name,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (selected)
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.check_circle, color: AppColors.accent, size: 18),
                      ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ── Step 4: Budget ──

class _BudgetStep extends StatelessWidget {
  final double monthlyBudget;
  final List<double> quickPicks;
  final ValueChanged<double> onBudgetChanged;

  const _BudgetStep({
    required this.monthlyBudget,
    required this.quickPicks,
    required this.onBudgetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Text('Set your\nmonthly budget', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        const Text('You can fine-tune categories later', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 48),
        Center(
          child: Text(
            fmtCurrencyShort(monthlyBudget),
            style: AppTheme.monoSized(48, color: AppColors.accent, weight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 32),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.15),
            trackHeight: 6,
          ),
          child: Slider(
            min: 50000, max: 1000000,
            divisions: 19,
            value: monthlyBudget,
            onChanged: onBudgetChanged,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: quickPicks.map((v) {
            final selected = monthlyBudget == v;
            return GestureDetector(
              onTap: () => onBudgetChanged(v),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.surfaceDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: selected ? AppColors.accent : AppColors.borderDefault),
                ),
                child: Text(
                  fmtCurrencyShort(v),
                  style: TextStyle(
                    color: selected ? AppColors.background : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

// ── Step 5: Notifications ──

class _NotifStep extends StatelessWidget {
  final Map<String, bool> notifs;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleAll;

  const _NotifStep({
    required this.notifs,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Text('Notification\npreferences', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        const Text('Choose what you want to be notified about', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onToggleAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.notifications_active_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Text('Enable All', style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        ...notifs.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(child: Text(e.key, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
              AppToggle(enabled: e.value, onChanged: () => onToggle(e.key)),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ── Step 6: Success ──

class _SuccessStep extends StatelessWidget {
  final String name;
  final int selectedBanksCount;
  final double monthlyBudget;
  final int enabledNotifsCount;
  final VoidCallback onComplete;

  const _SuccessStep({
    required this.name,
    required this.selectedBanksCount,
    required this.monthlyBudget,
    required this.enabledNotifsCount,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Spacer(flex: 2),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.15),
            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10)],
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.accent, size: 48),
        ),
        const SizedBox(height: 32),
        Text('All Set! 🎉', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 12),
        const Text(
          "You're ready to take control of your finances",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _SummaryRow(label: 'Name', value: name.isEmpty ? 'Not set' : name),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Banks linked', value: '$selectedBanksCount'),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Monthly budget', value: fmtCurrencyShort(monthlyBudget)),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Notifications', value: '$enabledNotifsCount enabled'),
          ]),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      ],
    );
  }
}
