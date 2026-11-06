import 'package:equatable/equatable.dart';

enum StudentExamStatus { belum, berlangsung, selesai }

/// Satu baris pada dashboard (hasil `siswa.ujian.list`).
class ExamSummary extends Equatable {
  final String id, judul, deskripsi, mapel, jenisUjian, guru;
  final int durasiMenit, jumlahSoal;
  final String mode; // 'gform' | 'native'
  final StudentExamStatus status;
  final bool bisaMulai;
  final String? sesiId, mulai, selesai;
  final int? sisaDetik;
  final num? nilai; // hanya bila guru mengizinkan & sudah disinkronkan/dinilai

  const ExamSummary({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.mapel,
    required this.jenisUjian,
    required this.guru,
    required this.durasiMenit,
    required this.jumlahSoal,
    required this.mode,
    required this.status,
    required this.bisaMulai,
    this.sesiId,
    this.mulai,
    this.selesai,
    this.sisaDetik,
    this.nilai,
  });

  bool get isGform => mode == 'gform';

  @override
  List<Object?> get props => [id, status, bisaMulai, sisaDetik, nilai, mode];
}
