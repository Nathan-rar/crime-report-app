import 'package:flutter/material.dart';

import '../models/comment_model.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../widgets/comment_item.dart';
import 'report_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({required this.reportId, super.key});

  final String reportId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _reportService = ReportService();
  final _commentController = TextEditingController();
  bool _isSendingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
        content: const Text('Laporan, foto, dan komentar terkait akan dihapus.'),
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
            body: Center(child: Text('Gagal memuat laporan: ${snapshot.error}')),
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
            actions: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportScreen(initialReport: report),
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
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(report.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 16),
              Text(report.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(report.description),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    label: Text(report.category),
                  ),
                  if (report.latitude != null && report.longitude != null)
                    Chip(
                      avatar: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(
                        '${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReportStatus>(
                value: report.status,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Klasifikasi penanganan',
                  prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                ),
                items: ReportStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ))
                    .toList(),
                onChanged: (status) {
                  if (status != null && status != report.status) {
                    _updateStatus(report, status);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text('Komentar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
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
                        border: OutlineInputBorder(),
                        hintText: 'Tulis komentar',
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
          return Text('Gagal memuat komentar: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return const Text('Belum ada komentar.');
        }

        return Column(
          children: comments.map((comment) => CommentItem(comment: comment)).toList(),
        );
      },
    );
  }
}
