import 'package:equatable/equatable.dart';

class StockCategory extends Equatable {
  final String id;
  final String name;

  const StockCategory({required this.id, required this.name});

  factory StockCategory.fromMap(Map<String, dynamic> map) {
    return StockCategory(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}
