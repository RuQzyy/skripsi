import 'package:flutter/material.dart';
import '../models/pengumuman_model.dart';

class DetailPengumumanPage extends StatelessWidget {
  final Pengumuman pengumuman;

  const DetailPengumumanPage({super.key, required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEDEDED),

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
                    Color(0xff1E5631),
                    Color(0xff2E7D32),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(60),
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
                          fontSize: 18,
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
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// ================= JUDUL =================
                      Text(
                        pengumuman.judul,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ================= TANGGAL =================
                      Row(
                        children: [
                          const Icon(Icons.access_time,size: 16),
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