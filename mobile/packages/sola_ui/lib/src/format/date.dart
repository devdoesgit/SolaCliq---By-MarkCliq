const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a date for display: `18 Oct 2026`.
///
/// The API sends UTC; the value is shown in the device's local time.
String formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// Formats a date and time for display: `18 Oct 2026, 14:05` (24-hour).
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${formatDate(local)}, $hh:$mm';
}

/// Formats a calendar day without the year: `23 Oct`.
String formatDayMonth(DateTime value) =>
    '${value.day} ${_months[value.month - 1]}';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// The short day name: `Mon`.
String formatWeekday(DateTime value) => _weekdays[value.weekday - 1];
