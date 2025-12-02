// lib/screens/home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../router/app_router.dart';
import '../components/double_stroke_text.dart';
import 'draw_path.dart';
import '../services/sound_service.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _tutorialKey = 'home_showcase_shown';

  final GlobalKey _connectNavKey = GlobalKey();
  final GlobalKey _newPathKey = GlobalKey();
  final GlobalKey _loadFileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    SoundService.instance.ensurePlaying();
    ShowcaseView.register(
      enableAutoScroll: false,
      disableBarrierInteraction: false,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartShowcase();
    });
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    super.dispose();
  }

  Future<void> _maybeStartShowcase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool(_tutorialKey) ?? false;
      if (hasShown || !mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      ShowcaseView.get().startShowCase([
        _connectNavKey,
        _newPathKey,
        _loadFileKey,
      ]);
      await prefs.setBool(_tutorialKey, true);
    } catch (e) {
      debugPrint('Failed to start showcase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1433),
      body: Stack(
        children: [
          // 1) Galaxy background
          Positioned.fill(
            child: Image.asset('assets/splash/bg.png', fit: BoxFit.cover),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  'assets/brand/mascotnobg.png',
                  width: MediaQuery.of(context).size.width * 0.18,
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;

                // Skala responsif (selaras dengan splash)
                final topNavW = math.min(w * 0.5, 520.0);
                final topNavH = math.min(h * 0.15, 72.0);

                final panelW = math.min(w * 0.78, 960.0);
                final panelH = math.min(h * 0.66, 380.0);

                final subtitleFont = math.min(w * 0.03, 20.0);

                final ctaW = math.min(w * 0.22, 320.0);
                final ctaH = math.min(h * 0.10, 64.0);

                return Stack(
                  children: [
                    // 2) Top segmented nav
                    Align(
                      alignment: const Alignment(0, -0.78),
                      child: _TopSegmentedNav(
                        width: topNavW,
                        height: topNavH,
                        onTapHome: () {},
                        onTapWorkspace: () {
                          // Navigator.pushReplacementNamed(context, AppRoutes.webview);
                        },
                        onTapConnect: () {
                          Navigator.pushNamed(context, AppRoutes.connect);
                        },
                        connectShowcaseKey: _connectNavKey,
                        l10n: l10n,
                      ),
                    ),

                    // 3) Panel tengah (galaxy card)
                    Align(
                      alignment: const Alignment(0, 0.6),
                      child: _GalaxyPanel(
                        width: panelW,
                        height: panelH,
                        subtitleFont: subtitleFont,
                        ctaWidth: ctaW,
                        ctaHeight: ctaH,
                        newPathKey: _newPathKey,
                        loadFileKey: _loadFileKey,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _SettingsButton(
                        onTap: () async {
                          SoundService.instance.playClick();
                          final result = await Navigator.pushNamed(
                            context,
                            AppRoutes.settings,
                          );
                          if (result == true && mounted) {
                            await Future.delayed(
                              const Duration(milliseconds: 300),
                            );
                            if (mounted) {
                              ShowcaseView.get().startShowCase([
                                _connectNavKey,
                                _newPathKey,
                                _loadFileKey,
                              ]);
                            }
                          }
                        },
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

class _TopSegmentedNav extends StatelessWidget {
  const _TopSegmentedNav({
    required this.width,
    required this.height,
    required this.onTapHome,
    required this.onTapWorkspace,
    required this.onTapConnect,
    this.connectShowcaseKey,
    this.l10n,
  });

  final double width;
  final double height;
  final VoidCallback onTapHome;
  final VoidCallback onTapWorkspace;
  final VoidCallback onTapConnect;
  final GlobalKey? connectShowcaseKey;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height * 0.45);
    final segmentHeight = height - (height * 0.28);
    final dividerColor = const Color.fromARGB(102, 164, 242, 255);
    final titleStyle = GoogleFonts.titanOne(
      fontSize: 16,
      color: const Color(0xFFA5F1FF),
      letterSpacing: 0.8,
    );
    final descStyle = GoogleFonts.inter(
      fontSize: 13,
      color: const Color(0xFFF5FDFF),
      fontWeight: FontWeight.w400,
    );

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.25,
        vertical: height * 0.14,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [Color(0xFF122A4D), Color(0xFF0F1D3C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: const Color.fromARGB(204, 115, 240, 255),
          width: 2.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(71, 106, 232, 255),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavPill(
              label: l10n?.navHome ?? 'HOME',
              width: width * 0.2,
              icon: Icons.rocket_launch_outlined,
              active: true,
              height: segmentHeight,
              onTap: onTapHome,
            ),
          ),
          _NavDivider(
            color: dividerColor,
            height: segmentHeight,
            width: width * 0.2,
          ),
          Expanded(
            child: connectShowcaseKey == null
                ? _NavPill(
                    label: l10n?.navConnect ?? 'CONNECT',
                    width: width * 0.2,
                    icon: Icons.wifi_tethering_outlined,
                    height: segmentHeight,
                    onTap: onTapConnect,
                  )
                : Showcase(
                    key: connectShowcaseKey!,
                    title: l10n?.showcaseConnectTitle ?? 'Connect',
                    description:
                        l10n?.showcaseConnectDesc ??
                        'Pastikan robotmu tersambung sebelum mulai menggambar jalur.',
                    targetBorderRadius: BorderRadius.circular(
                      segmentHeight * 0.48,
                    ),
                    tooltipBackgroundColor: const Color(0xFF0F1D3C),
                    tooltipBorderRadius: BorderRadius.circular(16),
                    titleTextStyle: titleStyle,
                    descTextStyle: descStyle,
                    tooltipPadding: const EdgeInsets.all(20),
                    showArrow: false,
                    tooltipActionConfig: const TooltipActionConfig(
                      position: TooltipActionPosition.outside,
                      alignment: MainAxisAlignment.spaceBetween,
                    ),
                    tooltipActions: [
                      TooltipActionButton(
                        type: TooltipDefaultActionType.skip,
                        name: l10n?.btnSkip ?? 'Skip',
                      ),
                      TooltipActionButton(
                        type: TooltipDefaultActionType.next,
                        name: l10n?.btnNext ?? 'Next',
                      ),
                    ],
                    child: _NavPill(
                      label: l10n?.navConnect ?? 'CONNECT',
                      width: width * 0.2,
                      icon: Icons.wifi_tethering_outlined,
                      height: segmentHeight,
                      onTap: onTapConnect,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NavDivider extends StatelessWidget {
  const _NavDivider({
    required this.color,
    required this.width,
    required this.height,
  });
  final double width;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * 0.2,
      child: Center(
        child: Container(
          width: width,
          height: height * 0.72,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.label,
    required this.icon,
    required this.height,
    this.width = double.infinity,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final double height;
  final double width;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(height * 0.48);
    final gradient = active
        ? const LinearGradient(
            colors: [Color(0xFF41D8FF), Color(0xFF4A7CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0x00222E5C), Color(0x33222E5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final borderColor = active
        ? const Color(0xFFA7F8FF)
        : const Color.fromARGB(166, 139, 216, 255);

    final textStyle = GoogleFonts.titanOne(
      fontSize: height * 0.25,
      color: Colors.white,
      letterSpacing: 0.2,
    );

    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap == null
          ? null
          : () {
              SoundService.instance.playClick();
              onTap?.call();
            },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor, width: 1.6),
          boxShadow: [
            if (active)
              BoxShadow(
                color: const Color.fromARGB(115, 128, 241, 255),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: height * 0.24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: height * 0.35, color: const Color(0xFFF5FDFF)),
            SizedBox(width: height * 0.16),
            Flexible(
              child: Text(label, textAlign: TextAlign.center, style: textStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalaxyPanel extends StatelessWidget {
  const _GalaxyPanel({
    required this.width,
    required this.height,
    required this.subtitleFont,
    required this.ctaWidth,
    required this.ctaHeight,
    required this.newPathKey,
    required this.loadFileKey,
  });

  final double width;
  final double height;
  final double subtitleFont;
  final double ctaWidth;
  final double ctaHeight;
  final GlobalKey newPathKey;
  final GlobalKey loadFileKey;

  @override
  Widget build(BuildContext context) {
    final shortestSide = math.min(width, height);
    final l10n = AppLocalizations.of(context);
    final outerRadius = BorderRadius.circular(shortestSide * 0.08);
    final innerRadius = BorderRadius.circular(shortestSide * 0.07);
    final panelPadding = shortestSide * 0.05;
    final logoVisualWidth = math.min(width * 0.6, height * 0.9);
    final logoSlotHeight = height * 0.18;
    final buttonSpacing = ctaWidth * 0.08;
    final runSpacing = ctaHeight * 0.35;
    final titleStyle = GoogleFonts.titanOne(
      fontSize: 16,
      color: const Color(0xFFA5F1FF),
      letterSpacing: 0.8,
    );
    final descStyle = GoogleFonts.inter(
      fontSize: 13,
      color: const Color(0xFFF5FDFF),
      fontWeight: FontWeight.w400,
    );
    void openNewPath() {
      Navigator.of(context).pushNamed(AppRoutes.drawPath);
    }

    void openLoadPath() {
      Navigator.of(context).pushNamed(
        AppRoutes.drawPath,
        arguments: const DrawPathScreenArgs(openLoadPicker: true),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: outerRadius,
        gradient: const LinearGradient(
          colors: [Color.fromARGB(99, 17, 45, 207), Color(0x6515234F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color.fromARGB(204, 115, 240, 255),
          width: math.max(4, height * 0.015),
        ),

        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(89, 178, 156, 255),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: panelPadding,
        ).copyWith(top: panelPadding * 4, bottom: panelPadding),
        decoration: BoxDecoration(
          borderRadius: innerRadius,
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(139, 115, 241, 255),
              Color.fromARGB(128, 25, 35, 69),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              height: logoSlotHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: OverflowBox(
                  minHeight: 0,
                  minWidth: 0,
                  maxWidth: logoVisualWidth,
                  maxHeight: height * 0.35,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/brand/logo_crop.png',
                    width: logoVisualWidth,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: height * 0.04),
            DoubleStrokeText(
              text: l10n.homeSubtitle,
              fontSize: subtitleFont,
              letterSpacing: 1.8,
              outerStrokeColor: const Color(0xFF0C2F66), // biru gelap
              innerStrokeColor: const Color(0xFF6EE7FF), // biru terang
              fillColor: const Color(0xFFF4FDFF), // putih lembut
              outerStrokeWidth: 4.0,
              innerStrokeWidth: 8.0,
            ),
            SizedBox(height: height * 0.08),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: buttonSpacing,
              runSpacing: runSpacing,
              children: [
                Showcase(
                  key: newPathKey,
                  title: l10n.showcaseNewPathTitle,
                  description: l10n.showcaseNewPathDesc,
                  targetBorderRadius: BorderRadius.circular(ctaHeight * 0.5),
                  tooltipBackgroundColor: const Color(0xFF0F1D3C),
                  tooltipBorderRadius: BorderRadius.circular(16),
                  titleTextStyle: titleStyle,
                  descTextStyle: descStyle,
                  tooltipPadding: const EdgeInsets.all(20),
                  showArrow: false,
                  tooltipActionConfig: const TooltipActionConfig(
                    position: TooltipActionPosition.outside,
                    alignment: MainAxisAlignment.spaceBetween,
                  ),
                  tooltipActions: [
                    TooltipActionButton(
                      type: TooltipDefaultActionType.previous,
                      name: l10n.btnPrevious,
                    ),
                    TooltipActionButton(
                      type: TooltipDefaultActionType.next,
                      name: l10n.btnNext,
                    ),
                  ],
                  child: _CTAButton(
                    width: ctaWidth,
                    height: ctaHeight,
                    label: l10n.btnNewPath,
                    icon: Icons.add_circle_rounded,
                    iconColor: const Color.fromARGB(255, 255, 255, 255),
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 233, 130, 253),
                        Color.fromARGB(255, 243, 167, 255),
                      ],
                    ),
                    borderColor: const Color(0xFFFDF5FF),
                    shadowColor: const Color(0xFFE3CFFF),
                    onTap: openNewPath,
                  ),
                ),
                Showcase(
                  key: loadFileKey,
                  title: l10n.showcaseLoadTitle,
                  description: l10n.showcaseLoadDesc,
                  targetBorderRadius: BorderRadius.circular(ctaHeight * 0.5),
                  tooltipBackgroundColor: const Color(0xFF0F1D3C),
                  tooltipBorderRadius: BorderRadius.circular(16),
                  titleTextStyle: titleStyle,
                  descTextStyle: descStyle,
                  tooltipPadding: const EdgeInsets.all(20),
                  showArrow: false,
                  tooltipActionConfig: const TooltipActionConfig(
                    position: TooltipActionPosition.outside,
                    alignment: MainAxisAlignment.spaceBetween,
                  ),
                  tooltipActions: [
                    TooltipActionButton(
                      type: TooltipDefaultActionType.previous,
                      name: l10n.btnPrevious,
                    ),
                    TooltipActionButton(
                      type: TooltipDefaultActionType.skip,
                      name: l10n.btnFinish,
                    ),
                  ],
                  child: _CTAButton(
                    width: ctaWidth,
                    height: ctaHeight,
                    label: l10n.btnLoadFile,
                    icon: Icons.folder_open_rounded,
                    iconColor: const Color.fromARGB(255, 255, 255, 255),
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 48, 195, 221),
                        Color(0xFF9FFCF6),
                      ],
                    ),
                    borderColor: const Color(0xFFE4FFFF),
                    shadowColor: const Color(0xFF7EE5F6),
                    onTap: openLoadPath,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CTAButton extends StatelessWidget {
  const _CTAButton({
    required this.width,
    required this.height,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.borderColor,
    required this.shadowColor,
    this.onTap,
  });

  final double width;
  final double height;
  final String label;
  final IconData icon;
  final Color iconColor;
  final LinearGradient gradient;
  final Color borderColor;
  final Color shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height * 0.5);
    final textStyle = GoogleFonts.titanOne(
      fontSize: height * 0.4,
      letterSpacing: 0.2,
      color: const Color.fromARGB(255, 255, 255, 255),
    );

    return InkWell(
      borderRadius: radius,
      onTap: onTap == null
          ? null
          : () {
              SoundService.instance.playClick();
              onTap?.call();
            },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          border: Border.all(color: borderColor, width: height * 0.06),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(
                140,
                shadowColor.red,
                shadowColor.green,
                shadowColor.blue,
              ), // ignore: deprecated_member_use
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: height * 0.36),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Stroke (black)
                Icon(icon, size: height * 0.45, color: Colors.black),
                // Fill
                Icon(icon, size: height * 0.42, color: iconColor),
              ],
            ),
            SizedBox(width: height * 0.24),
            Flexible(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // stroke (black)
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textStyle.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = math.max(1.0, height * 0.06)
                        ..color = const Color.fromARGB(129, 0, 0, 0),
                    ),
                  ),
                  // fill
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
          border: Border.all(
            color: const Color.fromARGB(204, 115, 240, 255),
            width: 2,
          ),
        ),
        child: const Icon(Icons.settings, color: Colors.white, size: 28),
      ),
    );
  }
}
