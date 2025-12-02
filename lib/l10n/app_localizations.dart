import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [Locale('en'), Locale('id')];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settingsTitle': 'Settings',
      'bgm': 'Background Music',
      'sfx': 'Button SFX',
      'tutorial': 'Show Tutorial',
      'language': 'Language',
      'english': 'English',
      'indonesian': 'Indonesian',
      'homeSubtitle': 'DRAW, CONTROL, AND COMMAND',
      'btnNewPath': 'NEW PATH',
      'btnLoadFile': 'LOAD FILE',
      'btnConnect': 'CONNECT',
      'btnRemote': 'REMOTE',
      'btnDisconnect': 'DISCONNECT',
      'navHome': 'HOME',
      'navConnect': 'CONNECT',
      'statusConnected': 'Connected to: {device}',
      'statusDisconnected': 'No Robot Connected',
      'connectTitle': 'Connect to Robot',
      'connectConnected': 'Connected to: {device}',
      'connectBattery': 'Battery: {percent}%',
      'connectFail': 'Connection failed',
      'connectSuccess': 'Connected to {device}',
      'connectUnknownDevice': 'Unknown Device',
      'connectNoDevices': 'No devices found.\nTry scanning again.',
      'connectScan': 'Start Scan',
      'connectScanning': 'Scanning...',
      'connectHint': 'Press the scan button to start',
      'connectingSuccess': 'Successfully Connected!',
      'connectingTo': 'Connected to {device}',
      'connectingFailed': 'Connection Failed',
      'connectingFailedSubtitle': 'Could not connect to the robot.',
      'connectingBack': 'Go Back',
      'connectingProgress': 'Connecting...',
      'connectingProgressSubtitle': 'Establishing connection to {device}',
      'connectingCancel': 'Cancel',
      'unknownError': 'Unknown error occurred',
      'btnSkip': 'Skip',
      'btnNext': 'Next',
      'btnPrevious': 'Previous',
      'btnFinish': 'Finish',
      'showcaseConnectTitle': 'Connect Robot',
      'showcaseConnectDesc':
          'Make sure your robot is connected before drawing a path.',
      'showcaseNewPathTitle': 'Create New Path',
      'showcaseNewPathDesc':
          'Start drawing a robot path directly on the canvas.',
      'showcaseLoadTitle': 'Load File',
      'showcaseLoadDesc': 'Open a saved path to edit or run it.',
      'drawTitle': 'Map & Draw Path',
      'drawPathLength': 'path length: {meters}m',
      'drawCameraHint': 'Tap the camera to capture the area photo',
      'drawPlaceFinishAfterPath': 'Draw a path before placing finish.',
      'drawConnectRobotFirst': 'Connect to the robot first!',
      'drawCompletePathFirst': 'Complete the path from start to finish first.',
      'drawSendingPath': 'Sending path to robot... ({count} waypoints)',
      'drawSendSuccess': 'Path sent! Robot will start moving.',
      'drawSendFailed': 'Failed to send path. Try again.',
      'drawSendError': 'Error sending path to robot.',
      'drawPlaceMarkerOnPath': 'Place the marker on the drawn path.',
      'drawConnectPathToExisting': 'Connect the path to existing cells.',
      'drawOneCellWide': 'Path must be only one cell wide.',
      'drawPlaceFinishOnPath': 'Place finish on the drawn path.',
      'drawTableSizeMinimum': 'Minimum table size is 5cm x 5cm.',
      'drawInvalidGridSize': 'Grid size is not valid.',
      'drawStartFinishRequired': 'Start and finish positions are not set.',
      'drawPathNotReadyToSave': 'Path is not ready to save.',
      'drawMissingPhotoOrSettings':
          'Make sure the photo and table settings are complete.',
      'drawFileSaved': 'File saved: {name}',
      'drawFileSaveError': 'Failed to save file: {error}',
      'drawNoSavedFiles': 'No saved files yet.',
      'drawFileLoaded': 'File loaded: {name}',
      'drawFileCorrupt': 'Corrupt file: {error}',
      'drawFileOpenError': 'Failed to open file: {error}',
      'drawLoadConfirmTitle': 'Load Path?',
      'drawLoadConfirmBody':
          'Opening a file will overwrite the current path. Continue?',
      'drawClearPathTitle': 'Clear Path?',
      'drawResizeWarning':
          'Changing the table size will remove the current path. Continue?',
      'btnCancel': 'Cancel',
      'btnContinue': 'Continue',
      'drawLoadPath': 'LOAD',
      'drawRunPath': 'RUN PATH',
      'drawSimulate': 'SIMULATE',
      'drawStop': 'STOP',
      'drawSave': 'SAVE',
      'drawAreaSettingsTitle': 'AREA SETTINGS',
      'drawAreaLength': 'Area Length',
      'drawAreaWidth': 'Area Width',
      'drawRobotSpeed': 'ROBOT SPEED (0% - 100%) : {speed}%',
      'drawCaptureTitle': 'Capture Area Photo',
      'drawCaptureHint':
          'Capture a top-down photo so that the scale is accurate.',
      'drawNoPhoto': 'No photo yet',
      'drawCaptureButton': 'Capture Photo',
      'btnUse': 'Use',
      'drawCameraError': 'Failed to open camera: {error}',
      'drawFileIncomplete': 'File is incomplete.',
      'drawEmptyPathData': 'Path data is empty.',
      'drawInvalidConfig': 'Invalid configuration.',
      'drawInvalidTableSize': 'Table size is not valid.',
      'drawLastModified': 'Last updated: {value}',
    },
    'id': {
      'settingsTitle': 'Pengaturan',
      'bgm': 'Musik Latar',
      'sfx': 'Suara Tombol',
      'tutorial': 'Tampilkan Tutorial',
      'language': 'Bahasa',
      'english': 'Inggris',
      'indonesian': 'Indonesia',
      'homeSubtitle': 'GAMBAR, KENDALIKAN, DAN PERINTAHKAN',
      'btnNewPath': 'JALUR BARU',
      'btnLoadFile': 'MUAT BERKAS',
      'btnConnect': 'SAMBUNG',
      'btnRemote': 'REMOTE',
      'btnDisconnect': 'PUTUSKAN',
      'navHome': 'BERANDA',
      'navConnect': 'SAMBUNG',
      'statusConnected': 'Tersambung ke: {device}',
      'statusDisconnected': 'Belum ada robot tersambung',
      'connectTitle': 'Sambungkan Robot',
      'connectConnected': 'Tersambung ke: {device}',
      'connectBattery': 'Baterai: {percent}%',
      'connectFail': 'Gagal tersambung',
      'connectSuccess': 'Tersambung ke {device}',
      'connectUnknownDevice': 'Perangkat Tidak Dikenal',
      'connectNoDevices': 'Tidak ada perangkat.\nCoba pindai lagi.',
      'connectScan': 'Mulai Pindai',
      'connectScanning': 'Memindai...',
      'connectHint': 'Tekan tombol pindai untuk memulai',
      'connectingSuccess': 'Berhasil Tersambung!',
      'connectingTo': 'Tersambung ke {device}',
      'connectingFailed': 'Gagal Tersambung',
      'connectingFailedSubtitle': 'Tidak dapat menyambung ke robot.',
      'connectingBack': 'Kembali',
      'connectingProgress': 'Menyambungkan...',
      'connectingProgressSubtitle': 'Membangun koneksi ke {device}',
      'connectingCancel': 'Batal',
      'unknownError': 'Terjadi kesalahan',
      'btnSkip': 'Lewati',
      'btnNext': 'Lanjut',
      'btnPrevious': 'Sebelumnya',
      'btnFinish': 'Selesai',
      'showcaseConnectTitle': 'Hubungkan Robot',
      'showcaseConnectDesc':
          'Pastikan robotmu tersambung sebelum mulai menggambar jalur.',
      'showcaseNewPathTitle': 'Buat Jalur Baru',
      'showcaseNewPathDesc': 'Mulai gambar jalur robot langsung dari kanvas.',
      'showcaseLoadTitle': 'Muat Berkas',
      'showcaseLoadDesc': 'Buka jalur tersimpan untuk diedit atau dijalankan.',
      'drawTitle': 'MAP & DRAW PATH',
      'drawPathLength': 'panjang jalur: {meters}m',
      'drawCameraHint': 'Klik kamera untuk foto area',
      'drawPlaceFinishAfterPath':
          'Gambar jalur dulu sebelum menaruh finish.',
      'drawConnectRobotFirst': 'Hubungkan robot terlebih dahulu!',
      'drawCompletePathFirst':
          'Lengkapi jalur dari start ke finish terlebih dahulu.',
      'drawSendingPath': 'Mengirim jalur ke robot... ({count} waypoints)',
      'drawSendSuccess': 'Jalur berhasil dikirim! Robot akan mulai bergerak.',
      'drawSendFailed': 'Gagal mengirim jalur. Coba lagi.',
      'drawSendError': 'Error: Gagal mengirim jalur ke robot.',
      'drawPlaceMarkerOnPath': 'Letakkan ikon di jalur yang sudah digambar.',
      'drawConnectPathToExisting':
          'Hubungkan jalur ke sel yang sudah dibuat.',
      'drawOneCellWide': 'Jalur hanya boleh selebar satu kotak.',
      'drawPlaceFinishOnPath': 'Letakkan finish di jalur yang sudah digambar.',
      'drawTableSizeMinimum': 'Minimum ukuran meja 5cm x 5cm.',
      'drawInvalidGridSize': 'Ukuran grid tidak valid.',
      'drawStartFinishRequired': 'Posisi start dan finish belum diatur.',
      'drawPathNotReadyToSave': 'Jalur belum valid untuk disimpan.',
      'drawMissingPhotoOrSettings':
          'Pastikan foto dan pengaturan meja sudah lengkap.',
      'drawFileSaved': 'File tersimpan: {name}',
      'drawFileSaveError': 'Gagal menyimpan file: {error}',
      'drawNoSavedFiles': 'Belum ada file tersimpan.',
      'drawFileLoaded': 'File berhasil dimuat: {name}',
      'drawFileCorrupt': 'File rusak: {error}',
      'drawFileOpenError': 'Gagal membuka file: {error}',
      'drawLoadConfirmTitle': 'Muat Jalur?',
      'drawLoadConfirmBody':
          'Membuka file baru akan menimpa jalur yang sedang aktif. Lanjutkan?',
      'drawClearPathTitle': 'Hapus Jalur?',
      'drawResizeWarning':
          'Mengubah ukuran meja akan menghapus jalur yang sudah digambar. Lanjutkan?',
      'btnCancel': 'Batal',
      'btnContinue': 'Lanjutkan',
      'drawLoadPath': 'MUAT',
      'drawRunPath': 'RUN PATH',
      'drawSimulate': 'SIMULASI',
      'drawStop': 'STOP',
      'drawSave': 'SIMPAN',
      'drawAreaSettingsTitle': 'PENGATURAN AREA',
      'drawAreaLength': 'Panjang Area',
      'drawAreaWidth': 'Lebar Area',
      'drawRobotSpeed': 'KECEPATAN ROBOT (0% - 100%) : {speed}%',
      'drawCaptureTitle': 'Ambil Foto Area',
      'drawCaptureHint':
          'Ambil foto dari tampak atas (top-down) agar skala akurat.',
      'drawNoPhoto': 'Belum ada foto',
      'drawCaptureButton': 'Ambil Foto',
      'btnUse': 'Gunakan',
      'drawCameraError': 'Gagal membuka kamera: {error}',
      'drawFileIncomplete': 'File tidak lengkap.',
      'drawEmptyPathData': 'Data jalur kosong.',
      'drawInvalidConfig': 'Pengaturan tidak valid.',
      'drawInvalidTableSize': 'Ukuran meja tidak valid.',
      'drawLastModified': 'Terakhir: {value}',
    },
  };

  String _t(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
      _localizedValues['en']![key]!;

  String _fmt(String key, Map<String, String> params) {
    var value = _t(key);
    params.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }

  String get settingsTitle => _t('settingsTitle');
  String get bgm => _t('bgm');
  String get sfx => _t('sfx');
  String get tutorial => _t('tutorial');
  String get language => _t('language');
  String get english => _t('english');
  String get indonesian => _t('indonesian');
  String get homeSubtitle => _t('homeSubtitle');
  String get btnNewPath => _t('btnNewPath');
  String get btnLoadFile => _t('btnLoadFile');
  String get btnConnect => _t('btnConnect');
  String get btnRemote => _t('btnRemote');
  String get btnDisconnect => _t('btnDisconnect');
  String get navHome => _t('navHome');
  String get navConnect => _t('navConnect');
  String statusConnected(String device) =>
      _fmt('statusConnected', {'device': device});
  String get statusDisconnected => _t('statusDisconnected');
  String get connectTitle => _t('connectTitle');
  String connectConnected(String device) =>
      _fmt('connectConnected', {'device': device});
  String connectBattery(int percent) =>
      _fmt('connectBattery', {'percent': '$percent'});
  String get connectFail => _t('connectFail');
  String connectSuccess(String device) =>
      _fmt('connectSuccess', {'device': device});
  String get connectUnknownDevice => _t('connectUnknownDevice');
  String get connectNoDevices => _t('connectNoDevices');
  String get connectScan => _t('connectScan');
  String get connectScanning => _t('connectScanning');
  String get connectHint => _t('connectHint');
  String get connectingSuccess => _t('connectingSuccess');
  String connectingTo(String device) =>
      _fmt('connectingTo', {'device': device});
  String get connectingFailed => _t('connectingFailed');
  String get connectingFailedSubtitle => _t('connectingFailedSubtitle');
  String get connectingBack => _t('connectingBack');
  String get connectingProgress => _t('connectingProgress');
  String connectingProgressSubtitle(String device) =>
      _fmt('connectingProgressSubtitle', {'device': device});
  String get connectingCancel => _t('connectingCancel');
  String get unknownError => _t('unknownError');
  String get btnSkip => _t('btnSkip');
  String get btnNext => _t('btnNext');
  String get btnPrevious => _t('btnPrevious');
  String get btnFinish => _t('btnFinish');
  String get showcaseConnectTitle => _t('showcaseConnectTitle');
  String get showcaseConnectDesc => _t('showcaseConnectDesc');
  String get showcaseNewPathTitle => _t('showcaseNewPathTitle');
  String get showcaseNewPathDesc => _t('showcaseNewPathDesc');
  String get showcaseLoadTitle => _t('showcaseLoadTitle');
  String get showcaseLoadDesc => _t('showcaseLoadDesc');
  String get drawTitle => _t('drawTitle');
  String pathLengthLabel(String meters) =>
      _fmt('drawPathLength', {'meters': meters});
  String get drawCameraHint => _t('drawCameraHint');
  String get drawPlaceFinishAfterPath => _t('drawPlaceFinishAfterPath');
  String get drawConnectRobotFirst => _t('drawConnectRobotFirst');
  String get drawCompletePathFirst => _t('drawCompletePathFirst');
  String drawSendingPath(String count) =>
      _fmt('drawSendingPath', {'count': count});
  String get drawSendSuccess => _t('drawSendSuccess');
  String get drawSendFailed => _t('drawSendFailed');
  String get drawSendError => _t('drawSendError');
  String get drawPlaceMarkerOnPath => _t('drawPlaceMarkerOnPath');
  String get drawConnectPathToExisting => _t('drawConnectPathToExisting');
  String get drawOneCellWide => _t('drawOneCellWide');
  String get drawPlaceFinishOnPath => _t('drawPlaceFinishOnPath');
  String get drawTableSizeMinimum => _t('drawTableSizeMinimum');
  String get drawInvalidGridSize => _t('drawInvalidGridSize');
  String get drawStartFinishRequired => _t('drawStartFinishRequired');
  String get drawPathNotReadyToSave => _t('drawPathNotReadyToSave');
  String get drawMissingPhotoOrSettings => _t('drawMissingPhotoOrSettings');
  String drawFileSaved(String name) => _fmt('drawFileSaved', {'name': name});
  String drawFileSaveError(String error) =>
      _fmt('drawFileSaveError', {'error': error});
  String get drawNoSavedFiles => _t('drawNoSavedFiles');
  String drawFileLoaded(String name) => _fmt('drawFileLoaded', {'name': name});
  String drawFileCorrupt(String error) =>
      _fmt('drawFileCorrupt', {'error': error});
  String drawFileOpenError(String error) =>
      _fmt('drawFileOpenError', {'error': error});
  String get drawLoadConfirmTitle => _t('drawLoadConfirmTitle');
  String get drawLoadConfirmBody => _t('drawLoadConfirmBody');
  String get drawClearPathTitle => _t('drawClearPathTitle');
  String get drawResizeWarning => _t('drawResizeWarning');
  String get btnCancel => _t('btnCancel');
  String get btnContinue => _t('btnContinue');
  String get drawLoadPath => _t('drawLoadPath');
  String get drawRunPath => _t('drawRunPath');
  String get drawSimulate => _t('drawSimulate');
  String get drawStop => _t('drawStop');
  String get drawSave => _t('drawSave');
  String get drawAreaSettingsTitle => _t('drawAreaSettingsTitle');
  String get drawAreaLength => _t('drawAreaLength');
  String get drawAreaWidth => _t('drawAreaWidth');
  String drawRobotSpeed(String speed) =>
      _fmt('drawRobotSpeed', {'speed': speed});
  String get drawCaptureTitle => _t('drawCaptureTitle');
  String get drawCaptureHint => _t('drawCaptureHint');
  String get drawNoPhoto => _t('drawNoPhoto');
  String get drawCaptureButton => _t('drawCaptureButton');
  String get btnUse => _t('btnUse');
  String drawCameraError(String error) =>
      _fmt('drawCameraError', {'error': error});
  String get drawFileIncomplete => _t('drawFileIncomplete');
  String get drawEmptyPathData => _t('drawEmptyPathData');
  String get drawInvalidConfig => _t('drawInvalidConfig');
  String get drawInvalidTableSize => _t('drawInvalidTableSize');
  String drawLastModified(String value) =>
      _fmt('drawLastModified', {'value': value});
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
