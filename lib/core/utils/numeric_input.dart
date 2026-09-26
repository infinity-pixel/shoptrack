/// Converts supported keyboard digits to the invariant representation used by
/// parsing, exactness checks and persisted quantities. User-authored names are
/// never passed through this function.
String normalizeNumericInput(String value) {
  const localizedDigits = ['০১২৩৪৫৬৭৮৯', '٠١٢٣٤٥٦٧٨٩', '۰۱۲۳۴۵۶۷۸۹'];
  var result = value;
  for (final digits in localizedDigits) {
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(digits[i], '$i');
    }
  }
  return result.replaceAll('٫', '.').replaceAll('٬', '');
}
