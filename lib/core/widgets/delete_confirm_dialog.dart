import 'package:flutter/material.dart';

/// حوار تأكيد حذف موحَّد (يستخدم في المفضلة والتنزيلات).
///
/// يُرجع `true` إذا أكّد المستخدم الحذف، أو `false` إذا ألغى.
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  String message = 'هل انت متاكد من الحذف؟',
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      return AlertDialog(
        content: Text(
          message,
          style: const TextStyle(height: 1.6),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('نعم'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('لا'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
