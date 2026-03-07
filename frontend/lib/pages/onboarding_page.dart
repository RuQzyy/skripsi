import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {

  int currentPage = 0;

  final liquidController = LiquidController();

  final List<Widget> pages = [

    const OnboardItem(
      image: "assets/images/2.jpg",
      title: "Sistem Absensi Berbasis Face Recognition",
      desc:
          "AbsenKITA menghadirkan sistem absensi modern dengan teknologi Face Recognition yang mampu mengidentifikasi pengguna secara otomatis, cepat, dan akurat. Fitur ini memastikan bahwa setiap proses absensi dilakukan oleh pengguna yang sah, sehingga meningkatkan keamanan, kepercayaan, dan integritas data kehadiran di lingkungan sekolah.",
    ),

    const OnboardItem(
      image: "assets/images/3.jpg",
      title: "Verifikasi Kehadiran dengan Geolokasi",
      desc:
          "Aplikasi ini dilengkapi dengan teknologi geolokasi yang memungkinkan sistem memverifikasi lokasi pengguna secara real-time. Dengan demikian, absensi hanya dapat dilakukan ketika pengguna berada di area sekolah, membantu meningkatkan kedisiplinan serta memastikan validitas data kehadiran.",
    ),

    const OnboardItem(
      image: "assets/images/4.jpg",
      title: "Notifikasi Kehadiran Terintegrasi WhatsApp",
      desc:
          "Setiap aktivitas absensi akan secara otomatis mengirimkan notifikasi melalui WhatsApp kepada pihak terkait. Integrasi ini memungkinkan pemantauan kehadiran secara langsung, meningkatkan transparansi, serta mempermudah komunikasi antara sekolah, siswa, dan orang tua.",
    ),

  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          /// LIQUID SWIPE
          LiquidSwipe(
            pages: pages,
            liquidController: liquidController,
            enableSideReveal: false,
            waveType: WaveType.liquidReveal,
            fullTransitionValue: 600,
            onPageChangeCallback: (index) {
              setState(() {
                currentPage = index;
              });
            },
          ),

          /// LOGO + TITLE
          Align(
            alignment: const Alignment(0, -0.65), 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Image.asset(
                  "assets/logo/fix.png",
                  height: 80,
                ),

                const SizedBox(height: 12),

                const Text(
                  "AbsenKITA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

              ],
            ),
          ),

          /// DOT INDICATOR
          Positioned(
            bottom: 110, 
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => buildDot(index),
              ),
            ),
          ),

          /// BUTTON
          Positioned(
            bottom: 40, // jarak dari bawah diperbesar
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () {

                if (currentPage < pages.length - 1) {

                  liquidController.animateToPage(
                    page: currentPage + 1,
                    duration: 400,
                  );

                } else {

                  /// pindah ke login
                  Navigator.pushReplacementNamed(context, "/login");

                }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 3,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                currentPage == pages.length - 1
                    ? "Mulai Sekarang"
                    : "Selanjutnya",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  /// DOT BUILDER
  Widget buildDot(int index) {

    bool isActive = currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isActive ? 18 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}






/// ONBOARD ITEM
class OnboardItem extends StatelessWidget {

  final String image;
  final String title;
  final String desc;

  const OnboardItem({
    super.key,
    required this.image,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [

        /// BACKGROUND IMAGE
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),

        /// GRADIENT OVERLAY
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.85),
              ],
              begin: Alignment.center,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        /// TEXT CONTENT
        Positioned(
          bottom: 180, // dinaikkan supaya tidak tabrakan dot & button
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

            ],
          ),
        ),

      ],
    );
  }
}