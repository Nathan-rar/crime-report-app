import 'package:flutter/material.dart';

import '../models/comment_model.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({required this.comment, super.key});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(comment.userEmail),
      subtitle: Text(comment.message),
      dense: true,
    );
  }
}
