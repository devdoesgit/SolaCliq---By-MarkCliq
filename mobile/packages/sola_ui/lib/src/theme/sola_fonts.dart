import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' SIL Open Font License texts to the app's licence
/// page. Call once at startup.
void registerSolaFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Space Grotesk', 'SpaceGrotesk-OFL.txt'),
      ('Space Mono', 'SpaceMono-OFL.txt'),
    ]) {
      final text = await rootBundle.loadString(
        'packages/sola_ui/assets/fonts/$file',
      );
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
