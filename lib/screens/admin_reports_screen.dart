import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import 'detail_screen.dart';
import 'report_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({this.reportsStream, super.key});

  final Stream<List<ReportModel>>? reportsStream;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  AuthService? _authService;
  ReportService? _reportService;

  AuthService get _auth => _authService ??= AuthService();

  ReportService get _reports => _reportService ??= ReportService();

  Future<void> _signOut() async {
    await _auth.signOut();
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
      await _reports.deleteReport(report);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laporan dihapus.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus laporan: $error')),
      );
    }
  }

  Future<void> _updateStatus(ReportModel report, ReportStatus status) async {
    try {
      await _reports.updateStatus(report: report, status: status);
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

  void _openCreateReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportScreen(adminMode: true),
      ),
    );
  }

  void _openEditReport(ReportModel report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportScreen(initialReport: report, adminMode: true),
      ),
    );
  }

  void _openDetailReport(ReportModel report) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(reportId: report.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(
          size: 34,
          showLabel: true,
          labelColor: Colors.white,
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: widget.reportsStream ?? _reports.streamReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppStateMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Gagal memuat laporan',
              message: snapshot.error.toString(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return AppStateMessage(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Belum ada laporan',
              message: 'Admin dapat membuat laporan manual dari tombol tambah.',
              action: AppButton(
                label: 'Buat Laporan',
                icon: Icons.add_location_alt_outlined,
                fullWidth: false,
                onPressed: _openCreateReport,
              ),
            );
          }

          return AppPage(
            maxWidth: 1120,
            child: ListView.separated(
              itemCount: reports.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AdminDashboardHeader(reports: reports);
                }

                final report = reports[index - 1];
                return _AdminReportTile(
                  report: report,
                  onTap: () => _openDetailReport(report),
                  onEdit: () => _openEditReport(report),
                  onDelete: () => _deleteReport(report),
                  onStatusChanged: (status) => _updateStatus(report, status),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateReport,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Buat Laporan'),
      ),
    );
  }
}

class _AdminDashboardHeader extends StatelessWidget {
  const _AdminDashboardHeader({required this.reports});

  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context) {
    final belum = reports
        .where((report) => report.status == ReportStatus.belum)
        .length;
    final diproses = reports
        .where((report) => report.status == ReportStatus.diproses)
        .length;
    final ditangani = reports
        .where((report) => report.status == ReportStatus.ditangani)
        .length;

    return AppPanel(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Admin Laporan',
      subtitle: 'Kelola seluruh laporan, status, komentar, dan data kejadian.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _AdminStatTile(
            label: 'Total',
            value: reports.length,
            color: AppColors.deepBlue,
          ),
          _AdminStatTile(label: 'Belum', value: belum, color: AppColors.danger),
          _AdminStatTile(
            label: 'Diproses',
            value: diproses,
            color: AppColors.warning,
          ),
          _AdminStatTile(
            label: 'Ditangani',
            value: ditangani,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _AdminStatTile extends StatelessWidget {
  const _AdminStatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AdminReportTile extends StatelessWidget {
  const _AdminReportTile({
    required this.report,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final ReportModel report;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<ReportStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final details = _ReportDetails(report: report);
              final controls = _ReportControls(
                report: report,
                statusColor: statusColor,
                onEdit: onEdit,
                onDelete: onDelete,
                onStatusChanged: onStatusChanged,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    details,
                    const SizedBox(height: 12),
                    controls,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  SizedBox(width: 280, child: controls),
                ],
              );
            },
          ),
        ),
      ),
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

class _ReportDetails extends StatelessWidget {
  const _ReportDetails({required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.deepBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.report_problem_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                report.reporterEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InlineInfo(
                    icon: Icons.category_outlined,
                    label: report.category,
                  ),
                  if (report.latitude != null && report.longitude != null)
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
      ],
    );
  }
}

class _ReportControls extends StatelessWidget {
  const _ReportControls({
    required this.report,
    required this.statusColor,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final ReportModel report;
  final Color statusColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<ReportStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusPill(label: report.status.label, color: statusColor),
        const SizedBox(height: 10),
        DropdownButtonFormField<ReportStatus>(
          initialValue: report.status,
          decoration: const InputDecoration(
            labelText: 'Status',
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
              onStatusChanged(status);
            }
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
