import 'package:flutter/material.dart';

import '../../models/finding.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class DamageDetailFlow extends StatefulWidget {
  const DamageDetailFlow({
    required this.finding,
    required this.onBackToWide,
    required this.onComplete,
    super.key,
  });

  final Finding finding;
  final VoidCallback onBackToWide;
  final VoidCallback onComplete;

  @override
  State<DamageDetailFlow> createState() => _DamageDetailFlowState();
}

class _DamageDetailFlowState extends State<DamageDetailFlow> {
  static const _views = <_DetailView>[
    _DetailView(
      label: '中央視角',
      instruction: '將疑似刮痕置於中央框內',
      asset: 'assets/frames/exterior_damage_detail_center.png',
    ),
    _DetailView(
      label: '左側視角',
      instruction: '向左移動一小步並保持距離',
      asset: 'assets/frames/exterior_damage_detail_left.png',
    ),
    _DetailView(
      label: '右側視角',
      instruction: '移至右側，讓反光角度改變',
      asset: 'assets/frames/exterior_damage_detail_right.png',
    ),
  ];

  int _step = 0;

  bool get _isResult => _step >= _views.length;

  void _captureCurrentView() {
    setState(() => _step += 1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: _isResult ? _buildResult(context) : _buildCapture(context),
    );
  }

  Widget _buildCapture(BuildContext context) {
    final view = _views[_step];
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: _DetailProgress(currentStep: _step, views: _views),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(view.asset, fit: BoxFit.cover),
                Center(
                  child: Container(
                    width: 250,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.warningOrange,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        view.instruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 190,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.scanSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.center_focus_strong_rounded,
                    color: AppColors.warningOrange,
                    size: 52,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    view.label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_step + 1} / ${_views.length}',
                    style: const TextStyle(color: Color(0xFFB7BCC2)),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _captureCurrentView,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warningOrange,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('擷取此角度'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: widget.onBackToWide,
                    child: const Text('返回廣角影像'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.scanSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.successGreen,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        '補充影像已完成',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: Row(
                      children: [
                        for (final view in _views)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        view.asset,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    view.label,
                                    style: const TextStyle(
                                      color: Color(0xFFD6D9DC),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '已取得補充證據',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '系統已保存廣角與三個近距離視角，後續將與歷史車況進行比對。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ResultFact(label: '區域', value: widget.finding.location),
                  const SizedBox(height: AppSpacing.xs),
                  const _ResultFact(label: '影像', value: '廣角 1 張、近距離 3 張'),
                  const Spacer(),
                  const Text(
                    '此結果僅代表已取得疑似異常影像，不代表責任或賠償判定。',
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: widget.onComplete,
                    child: const Text('完成左側檢查'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailProgress extends StatelessWidget {
  const _DetailProgress({required this.currentStep, required this.views});

  final int currentStep;
  final List<_DetailView> views;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.scanSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '近距離補掃',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            for (var index = 0; index < views.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      index < currentStep
                          ? Icons.check_circle_rounded
                          : index == currentStep
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: index <= currentStep
                          ? AppColors.warningOrange
                          : const Color(0xFF747A80),
                      size: 19,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        views[index].label,
                        style: TextStyle(
                          color: index == currentStep
                              ? AppColors.white
                              : const Color(0xFFB7BCC2),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ResultFact extends StatelessWidget {
  const _ResultFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.mutedInk, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailView {
  const _DetailView({
    required this.label,
    required this.instruction,
    required this.asset,
  });

  final String label;
  final String instruction;
  final String asset;
}
