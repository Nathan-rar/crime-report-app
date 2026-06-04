import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/report_card.dart';
import 'detail_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _reportService = ReportService();
  final _notificationService = NotificationService();
  StreamSubscription<RemoteMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    await _notificationService.initializeForUser(user.uid);
    _messageSubscription = _notificationService.foregroundMessages.listen((
      message,
    ) {
      final title = message.notification?.title ?? 'Update laporan';
      final body = message.notification?.body ?? 'Ada perubahan klasifikasi.';
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title - $body')));
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
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
        stream: _reportService.streamReports(),
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
              icon: Icons.assignment_outlined,
              title: 'Belum ada laporan',
              message: 'Buat laporan pertama dari tombol Lapor.',
              action: AppButton(
                label: 'Buat Laporan',
                icon: Icons.add_location_alt_outlined,
                fullWidth: false,
                onPressed: _openCreateReport,
              ),
            );
          }

          return AppPage(
            maxWidth: 920,
            child: ListView.separated(
              itemCount: reports.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _DashboardHeader(reports: reports);
                }

                final report = reports[index - 1];
                return ReportCard(
                  report: report,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(reportId: report.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateReport,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Lapor'),
      ),
    );
  }

  void _openCreateReport() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReportScreen()));
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.reports});

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
      icon: Icons.dashboard_outlined,
      title: 'Ringkasan Laporan',
      subtitle: 'Pantau jumlah kasus berdasarkan klasifikasi penanganan.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatTile(
            label: 'Total',
            value: reports.length,
            color: AppColors.deepBlue,
          ),
          _StatTile(label: 'Belum', value: belum, color: AppColors.danger),
          _StatTile(
            label: 'Diproses',
            value: diproses,
            color: AppColors.warning,
          ),
          _StatTile(
            label: 'Ditangani',
            value: ditangani,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
