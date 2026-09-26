import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/localization/shoptrack_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerShopTrackLocalizationLicenses();
  await Firebase.initializeApp();
  runApp(const ShopTrackApp());
}
