import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatRelativeTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  if (diff.inDays < 30) return '${diff.inDays} ngày trước';
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}

Color scoreColor(int score) {
  if (score >= 75) return const Color(0xFF059669);
  if (score >= 45) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

String scoreLabel(int score) {
  if (score >= 75) return 'Tốt';
  if (score >= 45) return 'Cần cải thiện';
  return 'Ưu tiên cải thiện';
}
