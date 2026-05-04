class Destination {
  final String name;
  final String province;
  final String price;
  final String imagePath;
  final String bgBlurPath;

  const Destination({
    required this.name,
    required this.province,
    required this.price,
    required this.imagePath,
    required this.bgBlurPath,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: (json['name'] ?? '') as String,
      province: (json['province'] ?? '') as String,
      price: (json['price'] ?? '') as String,
      imagePath: (json['imagePath'] ?? '') as String,
      bgBlurPath: (json['bgBlurPath'] ?? json['imagePath'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'province': province,
      'price': price,
      'imagePath': imagePath,
      'bgBlurPath': bgBlurPath,
    };
  }
}

const List<Destination> sampleDestinations = [
  Destination(
    name: 'Hạ Long Bay',
    province: 'Quảng Ninh',
    price: 'Chỉ từ 3 triệu đồng',
    imagePath: 'assets/images/halong.jpg',
    bgBlurPath: 'assets/images/halong.jpg',
  ),
  Destination(
    name: 'Hội An',
    province: 'Hà Nội',
    price: 'Chỉ từ 2 triệu đồng',
    imagePath: 'assets/images/Hoi An.jpg',
    bgBlurPath: 'assets/images/Hoi An.jpg',
  ),
  Destination(
    name: 'Đà Nẵng',
    province: 'Sài Gòn',
    price: 'Chỉ từ 1.5 triệu đồng',
    imagePath: 'assets/images/da_nang.jpg',
    bgBlurPath: 'assets/images/da_nang.jpg',
  ),
  Destination(
    name: 'Phong Nha',
    province: 'Đồng Tháp',
    price: 'Chỉ từ 1 triệu đồng',
    imagePath: 'assets/images/phongnhakebang.jpg',
    bgBlurPath: 'assets/images/phongnhakebang.jpg',
  ),
];
