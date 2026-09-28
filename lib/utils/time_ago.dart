/// "vừa xong", "5 phút", "3 giờ", "2 ngày", then a date.
String timeAgo(int millis) {
  final time = DateTime.fromMillisecondsSinceEpoch(millis);
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút';
  if (diff.inDays < 1) return '${diff.inHours} giờ';
  if (diff.inDays < 7) return '${diff.inDays} ngày';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(time.day)}/${two(time.month)}/${time.year}';
}
