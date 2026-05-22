class Destination {
  final String? id;
  final String name;
  final String province;
  final String price;
  final String imagePath;
  final String bgBlurPath;
  final double latitude;
  final double longitude;

  const Destination({
    this.id,
    required this.name,
    required this.province,
    required this.price,
    required this.imagePath,
    required this.bgBlurPath,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final String idVal = (json['_id'] ?? json['id'] ?? '') as String;
    final String nameVal = (json['title'] ?? json['name'] ?? '') as String;
    final String provinceVal = (json['state'] ?? json['city'] ?? json['province'] ?? '') as String;

    final sample = findSampleDestination(nameVal);

    return Destination(
      id: idVal.isNotEmpty ? idVal : null,
      name: nameVal.isNotEmpty ? nameVal : (sample?.name ?? ''),
      province: provinceVal.isNotEmpty ? provinceVal : (sample?.province ?? ''),
      price: (json['price'] ?? sample?.price ?? 'Chỉ từ 1.5 triệu đồng') as String,
      imagePath: (json['imagePath'] ?? sample?.imagePath ?? 'assets/images/halong.jpg') as String,
      bgBlurPath: (json['bgBlurPath'] ?? json['imagePath'] ?? sample?.bgBlurPath ?? 'assets/images/halong.jpg') as String,
      latitude: ((json['latitude'] ?? sample?.latitude ?? 0.0) as num).toDouble(),
      longitude: ((json['longitude'] ?? sample?.longitude ?? 0.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'province': province,
      'price': price,
      'imagePath': imagePath,
      'bgBlurPath': bgBlurPath,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

Destination? findSampleDestination(String name) {
  if (name.isEmpty) return null;
  for (var d in sampleDestinations) {
    if (d.name.toLowerCase().trim() == name.toLowerCase().trim()) {
      return d;
    }
  }
  for (var d in sampleDestinations) {
    if (d.name.toLowerCase().contains(name.toLowerCase()) || 
        name.toLowerCase().contains(d.name.toLowerCase())) {
      return d;
    }
  }
  return null;
}


const List<Destination> sampleDestinations = [
  Destination(
    name: 'Hạ Long Bay',
    province: 'Quảng Ninh',
    price: 'Chỉ từ 3 triệu đồng',
    imagePath: 'assets/images/halong.jpg',
    bgBlurPath: 'assets/images/halong.jpg',
    latitude: 20.9101,
    longitude: 107.1839,
  ),
  Destination(
    name: 'Hội An',
    province: 'Quảng Nam',
    price: 'Chỉ từ 2 triệu đồng',
    imagePath: 'assets/images/Hoi An.jpg',
    bgBlurPath: 'assets/images/Hoi An.jpg',
    latitude: 15.8801,
    longitude: 108.3380,
  ),
  Destination(
    name: 'Đà Nẵng',
    province: 'Đà Nẵng',
    price: 'Chỉ từ 1.5 triệu đồng',
    imagePath: 'assets/images/da_nang.jpg',
    bgBlurPath: 'assets/images/da_nang.jpg',
    latitude: 16.0544,
    longitude: 108.2022,
  ),
  Destination(
    name: 'Phong Nha',
    province: 'Quảng Bình',
    price: 'Chỉ từ 1 triệu đồng',
    imagePath: 'assets/images/phongnhakebang.jpg',
    bgBlurPath: 'assets/images/phongnhakebang.jpg',
    latitude: 17.5878,
    longitude: 106.2731,
  ),
];
