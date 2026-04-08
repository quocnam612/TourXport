// import 'package:flutter/material.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   bool isEmailSelected = true;
//   bool _isPasswordObscured = true; // Trạng thái chọn Email hay Điện thoại

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // 1. Header Image
//             _buildHeaderImage(),

//             // 2. Login Form Card
//             Transform.translate(
//               offset: const Offset(0, -30),
//               child: Container(
//                 width: double.infinity,
//                 constraints: BoxConstraints(
//                   minHeight: MediaQuery.of(context).size.height - 250,
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(30),
//                     topRight: Radius.circular(30),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text('Đăng nhập', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 25),

//                     // SLIDING TAB SECTION
//                     _buildSlidingTab(),

//                     const SizedBox(height: 25),

//                     // ANIMATED INPUT SECTION
//                     AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 200),
//                       child: _buildInputField(
//                         key: ValueKey<bool>(isEmailSelected),
//                         label: isEmailSelected ? "Địa chỉ Email" : "Số điện thoại",
//                         hint: isEmailSelected ? "abc@gmail.com" : "09xx xxx xxx",
//                         icon: isEmailSelected ? Icons.email_outlined : Icons.phone_android_outlined,
//                         isNumber: !isEmailSelected,
//                       ),
//                     ),

//                     const SizedBox(height: 15),
//                     _buildInputField(label: "Mật khẩu", hint: "123abc", isPassword: true, icon: Icons.lock_outline),

//                     const SizedBox(height: 25),

//                     // LOGIN BUTTON
//                     _buildPrimaryButton("Tiếp tục"),

//                     const SizedBox(height: 30),
//                     _buildSocialSection(),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- WIDGET COMPONENTS ---

//   Widget _buildHeaderImage() {
//     return Container(
//       height: 280,
//       width: double.infinity,
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage('assets/images/login.png'),
//           fit: BoxFit.cover,
//         ),
//       ),
//     );
//   }

//   Widget _buildSlidingTab() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         double tabWidth = constraints.maxWidth / 2;
//         return Container(
//           height: 50,
//           decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(25)),
//           child: Stack(
//             children: [
//               AnimatedPositioned(
//                 duration: const Duration(milliseconds: 250),
//                 curve: Curves.easeInOut,
//                 left: isEmailSelected ? tabWidth : 0,
//                 top: 4, bottom: 4,
//                 child: Container(
//                   width: tabWidth - 8,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(21),
//                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
//                   ),
//                 ),
//               ),
//               Row(
//                 children: [
//                   _tabButton("Điện thoại", !isEmailSelected, () => setState(() => isEmailSelected = false)),
//                   _tabButton("Email", isEmailSelected, () => setState(() => isEmailSelected = true)),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _tabButton(String title, bool active, VoidCallback onTap) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         behavior: HitTestBehavior.opaque,
//         child: Center(
//           child: AnimatedDefaultTextStyle(
//             duration: const Duration(milliseconds: 300),
//             style: TextStyle(
//               color: active ? Colors.black : Colors.grey.shade600,
//               fontWeight: active ? FontWeight.bold : FontWeight.normal,
//               fontSize: 14,
//             ),
//             child: Text(title),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInputField({
//     Key? key,
//     required String label,
//     required String hint,
//     required IconData icon,
//     bool isPassword = false,
//     bool isNumber = false,
//   }) {
//     return Column(
//       key: key,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
//         const SizedBox(height: 8),
//         TextField(
//           // Sử dụng biến trạng thái nếu đây là ô mật khẩu
//           obscureText: isPassword ? _isPasswordObscured : false,
//           keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
//           decoration: InputDecoration(
//             prefixIcon: Icon(icon, size: 20, color: Colors.grey),
            
//             hintText: hint,
//             hintStyle: TextStyle(
//               color: Colors.grey.withOpacity(0.3), 
//               fontSize: 14,
//               fontWeight: FontWeight.w400, 
//             ),
//             // PHẦN HIỆU ỨNG ICON MẮT
//             suffixIcon: isPassword 
//               ? GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _isPasswordObscured = !_isPasswordObscured;
//                     });
//                   },
//                   child: AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 250),
//                     transitionBuilder: (Widget child, Animation<double> animation) {
//                       // Hiệu ứng xoay nhẹ và phóng to khi đổi icon
//                       return ScaleTransition(
//                         scale: animation,
//                         child: RotationTransition(
//                           turns: animation,
//                           child: child,
//                         ),
//                       );
//                     },
//                     child: Icon(
//                       _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//                       key: ValueKey<bool>(_isPasswordObscured), // Cần Key để chạy hiệu ứng
//                       color: Colors.grey,
//                       size: 20,
//                     ),
//                   ),
//                 )
//               : null,
              
//             filled: true,
//             fillColor: Colors.grey.shade100,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(20), 
//               borderSide: BorderSide.none
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPrimaryButton(String title) {
//     return SizedBox(
//       width: double.infinity,
//       height: 55,
//       child: ElevatedButton(
//         onPressed: () {},
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.cyan.shade300,
//           elevation: 0,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         ),
//         child: Text(title, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }

//   Widget _buildSocialSection() {
//     return Column(
//       children: [
//         const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Đăng nhập bằng", style: TextStyle(color: Colors.grey, fontSize: 12))), Expanded(child: Divider())]),
//         const SizedBox(height: 25),
//         Wrap(
//           spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
//           children: [
//             _socialIcon("Google", "assets/icons/gg_logo.png"),
//             _socialIcon("X", "assets/icons/x_logo.png"),
//             _socialIcon("Facebook", "assets/icons/fb_logo.png", isWide: true),
//           ],
//         ),
//         const SizedBox(height: 30),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text("Bạn chưa có tài khoản? "),
//             GestureDetector(onTap: () {}, child: const Text("Đăng ký", style: TextStyle(fontWeight: FontWeight.bold))),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _socialIcon(String label, String path, {bool isWide = false}) {
//     return Container(
//       width: isWide ? 260 : 150,
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
//       decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Image.asset(path, width: 20, height: 20),
//           const SizedBox(width: 10),
//           Flexible(child: Text("Tiếp tục bằng $label", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
//         ],
//       ),
//     );
//   }
// } 