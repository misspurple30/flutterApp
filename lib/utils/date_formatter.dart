import 'package:intl/intl.dart';

class DateFormatter {
  /// Heure courte : "14:32"
  static String time(DateTime date) => DateFormat.Hm('fr_FR').format(date);

  /// Pour la liste de conversations : "14:32" aujourd'hui, "Hier",
  /// "lun.", ou "12/03/2024" plus ancien.
  static String listPreview(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;

    if (diff == 0) return DateFormat.Hm('fr_FR').format(date);
    if (diff == 1) return 'Hier';
    if (diff < 7) return DateFormat.E('fr_FR').format(date);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Séparateur de jour au sein d'un chat.
  static String daySeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;

    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
  }

  /// "Vu il y a 5 min", "Vu hier à 14h", etc.
  static String lastSeen(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "il y a ${diff.inHours} h";
    if (diff.inDays == 1) return "hier";
    if (diff.inDays < 7) return "il y a ${diff.inDays} j";
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
