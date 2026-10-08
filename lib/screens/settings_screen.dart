import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../services/gemini_vision_service.dart';
import 'widgets/cyber_glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _obscureKey = true;
  bool _isTestingKey = false;
  bool? _keyTestResult;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiKeyController = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key first.')),
      );
      return;
    }

    setState(() {
      _isTestingKey = true;
      _keyTestResult = null;
    });

    final success = await GeminiVisionService.testApiKey(key);

    if (mounted) {
      setState(() {
        _isTestingKey = false;
        _keyTestResult = success;
      });

      if (success) {
        ref.read(settingsProvider.notifier).updateApiKey(key);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemini API Key verified and saved successfully!'),
            backgroundColor: AppColors.riskLow,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification failed. Check the key and try again.'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Settings & Configuration',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textWhite : AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. Gemini Vision API Key Section
            _buildSectionHeader('AI VISION ENGINE CONFIGURATION'),
            const SizedBox(height: 8),
            CyberGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 18, color: AppColors.primaryCyan),
                      const SizedBox(width: 8),
                      Text(
                        'Google Gemini Vision API',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textWhite : AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: settings.hasApiKey
                              ? AppColors.riskLow.withOpacity(0.15)
                              : AppColors.riskModerate.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: settings.hasApiKey
                                ? AppColors.riskLow.withOpacity(0.4)
                                : AppColors.riskModerate.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          settings.hasApiKey ? 'KEY ACTIVE' : 'OFFLINE MODE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: settings.hasApiKey
                                ? AppColors.riskLow
                                : AppColors.riskModerate,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zenith sends captured images to Gemini Multimodal Vision for deep neural OPSEC threat assessment. Enter your Google AI Studio key below.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Key text field
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateApiKey(val.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureKey
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscureKey = !_obscureKey),
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryCyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Test Connection Button
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isTestingKey ? null : _testApiKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryCyan.withOpacity(0.18),
                          foregroundColor: AppColors.primaryCyan,
                          elevation: 0,
                          side: const BorderSide(
                            color: AppColors.primaryCyan,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        icon: _isTestingKey
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryCyan,
                                ),
                              )
                            : const Icon(Icons.network_check_rounded,
                                size: 16),
                        label: Text(
                          _isTestingKey ? 'Verifying...' : 'Test Connection',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_keyTestResult != null)
                        Row(
                          children: [
                            Icon(
                              _keyTestResult!
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 16,
                              color: _keyTestResult!
                                  ? AppColors.riskLow
                                  : AppColors.riskCritical,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _keyTestResult! ? 'Connected' : 'Invalid Key',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _keyTestResult!
                                    ? AppColors.riskLow
                                    : AppColors.riskCritical,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Multimodal Model Selector
            _buildSectionHeader('AI MODEL SELECTION'),
            const SizedBox(height: 8),
            CyberGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRadioOption(
                    title: 'Gemini 2.5 Flash',
                    subtitle: 'Next-gen reasoning, fastest vision analysis (Recommended)',
                    value: 'gemini-2.5-flash',
                    groupValue: settings.model,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateModel(val!);
                    },
                  ),
                  const Divider(height: 20),
                  _buildRadioOption(
                    title: 'Gemini 1.5 Flash',
                    subtitle: 'High performance standard multimodal model',
                    value: 'gemini-1.5-flash',
                    groupValue: settings.model,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateModel(val!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Sensitivity Threshold
            _buildSectionHeader('OPSEC SENSITIVITY THRESHOLD'),
            const SizedBox(height: 8),
            CyberGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRadioOption(
                    title: AppConstants.sensitivityConservative,
                    subtitle: 'Flags clear PII, badges, credentials, and obvious addresses',
                    value: AppConstants.sensitivityConservative,
                    groupValue: settings.sensitivity,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateSensitivity(val!);
                    },
                  ),
                  const Divider(height: 20),
                  _buildRadioOption(
                    title: AppConstants.sensitivityBalanced,
                    subtitle: 'Standard OPSEC: Identifies credentials, locations, transit, and inferences',
                    value: AppConstants.sensitivityBalanced,
                    groupValue: settings.sensitivity,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateSensitivity(val!);
                    },
                  ),
                  const Divider(height: 20),
                  _buildRadioOption(
                    title: AppConstants.sensitivityParanoid,
                    subtitle: 'High vigilance: Flags reflections, background signs, and partial barcodes',
                    value: AppConstants.sensitivityParanoid,
                    groupValue: settings.sensitivity,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateSensitivity(val!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Onboard Simulator Fallback
            _buildSectionHeader('FALLBACK ENGINE'),
            const SizedBox(height: 8),
            CyberGlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Onboard Threat Simulation Fallback',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textWhite
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Allows testing and analysis without network latency or when API quota is exhausted.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.useMockFallback,
                    activeColor: AppColors.primaryCyan,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .toggleMockFallback(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. About Zenith & OPSEC Mission
            _buildSectionHeader('ABOUT ZENITH'),
            const SizedBox(height: 8),
            CyberGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_outlined,
                            size: 18, color: AppColors.primaryCyan),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Zenith OPSEC Assistant v${AppConstants.appVersion}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textWhite : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Zenith is engineered to stop accidental privacy leaks before photos reach public feeds. By combining computer vision with threat modeling, Zenith reveals both direct exposure and deep attacker deductions.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: AppColors.primaryCyan,
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.primaryCyan,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
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
