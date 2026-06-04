import 'package:flutter/material.dart';

import '../models/comment_model.dart';
import '../theme/app_theme.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({required this.comment, super.key});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.silver),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.deepBlue,
            child: Icon(Icons.person_outline, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(comment.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
