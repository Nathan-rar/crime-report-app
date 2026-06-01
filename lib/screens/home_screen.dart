import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
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
    _messageSubscription = _notificationService.foregroundMessages.listen(
      (message) {
        final title = message.notification?.title ?? 'Update laporan';
        final body = message.notification?.body ?? 'Ada perubahan klasifikasi.';
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title - $body')),
        );
      },
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kriminal'),
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
            return Center(child: Text('Gagal memuat laporan: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada laporan. Buat laporan pertama dari tombol tambah.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final report = reports[index];
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportScreen()),
          );
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Lapor'),
      ),
    );
  }
}
