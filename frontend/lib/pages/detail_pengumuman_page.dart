import 'package:flutter/material.dart';
import '../models/pengumuman_model.dart';
import '../pages/login_page.dart'; // sumber AppColors

class DetailPengumumanPage extends StatelessWidget {
  final Pengumuman pengumuman;

  const DetailPengumumanPage({super.key, required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightest,

      body: SafeArea(
        child: Column(
          children: [

            /// ================= HEADER =================
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    icon: const Icon(Icons.arrow_back,color: Colors.white),
                    onPressed: (){
                      Navigator.pop(context);
                    },
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        "Detail Pengumuman",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 40)

                ],
              ),
            ),

            /// ================= CONTENT =================
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),

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

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// ================= GAMBAR =================
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          pengumuman.foto,
                          width: double.infinity,
                          height: 180,
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

                      const SizedBox(height: 16),

                      /// ================= JUDUL =================
                      Text(
                        pengumuman.judul,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkest,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ================= TANGGAL =================
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.medium,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pengumuman.tanggal ?? "",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// ================= DESKRIPSI =================
                      Text(
                        pengumuman.deskripsi ?? "",
                        style: const TextStyle(
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}