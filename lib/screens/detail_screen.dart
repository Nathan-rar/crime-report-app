import 'package:flutter/material.dart';

import '../models/comment_model.dart';
import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/comment_item.dart';
import '../widgets/custom_button.dart';
import '../widgets/stored_image.dart';
import 'report_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({required this.reportId, super.key});

  final String reportId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _reportService = ReportService();
  final _authService = AuthService();
  final _commentController = TextEditingController();
  bool _isSendingComment = false;
  bool _isCheckingAdmin = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdminAccess();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminAccess() async {
    try {
      final isAdmin = await _authService.isCurrentUserAdmin();
      if (!mounted) {
        return;
      }
      setState(() {
        _isAdmin = isAdmin;
        _isCheckingAdmin = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
  }

  Future<void> _updateStatus(ReportModel report, ReportStatus status) async {
    try {
      await _reportService.updateStatus(report: report, status: status);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diperbarui ke ${status.label}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $error')),
      );
    }
  }

  Future<void> _deleteReport(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: const Text(
          'Laporan, foto, dan komentar terkait akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _reportService.deleteReport(report);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus laporan: $error')),
      );
    }
  }

  Future<void> _sendComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) {
      return;
    }

    setState(() => _isSendingComment = true);
    try {
      await _reportService.addComment(
        reportId: widget.reportId,
        message: message,
      );
      _commentController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim komentar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReportModel>(
      stream: _reportService.streamReport(widget.reportId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Laporan')),
            body: AppStateMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Gagal memuat laporan',
              message: snapshot.error.toString(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Laporan')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final report = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Laporan'),
            actions: _isAdmin
                ? [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportScreen(
                              initialReport: report,
                              adminMode: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: () => _deleteReport(report),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ]
                : null,
          ),
          body: AppPage(
            maxWidth: 820,
            child: ListView(
              children: [
                if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: StoredImage(imageRef: report.imageUrl!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AppPanel(
                  icon: Icons.report_problem_outlined,
                  title: report.title,
                  subtitle: report.reporterEmail,
                  trailing: StatusPill(
                    label: report.status.label,
                    color: _statusColor(report.status),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.description),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InlineInfo(
                            icon: Icons.category_outlined,
                            label: report.category,
                          ),
                          if (report.latitude != null &&
                              report.longitude != null)
                            InlineInfo(
                              icon: Icons.location_on_outlined,
                              label:
                                  '${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isCheckingAdmin) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ] else if (_isAdmin) ...[
                  const SizedBox(height: 12),
                  AppPanel(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Klasifikasi Penanganan',
                    subtitle:
                        'Perubahan status akan dicatat untuk notifikasi update kasus.',
                    child: DropdownButtonFormField<ReportStatus>(
                      initialValue: report.status,
                      decoration: const InputDecoration(
                        labelText: 'Status kasus',
                        prefixIcon: Icon(Icons.sync_alt_outlined),
                      ),
                      items: ReportStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      onChanged: (status) {
                        if (status != null && status != report.status) {
                          _updateStatus(report, status);
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppPanel(
                  icon: Icons.forum_outlined,
                  title: 'Komentar',
                  subtitle: 'Catatan tindak lanjut atau klarifikasi laporan.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CommentList(
                        reportId: widget.reportId,
                        reportService: _reportService,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              minLines: 1,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Tulis komentar',
                                prefixIcon: Icon(Icons.chat_bubble_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Kirim komentar',
                            onPressed: _isSendingComment ? null : _sendComment,
                            icon: _isSendingComment
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(ReportStatus status) {
    return switch (status) {
      ReportStatus.belum => AppColors.danger,
      ReportStatus.diproses => AppColors.warning,
      ReportStatus.ditangani => AppColors.success,
    };
  }
}

class _CommentList extends StatelessWidget {
  const _CommentList({required this.reportId, required this.reportService});

  final String reportId;
  final ReportService reportService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommentModel>>(
      stream: reportService.streamComments(reportId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppStateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Gagal memuat komentar',
            message: snapshot.error.toString(),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return const AppStateMessage(
            icon: Icons.chat_bubble_outline,
            title: 'Belum ada komentar',
          );
        }

        return Column(
          children: comments
              .map((comment) => CommentItem(comment: comment))
              .toList(),
        );
      },
    );
  }
}
