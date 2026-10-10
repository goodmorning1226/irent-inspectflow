import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/mobile_inspection_result.dart';
import '../../models/inspection_zone.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';
import 'submission_complete_page.dart';

enum _UploadStatus { waiting, uploading, failed, completed }

class InspectionUploadPage extends StatefulWidget {
  const InspectionUploadPage({
    required this.result,
    required this.onReset,
    super.key,
  });

  final MobileInspectionResult result;
  final VoidCallback onReset;

  @override
  State<InspectionUploadPage> createState() => _InspectionUploadPageState();
}

class _InspectionUploadPageState extends State<InspectionUploadPage> {
  late final List<_UploadStatus> _statuses;
  bool _hasSimulatedFailure = false;
  bool _isRunning = false;

  bool get _hasFailure => _statuses.contains(_UploadStatus.failed);
  bool get _isComplete =>
      _statuses.every((status) => status == _UploadStatus.completed);

  @override
  void initState() {
    super.initState();
    _statuses = List.filled(widget.result.zones.length, _UploadStatus.waiting);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_runUpload()),
    );
  }

  Future<void> _runUpload() async {
    if (_isRunning) return;
    _isRunning = true;
    for (var index = 0; index < _statuses.length; index++) {
      if (_statuses[index] == _UploadStatus.completed) continue;
      if (!mounted) return;
      setState(() => _statuses[index] = _UploadStatus.uploading);
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      if (!_hasSimulatedFailure && index == 1) {
        setState(() {
          _statuses[index] = _UploadStatus.failed;
          _hasSimulatedFailure = true;
          _isRunning = false;
        });
        return;
      }
      setState(() => _statuses[index] = _UploadStatus.completed);
    }
    _isRunning = false;
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubmissionCompletePage(
          result: widget.result,
          onReset: widget.onReset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completeCount = _statuses
        .where((status) => status == _UploadStatus.completed)
        .length;
    return IrentFlowScaffold(
      title: '上傳車況紀錄',
      showBackButton: true,
      bottom: FilledButton(
        onPressed: _hasFailure
            ? () => unawaited(_runUpload())
            : _isComplete
            ? _continue
            : null,
        child: Text(
          _hasFailure
              ? '重試未完成項目'
              : _isComplete
              ? '繼續'
              : '正在上傳…',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isComplete ? '所有影像已準備完成' : '正在整理六區影像',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                '$completeCount / ${_statuses.length}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _isComplete
                      ? AppColors.successGreen
                      : AppColors.brandRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: completeCount / _statuses.length,
            minHeight: 7,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: AppColors.divider,
            color: _isComplete ? AppColors.successGreen : AppColors.brandRed,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Prototype 會固定模擬一次連線中斷，點選重試即可繼續。資料只保留在本機。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var index = 0; index < widget.result.zones.length; index++)
                  _UploadRow(
                    label: widget.result.zones[index].type.label,
                    status: _statuses[index],
                    showDivider: index != widget.result.zones.length - 1,
                  ),
              ],
            ),
          ),
          if (_hasFailure) ...[
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F4),
                border: Border.all(color: const Color(0xFFF0B6B6)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: AppColors.brandRed),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('左側影像尚未完成，已完成的項目不會重複上傳。')),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  const _UploadRow({
    required this.label,
    required this.status,
    required this.showDivider,
  });

  final String label;
  final _UploadStatus status;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (status) {
      _UploadStatus.waiting => (
        Icons.schedule_rounded,
        AppColors.mutedInk,
        '等待中',
      ),
      _UploadStatus.uploading => (
        Icons.sync_rounded,
        AppColors.brandRed,
        '上傳中',
      ),
      _UploadStatus.failed => (
        Icons.error_outline_rounded,
        AppColors.brandRed,
        '需要重試',
      ),
      _UploadStatus.completed => (
        Icons.check_circle_rounded,
        AppColors.successGreen,
        '已完成',
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
