# SUMMARY.md

## Ringkasan Workspace

Repository ini adalah proyek Flutter bernama `crime_report_app`. Struktur platform bawaan Flutter tersedia untuk Android, iOS, Web, Linux, macOS, dan Windows. Dari nama folder dan dependency yang dipasang, aplikasi ini diarahkan menjadi aplikasi pelaporan kriminal berbasis Firebase, lokasi perangkat, unggah gambar, dan notifikasi.

Kondisi aktual kode masih berada pada tahap scaffold/awal:

- `lib/main.dart` masih berisi aplikasi counter demo bawaan Flutter.
- `test/widget_test.dart` masih menguji counter demo.
- Sebagian besar file domain sudah dibuat tetapi masih kosong.
- `lib/screens/login_screen.dart` adalah satu-satunya screen non-kosong di luar counter demo, tetapi belum terhubung ke `main.dart`.
- Belum ditemukan file konfigurasi Firebase seperti `firebase_options.dart`, `google-services.json`, atau `GoogleService-Info.plist`.

## Flow Aplikasi Saat Ini

Flow yang benar-benar berjalan dari entry point saat ini:

1. `main()` di `lib/main.dart` menjalankan `runApp(const MyApp())`.
2. `MyApp` membuat `MaterialApp`.
3. `home` diarahkan ke `MyHomePage`, yaitu halaman counter demo.
4. User menekan tombol `FloatingActionButton`.
5. State `_counter` bertambah dan UI counter diperbarui.

Artinya, aplikasi yang aktif saat ini belum menggunakan flow laporan kriminal, Firebase, auth, location, storage, atau notification.

## Flow yang Terlihat Direncanakan

Berdasarkan folder dan nama file, rancangan flow aplikasi kemungkinan seperti ini:

1. User membuka aplikasi.
2. User masuk melalui `LoginScreen`.
3. `LoginScreen` memakai `AuthService` untuk `signIn` atau `register`.
4. Setelah login berhasil, user diarahkan ke `HomeScreen`.
5. `HomeScreen` kemungkinan akan menampilkan daftar laporan kriminal.
6. User dapat membuat laporan lewat `ReportScreen`.
7. Laporan kemungkinan menyimpan data ke Firestore melalui service laporan/firestore.
8. Lampiran gambar kemungkinan diunggah ke Firebase Storage.
9. Lokasi laporan kemungkinan diambil dari `geolocator`.
10. Detail laporan dan komentar kemungkinan ditampilkan lewat `DetailScreen`, `ReportCard`, dan `CommentItem`.
11. Notifikasi kemungkinan dikelola melalui Firebase Messaging.

Namun flow di atas belum menjadi implementasi aktif karena file-file pendukungnya masih kosong.

## Dependency yang Digunakan

Dependency runtime di `pubspec.yaml`:

- `flutter`: SDK utama untuk membangun aplikasi.
- `cupertino_icons`: ikon gaya iOS untuk widget Flutter.
- `firebase_core`: inisialisasi Firebase di aplikasi Flutter.
- `firebase_auth`: autentikasi user menggunakan Firebase Authentication.
- `cloud_firestore`: database dokumen untuk menyimpan data seperti user, laporan, komentar, dan status laporan.
- `firebase_storage`: penyimpanan file, kemungkinan untuk foto bukti atau lampiran laporan.
- `firebase_messaging`: push notification melalui Firebase Cloud Messaging.
- `geolocator`: akses lokasi perangkat dan koordinat laporan.
- `image_picker`: memilih/mengambil gambar dari kamera atau galeri.

Dev dependency:

- `flutter_test`: framework test bawaan Flutter.
- `flutter_lints`: lint rules rekomendasi Flutter yang diaktifkan melalui `analysis_options.yaml`.

## Struktur Folder dan Aturan Penggunaan

### `lib/`

Folder utama kode Dart aplikasi.

Aturan:

- Entry point aplikasi berada di `lib/main.dart`.
- File di bawah `lib/` sebaiknya hanya berisi kode aplikasi, bukan konfigurasi native platform.
- Import internal sebaiknya konsisten. Saat ini `login_screen.dart` memakai relative import seperti `../services/auth_service.dart`.

### `lib/screens/`

Berisi halaman penuh atau route aplikasi.

File saat ini:

- `login_screen.dart`: screen login/register, sudah berisi UI dan memanggil `AuthService`.
- `home_screen.dart`: masih kosong.
- `register_screen.dart`: masih kosong.
- `report_screen.dart`: masih kosong.
- `detail_screen.dart`: masih kosong.

Aturan:

- Screen bertanggung jawab atas layout halaman dan navigasi.
- Logic bisnis sebaiknya tidak ditaruh langsung di screen; gunakan service.
- Screen boleh memakai widget reusable dari `lib/widgets/`.
- Screen tidak seharusnya langsung mengakses Firebase jika sudah tersedia service khusus.

### `lib/services/`

Berisi lapisan integrasi eksternal dan logic aplikasi.

File saat ini:

