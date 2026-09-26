import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/localization/shoptrack_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerShopTrackLocalizationLicenses();
  LicenseRegistry.addLicense(() async* {
    for (final file in [
      'ShopTrackCurrency-LICENSE.txt',
      'ShopTrackRufiyaa-OFL.txt',
      'Unifont-COPYING.txt',
    ]) {
      yield LicenseEntryWithLineBreaks([
        'ShopTrack currency fonts',
      ], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
  await Firebase.initializeApp();
  runApp(const ShopTrackApp());
}
