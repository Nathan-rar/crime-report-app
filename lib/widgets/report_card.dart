import 'package:flutter/material.dart';

import '../models/report_model.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    required this.report,
    required this.onTap,
    super.key,
  });

  final ReportModel report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (report.status) {
      ReportStatus.belum => Colors.red,
      ReportStatus.diproses => Colors.orange,
      ReportStatus.ditangani => Colors.green,
    };

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
                child: Image.network(
                  report.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFE5E7EB),
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(report.status.label),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: color),
                        labelStyle: TextStyle(color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _InfoChip(icon: Icons.category_outlined, label: report.category),
                      if (report.latitude != null && report.longitude != null)
                        _InfoChip(
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(label, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
