import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../model/relationship_model.dart';
import '../resource/app_text.dart';

/// The friend button for another user. Which callback fires depends on the current status.
class RelationshipButton extends StatelessWidget {
  final RelationshipModel relationship;
  final bool isBusy;
  final bool compact;
  final VoidCallback onAdd;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onUnfriend;

  const RelationshipButton({
    super.key,
    required this.relationship,
    required this.onAdd,
    required this.onCancel,
    required this.onAccept,
    required this.onDecline,
    required this.onUnfriend,
    this.isBusy = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return SizedBox(
        width: 24.r,
        height: 24.r,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final textSize = compact ? 13.0 : 14.0;
    Widget filled(String text, IconData icon, VoidCallback onPressed) =>
        FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18.r),
          label: Text(
            text,
            style: AppText.medium(size: textSize, color: Colors.white),
          ),
        );
    Widget outlined(String text, IconData icon, VoidCallback onPressed) =>
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18.r),
          label: Text(text, style: AppText.medium(size: textSize)),
        );

    return switch (relationship.status) {
      RelationshipStatus.none => filled(
        'Kết bạn',
        Icons.person_add_alt_1,
        onAdd,
      ),
      RelationshipStatus.outgoing => outlined(
        'Đã gửi lời mời',
        Icons.schedule_send,
        onCancel,
      ),
      RelationshipStatus.friends => outlined(
        'Bạn bè',
        Icons.how_to_reg,
        onUnfriend,
      ),
      // In a list row there is only room for icons.
      RelationshipStatus.incoming when compact => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            icon: const Icon(Icons.check),
            tooltip: 'Chấp nhận',
            onPressed: onAccept,
          ),
          IconButton.outlined(
            icon: const Icon(Icons.close),
            tooltip: 'Từ chối',
            onPressed: onDecline,
          ),
        ],
      ),
      RelationshipStatus.incoming => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          filled('Chấp nhận', Icons.check, onAccept),
          SizedBox(width: 8.w),
          outlined('Từ chối', Icons.close, onDecline),
        ],
      ),
      RelationshipStatus.self => const SizedBox.shrink(),
    };
  }
}
