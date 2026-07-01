import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';
import '../models/pengumuman_model.dart';
import '../services/pengumuman_service.dart';
import '../pages/pengumuman_page.dart';
import '../pages/detail_pengumuman_page.dart';
import '../models/attendance_setting.dart';
import '../services/attendance_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../pages/attendance_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double? userLatitude;
  double? userLongitude;
  double distance = 0;
  bool canAttendance = false;
  Map<String, dynamic>? todayAttendance;
  bool isLoadingTodayAttendance = true;
  List<dynamic> riwayatList = [];
  bool isLoadingRiwayat = true;
  String formattedDate = "";
  String name = "";
  AttendanceSetting? setting;
  bool isLoadingSetting = true;
  List<Pengumuman> pengumumanList = [];

  bool isLoadingPengumuman = true;

  Future getCurrentLocation() async {
    print("1. Mulai ambil lokasi");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    print("2. Service : $serviceEnabled");

    if (!serviceEnabled) {
      print("Service mati");

      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    print("3. Permission awal : $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      print("4. Permission setelah request : $permission");
    }

    if (permission == LocationPermission.deniedForever) {
      print("Permission ditolak permanen");

      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    print("5. Latitude : ${position.latitude}");

    print("6. Longitude : ${position.longitude}");

    setState(() {
      userLatitude = position.latitude;

      userLongitude = position.longitude;
    });

    calculateDistance();
  }

  void calculateDistance() {
    if (setting == null || userLatitude == null || userLongitude == null) {
      return;
    }

    double meter = Geolocator.distanceBetween(
      userLatitude!,
      userLongitude!,
      setting!.latitude,
      setting!.longitude,
    );

    bool allowed = meter <= setting!.radius;

    print("===== ABSENSI =====");

    print("Latitude User : $userLatitude");

    print("Longitude User : $userLongitude");

    print("Jarak : $meter");

    print("Radius : ${setting!.radius}");

    print("Boleh Absen : $allowed");

    setState(() {
      distance = meter;

      canAttendance = allowed;
    });
  }

  Future<void> loadSetting() async {
    final result = await AttendanceService().getSetting();

    setState(() {
      setting = result;

      isLoadingSetting = false;
    });

    getCurrentLocation();
  }

  Future<void> getUser() async {
    final user = await AuthService.getUser();

    setState(() {
      name = user?["name"] ?? "";
    });
  }

  Future<void> getTodayAttendance() async {
    try {
      final result = await AttendanceService().getTodayAttendance();

      setState(() {
        todayAttendance = result;
        isLoadingTodayAttendance = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTodayAttendance = false;
      });
    }
  }

  Future<void> getRiwayatAttendance() async {
    try {
      final result = await AttendanceService().getRiwayatAttendance();

      setState(() {
        riwayatList = result;
        isLoadingRiwayat = false;
      });
    } catch (e) {
      setState(() {
        isLoadingRiwayat = false;
      });
    }
  }

  Future<void> getPengumuman() async {
    try {
      final result = await PengumumanService.getPengumuman(limit: 3);

      List<Pengumuman> data = result["data"];

      setState(() {
        pengumumanList = data;
        isLoadingPengumuman = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPengumuman = false;
      });
    }
  }

  Future getAttendanceSetting() async {
    try {
      final result = await AttendanceService().getSetting();

      setState(() {
        setting = result;

        isLoadingSetting = false;
      });

      // TAMBAHKAN INI
      await getCurrentLocation();
    } catch (e) {
      setState(() {
        isLoadingSetting = false;
      });
    }
  }

  void logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text("Apakah anda ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                bool success = await AuthService.logout();

                if (!mounted) return;

                if (success) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Logout gagal")));
                }
              },
              child: const Text("Keluar"),
            ),
          ],
        );
      },
    );
  }

 @override
  void initState() {
    super.initState();

    initializeDate();

    getUser();

    getPengumuman();

    getAttendanceSetting();

    getTodayAttendance();

    getRiwayatAttendance();
  }

  Future<void> initializeDate() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      formattedDate = DateFormat(
        "EEEE, dd MMMM yyyy\nHH:mm",
        "id_ID",
      ).format(DateTime.now());
    });
  }

  @override
  bool isAbsensi = true;
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEDEDED),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// ================= HEADER + CARD ABSENSI =================
              Column(
                children: [
                  /// ================= HEADER HIJAU =================
                  Container(
                    height: 230,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xff1E5631),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Hallo $name",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none,
                                      color: Colors.white),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout,
                                      color: Colors.white),
                                  onPressed: () {
                                    logout();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Silahkan Melakukan Absensi",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ================= CARD PUTIH =================
                  Transform.translate(
                    offset: const Offset(0, -100),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          /// ================= TAB =================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isAbsensi = true;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      "Absensi",
                                      style: TextStyle(
                                        fontWeight: isAbsensi
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (isAbsensi)
                                      const SizedBox(
                                        width: 40,
                                        child: Divider(
                                          thickness: 2,
                                          color: Color(0xff1E5631),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isAbsensi = false;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      "Riwayat Absensi",
                                      style: TextStyle(
                                        fontWeight: !isAbsensi
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (!isAbsensi)
                                      const SizedBox(
                                        width: 70,
                                        child: Divider(
                                          thickness: 2,
                                          color: Color(0xff1E5631),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(),

                          /// ================= ISI CARD (DINAMIS) =================

                          if (isLoadingSetting)
                            const Center(
                              child: CircularProgressIndicator(),
                            )
                          else if (setting == null)
                            const Center(
                              child: Text(
                                "Gagal memuat data absensi",
                              ),
                            )
                         else
                            isAbsensi
                                ?  _absensiView(
                                    context,
                                    setting!,
                                    canAttendance,
                                    todayAttendance,
                                    () {
                                      getTodayAttendance();
                                      getRiwayatAttendance();
                                    },
                                  )
                               : _riwayatView(riwayatList, isLoadingRiwayat, context)
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              /// ================= DATE CARD =================
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff2E7D32),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formattedDate.isEmpty ? "Loading..." : formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ================= PENGUMUMAN =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Pengumuman",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PengumumanPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Lihat Semua",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 210,
                child: isLoadingPengumuman
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : pengumumanList.isEmpty
                        ? const Center(
                            child: Text("Belum ada pengumuman"),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 20),
                            itemCount: pengumumanList.length,
                            itemBuilder: (context, index) {
                              final pengumuman = pengumumanList[index];

                              return Container(
                                width: 260,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// ================= GAMBAR =================
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                      child: Image.network(
                                        pengumuman.foto,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;

                                          return Container(
                                            height: 120,
                                            alignment: Alignment.center,
                                            child:
                                                const CircularProgressIndicator(),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: 120,
                                            color: Colors.grey[300],
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// ================= JUDUL =================
                                          Text(
                                            pengumuman.judul,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          /// ================= BUTTON =================
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: SizedBox(
                                              height: 26,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          DetailPengumumanPage(
                                                        pengumuman: pengumuman,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xffF4D03F),
                                                  foregroundColor: Colors.black,
                                                  elevation: 0,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                ),
                                                child: const Text(
                                                  "Lihat Selengkapnya",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 20),

              /// ================= AREA ABSENSI =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Area Absensi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (isLoadingSetting)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (setting != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      /// GOOGLE MAP
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 230,
                          child: GoogleMap(
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                setting!.latitude,
                                setting!.longitude,
                              ),
                              zoom: 17,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("sekolah"),
                                position: LatLng(
                                  setting!.latitude,
                                  setting!.longitude,
                                ),
                                infoWindow: InfoWindow(
                                  title: setting!.namaLokasi,
                                ),
                              ),
                            },
                            circles: {
                              Circle(
                                circleId: const CircleId("radius"),
                                center: LatLng(
                                  setting!.latitude,
                                  setting!.longitude,
                                ),
                                radius: setting!.radius.toDouble(),
                                fillColor: Colors.green.withOpacity(0.2),
                                strokeColor: Colors.green,
                                strokeWidth: 2,
                              ),
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xff1E5631),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pastikan Anda Melakukan Absensi Pada Area Yang Sudah Ditentukan",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    setting!.namaLokasi,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Lakukan Absensi Sebelum ${setting!.jamTerlambat.substring(0, 5)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.social_distance,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${distance.toStringAsFixed(0)} meter",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  canAttendance
                                      ? "Di dalam area absensi"
                                      : "Di luar area absensi",
                                  style: TextStyle(
                                    color: canAttendance
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.radio_button_checked,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Radius ${setting!.radius} meter",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                           SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                onPressed:
                                    (canAttendance && todayAttendance == null)
                                        ? () async {
                                        print(
                                            ">>> TOMBOL ABSENSI (Area Absensi) DITEKAN <<<");
                                        try {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AttendancePage(),
                                            ),
                                          );

                                          print(">>> RESULT = $result <<<");

                                          if (result == true &&
                                              context.mounted) {
                                            getTodayAttendance();
                                            getRiwayatAttendance();

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content:
                                                    Text("Absensi berhasil"),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e, stack) {
                                          print(">>> ERROR NAVIGASI: $e");
                                          print(stack);
                                        }
                                      }
                                    : null,
                               style: ElevatedButton.styleFrom(
                                  backgroundColor: todayAttendance != null
                                      ? const Color(0xff2E7D32)
                                      : (canAttendance
                                          ? const Color(0xffF4D03F)
                                          : Colors.grey),
                                  foregroundColor: todayAttendance != null
                                      ? Colors.white
                                      : Colors.black,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  todayAttendance != null
                                      ? "Sudah Melakukan Absensi"
                                      : (canAttendance
                                          ? "Lakukan Absensi"
                                          : "Di Luar Area Absensi"),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      /// ================= BOTTOM NAV =================
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xff1E5631),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xffF4D03F),
          unselectedItemColor: Colors.white70,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PengumumanPage(),
                ),
              );
            }

            if (index == 2) {
              Navigator.pushNamed(context, "/profile");
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: "Pengumuman",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

Widget _absensiView(
  BuildContext context,
  AttendanceSetting setting,
  bool canAttendance,
  Map<String, dynamic>? todayAttendance,
  VoidCallback onAbsensiBerhasil,
) {
  final bool sudahAbsen = todayAttendance != null;

  final String statusText =
      sudahAbsen ? (todayAttendance["status"] ?? "Hadir") : "-";

  final String jamText = sudahAbsen
      ? ((todayAttendance["jam_masuk"] ?? "").toString().length >= 5
          ? todayAttendance["jam_masuk"].toString().substring(0, 5)
          : "-")
      : "-";

  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Row(
            children: [
              Icon(Icons.person, size: 18),
              SizedBox(width: 6),
              Text("Status"),
            ],
          ),
          Row(
            children: [
              Icon(Icons.access_time, size: 18),
              SizedBox(width: 6),
              Text("Waktu Absensi"),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(statusText, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(jamText, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        "Pastikan Anda Melakukan Absensi\nSebelum ${setting.jamTerlambat.substring(0, 5)}",
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          onPressed: (canAttendance && !sudahAbsen)
              ? () async {
                  print(">>> TOMBOL ABSENSI (tab Absensi) DITEKAN <<<");
                  try {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendancePage(),
                      ),
                    );

                    print(">>> RESULT = $result <<<");

                    if (result == true && context.mounted) {
                      onAbsensiBerhasil();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Absensi berhasil"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e, stack) {
                    print(">>> ERROR NAVIGASI: $e");
                    print(stack);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: sudahAbsen
                ? const Color(0xff2E7D32)
                : (canAttendance ? const Color(0xffF4D03F) : Colors.grey),
            foregroundColor: sudahAbsen ? Colors.white : Colors.black,
            disabledBackgroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            sudahAbsen
                ? "Sudah Melakukan Absensi"
                : (canAttendance ? "Lakukan Absensi" : "Di Luar Area Absensi"),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _riwayatView(List<dynamic> riwayatList, bool isLoading, BuildContext context) {
  if (isLoading) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  if (riwayatList.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text("Belum ada riwayat absensi")),
    );
  }

  final latest = riwayatList.first; // data absensi terbaru

  String tanggal = "-";
  try {
    final parsedDate = DateTime.parse(latest["tanggal"]);
    tanggal = DateFormat("EEEE dd-MM-yyyy", "id_ID").format(parsedDate);
  } catch (_) {}

  final String jamMasuk = (latest["jam_masuk"] ?? "").toString().length >= 5
      ? latest["jam_masuk"].toString().substring(0, 5)
      : "-";
  final String status = latest["status"] ?? "-";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Status Kehadiran",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(status, style: const TextStyle(fontSize: 13, color: Colors.grey)),

      const SizedBox(height: 18),

      /// TIMELINE (titik - garis putus2 - icon - garis putus2 - titik)
      Row(
        children: [
          _dot(),
          Expanded(child: _dashedLine()),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xff1E5631),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge, size: 16, color: Colors.white),
          ),
          Expanded(child: _dashedLine()),
          _dot(),
        ],
      ),

      const SizedBox(height: 18),

      /// TANGGAL & WAKTU ABSENSI
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tanggal", style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(tanggal, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Waktu Absensi", style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(jamMasuk, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),

      const SizedBox(height: 20),

      /// TOMBOL LIHAT SEMUA
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () => _showRiwayatSheet(context, riwayatList),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffF4D03F),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("Lihat Semua", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );
}
Widget _dot() {
  return Container(
    width: 12,
    height: 12,
    decoration: const BoxDecoration(
      color: Color(0xff1E5631),
      shape: BoxShape.circle,
    ),
  );
}

Widget _dashedLine() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _DashedLinePainter(),
    ),
  );
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff1E5631)
      ..strokeWidth = 2;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showRiwayatSheet(BuildContext context, List<dynamic> riwayatList) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Riwayat Absensi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: _riwayatListLama(riwayatList), // isi list lama (card per item)
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
Widget _riwayatListLama(List<dynamic> riwayatList) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: riwayatList.map((item) {
      String tanggal = "-";
      try {
        final parsedDate = DateTime.parse(item["tanggal"]);
        tanggal = DateFormat("dd-MM-yyyy", "id_ID").format(parsedDate);
      } catch (_) {}

      final String jamMasuk = (item["jam_masuk"] ?? "").toString().length >= 5
          ? item["jam_masuk"].toString().substring(0, 5)
          : "-";
      final String status = item["status"] ?? "-";

      final bool isHadir = status == "Hadir";

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xffF7F7F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: TextStyle(
                color: isHadir ? const Color(0xff2E7D32) : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tanggal", style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        tanggal,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Waktu Absensi",
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        jamMasuk,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList(),
  );
}