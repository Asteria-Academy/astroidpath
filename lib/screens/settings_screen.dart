// lib/screens/settings_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';
import '../l10n/app_localizations.dart';
import '../services/sound_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _musicVolumeKey = 'music_volume';
  static const _sfxVolumeKey = 'sfx_volume';
  static const _languageKey = 'language';

  double _musicVolume = 0.2;
  double _sfxVolume = 0.8;
  bool _isLoading = true;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    SoundService.instance.ensurePlaying();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.2;
      _sfxVolume = prefs.getDouble(_sfxVolumeKey) ?? 0.8;
      _language = prefs.getString(_languageKey) ?? 'en';
      _isLoading = false;
    });
    await SoundService.instance.init(
      bgmVolume: _musicVolume,
      sfxVolume: _sfxVolume,
    );
  }

  Future<void> _setMusicEnabled(bool enabled) async {
    final value = enabled ? 1.0 : 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, value);
    setState(() => _musicVolume = value);
    _previewMusic();
  }

  Future<void> _setSfxEnabled(bool enabled) async {
    final value = enabled ? 1.0 : 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sfxVolumeKey, value);
    setState(() => _sfxVolume = value);
    SoundService.instance.setSfxVolume(value);
    _previewSfx();
  }

  Future<void> _saveLanguage(String code) async {
    SoundService.instance.playClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
    setState(() => _language = code);
    if (mounted) {
      MyApp.setLocale(context, Locale(code));
    }
  }

  void _previewMusic() {
    SoundService.instance.setBgmVolume(_musicVolume);
  }

  void _previewSfx() {
    SoundService.instance.playClick();
  }

  void _showTutorial() {
    SoundService.instance.playClick();
    SoundService.instance.resumeBgmIfEnabled();
    Navigator.pop(context, true); // return true to trigger showcase on home
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1433),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/splash/bg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                final panelW = math.min(w * 0.82, 860.0);
                final panelH = math.min(h * 0.72, 520.0);
                final titleFont = math.min(w * 0.045, 28.0);

                return Stack(
                  children: [
                    Positioned(
                      left: 16,
                      top: 16,
                      child: _BackButton(
                        onTap: () {
                          SoundService.instance.playClick();
                          SoundService.instance.resumeBgmIfEnabled();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: _SettingsPanel(
                        width: panelW,
                        height: panelH,
                        titleFont: titleFont,
                        musicEnabled: _musicVolume > 0,
                        sfxEnabled: _sfxVolume > 0,
                        isLoading: _isLoading,
                        language: _language,
                        l10n: l10n,
                        onMusicToggle: _setMusicEnabled,
                        onSfxToggle: _setSfxEnabled,
                        onLanguageChange: _saveLanguage,
                        onShowTutorial: _showTutorial,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.width,
    required this.height,
    required this.titleFont,
    required this.musicEnabled,
    required this.sfxEnabled,
    required this.isLoading,
    required this.language,
    required this.l10n,
    required this.onMusicToggle,
    required this.onSfxToggle,
    required this.onLanguageChange,
    required this.onShowTutorial,
  });

  final double width;
  final double height;
  final double titleFont;
  final bool musicEnabled;
  final bool sfxEnabled;
  final bool isLoading;
  final String language;
  final AppLocalizations l10n;
  final ValueChanged<bool> onMusicToggle;
  final ValueChanged<bool> onSfxToggle;
  final ValueChanged<String> onLanguageChange;
  final VoidCallback onShowTutorial;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width * 0.04);
    final innerRadius = BorderRadius.circular(width * 0.035);
    final panelPadding = width * 0.045;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [Color(0x64283268), Color(0x6515234F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFB7A6FF),
          width: math.max(4, height * 0.015),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(89, 178, 156, 255),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: innerRadius,
          gradient: const LinearGradient(
            colors: [Color(0x80213C7A), Color(0x801B2856)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(panelPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsTitle,
                      style: GoogleFonts.titanOne(
                        fontSize: titleFont,
                        color: const Color(0xFFF4FDFF),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LanguageRow(
                      l10n: l10n,
                      current: language,
                      onChanged: onLanguageChange,
                    ),
                    const SizedBox(height: 20),
                    _ToggleTile(
                      label: l10n.bgm,
                      value: musicEnabled,
                      isLoading: isLoading,
                      onChanged: onMusicToggle,
                    ),
                    const SizedBox(height: 12),
                    _ToggleTile(
                      label: l10n.sfx,
                      value: sfxEnabled,
                      isLoading: isLoading,
                      onChanged: onSfxToggle,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _TutorialButton(
                        label: l10n.tutorial,
                        onTap: onShowTutorial,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isLoading,
  });

  final String label;
  final bool value;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      fontSize: 16,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Switch.adaptive(
          value: value,
          onChanged: isLoading ? null : onChanged,
          activeColor: const Color(0xFF41D8FF),
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.l10n,
    required this.current,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final chipStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFF5FDFF),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.language,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LangChip(
              label: l10n.english,
              selected: current == 'en',
              onTap: () => onChanged('en'),
              textStyle: chipStyle,
            ),
            const SizedBox(width: 10),
            _LangChip(
              label: l10n.indonesian,
              selected: current == 'id',
              onTap: () => onChanged('id'),
              textStyle: chipStyle,
            ),
          ],
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF41D8FF), Color(0xFF4A7CFF)],
                )
              : const LinearGradient(
                  colors: [Color(0x33213C7A), Color(0x331B2856)],
                ),
          border: Border.all(
            color: selected ? const Color(0xFFA7F8FF) : const Color(0x6685A0FF),
            width: 1.6,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color.fromARGB(80, 128, 241, 255),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }
}

class _TutorialButton extends StatelessWidget {
  const _TutorialButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.school, color: Color(0xFFA7F8FF)),
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFFF5FDFF),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0x33213C7A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF41D8FF), Color(0xFF4A7CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(115, 128, 241, 255),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}
