import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/models/certification_model.dart';
import '../providers/certification_provider.dart';
import 'package:easy_localization/easy_localization.dart';

/// 资质认证页面 - 对标网站 certification.html
class CertificationScreen extends ConsumerStatefulWidget {
  const CertificationScreen({super.key});

  @override
  ConsumerState<CertificationScreen> createState() =>
      _CertificationScreenState();
}

class _CertificationScreenState extends ConsumerState<CertificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(certificationProvider.notifier).loadCertifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(certificationProvider);
    final certs = state.certifications;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('certification.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading && certs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(certificationProvider.notifier).loadCertifications(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusBanner(state.hasApproved),
                    const SizedBox(height: 16),
                    ..._buildCertTypes(),
                    if (certs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildCertHistory(certs),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBanner(bool hasPassed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: hasPassed
            ? LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.15),
                  AppColors.cardBg,
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.15),
                  AppColors.cardBg,
                ],
              ),
        borderRadius: AppRadius.lgBorder,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (hasPassed ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPassed ? Icons.verified_rounded : Icons.shield_outlined,
              size: 28,
              color: hasPassed ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPassed
                      ? 'certification.completed'.tr()
                      : 'certification.not_completed'.tr(),
                  style: AppTextStyles.headingS,
                ),
                const SizedBox(height: 4),
                Text(
                  hasPassed
                      ? 'certification.completed_desc'.tr()
                      : 'certification.not_completed_desc'.tr(),
                  style: AppTextStyles.bodyS,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCertTypes() {
    final types = [
      {
        'icon': Icons.business_rounded,
        'title': 'certification.business_license'.tr(),
        'desc': 'certification.business_license_desc'.tr(),
        'color': AppColors.catBlue,
      },
      {
        'icon': Icons.verified_user_outlined,
        'title': 'certification.iso_cert'.tr(),
        'desc': 'certification.iso_cert_desc'.tr(),
        'color': AppColors.catGreen,
      },
      {
        'icon': Icons.factory_outlined,
        'title': 'certification.factory_audit'.tr(),
        'desc': 'certification.factory_audit_desc'.tr(),
        'color': AppColors.catOrange,
      },
      {
        'icon': Icons.description_outlined,
        'title': 'certification.industry_cert'.tr(),
        'desc': 'certification.industry_cert_desc'.tr(),
        'color': AppColors.catPurple,
      },
    ];

    return types
        .map(
          (t) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: AppRadius.lgBorder,
              boxShadow: AppShadows.cardSmall,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (t['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    t['icon'] as IconData,
                    size: 22,
                    color: t['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['title'] as String,
                        style: AppTextStyles.bodyL.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTitle,
                        ),
                      ),
                      Text(t['desc'] as String, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textPlaceholder,
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildCertHistory(List<CertificationModel> certs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('certification.cert_history'.tr(), style: AppTextStyles.headingS),
        const SizedBox(height: 10),
        ...certs.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.type,
                        style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTitle,
                        ),
                      ),
                      if (c.createdAt != null)
                        Text(
                          'certification.submitted_at'.tr(
                            args: ['${c.createdAt!.month}/${c.createdAt!.day}'],
                          ),
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    c.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
