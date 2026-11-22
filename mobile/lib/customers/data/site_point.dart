import 'package:equatable/equatable.dart';

/// Where a customer's site is, as the agent's phone gave it.
class SitePoint extends Equatable {
  const new(this.lat, this.lng);

  final double lat;
  final double lng;

  /// "30.70460, 76.71790": to about a metre, for showing.
  String get label => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  @override
  List<Object> get props => [lat, lng];
}
