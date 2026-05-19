import 'package:flutter/material.dart';

class ProductUnitData {
  static const List<DropdownMenuItem<String>> unitItems = [
    DropdownMenuItem(value: 'كيلوغرام', child: Text('كيلوغرام')),
    DropdownMenuItem(value: 'غرام', child: Text('غرام')),
    DropdownMenuItem(value: 'ظرف', child: Text('ظرف')),
    DropdownMenuItem(value: 'قطعه', child: Text('قطعه')),
    DropdownMenuItem(value: 'لتر', child: Text('لتر')),
    DropdownMenuItem(value: 'مل', child: Text('مل')),
    DropdownMenuItem(value: 'متر', child: Text('متر')),
  ];

}
