import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../theme/app_theme.dart';
import 'custom_button.dart';
import 'stored_image.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({required this.report, required this.onTap, super.key});

  final ReportModel report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: StoredImage(
                  imageRef: report.imageUrl!,
                  placeholderIcon: Icons.broken_image_outlined,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.deepBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.report_problem_outlined,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              report.reporterEmail,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        label: report.status.label,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
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
