// import 'package:erad/core/utils/app_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';

// class CustomDateRangePicker {
//   static Future<void> showDateRangePicker({
//     required BuildContext context,
//     required Function(DateTimeRange) onDateRangeChanged,
//     DateTimeRange? initialDateRange,
//     DateTime? firstDate,
//     DateTime? lastDate,
//     CalendarTheme? theme,
//     String? startDateText,
//     String? endDateText,
//     String? confirmText,
//     String? cancelText,
//   }) async {
//     await showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           width: MediaQuery.of(context).size.width * 0.55,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               DateRangePickerWidget(
//                 height: 400,
//                 initialDateRange: initialDateRange != null
//                     ? DateRange(initialDateRange.start, initialDateRange.end)
//                     : null,
//                 disabledDates: [],
//                 initialDisplayedDate: initialDateRange?.start ?? DateTime.now(),
//                 onDateRangeChanged: (dateRange) {
//                   if (dateRange != null) {
//                     onDateRangeChanged(
//                       DateTimeRange(start: dateRange.start, end: dateRange.end),
//                     );
//                     Navigator.of(context).pop();
//                   }
//                 },
//                 allowSingleTapDaySelection: true,
//                 theme: theme ?? _getDefaultTheme(),
//                 quickDateRanges: [
//                   QuickDateRange(
//                     dateRange: DateRange(
//                       DateTime.now(),
//                       DateTime.now(),
//                     ),
//                     label: 'اليوم',
//                   ),
//                   QuickDateRange(
//                     dateRange: DateRange(
//                       DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
//                       DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)),
//                     ),
//                     label: 'هذا الأسبوع',
//                   ),
//                   QuickDateRange(
//                     dateRange: DateRange(
//                       DateTime.now().subtract(Duration(days: DateTime.now().day - 1)),
//                       DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
//                     ),
//                     label: 'هذا الشهر',
//                   ),
//                   QuickDateRange(
//                     dateRange: DateRange(
//                       DateTime(DateTime.now().year, 1, 1),
//                       DateTime(DateTime.now().year, 12, 31),
//                     ),
//                     label: 'هذا العام',
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: Text(cancelText ?? 'إلغاء'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   static CalendarTheme _getDefaultTheme() {
//     return CalendarTheme(
//       selectedColor: const Color(0xFF1D4ED8),
//       dayNameTextStyle: const TextStyle(color: Colors.black45, fontSize: 10),
//       inRangeColor: const Color(0xFFD9EDFA),
//       inRangeTextStyle: const TextStyle(color: Color(0xFF1D4ED8)),
//       selectedTextStyle: const TextStyle(color: Colors.white),
//       todayTextStyle: const TextStyle(fontWeight: FontWeight.bold),
//       defaultTextStyle: const TextStyle(color: Colors.black, fontSize: 12),
//       radius: 10,
//       tileSize: 40,
//       disabledTextStyle: const TextStyle(color: Colors.grey),
//     );
//   }

//   static Widget buildDateRangeDisplay({
//     required DateTimeRange? dateRange,
//     required VoidCallback onTap,
//     String? placeholder,
//     TextStyle? textStyle,
//     Color? borderColor,
//     double? height,
//     double? borderRadius,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(borderRadius ?? 8),
//       child: Container(
//         height: height ?? 40,
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: borderColor ?? const Color(0xFFE5E7EB),
//             width: 1,
//           ),
//           borderRadius: BorderRadius.circular(borderRadius ?? 8),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               Icons.calendar_today,
//               size: 16,
//               color: textStyle?.color ?? const Color(0xFF6B7280),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 dateRange != null
//                     ? '${ AppUtils.formatDate(dateRange.start)} - ${AppUtils.formatDate(dateRange.end)}'
//                     : (placeholder ?? 'اختر نطاق التاريخ'),
//                 style:
//                     textStyle ??
//                     const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }



//   static bool isDateInRange(DateTime date, DateTimeRange? dateRange) {
//     if (dateRange == null) return false;
//     return (date.isAfter(dateRange.start) ||
//             date.isAtSameMomentAs(dateRange.start)) &&
//         (date.isBefore(dateRange.end) || date.isAtSameMomentAs(dateRange.end));
//   }

//   static String getDateRangeText(DateTimeRange? dateRange) {
//     if (dateRange == null) {
//       return 'select_date_range';
//     }
//     return '${ AppUtils.formatDate(dateRange.start)} - ${AppUtils.formatDate(dateRange.end)}';
//   }

//   // Backward compatibility for old usage
//   static Future<void> showDateRangePickerLegacy({
//     required BuildContext context,
//     required Function(DateTime, DateTime) onDateRangeChanged,
//     DateTime? initialStartDate,
//     DateTime? initialEndDate,
//     DateTime? firstDate,
//     DateTime? lastDate,
//     String? startDateText,
//     String? endDateText,
//     String? confirmText,
//     String? cancelText,
//     Color? primaryColor,
//   }) async {
//     final DateTimeRange? initialRange =
//         initialStartDate != null && initialEndDate != null
//         ? DateTimeRange(start: initialStartDate, end: initialEndDate)
//         : null;

//     await showDateRangePicker(
//       context: context,
//       onDateRangeChanged: (dateRange) {
//         onDateRangeChanged(dateRange.start, dateRange.end);
//       },
//       initialDateRange: initialRange,
//       firstDate: firstDate,
//       lastDate: lastDate,
//       startDateText: startDateText ?? 'تاريخ البدء',
//       endDateText: endDateText ?? 'تاريخ النهاية',
//       confirmText: confirmText ?? 'تأكيد',
//       cancelText: cancelText ?? 'إلغاء',
//       theme: CalendarTheme(
//         selectedColor: primaryColor ?? const Color(0xFF1D4ED8),
//         dayNameTextStyle: const TextStyle(color: Colors.black45, fontSize: 10),
//         inRangeColor: const Color(0xFFD9EDFA),
//         inRangeTextStyle: TextStyle(
//           color: primaryColor ?? const Color(0xFF1D4ED8),
//         ),
//         selectedTextStyle: const TextStyle(color: Colors.white),
//         todayTextStyle: const TextStyle(fontWeight: FontWeight.bold),
//         defaultTextStyle: const TextStyle(color: Colors.black, fontSize: 12),
//         radius: 10,
//         tileSize: 40,
//         disabledTextStyle: const TextStyle(color: Colors.grey),
//       ),
//     );
//   }
// }
