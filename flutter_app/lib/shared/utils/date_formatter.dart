import 'package:intl/intl.dart';

class DateFormatter {
  static final _short = DateFormat('dd/MM/yyyy', 'pt');
  static final _full = DateFormat('dd/MM/yyyy HH:mm', 'pt');

  static String short(DateTime date) => _short.format(date);
  static String full(DateTime date) => _full.format(date);

  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inHours < 1) return 'Há ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Há ${diff.inHours}h';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
    return _short.format(date);
  }
}
