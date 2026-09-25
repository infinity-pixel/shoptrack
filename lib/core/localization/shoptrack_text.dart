import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Translates interface copy only. User-authored item and list names should
/// continue to use Flutter's ordinary Text widget unchanged.
class ShopText extends StatelessWidget {
  const ShopText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String? data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) => Text(
    shopTr(context, data ?? ''),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel == null
        ? null
        : shopTr(context, semanticsLabel!),
    semanticsIdentifier: semanticsIdentifier,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}

String shopTr(BuildContext context, String english) {
  if (Localizations.localeOf(context).languageCode != 'bn') return english;
  return _bangla[english] ?? english;
}

bool shopIsBangla(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'bn';

String shopNumber(BuildContext context, num value) => shopIsBangla(context)
    ? NumberFormat.decimalPattern('bn_BD').format(value)
    : NumberFormat.decimalPattern('en_US').format(value);

String shopCount(
  BuildContext context,
  int count, {
  String singular = 'Item',
  String plural = 'Items',
}) =>
    '${shopNumber(context, count)} ${shopTr(context, count == 1 ? singular : plural)}';

String shopListName(
  BuildContext context, {
  required String id,
  required String name,
}) => id == 'default-list' && name == 'My List'
    ? shopTr(context, 'My List')
    : name;

const Map<String, String> _bangla = {
  'Lists': 'তালিকা',
  'History': 'ইতিহাস',
  'Profile': 'প্রোফাইল',
  'Today': 'আজ',
  'TODAY': 'আজ',
  'UPCOMING': 'আসন্ন',
  'To Buy': 'কিনতে হবে',
  'Purchased': 'কেনা হয়েছে',
  'Planned': 'পরিকল্পিত',
  'Pending': 'বাকি',
  'Total Amount': 'মোট পরিমাণ',
  'Purchased Amount': 'কেনা পণ্যের মোট দাম',
  'Total Purchased': 'মোট কেনাকাটা',
  'Add Item': 'পণ্য যোগ করুন',
  'Add item': 'পণ্য যোগ করুন',
  'Edit Item': 'পণ্য সম্পাদনা',
  'New Date': 'নতুন তারিখ',
  'Create a past or future date': 'আগের বা ভবিষ্যতের তারিখ তৈরি করুন',
  'Share Your List': 'তালিকা শেয়ার করুন',
  'Share': 'শেয়ার',
  'Copy Text': 'লেখা কপি করুন',
  'Copy or Share': 'কপি বা শেয়ার',
  'More actions': 'আরও কাজ',
  'Cancel': 'বাতিল',
  'Save': 'সংরক্ষণ',
  'Save Changes': 'পরিবর্তন সংরক্ষণ',
  'Delete': 'মুছুন',
  'Delete List': 'তালিকা মুছুন',
  'Delete Permanently': 'স্থায়ীভাবে মুছুন',
  'Move': 'সরান',
  'Remove': 'সরান',
  'Edit': 'সম্পাদনা',
  'Create': 'তৈরি করুন',
  'Clear': 'মুছুন',
  'Apply Range': 'সময়সীমা প্রয়োগ করুন',
  'Try Again': 'আবার চেষ্টা করুন',
  'OK': 'ঠিক আছে',
  'Quantity': 'পরিমাণ',
  'Unit': 'একক',
  'No Unit': 'একক নেই',
  'Price basis': 'দামের ভিত্তি',
  'Currency': 'মুদ্রা',
  'Total Price': 'মোট দাম',
  'Price per Unit': 'প্রতি এককের দাম',
  'Notes': 'নোট',
  'Item Name': 'পণ্যের নাম',
  'Often Bought': 'প্রায়ই কেনা হয়',
  'Frequently Purchased': 'প্রায়ই কেনা হয়',
  'Fewer Options': 'কম বিকল্প',
  'More Options': 'আরও বিকল্প',
  'Search history': 'ইতিহাস খুঁজুন',
  'Search History': 'ইতিহাস খুঁজুন',
  'Date Range': 'তারিখের সীমা',
  'Select Date Range': 'তারিখের সীমা বাছুন',
  'Past Date': 'আগের তারিখ',
  'Future Date': 'ভবিষ্যতের তারিখ',
  'Edit Date': 'তারিখ সম্পাদনা',
  'Edit Shopping Date': 'কেনাকাটার তারিখ সম্পাদনা',
  'Date Already Exists': 'তারিখটি আগে থেকেই আছে',
  'Purchased items detected': 'কেনা পণ্য পাওয়া গেছে',
  'Change Shopping Date?': 'কেনাকাটার তারিখ বদলাবেন?',
  'Move Date': 'তারিখ সরান',
  'Continue': 'চালিয়ে যান',
  'Purchased items stay in Today. No future session created.':
      'কেনা পণ্য আজকের তালিকাতেই থাকবে। ভবিষ্যতের জন্য কোনো রেকর্ড তৈরি হয়নি।',
  'All items moved to Today': 'সব পণ্য আজকের তালিকায় সরানো হয়েছে',
  'Add Shopping Date': 'কেনাকাটার তারিখ যোগ করুন',
  'Create shopping date?': 'কেনাকাটার তারিখ তৈরি করবেন?',
  'No shopping history yet': 'এখনও কেনাকাটার ইতিহাস নেই',
  'No items added': 'কোনো পণ্য যোগ করা হয়নি',
  'A list with that name already exists.': 'এই নামে ইতিমধ্যে একটি তালিকা আছে।',
  'Rename List': 'তালিকার নাম বদলান',
  'Delete item?': 'পণ্যটি মুছবেন?',
  'Are you sure you want to delete this item?': 'পণ্যটি মুছতে চান?',
  'Delete this date?': 'এই তারিখটি মুছবেন?',
  'This permanently deletes this shopping record and every list inside it.':
      'এতে এই কেনাকাটার রেকর্ড ও এর সব তালিকা স্থায়ীভাবে মুছে যাবে।',
  'This will permanently delete this shopping record and all of its items. This action cannot be undone.':
      'এতে এই কেনাকাটার রেকর্ড ও সব পণ্য স্থায়ীভাবে মুছে যাবে। এটি ফেরানো যাবে না।',
  'You must add at least one item for this date to be saved.':
      'এই তারিখ সংরক্ষণ করতে অন্তত একটি পণ্য যোগ করুন।',
  'Stay Here': 'এখানেই থাকুন',
  'Discard & Go Back': 'বাতিল করে ফিরে যান',
  'Discard Changes?': 'পরিবর্তন বাতিল করবেন?',
  'Your profile has not been saved.': 'প্রোফাইলের পরিবর্তন সংরক্ষিত হয়নি।',
  'Keep Editing': 'সম্পাদনা চালিয়ে যান',
  'Discard': 'বাতিল করুন',
  'All Lists': 'সব তালিকা',
  'Choose one or more lists': 'একটি বা একাধিক তালিকা বাছুন',
  'Select at least one list.': 'অন্তত একটি তালিকা বাছুন।',
  'Add an item before sharing this list.':
      'তালিকা শেয়ার করার আগে একটি পণ্য যোগ করুন।',
  'Shopping list copied.': 'কেনাকাটার তালিকা কপি হয়েছে।',
  'Could not copy this list. Please try again.':
      'তালিকাটি কপি করা যায়নি। আবার চেষ্টা করুন।',
  'Could not share this list. Please try again.':
      'তালিকাটি শেয়ার করা যায়নি। আবার চেষ্টা করুন।',
  'Failed to create local backup': 'স্থানীয় ব্যাকআপ তৈরি করা যায়নি',
  'Failed to restore local backup': 'স্থানীয় ব্যাকআপ পুনরুদ্ধার করা যায়নি',
  'Cloud backup failed': 'ক্লাউড ব্যাকআপ করা যায়নি',
  'Cloud restore failed': 'ক্লাউড ব্যাকআপ পুনরুদ্ধার করা যায়নি',
  'No matching currency': 'মিলে যাওয়া মুদ্রা নেই',
  'Try its three-letter code or full name.':
      'তিন অক্ষরের কোড বা পুরো নাম লিখে খুঁজুন।',
  'Default Currency': 'ডিফল্ট মুদ্রা',
  'Choose Currency': 'মুদ্রা বাছুন',
  'Search by code or currency name': 'কোড বা মুদ্রার নাম দিয়ে খুঁজুন',
  'Recent': 'সাম্প্রতিক',
  'default': 'ডিফল্ট',
  'recent': 'সাম্প্রতিক',
  '(default)': '(ডিফল্ট)',
  'Appearance': 'রূপ',
  'My List': 'আমার তালিকা',
  "Today's Shopping": 'আজকের কেনাকাটা',
  'TO BUY': 'কিনতে হবে',
  'PURCHASED': 'কেনা হয়েছে',
  'SELECTED ITEMS': 'নির্বাচিত পণ্য',
  'ALL LISTS': 'সব তালিকা',
  'Note': 'নোট',
  'total': 'মোট',
  'totals': 'মোট',
  'No items yet.': 'এখনও কোনো পণ্য নেই।',
  'All': 'সব',
  'This empty list will be deleted.': 'খালি তালিকাটি মুছে যাবে।',
  'This record changed elsewhere. Both versions are kept; review them in Profile → Cloud Sync.':
      'রেকর্ডটি অন্য জায়গায় পরিবর্তিত হয়েছে। দুই সংস্করণই রাখা হয়েছে; প্রোফাইল → ক্লাউড সিঙ্কে দেখে নিন।',
  'This record changed elsewhere. Review changes in Profile → Cloud Sync.':
      'রেকর্ডটি অন্য জায়গায় পরিবর্তিত হয়েছে। প্রোফাইল → ক্লাউড সিঙ্কে পরিবর্তনগুলো দেখে নিন।',
  'Move undone.': 'সরানো বাতিল করা হয়েছে।',
  'Could not open this shopping list. Your data is still on this device.':
      'কেনাকাটার তালিকাটি খোলা যায়নি। আপনার তথ্য এই ডিভাইসেই আছে।',
  'Could not undo the move. The items or lists may have changed; your latest data is kept.':
      'সরানো বাতিল করা যায়নি। পণ্য বা তালিকা বদলে থাকতে পারে; সর্বশেষ তথ্য রাখা হয়েছে।',
  'Could not undo the deletion because this list changed. Your latest data is kept.':
      'তালিকাটি বদলে যাওয়ায় মুছে ফেলা ফেরানো যায়নি। সর্বশেষ তথ্য রাখা হয়েছে।',
  'Could not save this change. Your selection is kept; please try again.':
      'পরিবর্তনটি সংরক্ষণ করা যায়নি। আপনার নির্বাচন রাখা হয়েছে; আবার চেষ্টা করুন।',
  'Create List': 'তালিকা তৈরি করুন',
  'Preferences': 'পছন্দসমূহ',
  'Account & Data': 'অ্যাকাউন্ট ও তথ্য',
  'Language': 'ভাষা',
  'Language Preference': 'ভাষা বাছুন',
  'English': 'ইংরেজি',
  'Bangla': 'বাংলা',
  'Number Format': 'সংখ্যার বিন্যাস',
  'Automatic': 'স্বয়ংক্রিয়',
  'International': 'আন্তর্জাতিক',
  'South Asian': 'দক্ষিণ এশীয়',
  'Match each currency’s region': 'প্রতিটি মুদ্রার অঞ্চলের নিয়ম অনুযায়ী',
  'Follow your device region': 'ডিভাইসের অঞ্চল অনুযায়ী',
  'System': 'সিস্টেম',
  'Light': 'উজ্জ্বল',
  'Dark': 'অন্ধকার',
  'Edit Profile': 'প্রোফাইল সম্পাদনা',
  'Change Photo': 'ছবি বদলান',
  'Choose From Gallery': 'গ্যালারি থেকে বাছুন',
  'Remove Photo': 'ছবি সরান',
  'Google Account': 'গুগল অ্যাকাউন্ট',
  'Email cannot be edited here.': 'এখানে ইমেইল পরিবর্তন করা যাবে না।',
  'Saved on this device. Your Google account name and photo stay unchanged.':
      'এই ডিভাইসে সংরক্ষিত। আপনার গুগল অ্যাকাউন্টের নাম ও ছবি অপরিবর্তিত থাকবে।',
  'Your saved profile could not be loaded. Please restart the app.':
      'সংরক্ষিত প্রোফাইল খোলা যায়নি। অ্যাপটি আবার চালু করুন।',
  'Sign In Required': 'সাইন ইন প্রয়োজন',
  'Sign in Required': 'সাইন ইন প্রয়োজন',
  'Sign In': 'সাইন ইন',
  'Sign In with Google': 'গুগল দিয়ে সাইন ইন করুন',
  'Sign Out': 'সাইন আউট',
  'Sign Out?': 'সাইন আউট করবেন?',
  'Your lists stay accessible on this device. Cloud sync pauses until you sign back into the same account.\n\nCloud data and backups are kept. Other accounts have separate history.':
      'এই ডিভাইসে আপনার তালিকাগুলো থাকবে। একই অ্যাকাউন্টে আবার সাইন ইন না করা পর্যন্ত ক্লাউড সিঙ্ক বন্ধ থাকবে।\n\nক্লাউডের তথ্য ও ব্যাকআপ থাকবে। অন্য অ্যাকাউন্টের ইতিহাস আলাদা।',
  'You need to sign in with your Google account to use cloud backup and synchronization features.':
      'ক্লাউড ব্যাকআপ ও সিঙ্ক ব্যবহার করতে গুগল অ্যাকাউন্টে সাইন ইন করুন।',
  'You need to sign in with your Google account to use cloud backup features.':
      'ক্লাউড ব্যাকআপ ব্যবহার করতে গুগল অ্যাকাউন্টে সাইন ইন করুন।',
  'Cloud Sync': 'ক্লাউড সিঙ্ক',
  'Retry Sync': 'আবার সিঙ্ক করুন',
  'Review Changes': 'পরিবর্তন পর্যালোচনা',
  'The same record changed in two places. Review both versions before choosing. Other edits can continue syncing.':
      'একই রেকর্ড দুই জায়গায় বদলেছে। বেছে নেওয়ার আগে দুই সংস্করণই দেখুন। অন্য পরিবর্তনগুলো সিঙ্ক হতে থাকবে।',
  'This is part of an item transfer. Your choice applies to both related dates below.':
      'এটি পণ্য স্থানান্তরের অংশ। আপনার সিদ্ধান্ত নিচের দুটি সম্পর্কিত তারিখেই প্রযোজ্য হবে।',
  'This Device': 'এই ডিভাইস',
  'Saved Version': 'সংরক্ষিত সংস্করণ',
  'Keep Saved Version': 'সংরক্ষিত সংস্করণ রাখুন',
  'Use My Changes': 'আমার পরিবর্তন রাখুন',
  'Advanced Backup & Restore': 'উন্নত ব্যাকআপ ও পুনরুদ্ধার',
  'File and Google Drive backups': 'ফাইল ও গুগল ড্রাইভ ব্যাকআপ',
  'Backup & Restore': 'ব্যাকআপ ও পুনরুদ্ধার',
  'Restore Backup?': 'ব্যাকআপ পুনরুদ্ধার করবেন?',
  'Restoring this backup will replace your current local ShopTrack data. If cloud sync is enabled, these changes also sync to this account’s other devices. Export a backup first if you want to keep the current version.':
      'এই ব্যাকআপ পুনরুদ্ধার করলে বর্তমান স্থানীয় তথ্য বদলে যাবে। ক্লাউড সিঙ্ক চালু থাকলে পরিবর্তনটি এই অ্যাকাউন্টের অন্য ডিভাইসেও পৌঁছাবে। বর্তমান সংস্করণ রাখতে চাইলে আগে একটি ব্যাকআপ নিন।',
  'Restore': 'পুনরুদ্ধার',
  'Data restored successfully': 'তথ্য পুনরুদ্ধার হয়েছে',
  'Local backup created successfully': 'স্থানীয় ব্যাকআপ তৈরি হয়েছে',
  'No backup found in your cloud storage.':
      'ক্লাউডে কোনো ব্যাকআপ পাওয়া যায়নি।',
  'Could not save your choice. Please try again.':
      'আপনার পছন্দ সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।',
  'Could not save the currency preference.':
      'মুদ্রার পছন্দ সংরক্ষণ করা যায়নি।',
  'Could not save the language preference.': 'ভাষার পছন্দ সংরক্ষণ করা যায়নি।',
  'Cloud Backup': 'ক্লাউড ব্যাকআপ',
  'Back up to your Google account': 'গুগল অ্যাকাউন্টে ব্যাকআপ রাখুন',
  'Sign in to enable cloud backup': 'ক্লাউড ব্যাকআপ চালু করতে সাইন ইন করুন',
  'Lists stay on this device': 'তালিকাগুলো এই ডিভাইসে থাকবে',
  'Your Profile': 'আপনার প্রোফাইল',
  'Welcome to ShopTrack': 'শপট্র্যাকে স্বাগতম',
  'Sign in with Google to use cloud backup.':
      'ক্লাউড ব্যাকআপ ব্যবহার করতে গুগল দিয়ে সাইন ইন করুন।',
  'Could not save this change. Please try again.':
      'পরিবর্তন সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।',
  'Could not move this item. Please try again.':
      'পণ্যটি সরানো যায়নি। আবার চেষ্টা করুন।',
  'Item deleted': 'পণ্য মুছে ফেলা হয়েছে',
  'Item saved, but the recent currency shortcut could not be updated.':
      'পণ্য সংরক্ষিত হয়েছে, তবে সাম্প্রতিক মুদ্রার শর্টকাট আপডেট হয়নি।',
  'About ShopTrack': 'শপট্র্যাক সম্পর্কে',
  'Your Shopping Companion': 'আপনার কেনাকাটার সঙ্গী',
  'Plan your shopping, track purchases and keep your history close—even offline.':
      'কেনাকাটার পরিকল্পনা করুন, কেনা পণ্যের হিসাব রাখুন, আর অফলাইনেও ইতিহাস দেখুন।',
  'App Version': 'অ্যাপের সংস্করণ',
  '© 2026 ShopTrack Team': '© ২০২৬ শপট্র্যাক টিম',
  'Stay organized. Shop smarter.': 'গুছিয়ে রাখুন। বুদ্ধিমত্তার সঙ্গে কিনুন।',
  'Find items across your shopping dates': 'সব কেনাকাটার তারিখে পণ্য খুঁজুন',
  'Close': 'বন্ধ করুন',
  'Back': 'ফিরে যান',
  'Back to History': 'ইতিহাসে ফিরুন',
  'Day': 'দিন',
  'Month': 'মাস',
  'Year': 'বছর',
  'Search currencies': 'মুদ্রা খুঁজুন',
  'Clear search': 'খোঁজা মুছুন',
  'Search items': 'পণ্য খুঁজুন',
  'e.g. Eggs': 'যেমন: ডিম',
  'e.g. Household': 'যেমন: সংসার',
  'e.g. Grandmother': 'যেমন: নানি',
  'List name': 'তালিকার নাম',
  'New shopping list': 'নতুন কেনাকাটার তালিকা',
  'Rename shopping list': 'তালিকার নাম বদলান',
  'Move to List': 'অন্য তালিকায় সরান',
  'Choose where the selected items should go.':
      'নির্বাচিত পণ্যগুলো কোন তালিকায় যাবে, বাছুন।',
  'No other lists yet': 'এখনও অন্য তালিকা নেই',
  'Create another list, then move these items into it.':
      'আরেকটি তালিকা তৈরি করে পণ্যগুলো সেখানে সরান।',
  'Undo': 'ফেরান',
  'Manage this shopping list.': 'এই কেনাকাটার তালিকা পরিচালনা করুন।',
  'Cancel Selection': 'নির্বাচন বাতিল',
  'Select All': 'সব বাছুন',
  'Deselect All': 'সব নির্বাচন সরান',
  'Selected': 'নির্বাচিত',
  'Item': 'পণ্য',
  'Items': 'পণ্য',
  'item': 'পণ্য',
  'items': 'পণ্য',
  'list': 'তালিকা',
  'lists': 'তালিকা',
  'Copy or Share Selected Items': 'নির্বাচিত পণ্য কপি বা শেয়ার করুন',
  'Date options': 'তারিখের বিকল্প',
  'Previous month': 'আগের মাস',
  'Next month': 'পরের মাস',
  'Add an earlier record or plan a future trip.':
      'আগের কেনাকাটা যোগ করুন বা ভবিষ্যতের পরিকল্পনা করুন।',
  'Choose Theme': 'থিম বাছুন',
  'Light Theme': 'উজ্জ্বল থিম',
  'Dark Theme': 'অন্ধকার থিম',
  'Golden Summer': 'সোনালি গ্রীষ্ম',
  'Blooming Spring': 'ফুলেল বসন্ত',
  'Tranquil Ocean': 'শান্ত সমুদ্র',
  'Ember Autumn': 'অগ্নিময় শরৎ',
  'Silent Midnight': 'নীরব মধ্যরাত',
  'Ethereal Aurora': 'অলৌকিক মেরুজ্যোতি',
  'Bleeding Moonlight': 'রক্তিম চাঁদের আলো',
  'Ancient Forest': 'প্রাচীন অরণ্য',
  'Profile Photo': 'প্রোফাইল ছবি',
  'Choose how your profile appears in ShopTrack.':
      'শপট্র্যাকে আপনার প্রোফাইল কেমন দেখাবে, বাছুন।',
  'Display Name': 'দেখানো নাম',
  'Only used in ShopTrack': 'শুধু শপট্র্যাকে ব্যবহৃত হবে',
  'Create Local Backup': 'স্থানীয় ব্যাকআপ তৈরি করুন',
  'Export your data to a JSON file': 'তথ্য JSON ফাইলে সংরক্ষণ করুন',
  'Restore from Local File': 'স্থানীয় ফাইল থেকে পুনরুদ্ধার করুন',
  'Select a previously saved JSON backup': 'আগে সংরক্ষিত JSON ব্যাকআপ বাছুন',
  'Back up to Cloud': 'ক্লাউডে ব্যাকআপ রাখুন',
  'Sync your data to Google Drive App Data':
      'গুগল ড্রাইভ অ্যাপ ডেটায় তথ্য সিঙ্ক করুন',
  'Restore from Cloud': 'ক্লাউড থেকে পুনরুদ্ধার করুন',
  'Download your latest cloud backup': 'সর্বশেষ ক্লাউড ব্যাকআপ নামান',
  'Synced': 'সিঙ্ক হয়েছে',
  'Lists, items, prices, quantities and history.':
      'তালিকা, পণ্য, দাম, পরিমাণ ও ইতিহাস।',
  'On This Device': 'এই ডিভাইসে',
  'Appearance and your ShopTrack profile.':
      'রূপের সেটিং ও আপনার শপট্র্যাক প্রোফাইল।',
  'Use Another Device': 'অন্য ডিভাইসে ব্যবহার করুন',
  'Sign in to the same account to load your lists.':
      'তালিকা পেতে একই অ্যাকাউন্টে সাইন ইন করুন।',
  'Kilogram (kg)': 'কিলোগ্রাম (kg)',
  'Gram (g)': 'গ্রাম (g)',
  'Litre (L)': 'লিটার (L)',
  'Millilitre (mL)': 'মিলিলিটার (mL)',
  'Piece (pc)': 'পিস (pc)',
  'Packet': 'প্যাকেট',
  'Package': 'প্যাকেজ',
  'Item name is required': 'পণ্যের নাম লিখুন',
  'Unit required for Price per Unit': 'প্রতি এককের দাম দিতে একটি একক বাছুন',
  'Last used price': 'আগে ব্যবহৃত দাম',
  'Double tap to change currency': 'মুদ্রা বদলাতে দুবার চাপুন',
  'Price per': 'প্রতি',
  'Taka': 'টাকা',
  'US Dollar': 'মার্কিন ডলার',
  'Euro': 'ইউরো',
  'Pound Sterling': 'ব্রিটিশ পাউন্ড',
  'Saudi Riyal': 'সৌদি রিয়াল',
  'UAE Dirham': 'সংযুক্ত আরব আমিরাতের দিরহাম',
  'Yen': 'জাপানি ইয়েন',
  'Yuan Renminbi': 'চীনা ইউয়ান',
  'Indian Rupee': 'ভারতীয় রুপি',
  'Price per unit': 'প্রতি এককের দাম',
  'Total': 'মোট',
  'This quantity cannot be saved exactly.':
      'এই পরিমাণটি নির্ভুলভাবে সংরক্ষণ করা যাবে না।',
  'Enter an exact price with up to 2 decimals.':
      'দশমিকের পরে সর্বোচ্চ ২ ঘরসহ নির্ভুল দাম লিখুন।',
  'This total cannot be saved exactly.':
      'এই মোট দামটি নির্ভুলভাবে সংরক্ষণ করা যাবে না।',
};