- `auth_service.dart`: masih kosong, tetapi direferensikan oleh `LoginScreen`.
- `firestore_service.dart`: masih kosong.
- `location_service.dart`: masih kosong.
- `notification_service.dart`: masih kosong.
- `report_service.dart`: masih kosong.
- `storage_service.dart`: masih kosong.

Aturan:

- `AuthService` menangani login, register, logout, dan current user.
- `FirestoreService` menangani operasi baca/tulis Firestore.
- `StorageService` menangani upload file ke Firebase Storage.
- `LocationService` menangani permission dan pengambilan lokasi.
- `NotificationService` menangani permission, token FCM, dan handler notifikasi.
- `ReportService` dapat menjadi service orkestrasi yang menggabungkan Firestore, Storage, dan Location untuk membuat atau membaca laporan.

### `lib/models/`

Berisi model data aplikasi.

File saat ini:

- `user_model.dart`: masih kosong.
- `report_model.dart`: masih kosong.
- `comment_model.dart`: masih kosong.

Aturan:

- Model sebaiknya mewakili struktur data Firestore.
- Model sebaiknya memiliki method `fromMap`/`toMap` atau pola serialisasi lain yang konsisten.
- Field umum yang mungkin diperlukan:
  - `UserModel`: id, name/email, role, createdAt.
  - `ReportModel`: id, userId, title, description, category, imageUrl, latitude, longitude, status, createdAt.
  - `CommentModel`: id, reportId, userId, message, createdAt.

### `lib/widgets/`

Berisi komponen UI reusable.

File saat ini:

- `custom_button.dart`: masih kosong, tetapi direferensikan oleh `LoginScreen`.
- `report_card.dart`: masih kosong.
- `comment_item.dart`: masih kosong.

Aturan:

- Widget di folder ini sebaiknya stateless/reusable jika memungkinkan.
- Widget tidak seharusnya menyimpan logic bisnis atau akses service langsung.
- Penamaan class perlu konsisten mengikuti Dart style, misalnya `CustomButton`, bukan `Custom_button`.

### `test/`

Berisi automated test.

Kondisi saat ini:

- `widget_test.dart` masih menguji counter demo.

Aturan:

- Test perlu diperbarui ketika `main.dart` sudah tidak lagi memakai counter demo.
- Untuk flow login/laporan, test sebaiknya memisahkan UI test dan service test.

### Folder Platform

Folder berikut adalah scaffold platform Flutter:

- `android/`
- `ios/`
- `web/`
- `linux/`
- `macos/`
- `windows/`

Aturan:

- Jangan mengubah file generated kecuali memang dibutuhkan oleh konfigurasi platform.
- Permission native perlu ditambahkan sesuai dependency:
  - Android perlu permission lokasi, internet, kamera/media sesuai kebutuhan.
  - iOS perlu key permission di `Info.plist` untuk lokasi, kamera, photo library, dan notifikasi.
- Firebase native config perlu ditambahkan jika target build mobile dipakai.

## Catatan Masalah/GAP Saat Ini

Beberapa hal yang perlu dibereskan sebelum aplikasi laporan kriminal bisa berjalan:

- `main.dart` belum menginisialisasi Firebase dengan `Firebase.initializeApp()`.
- `main.dart` belum mengarah ke `LoginScreen` atau auth gate.
- `AuthService` masih kosong, sementara `LoginScreen` memanggil `signIn` dan `register`.
- `HomeScreen` masih kosong, tetapi `LoginScreen` melakukan navigasi ke sana.
- `custom_button.dart` masih kosong, tetapi `LoginScreen` memakai `CustomTextField` dan `Custom_button`.
- Penamaan `Custom_button` tidak mengikuti konvensi class Dart.
- Model data belum tersedia.
- Service Firestore, Storage, Location, Notification, dan Report belum tersedia.
- File konfigurasi Firebase belum ada di workspace.
- Permission lokasi/kamera/media/notifikasi belum tampak dikonfigurasi di manifest/plist utama.
- Test masih menguji counter demo, bukan flow aplikasi sebenarnya.
- Command `flutter analyze` belum bisa dijalankan di environment ini karena executable `flutter` tidak ditemukan melalui `rtk`.

## Rekomendasi Urutan Implementasi

1. Tambahkan konfigurasi Firebase dan `firebase_options.dart`.
2. Ubah `main.dart` untuk inisialisasi Firebase dan arahkan ke auth flow.
3. Implementasikan `AuthService`.
4. Implementasikan `CustomTextField` dan `CustomButton` dengan penamaan class yang konsisten.
5. Implementasikan model `UserModel`, `ReportModel`, dan `CommentModel`.
6. Implementasikan `HomeScreen` untuk daftar laporan.
7. Implementasikan `ReportScreen` untuk membuat laporan dengan gambar dan lokasi.
8. Implementasikan service Firestore/Storage/Location.
9. Implementasikan `DetailScreen`, `ReportCard`, dan `CommentItem`.
10. Tambahkan permission native Android/iOS sesuai fitur.
11. Perbarui test agar sesuai flow aplikasi.
