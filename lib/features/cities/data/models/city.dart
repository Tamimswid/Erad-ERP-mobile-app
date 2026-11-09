import 'package:equatable/equatable.dart';

class CityModel extends Equatable {
  final String id;
  final String name;
  final bool isActive;

  const CityModel({required this.id, required this.name, this.isActive = true});

  factory CityModel.fromMap(Map<String, dynamic> map) {
    return CityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'is_active': isActive};
  }

  @override
  List<Object?> get props => [id, name, isActive];
}
