/// India's 15-character GST number, checked as the server checks it
/// (`backend/src/gstin.rs`), so a typo is caught before anything is sent.
///
/// Layout: 2-digit state code, the 10-character PAN, an entity number,
/// a fixed `Z`, and a check character computed from the first 14.
class Gstin {
  const new _(this.number, this.state);

  /// Uppercase, no spaces.
  final String number;

  /// The state or union territory its first two digits stand for.
  final String state;

  /// The business's PAN: characters 3 to 12.
  String get pan => number.substring(2, 12);

  static const _charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static final _shape = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
  );

  /// The GSTIN in [raw] (spaces and lowercase allowed), or null when it
  /// isn't valid.
  static Gstin? tryParse(String raw) {
    final number = raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!_shape.hasMatch(number)) return null;
    if (_checkChar(number.substring(0, 14)) != number[14]) return null;
    final state = _states[number.substring(0, 2)];
    return state == null ? null : Gstin._(number, state);
  }

  /// Values at odd places are doubled; each product adds its 36s and its
  /// remainder; the check character brings the sum to a multiple of 36.
  static String _checkChar(String first14) {
    var sum = 0;
    for (var i = 0; i < first14.length; i++) {
      final product = _charset.indexOf(first14[i]) * (i.isEven ? 1 : 2);
      sum += product ~/ 36 + product % 36;
    }
    return _charset[(36 - sum % 36) % 36];
  }

  static const _states = {
    '01': 'Jammu and Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '25': 'Dadra and Nagar Haveli and Daman and Diu',
    '26': 'Dadra and Nagar Haveli and Daman and Diu',
    '27': 'Maharashtra',
    '28': 'Andhra Pradesh',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman and Nicobar Islands',
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
    '38': 'Ladakh',
    '97': 'Other Territory',
  };
}
