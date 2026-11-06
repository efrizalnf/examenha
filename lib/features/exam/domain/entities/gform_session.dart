/// Hasil `siswa.ujian.start` (mode gform).
class GformSession {
  final String sesiId, ujianId, judul, formUrl;
  final int remainingSeconds;

  const GformSession({
    required this.sesiId,
    required this.ujianId,
    required this.judul,
    required this.formUrl,
    required this.remainingSeconds,
  });
}
