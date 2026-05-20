import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

// ── Public entry point ────────────────────────────────────────────────────────

enum PasscodeMode { verify, setup }

Future<bool?> showPasscodeScreen(
  BuildContext context, {
  required PasscodeMode mode,
  String? title,
  String? subtitle,
}) {
  return Navigator.of(context).push<bool>(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) =>
          PasscodeScreen(mode: mode, title: title, subtitle: subtitle),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    ),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PasscodeScreen extends StatefulWidget {
  final PasscodeMode mode;
  final String? title;
  final String? subtitle;
  const PasscodeScreen({super.key, required this.mode, this.title, this.subtitle});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen>
    with SingleTickerProviderStateMixin {
  static const _len = 6;
  static const _prefKey = 'app_passcode';

  String _pin = '';
  String? _firstPin;
  bool _confirming = false;
  String? _error;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.mode == PasscodeMode.setup) {
      return _confirming ? 'Re-enter Passcode' : (widget.title ?? 'Set Passcode');
    }
    return widget.title ?? 'Enter Passcode';
  }

  String get _subtitle {
    if (_error != null) return _error!;
    if (widget.mode == PasscodeMode.setup) {
      return _confirming ? 'Confirm your new passcode' : 'Choose a 6-digit passcode';
    }
    return widget.subtitle ?? '';
  }

  bool get _isError => _error != null;

  Future<void> _onKey(String digit) async {
    if (_pin.length >= _len) return;
    HapticFeedback.lightImpact();
    final next = _pin + digit;
    setState(() { _pin = next; _error = null; });
    if (next.length < _len) return;

    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    if (widget.mode == PasscodeMode.setup) {
      if (!_confirming) {
        setState(() { _firstPin = next; _pin = ''; _confirming = true; });
      } else {
        if (next == _firstPin) {
          final p = await SharedPreferences.getInstance();
          await p.setString(_prefKey, next);
          if (mounted) Navigator.of(context).pop(true);
        } else {
          await _shake();
          setState(() { _pin = ''; _firstPin = null; _confirming = false; _error = 'Passcodes did not match'; });
        }
      }
    } else {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString(_prefKey);
      if (saved == next) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        await _shake();
        setState(() { _pin = ''; _error = 'Incorrect passcode'; });
      }
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() { _pin = _pin.substring(0, _pin.length - 1); _error = null; });
  }

  Future<void> _shake() async {
    HapticFeedback.vibrate();
    await _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Always dark background like iOS passcode screen
    const bg = Color(0xFF1C1C1E);
    const textColor = Colors.white;
    const subtitleColor = Color(0xFFAAAAAA);
    const keyBg = Color(0xFF3A3A3C);
    const keyBgPressed = Color(0xFF636366);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Title
            Text(_title,
                style: const TextStyle(
                    color: textColor, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Subtitle / error
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isError ? AppColors.destructive : subtitleColor,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),

            // Dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeCtrl.isAnimating ? _shakeAnim.value : 0, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_len, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? textColor : Colors.transparent,
                      border: Border.all(color: textColor.withValues(alpha: filled ? 1.0 : 0.5), width: 1.5),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 4),

            // Numpad — rows 1-9 then bottom row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: Column(
                children: [
                  // Rows 1-3
                  for (final row in [
                    [_K('1', ''), _K('2', 'ABC'), _K('3', 'DEF')],
                    [_K('4', 'GHI'), _K('5', 'JKL'), _K('6', 'MNO')],
                    [_K('7', 'PQRS'), _K('8', 'TUV'), _K('9', 'WXYZ')],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row
                            .map((k) => _DialKey(
                                  digit: k.digit,
                                  letters: k.letters,
                                  bg: keyBg,
                                  bgPressed: keyBgPressed,
                                  textColor: textColor,
                                  onTap: () => _onKey(k.digit),
                                ))
                            .toList(),
                      ),
                    ),

                  // Bottom row: empty | 0 | backspace
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 80, height: 80), // empty slot
                      _DialKey(
                        digit: '0',
                        letters: '',
                        bg: keyBg,
                        bgPressed: keyBgPressed,
                        textColor: textColor,
                        onTap: () => _onKey('0'),
                      ),
                      // Backspace
                      SizedBox(
                        width: 80, height: 80,
                        child: GestureDetector(
                          onTap: _onDelete,
                          child: const Center(
                            child: Icon(Icons.backspace_outlined,
                                color: textColor, size: 26),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Bottom bar: Cancel only
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(color: textColor, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Key data ──────────────────────────────────────────────────────────────────

class _K {
  final String digit, letters;
  const _K(this.digit, this.letters);
}

// ── Dial key ──────────────────────────────────────────────────────────────────

class _DialKey extends StatefulWidget {
  final String digit, letters;
  final Color bg, bgPressed, textColor;
  final VoidCallback onTap;
  const _DialKey({
    required this.digit,
    required this.letters,
    required this.bg,
    required this.bgPressed,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_DialKey> createState() => _DialKeyState();
}

class _DialKeyState extends State<_DialKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed ? widget.bgPressed : widget.bg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.digit,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 32,
                fontWeight: FontWeight.w300,
                height: 1.0,
              ),
            ),
            if (widget.letters.isNotEmpty)
              Text(
                widget.letters,
                style: TextStyle(
                  color: widget.textColor.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
