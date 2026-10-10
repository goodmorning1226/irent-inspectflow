import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/mobile_inspection_result.dart';
import '../../models/inspection_zone.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';
import 'submission_complete_page.dart';

enum _UploadStatus { waiting, uploading, completed }

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
  bool _isRunning = false;

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
        onPressed: _isComplete ? _continue : null,
        child: Text(_isComplete ? '繼續' : '正在上傳…'),
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
            '六區影像會依序整理完成；Prototype 資料只保留在本機，不會實際上傳。',
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
