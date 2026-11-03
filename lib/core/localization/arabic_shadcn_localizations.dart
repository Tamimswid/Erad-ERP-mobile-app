import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ArabicShadcnLocalizations extends ShadcnLocalizations {
  ArabicShadcnLocalizations() : super('ar');

  static const LocalizationsDelegate<ShadcnLocalizations> delegate =
      _ArabicShadcnLocalizationsDelegate();

  @override
  String get formNotEmpty => 'هذا الحقل مطلوب';

  @override
  String get invalidValue => 'قيمة غير صالحة';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get invalidURL => 'رابط غير صالح';

  @override
  String formLessThan(double value) => 'يجب أن يكون أقل من $value';

  @override
  String formGreaterThan(double value) => 'يجب أن يكون أكبر من $value';

  @override
  String formLessThanOrEqualTo(double value) =>
      'يجب أن يكون أقل من أو يساوي $value';

  @override
  String get formPhoneNumberInvalid => 'رقم الهاتف غير صالح';

  @override
  String get formPhoneNumberEmpty => 'رقم الهاتف مطلوب';

  @override
  String formGreaterThanOrEqualTo(double value) =>
      'يجب أن يكون أكبر من أو يساوي $value';

  @override
  String formBetweenInclusively(double min, double max) =>
      'يجب أن يكون بين $min و $max (شاملًا الطرفين)';

  @override
  String formBetweenExclusively(double min, double max) =>
      'يجب أن يكون بين $min و $max (غير شامل الطرفين)';

  @override
  String formLengthLessThan(int value) => 'يجب ألا يقل عن $value حرفًا';

  @override
  String formLengthGreaterThan(int value) => 'يجب ألا يزيد عن $value حرفًا';

  @override
  String get formPasswordDigits => 'يجب أن يحتوي على رقم واحد على الأقل';

  @override
  String get formPasswordLowercase =>
      'يجب أن يحتوي على حرف صغير واحد على الأقل';

  @override
  String get formPasswordUppercase =>
      'يجب أن يحتوي على حرف كبير واحد على الأقل';

  @override
  String get formPasswordSpecial => 'يجب أن يحتوي على رمز خاص واحد على الأقل';

  @override
  String get commandSearch => 'اكتب أمرًا أو ابحث...';

  @override
  String get commandEmpty => 'لا توجد نتائج.';

  @override
  String get datePickerSelectYear => 'اختر السنة';

  @override
  String get abbreviatedMonday => 'ن';

  @override
  String get abbreviatedTuesday => 'ث';

  @override
  String get abbreviatedWednesday => 'ر';

  @override
  String get abbreviatedThursday => 'خ';

  @override
  String get abbreviatedFriday => 'ج';

  @override
  String get abbreviatedSaturday => 'س';

  @override
  String get abbreviatedSunday => 'ح';

  @override
  String get monthJanuary => 'يناير';

  @override
  String get monthFebruary => 'فبراير';

  @override
  String get monthMarch => 'مارس';

  @override
  String get monthApril => 'أبريل';

  @override
  String get monthMay => 'مايو';

  @override
  String get monthJune => 'يونيو';

  @override
  String get monthJuly => 'يوليو';

  @override
  String get monthAugust => 'أغسطس';

  @override
  String get monthSeptember => 'سبتمبر';

  @override
  String get monthOctober => 'أكتوبر';

  @override
  String get monthNovember => 'نوفمبر';

  @override
  String get monthDecember => 'ديسمبر';

  @override
  String get abbreviatedJanuary => 'ينا';

  @override
  String get abbreviatedFebruary => 'فبر';

  @override
  String get abbreviatedMarch => 'مار';

  @override
  String get abbreviatedApril => 'أبر';

  @override
  String get abbreviatedMay => 'ماي';

  @override
  String get abbreviatedJune => 'يون';

  @override
  String get abbreviatedJuly => 'يول';

  @override
  String get abbreviatedAugust => 'أغس';

  @override
  String get abbreviatedSeptember => 'سبت';

  @override
  String get abbreviatedOctober => 'أكت';

  @override
  String get abbreviatedNovember => 'نوف';

  @override
  String get abbreviatedDecember => 'ديس';

  @override
  String get buttonCancel => 'إلغاء';

  @override
  String get buttonSave => 'حفظ';

  @override
  String get timeHour => 'ساعة';

  @override
  String get timeMinute => 'دقيقة';

  @override
  String get timeSecond => 'ثانية';

  @override
  String get timeAM => 'ص';

  @override
  String get timePM => 'م';

  @override
  String get colorRed => 'أحمر';

  @override
  String get colorGreen => 'أخضر';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get colorAlpha => 'الشفافية';

  @override
  String get colorHue => 'درجة اللون';

  @override
  String get colorSaturation => 'التشبع';

  @override
  String get colorValue => 'القيمة';

  @override
  String get colorLightness => 'الإضاءة';

  @override
  String get menuCut => 'قص';

  @override
  String get menuCopy => 'نسخ';

  @override
  String get menuPaste => 'لصق';

  @override
  String get menuSelectAll => 'تحديد الكل';

  @override
  String get menuUndo => 'تراجع';

  @override
  String get menuRedo => 'إعادة';

  @override
  String get menuDelete => 'حذف';

  @override
  String get menuShare => 'مشاركة';

  @override
  String get menuSearchWeb => 'البحث في الويب';

  @override
  String get menuLiveTextInput => 'إدخال نص مباشر';

  @override
  String get placeholderDatePicker => 'اختر تاريخًا';

  @override
  String get placeholderTimePicker => 'اختر وقتًا';

  @override
  String get placeholderColorPicker => 'اختر لونًا';

  @override
  String get buttonPrevious => 'السابق';

  @override
  String get buttonNext => 'التالي';

  @override
  String get refreshTriggerPull => 'اسحب للتحديث';

  @override
  String get refreshTriggerRelease => 'أفلت للتحديث';

  @override
  String get refreshTriggerRefreshing => 'جارٍ التحديث...';

  @override
  String get refreshTriggerComplete => 'اكتمل التحديث';

  @override
  String get colorPickerTabRecent => 'الأخيرة';

  @override
  String get colorPickerTabRGB => 'RGB';

  @override
  String get colorPickerTabHSV => 'HSV';

  @override
  String get colorPickerTabHSL => 'HSL';

  @override
  String get colorPickerTabHEX => 'HEX';

  @override
  String get commandMoveUp => 'تحريك لأعلى';

  @override
  String get commandMoveDown => 'تحريك لأسفل';

  @override
  String get commandActivate => 'تحديد';

  @override
  String dataTableSelectedRows(int count, int total) =>
      'تم تحديد $count من $total صفًا.';

  @override
  String get dataTableNext => 'التالي';

  @override
  String get dataTablePrevious => 'السابق';

  @override
  String get dataTableColumns => 'الأعمدة';

  @override
  String get timeDaysAbbreviation => 'ي';

  @override
  String get timeHoursAbbreviation => 'س';

  @override
  String get timeMinutesAbbreviation => 'د';

  @override
  String get timeSecondsAbbreviation => 'ث';

  @override
  String get placeholderDurationPicker => 'اختر مدة';

  @override
  String get durationDay => 'يوم';

  @override
  String get durationHour => 'ساعة';

  @override
  String get durationMinute => 'دقيقة';

  @override
  String get durationSecond => 'ثانية';
}

class _ArabicShadcnLocalizationsDelegate
    extends LocalizationsDelegate<ShadcnLocalizations> {
  const _ArabicShadcnLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<ShadcnLocalizations> load(Locale locale) =>
      SynchronousFuture<ShadcnLocalizations>(ArabicShadcnLocalizations());

  @override
  bool shouldReload(
          covariant LocalizationsDelegate<ShadcnLocalizations> old) =>
      false;
}
