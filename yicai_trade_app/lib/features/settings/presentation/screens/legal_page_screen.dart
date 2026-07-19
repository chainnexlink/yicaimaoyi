import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';

/// Legal text page - About / Privacy / Terms / Service
class LegalPageScreen extends StatelessWidget {
  final String title;
  final String type; // 'about', 'privacy', 'terms', 'service'

  const LegalPageScreen({super.key, required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(title, style: AppTextStyles.headingM),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: AppRadius.lgBorder,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildContent(),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    return switch (type) {
      'about' => _aboutContent(),
      'privacy' => _privacyContent(),
      'terms' => _termsContent(),
      'service' => _serviceContent(),
      _ => [Text('common.loading'.tr())],
    };
  }

  List<Widget> _aboutContent() {
    return [
      _heading('legal.about'.tr()),
      _body('legal.about_p1'.tr()),
      const SizedBox(height: 16),
      _heading('legal.about_mission_title'.tr()),
      _body('legal.about_mission_content'.tr()),
      const SizedBox(height: 16),
      _heading('legal.about_features_title'.tr()),
      _bullet('legal.about_feature_1'.tr()),
      _bullet('legal.about_feature_2'.tr()),
      _bullet('legal.about_feature_3'.tr()),
      _bullet('legal.about_feature_4'.tr()),
      _bullet('legal.about_feature_5'.tr()),
      const SizedBox(height: 16),
      _heading('legal.about_contact_title'.tr()),
      _body('legal.about_contact_email'.tr()),
      _body('legal.about_contact_phone'.tr()),
      _body('legal.about_contact_hours'.tr()),
    ];
  }

  List<Widget> _privacyContent() {
    return [
      _heading('legal.privacy'.tr()),
      _body('legal.privacy_update_date'.tr()),
      const SizedBox(height: 12),
      _body('legal.privacy_intro'.tr()),
      const SizedBox(height: 16),
      _heading('legal.privacy_collect_title'.tr()),
      _body('legal.privacy_collect_intro'.tr()),
      _bullet('legal.privacy_collect_1'.tr()),
      _bullet('legal.privacy_collect_2'.tr()),
      _bullet('legal.privacy_collect_3'.tr()),
      _bullet('legal.privacy_collect_4'.tr()),
      const SizedBox(height: 16),
      _heading('legal.privacy_usage_title'.tr()),
      _body('legal.privacy_usage_intro'.tr()),
      _bullet('legal.privacy_usage_1'.tr()),
      _bullet('legal.privacy_usage_2'.tr()),
      _bullet('legal.privacy_usage_3'.tr()),
      _bullet('legal.privacy_usage_4'.tr()),
      _bullet('legal.privacy_usage_5'.tr()),
      const SizedBox(height: 16),
      _heading('legal.privacy_protect_title'.tr()),
      _body('legal.privacy_protect_content'.tr()),
      const SizedBox(height: 16),
      _heading('legal.privacy_share_title'.tr()),
      _body('legal.privacy_share_intro'.tr()),
      _bullet('legal.privacy_share_1'.tr()),
      _bullet('legal.privacy_share_2'.tr()),
      _bullet('legal.privacy_share_3'.tr()),
    ];
  }

  List<Widget> _termsContent() {
    return [
      _heading('legal.terms'.tr()),
      _body('legal.terms_update_date'.tr()),
      const SizedBox(height: 12),
      _body('legal.terms_intro'.tr()),
      const SizedBox(height: 16),
      _heading('legal.terms_service_title'.tr()),
      _body('legal.terms_service_content'.tr()),
      const SizedBox(height: 16),
      _heading('legal.terms_register_title'.tr()),
      _body('legal.terms_register_content'.tr()),
      const SizedBox(height: 16),
      _heading('legal.terms_trade_title'.tr()),
      _bullet('legal.terms_trade_1'.tr()),
      _bullet('legal.terms_trade_2'.tr()),
      _bullet('legal.terms_trade_3'.tr()),
      _bullet('legal.terms_trade_4'.tr()),
      const SizedBox(height: 16),
      _heading('legal.terms_ip_title'.tr()),
      _body('legal.terms_ip_content'.tr()),
      const SizedBox(height: 16),
      _heading('legal.terms_disclaimer_title'.tr()),
      _body('legal.terms_disclaimer_content'.tr()),
    ];
  }

  List<Widget> _serviceContent() {
    return [
      _heading('legal.service_agreement'.tr()),
      _body('legal.service_update_date'.tr()),
      const SizedBox(height: 12),
      _body('legal.service_intro'.tr()),
      const SizedBox(height: 16),
      _heading('legal.service_content_title'.tr()),
      _bullet('legal.service_content_1'.tr()),
      _bullet('legal.service_content_2'.tr()),
      _bullet('legal.service_content_3'.tr()),
      _bullet('legal.service_content_4'.tr()),
      _bullet('legal.service_content_5'.tr()),
      _bullet('legal.service_content_6'.tr()),
      const SizedBox(height: 16),
      _heading('legal.service_fee_title'.tr()),
      _body('legal.service_fee_content'.tr()),
      const SizedBox(height: 16),
      _heading('legal.service_change_title'.tr()),
      _body('legal.service_change_content'.tr()),
    ];
  }

  static Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.headingS.copyWith(color: AppColors.textTitle),
      ),
    );
  }

  static Widget _body(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.bodyM.copyWith(
          color: AppColors.textBody,
          height: 1.7,
        ),
      ),
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.circle, size: 5, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textBody,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
