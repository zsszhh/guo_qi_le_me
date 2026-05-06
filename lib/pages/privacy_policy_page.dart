import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 隐私政策页面
///
/// 展示应用的隐私政策内容，采用本地优先存储策略，
/// 涵盖信息收集、存储、第三方服务、用户权利等条款。
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '隐私政策',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 引言
            _buildParagraph(
              '欢迎使用"过期了么"。我们深知个人信息对您的重要性，因此我们将尽全力保护您的个人信息安全。'
              '本隐私政策适用于"过期了么"应用（以下简称"本应用"）提供的所有服务。'
              '请您在使用本应用前仔细阅读本政策。',
            ),

            const SizedBox(height: AppSpacing.lg),

            // 一、信息收集与使用
            _buildSectionTitle('一、信息收集与使用'),
            _buildParagraph(
              '本应用遵循最小化信息收集原则，仅收集为您提供服务所必需的信息。',
            ),
            _buildSubTitle('1.1 您主动提供的信息'),
            _buildBulletPoint('物品名称、保质期、存放位置等物品信息'),
            _buildBulletPoint('提醒配置与时间设置'),
            _buildBulletPoint('AI 服务配置（API 密钥等）'),
            _buildBulletPoint('WebDAV 同步配置（服务器地址、凭据等）'),
            _buildSubTitle('1.2 自动收集的信息'),
            _buildBulletPoint('应用使用日志（仅用于故障排查）'),
            _buildBulletPoint('设备型号与操作系统版本（仅用于兼容性适配）'),
            _buildSubTitle('1.3 我们不会收集的信息'),
            _buildBulletPoint('您的姓名、电话号码等个人身份信息'),
            _buildBulletPoint('您的地理位置信息'),
            _buildBulletPoint('您的通讯录数据'),
            _buildBulletPoint('任何与本应用功能无关的信息'),

            const SizedBox(height: AppSpacing.lg),

            // 二、信息存储
            _buildSectionTitle('二、信息存储'),
            _buildSubTitle('2.1 本地存储优先'),
            _buildParagraph(
              '本应用采用"本地优先"的存储策略。您所有的物品数据、提醒配置等核心信息均存储在您的设备本地数据库中，'
              '不会上传至我们的任何服务器。',
            ),
            _buildSubTitle('2.2 存储位置'),
            _buildBulletPoint('物品数据、分类信息、提醒记录等存储在应用本地 SQLite 数据库'),
            _buildBulletPoint('AI 配置与 WebDAV 配置存储在应用安全存储区域'),
            _buildBulletPoint('应用设置存储在设备本地'),
            _buildSubTitle('2.3 数据保留'),
            _buildParagraph(
              '您的数据将一直保留在您的设备上，直到您主动删除或卸载应用。'
              '我们不会远程删除或修改您的任何数据。',
            ),

            const SizedBox(height: AppSpacing.lg),

            // 三、第三方服务
            _buildSectionTitle('三、第三方服务'),
            _buildParagraph(
              '本应用可能涉及以下第三方服务，使用这些服务时您的数据将受到相应第三方的隐私政策约束：',
            ),
            _buildSubTitle('3.1 AI 识别服务'),
            _buildParagraph(
              '当您启用 AI 智能识别功能时，您主动提交的文字或图片描述将通过您配置的 API 接口'
              '发送至您选择的大语言模型服务提供商（如 OpenAI、Anthropic 等）进行处理。'
              '请注意以下事项：',
            ),
            _buildBulletPoint('AI 识别请求由您主动发起，不会在后台自动发送'),
            _buildBulletPoint('发送的数据仅包含您主动输入的文字描述，不包含个人身份信息'),
            _buildBulletPoint('API 密钥存储在您的设备本地，不会传输至我们的服务器'),
            _buildBulletPoint('具体的数据处理方式请参阅相应 AI 服务提供商的隐私政策'),
            _buildSubTitle('3.2 WebDAV 同步服务'),
            _buildParagraph(
              '当您启用 WebDAV 同步功能时，您的数据将通过 WebDAV 协议同步至您自行配置的服务器。请注意以下事项：',
            ),
            _buildBulletPoint('WebDAV 服务器由您自行选择和管理，我们不控制该服务器'),
            _buildBulletPoint('同步的数据包括物品信息、分类数据等应用核心数据'),
            _buildBulletPoint('WebDAV 凭据（用户名、密码）存储在您的设备本地'),
            _buildBulletPoint('数据传输采用 HTTPS 加密（需您的服务器支持）'),
            _buildBulletPoint('我们无法访问您的 WebDAV 服务器中的数据'),

            const SizedBox(height: AppSpacing.lg),

            // 四、信息共享
            _buildSectionTitle('四、信息共享'),
            _buildParagraph(
              '我们不会与任何第三方共享您的个人信息，但以下情况除外：',
            ),
            _buildBulletPoint('获得您的明确同意后'),
            _buildBulletPoint('根据法律法规的要求或行政、司法机关的要求'),
            _buildBulletPoint('为保护本应用、其他用户或公众的权利、财产或安全'),
            _buildParagraph(
              '本应用不会将您的个人信息用于商业目的出售、出租或交换。',
            ),

            const SizedBox(height: AppSpacing.lg),

            // 五、信息安全
            _buildSectionTitle('五、信息安全'),
            _buildParagraph(
              '我们采取以下措施保护您的数据安全：',
            ),
            _buildBulletPoint('应用数据存储在设备本地加密数据库中'),
            _buildBulletPoint('敏感配置（API 密钥、WebDAV 凭据）使用安全存储机制'),
            _buildBulletPoint('支持本地备份与恢复功能，方便您自行管理数据'),
            _buildBulletPoint('应用不收集或传输不必要的数据'),
            _buildParagraph(
              '尽管我们采取了合理的安全措施，但请您理解在互联网环境下不存在绝对的安全。'
              '我们会尽最大努力保护您的数据安全。',
            ),

            const SizedBox(height: AppSpacing.lg),

            // 六、用户权利
            _buildSectionTitle('六、用户权利'),
            _buildParagraph('您对自己的数据享有以下权利：'),
            _buildBulletPoint('访问权：您可以随时查看应用中存储的所有数据'),
            _buildBulletPoint('修改权：您可以随时修改物品信息和应用设置'),
            _buildBulletPoint('删除权：您可以随时删除任何物品记录或清空全部数据'),
            _buildBulletPoint('导出权：您可以通过备份功能导出自己的数据'),
            _buildBulletPoint('撤回同意权：您可以随时关闭 AI 识别或 WebDAV 同步功能'),
            _buildParagraph(
              '由于本应用采用纯本地存储架构，您对数据拥有完全的控制权。'
              '卸载应用将删除设备上的所有应用数据。',
            ),

            const SizedBox(height: AppSpacing.lg),

            // 七、未成年人保护
            _buildSectionTitle('七、未成年人保护'),
            _buildParagraph(
              '我们非常重视未成年人个人信息的保护。本应用不会主动收集 14 周岁以下未成年人的个人信息。'
              '如果您是 14 周岁以下的未成年人，请在监护人的指导下使用本应用。',
            ),

            const SizedBox(height: AppSpacing.lg),

            // 八、政策更新
            _buildSectionTitle('八、政策更新'),
            _buildParagraph(
              '我们可能会适时更新本隐私政策。更新后的政策将在本应用内发布，'
              '并在发布时注明生效日期。建议您定期查看本页面以获取最新信息。'
              '继续使用本应用即表示您同意受更新后的隐私政策约束。',
            ),

            const SizedBox(height: AppSpacing.lg),

            // 九、联系我们
            _buildSectionTitle('九、联系我们'),
            _buildParagraph(
              '如果您对本隐私政策有任何疑问、意见或建议，请通过以下方式与我们联系：',
            ),
            _buildBulletPoint('应用内反馈：设置 > 帮助与反馈'),
            _buildParagraph(
              '我们将在收到您的反馈后尽快回复。',
            ),

            const SizedBox(height: AppSpacing.xl),

            // 分隔线
            Divider(
              color: AppColors.outlineVariant.withValues(alpha:0.3),
              height: 1,
            ),

            const SizedBox(height: AppSpacing.lg),

            // 底部版权信息
            Center(
              child: Column(
                children: [
                  Text(
                    '本隐私政策最后更新日期：2026年5月6日',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '© 2026 过期了么. All rights reserved.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleLg.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 构建子标题
  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.bodyBase.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 构建正文段落
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.bodyBase.copyWith(
          color: AppColors.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    );
  }

  /// 构建列表项
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
