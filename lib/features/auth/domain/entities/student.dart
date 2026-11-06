import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final String nis, nama, kelas, jenjang;

  const Student({
    required this.nis,
    required this.nama,
    required this.kelas,
    required this.jenjang,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
    nis: (j['nis'] as String?) ?? (j['username'] as String?) ?? '',
    nama: (j['nama'] as String?) ?? '',
    kelas: (j['kelas'] as String?) ?? '',
    jenjang: (j['jenjang'] as String?) ?? '',
  );

  @override
  List<Object?> get props => [nis, nama, kelas, jenjang];
}
