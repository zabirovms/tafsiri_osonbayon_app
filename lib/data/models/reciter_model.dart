import 'package:equatable/equatable.dart';

class ReciterModel extends Equatable {
  final String id; // e.g., 'ar.alafasy'
  final String name; // e.g., 'Mishary Alafasy'
  final String nameTajik; // e.g., 'Мишарӣ Ал-Афосӣ'
  final String nameArabic; // e.g., 'مشاري العفاسي'
  final String? imageUrl; // Optional image URL
  final String? description; // Optional description

  const ReciterModel({
    required this.id,
    required this.name,
    required this.nameTajik,
    required this.nameArabic,
    this.imageUrl,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, nameTajik, nameArabic, imageUrl, description];
}

