import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _defaultPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.athkar.athkarcom';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('AppConfig')
          .doc('version')
          .get();

      if (doc.exists && doc.data() != null) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        final String latestVersion = data['latestVersion'] as String? ?? '';
        final String minVersion = data['minVersion'] as String? ?? '';
        final String updateUrl =
            data['updateUrl'] as String? ?? _defaultPlayStoreUrl;
        final String updateMessage = data['updateMessage'] as String? ??
            'يتوفر إصدار جديد من تطبيق أذكاركم. يرجى التحديث للحصول على آخر الميزات والتحسينات.';

        if (_isVersionOlder(currentVersion, latestVersion)) {
          final bool isForceUpdate =
          _isVersionOlder(currentVersion, minVersion);

          if (context.mounted) {
            _showUpdateDialog(
              context,
              latestVersion: latestVersion,
              updateUrl: updateUrl,
              updateMessage: updateMessage,
              isForceUpdate: isForceUpdate,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static bool _isVersionOlder(String current, String target) {
    if (current.isEmpty || target.isEmpty) return false;

    final String currentClean = current.split('+').first;
    final String targetClean = target.split('+').first;

    final List<int> currentParts =
    currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final List<int> targetParts =
    targetClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final int maxLength = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    while (currentParts.length < maxLength) currentParts.add(0);
    while (targetParts.length < maxLength) targetParts.add(0);

    for (int i = 0; i < maxLength; i++) {
      if (currentParts[i] < targetParts[i]) return true;
      if (currentParts[i] > targetParts[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
      BuildContext context, {
        required String latestVersion,
        required String updateUrl,
        required String updateMessage,
        required bool isForceUpdate,
      }) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => _UpdateDialog(
        latestVersion: latestVersion,
        updateUrl: updateUrl,
        updateMessage: updateMessage,
        isForceUpdate: isForceUpdate,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Update Dialog Widget
// ─────────────────────────────────────────────
class _UpdateDialog extends StatefulWidget {
  final String latestVersion;
  final String updateUrl;
  final String updateMessage;
  final bool isForceUpdate;

  const _UpdateDialog({
    required this.latestVersion,
    required this.updateUrl,
    required this.updateMessage,
    required this.isForceUpdate,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUpdate() async {
    final Uri url = Uri.parse(widget.updateUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch update url: ${widget.updateUrl}');
    }

    if (widget.isForceUpdate && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withOpacity(0.6),
            builder: (_) => _UpdateDialog(
              latestVersion: widget.latestVersion,
              updateUrl: widget.updateUrl,
              updateMessage: widget.updateMessage,
              isForceUpdate: widget.isForceUpdate,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A2A),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header banner ──────────────────────────────
                  _Header(isForceUpdate: widget.isForceUpdate),

                  // ── Body ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Version badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D6E).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: const Color(0xFF4CAF96).withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.new_releases_rounded,
                                size: 14,
                                color: Color(0xFF4CAF96),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'الإصدار ${widget.latestVersion}',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4CAF96),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          widget.isForceUpdate
                              ? 'يجب تحديث التطبيق'
                              : 'تحديث جديد متاح',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF0F4F3),
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Divider line
                        Container(
                          width: 40,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF96).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Message
                        Text(
                          widget.updateMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14.5,
                            height: 1.65,
                            color: const Color(0xFFB0C4BC),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Feature chips
                        if (!widget.isForceUpdate) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _FeatureChip(
                                  icon: Icons.speed_rounded,
                                  label: 'أداء أسرع'),
                              _FeatureChip(
                                  icon: Icons.bug_report_rounded,
                                  label: 'إصلاح الأخطاء'),
                              _FeatureChip(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'مميزات جديدة'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Buttons ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      children: [
                        // Update button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2E7D6E),
                                  Color(0xFF1E5C51),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  const Color(0xFF2E7D6E).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: _launchUpdate,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.system_update_alt_rounded,
                                      size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'تحديث الآن',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // "Later" button — only for optional updates
                        if (!widget.isForceUpdate) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF7A9E96),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color:
                                    const Color(0xFF4CAF96).withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'لاحقاً',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header with gradient illustration
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isForceUpdate;
  const _Header({required this.isForceUpdate});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A4A40), Color(0xFF0D2B25)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative rings
            _Ring(size: 180, opacity: 0.06),
            _Ring(size: 120, opacity: 0.09),
            _Ring(size: 68, opacity: 0.14),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF96), Color(0xFF2E7D6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF96).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isForceUpdate
                    ? Icons.system_update_rounded
                    : Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),

            // Small sparkle dots
            Positioned(
                top: 22, left: 40, child: _Dot(size: 5, opacity: 0.4)),
            Positioned(
                top: 50, right: 50, child: _Dot(size: 4, opacity: 0.3)),
            Positioned(
                bottom: 24, left: 70, child: _Dot(size: 6, opacity: 0.25)),
            Positioned(
                bottom: 18, right: 38, child: _Dot(size: 4, opacity: 0.35)),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final double opacity;
  const _Ring({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF4CAF96).withOpacity(opacity),
          width: 1.2,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final double opacity;
  const _Dot({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4CAF96).withOpacity(opacity),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Feature chip
// ─────────────────────────────────────────────
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF243330),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color(0xFF4CAF96).withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF4CAF96)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Color(0xFF8DB8AE),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}