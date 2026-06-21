import 'package:flutter/material.dart';
import '../models/pengumuman_model.dart';
import '../services/pengumuman_service.dart';
import '../pages/detail_pengumuman_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/profile_page.dart';

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
      backgroundColor: const Color(0xffEDEDED),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
              height: MediaQuery.of(context).size.width * 0.30,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xff1E5631),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(60),
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
                        fontSize: 20,
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
                      color: const Color(0xffF4D03F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${pengumumanList.length}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// LIST PENGUMUMAN
            Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () async {
                          page = 1;
                          hasMore = true;
                          pengumumanList.clear();

                          await getPengumuman();
                        },
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
                                      color: Colors.black.withOpacity(0.05),
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
                                              color: Colors.grey.shade300,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.grey,
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
                                                color: Color(0xff1E5631),
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    pengumuman.tanggal,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
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
                                                    color: const Color(0xffF4D03F)
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    getWaktuPengumuman(
                                                      pengumuman.tanggal,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xff1E5631),
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
                                                        const Color(0xffF4D03F),
                                                    foregroundColor: Colors.black,
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
                                  child: CircularProgressIndicator(),
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

          currentIndex: 1, // PROFILE AKTIF

          onTap: (index) {

            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardPage(),
                ),
              );
            }

            if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
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
