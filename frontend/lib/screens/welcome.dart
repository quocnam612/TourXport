// import 'package:flutter/material.dart';
// import 'login.dart';

// class WelcomeScreen extends StatelessWidget {
//   const WelcomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           /// 🔹 1. Background Image (Giữ nguyên)
//           Positioned.fill(
//             child: Image.asset(
//               "assets/images/halong.jpg",
//               fit: BoxFit.cover,
//             ),
//           ),

//           /// 🔹 2. CẢI TIẾN: Thêm Overlay Gradient phía trên (Top Overlay)
//           /// Giúp làm tối nhẹ phần trên màn hình để LOGO NỔI BẬT HƠN
//           Positioned.fill(
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   stops: const [0.0, 0.3, 0.7, 1.0], // Kiểm soát độ mờ
//                   colors: [
//                     Colors.black.withOpacity(0.6), // Tối hơn ở trên cùng
//                     Colors.black.withOpacity(0.3), // Mờ dần xuống
//                     Colors.transparent,
//                     Colors.black.withOpacity(0.7), // Tối lại ở dưới cùng cho text
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           /// 🔹 3. Content
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 children: [
//                   const Spacer(flex: 2),

//                   /// 🔹 LOGO
//                   Column(
//                     children: [
//                       Image.asset(
//                         "assets/images/logo.png",
//                         height: 150,
//                         fit: BoxFit.contain,
//                       ),
//                       const SizedBox(height: 15),
//                     ],
//                   ),
//                   const Spacer(flex: 4), 

//                   /// 🔹 Khám phá Việt Nam
//                   Column(
//                     children: [
//                       const Text(
//                         "KHÁM PHÁ",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 30, 
//                           fontWeight: FontWeight.w400,
//                           letterSpacing: 3,
//                         ),
//                       ),
//                       const Text(
//                         "VIỆT NAM",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 40,
//                           fontWeight: FontWeight.w400,
//                           letterSpacing: 4,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 10),

//                   /// 🔹 Description (Dòng chữ nhỏ bên dưới)
//                   Text(
//                     "Tìm điểm đến phù hợp cho bạn\nvới TourXport",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.8),
//                       fontSize: 14,
//                       height: 1.5,
//                       fontWeight: FontWeight.w300,
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   /// 🔹 Button (Giữ nguyên)
//                   InkWell(
//                     onTap: () {
//                       showModalBottomSheet(
//                         context: context,
//                         isScrollControlled: true,
//                         backgroundColor: Colors.transparent,
//                         builder: (context) => const LoginScreen(),
//                       );
//                     },
//                     child: Container(
//                       width: double.infinity,
//                       height: 55,
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.5),
//                         borderRadius: BorderRadius.circular(30),
//                         border: Border.all(color: Colors.white30),
//                       ),
//                       child: const Center(
//                         child: Text(
//                           "BẮT ĐẦU NGAY",
//                           style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }