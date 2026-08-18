import 'package:flutter/material.dart';
import '../models/pengumuman_model.dart';
import '../services/pengumuman_service.dart';
import '../pages/detail_pengumuman_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/profile_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../utils/page_transition.dart';
import '../pages/login_page.dart'; // sumber AppColors

class PengumumanPage extends StatefulWidget {
  const PengumumanPage({super.key});

  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage> {
  List<Pengumuman> pengumumanList = [];

  int page = 1;

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  ScrollController scrollController = ScrollController();

  Future<void> getPengumuman() async {
    if (!hasMore) return;

    if (page == 1) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }

    setState(() {});

    try {
      final result = await PengumumanService.getPengumuman(page: page);

      List<Pengumuman> data = result["data"];
      int lastPage = result["last_page"];

      setState(() {
        pengumumanList.addAll(data);

        if (page >= lastPage) {
          hasMore = false;
        } else {
          page++;
        }

        isLoading = false;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  String getWaktuPengumuman(String tanggal) {
    DateTime tanggalPost = DateTime.parse(tanggal);
    DateTime sekarang = DateTime.now();

    Duration selisih = sekarang.difference(tanggalPost);

    if (selisih.inDays > 0) {
      return "${selisih.inDays} hari";
    } else if (selisih.inHours > 0) {
      return "${selisih.inHours} jam";
    } else if (selisih.inMinutes > 0) {
      return "${selisih.inMinutes} menit";
    } else {
      return "Baru saja";
    }
  }
  
  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        if (!isActive) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    getPengumuman();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && hasMore) {
          getPengumuman();
        }
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightest,
      body: SafeArea(
        child: Column(
          children: [
            /// ===================== HEADER =====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.darkest,
                    AppColors.mediumDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Pengumuman",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${pengumumanList.length}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkest,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ===================== LIST PENGUMUMAN =====================
            Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.mediumDark,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          page = 1;
                          hasMore = true;
                          pengumumanList.clear();

                          await getPengumuman();
                        },
                        color: AppColors.mediumDark,
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: pengumumanList.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < pengumumanList.length) {
                              final pengumuman = pengumumanList[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.darkest.withOpacity(0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailPengumumanPage(
                                          pengumuman: pengumuman,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// FOTO
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                        child: Image.network(
                                          pengumuman.foto,
                                          width: double.infinity,
                                          height: MediaQuery.of(context).size.width * 0.45,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 180,
                                              color: AppColors.light.withOpacity(0.3),
                                              child: Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: AppColors.medium,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      /// ISI
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pengumuman.judul,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.darkest,
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: AppColors.medium,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    pengumuman.tanggal,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black45,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 14),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.mediumDark
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    getWaktuPengumuman(
                                                      pengumuman.tanggal,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.darkest,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),

                                                ElevatedButton.icon(
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
                                                  icon: const Icon(
                                                    Icons.arrow_forward,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    "Detail",
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.mediumDark,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(30),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.mediumDark,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      )),
          ],
        ),
      ),
           /// ================= BOTTOM NAV =================
      bottomNavigationBar: CurvedNavigationBar(
        index: 1, // PENGUMUMAN AKTIF
        height: 60,
        backgroundColor: Colors.transparent, // biar menyatu dengan body
        color: AppColors.darkest, // warna bar
        buttonBackgroundColor: AppColors.mediumDark, // warna tombol yang aktif (yang "nongol")
        animationDuration: const Duration(milliseconds: 400),
        animationCurve: Curves.easeInOut,
                items: [
          _navItem(icon: Icons.home, label: "Home", isActive: false),
          _navItem(icon: Icons.campaign, label: "Pengumuman", isActive: true),
          _navItem(icon: Icons.person, label: "Profile", isActive: false),
        ],
                onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              fadePageRoute(const DashboardPage()),
            );
          }

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              fadePageRoute(const ProfilePage()),
            );
          }
        },
      ),
    );
  }
}