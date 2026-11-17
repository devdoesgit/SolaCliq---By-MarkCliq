/// A system's size in kW as people say it: `5` not `5.0`, `3.5` kept.
String formatKw(num kw) => kw == kw.roundToDouble() ? '${kw.round()}' : '$kw';
