/// Represents a faculty member in the Smart Meet system.
class FacultyModel {
  final String id;
  final String name;
  final String department;
  final String designation;
  final String? specialization;
  final String? email;
  final bool isAvailable;

  const FacultyModel({
    required this.id,
    required this.name,
    required this.department,
    required this.designation,
    this.specialization,
    this.email,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'department': department,
    'designation': designation,
    'specialization': specialization,
    'email': email,
    'isAvailable': isAvailable,
  };

  factory FacultyModel.fromJson(Map<String, dynamic> json) => FacultyModel(
    id: json['id'] as String,
    name: json['name'] as String,
    department: json['department'] as String,
    designation: json['designation'] as String,
    specialization: json['specialization'] as String?,
    email: json['email'] as String?,
    isAvailable: json['isAvailable'] as bool? ?? true,
  );
}
