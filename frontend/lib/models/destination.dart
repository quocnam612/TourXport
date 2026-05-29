import 'package:flutter/material.dart';

const String destinationPlaceholderPath = 'assets/images/placeholder.png';

class Destination {
  final String? id;
  final String name;
  final String province;
  final String price;
  final String imagePath;
  final String bgBlurPath;
  final double latitude;
  final double longitude;
  final String type; // e.g. 'Địa điểm', 'Nhà hàng', 'Khách sạn'

  const Destination({
    this.id,
    required this.name,
    required this.province,
    required this.price,
    required this.imagePath,
    required this.bgBlurPath,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.type = 'Địa điểm',
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final String idVal = (json['_id'] ?? json['id'] ?? '').toString();
    final String nameVal = (json['title'] ?? json['name'] ?? '').toString();
    final String provinceVal = (json['state'] ?? json['city'] ?? json['province'] ?? '').toString();
    final String typeVal = (json['type'] ?? 'Địa điểm').toString();

    final sample = findSampleDestination(nameVal);

    // TripAdvisor image.url or direct imageUrl / imagePath
    String imgUrl = '';
    if (json['image'] != null && json['image'] is Map) {
      imgUrl = (json['image']['url'] ?? '').toString();
    }
    if (imgUrl.isEmpty) {
      imgUrl = (json['imageUrl'] ?? json['imagePath'] ?? destinationPlaceholderPath).toString();
    }

    // Coordinates extraction: GeoJSON is [lng, lat]
    double latVal = 0.0;
    double lngVal = 0.0;
    if (json['location'] != null && json['location'] is Map) {
      final loc = json['location'];
      if (loc['coordinates'] != null && loc['coordinates'] is List && loc['coordinates'].length >= 2) {
        lngVal = (loc['coordinates'][0] as num).toDouble();
        latVal = (loc['coordinates'][1] as num).toDouble();
      }
    } else {
      latVal = ((json['latitude'] ?? sample?.latitude ?? 0.0) as num).toDouble();
      lngVal = ((json['longitude'] ?? sample?.longitude ?? 0.0) as num).toDouble();
    }

    final String parsedName = _translateName(nameVal.isNotEmpty ? nameVal : (sample?.name ?? ''));
    final String parsedProvince = _translateProvince(provinceVal.isNotEmpty ? provinceVal : (sample?.province ?? ''));


    // Only fall back to the app placeholder if the image URL is empty or the legacy default image.
    if (imgUrl.isEmpty || imgUrl == 'assets/images/halong.jpg') {
      imgUrl = getLocalFallbackAsset(parsedName.isNotEmpty ? parsedName : parsedProvince);
    }

    return Destination(
      id: idVal.isNotEmpty ? idVal : null,
      name: parsedName,
      province: parsedProvince,
      price: (json['price'] ?? json['priceRange'] ?? sample?.price ?? 'Chỉ từ 1.5 triệu đồng').toString(),
      imagePath: imgUrl,
      bgBlurPath: imgUrl,
      latitude: latVal,
      longitude: lngVal,
      type: typeVal,
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
      'type': type,
    };
  }

  static Widget buildImage(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (path.isEmpty) {
      return Image.asset(
        destinationPlaceholderPath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF2A4A3E),
          width: width,
          height: height,
          child: const Center(
            child: Icon(Icons.image, color: Colors.white38, size: 40),
          ),
        ),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Load the authentic network image from the database completely unchanged,
      // using browser header spoofing to prevent access blocks or rate-limiting.
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        filterQuality: FilterQuality.high,
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.tripadvisor.com/',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF1E2E2A),
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
                ),
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            destinationPlaceholderPath,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => Image.asset(
              destinationPlaceholderPath,
              fit: fit,
              width: width,
              height: height,
            ),
          );
        },
      );
    }

    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Image.asset(
        destinationPlaceholderPath,
        fit: fit,
        width: width,
        height: height,
      ),
    );
  }

  static String _translateName(String name) {
    final String trimmed = name.trim();
    
    final Map<String, String> translationMap = {
      'War Remnants Museum': 'Bảo tàng Chứng tích Chiến tranh',
      'Cu Chi Tunnels': 'Địa đạo Củ Chi',
      'Bưu điện trung tâm Sài Gòn': 'Bưu điện Trung tâm Sài Gòn',
      'Lăng Chủ Tịch Hồ Chí Minh': 'Lăng Chủ tịch Hồ Chí Minh',
      'Hoàng Thành Huế': 'Đại Nội Huế (Hoàng Thành)',
      'Văn Miếu Q': 'Văn Miếu - Quốc Tử Giám',
      'Hoa Lo Prison': 'Di tích Nhà tù Hỏa Lò',
      'Núi Ngũ Hành Sơn': 'Danh thắng Ngũ Hành Sơn',
      'Vietnam Museum of Ethnology': 'Bảo tàng Dân tộc học Việt Nam',
      'Tháp Tài Chính Bitexco': 'Tòa tháp Bitexco Financial',
      'Bảo tàng Phụ nữ Việt Nam': 'Bảo tàng Phụ nữ Việt Nam',
      'Lady Buddha': 'Tượng Phật Bà Chùa Linh Ứng',
      'Nhà hát Thành Phố Hồ Chí Minh': 'Nhà hát Thành phố Hồ Chí Minh',
      'Chùa Thiên Mụ': 'Chùa Thiên Mụ',
      'Crazy House': 'Biệt thự Hằng Nga (Crazy House)',
      'Thánh Địa Mỹ Sơn': 'Thánh địa Mỹ Sơn',
      'Khu di tích chủ tịch Hồ Chí Minh tại Phủ Chủ Tịch': 'Di tích Phủ Chủ Tịch',
      'Quảng trường Hồ Chí Minh': 'Quảng trường Hồ Chí Minh',
      'Đồi Cát Trắng': 'Đồi Cát Trắng (Mũi Né)',
      'Nhà Thờ Lớn': 'Nhà Thờ Lớn Hà Nội',
      'Tam Cốc-Bích Động': 'Khu du lịch Tam Cốc - Bích Động',
      'My Khe Beach': 'Bãi biển Mỹ Khê',
      'Trang An Grottoes': 'Khu du lịch sinh thái Tràng An',
      'Fairy Stream (Suoi Tien)': 'Suối Tiên (Mũi Né)',
      'Fairy Stream': 'Suối Tiên (Mũi Né)',
      'Mausoleum of Emperor Minh Mang': 'Lăng Minh Mạng',
      'Tomb of Tu Duc': 'Lăng Tự Đức',
      'Long Son Pagoda': 'Chùa Long Sơn',
      'Cat Ba National Park': 'Vườn quốc gia Cát Bà',
      'Fansipan Mountain': 'Đỉnh núi Fansipan',
      'Golden Bridge': 'Cầu Vàng (Bà Nà Hills)',
      'Ba Na Hills': 'Khu du lịch Bà Nà Hills',
    };

    return translationMap[trimmed] ?? trimmed;
  }

  static String _translateProvince(String province) {
    final String trimmed = province.trim();
    final Map<String, String> provinceMap = {
      'Ho Chi Minh City': 'TP. Hồ Chí Minh',
      'Hanoi': 'Hà Nội',
      'Quang Nam': 'Quảng Nam',
      'Quang Ninh': 'Quảng Ninh',
      'Da Nang': 'Đà Nẵng',
      'Thua Thien Hue': 'Thừa Thiên Huế',
      'Hue': 'Thừa Thiên Huế',
      'Nha Trang': 'Khánh Hòa',
      'Khanh Hoa': 'Khánh Hòa',
      'Lao Cai': 'Lào Cai',
      'Sapa': 'Lào Cai',
      'Ninh Binh': 'Ninh Bình',
      'Binh Thuan': 'Bình Thuận',
      'Phan Thiet': 'Bình Thuận',
      'Mui Ne': 'Bình Thuận',
      'Kien Giang': 'Kiên Giang',
      'Phu Quoc': 'Kiên Giang',
      'Ba Ria-Vung Tau': 'Bà Rịa - Vũng Tàu',
      'Vung Tau': 'Bà Rịa - Vũng Tàu',
    };
    return provinceMap[trimmed] ?? trimmed;
  }
}

List<Destination> getFallbackDestinationsForProvince(String province) {
  final Map<String, List<Destination>> map = {
    'Đà Nẵng': [
      Destination(
        name: 'Cầu Vàng (Golden Bridge)',
        province: 'Đà Nẵng',
        price: 'Chỉ từ 900.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/18/85/67/6f/caption.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/18/85/67/6f/caption.jpg',
        latitude: 15.9983,
        longitude: 107.9961,
      ),
      Destination(
        name: 'Bà Nà Hills',
        province: 'Đà Nẵng',
        price: 'Chỉ từ 900.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/4a/4a/6a/caption.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/4a/4a/6a/caption.jpg',
        latitude: 15.9958,
        longitude: 107.9864,
      ),
      Destination(
        name: 'Bãi biển Mỹ Khê',
        province: 'Đà Nẵng',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/22/e1/98/beautiful-beach.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/22/e1/98/beautiful-beach.jpg',
        latitude: 16.0628,
        longitude: 108.2435,
      ),
      Destination(
        name: 'Chùa Linh Ứng Sơn Trà',
        province: 'Đà Nẵng',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/c6/12/36/linh-ung-pagoda.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/c6/12/36/linh-ung-pagoda.jpg',
        latitude: 16.1001,
        longitude: 108.2782,
      ),
      Destination(
        name: 'Ngũ Hành Sơn',
        province: 'Đà Nẵng',
        price: 'Chỉ từ 40.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/20/cf/50/cave-inside.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/20/cf/50/cave-inside.jpg',
        latitude: 16.0121,
        longitude: 108.2635,
      ),
    ],
    'Hà Nội': [
      Destination(
        name: 'Hồ Hoàn Kiếm & Đền Ngọc Sơn',
        province: 'Hà Nội',
        price: 'Chỉ từ 30.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/11/48/45/ea/ngoc-son-temple.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/11/48/45/ea/ngoc-son-temple.jpg',
        latitude: 21.0285,
        longitude: 105.8522,
      ),
      Destination(
        name: 'Lăng Chủ tịch Hồ Chí Minh',
        province: 'Hà Nội',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/b7/c1/cf/ho-chi-minh-mausoleum.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/b7/c1/cf/ho-chi-minh-mausoleum.jpg',
        latitude: 21.0368,
        longitude: 105.8347,
      ),
      Destination(
        name: 'Văn Miếu - Quốc Tử Giám',
        province: 'Hà Nội',
        price: 'Chỉ từ 30.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/45/42/4f/van-mieu.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/45/42/4f/van-mieu.jpg',
        latitude: 21.0294,
        longitude: 105.8355,
      ),
      Destination(
        name: 'Hoàng Thành Thăng Long',
        province: 'Hà Nội',
        price: 'Chỉ từ 30.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/26/51/7f/imperial-citadel.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/26/51/7f/imperial-citadel.jpg',
        latitude: 21.0353,
        longitude: 105.8407,
      ),
      Destination(
        name: 'Chùa Một Cột',
        province: 'Hà Nội',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/e6/5b/eb/photo2jpg.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/e6/5b/eb/photo2jpg.jpg',
        latitude: 21.0358,
        longitude: 105.8336,
      ),
    ],
    'TP. Hồ Chí Minh': [
      Destination(
        name: 'Nhà thờ Đức Bà Sài Gòn',
        province: 'TP. Hồ Chí Minh',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/34/bd/ca/notre-dame.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/34/bd/ca/notre-dame.jpg',
        latitude: 10.7798,
        longitude: 106.6990,
      ),
      Destination(
        name: 'Dinh Độc Lập',
        province: 'TP. Hồ Chí Minh',
        price: 'Chỉ từ 40.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/f2/8e/31/front-view.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/f2/8e/31/front-view.jpg',
        latitude: 10.7770,
        longitude: 106.6953,
      ),
      Destination(
        name: 'Bưu điện Trung tâm Sài Gòn',
        province: 'TP. Hồ Chí Minh',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/be/89/3e/inside.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/be/89/3e/inside.jpg',
        latitude: 10.7799,
        longitude: 106.6999,
      ),
      Destination(
        name: 'Chợ Bến Thành',
        province: 'TP. Hồ Chí Minh',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/be/be/47/front-entrance.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/be/be/47/front-entrance.jpg',
        latitude: 10.7725,
        longitude: 106.6980,
      ),
      Destination(
        name: 'Tòa nhà Landmark 81',
        province: 'TP. Hồ Chí Minh',
        price: 'Chỉ từ 400.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/04/ea/1c/landmark-81.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/04/ea/1c/landmark-81.jpg',
        latitude: 10.7946,
        longitude: 106.7218,
      ),
    ],
    'Quảng Nam': [
      Destination(
        name: 'Phố cổ Hội An',
        province: 'Quảng Nam',
        price: 'Chỉ từ 80.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/a4/be/83/hoi-an-ancient-town.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/a4/be/83/hoi-an-ancient-town.jpg',
        latitude: 15.8801,
        longitude: 108.3380,
      ),
      Destination(
        name: 'Thánh địa Mỹ Sơn',
        province: 'Quảng Nam',
        price: 'Chỉ từ 150.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/45/2c/66/my-son-sanctuary.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/45/2c/66/my-son-sanctuary.jpg',
        latitude: 15.7642,
        longitude: 108.1242,
      ),
      Destination(
        name: 'Đảo Cù Lao Chàm',
        province: 'Quảng Nam',
        price: 'Chỉ từ 450.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0c/3e/cf/58/cu-lao-cham.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0c/3e/cf/58/cu-lao-cham.jpg',
        latitude: 15.9525,
        longitude: 108.5133,
      ),
      Destination(
        name: 'Rừng dừa Bảy Mẫu',
        province: 'Quảng Nam',
        price: 'Chỉ từ 150.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/41/50/41/basket-boat-tour.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/41/50/41/basket-boat-tour.jpg',
        latitude: 15.8906,
        longitude: 108.3719,
      ),
      Destination(
        name: 'Bãi biển An Bàng',
        province: 'Quảng Nam',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/69/cb/09/an-bang-beach.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/69/cb/09/an-bang-beach.jpg',
        latitude: 15.9122,
        longitude: 108.3562,
      ),
    ],
    'Quảng Ninh': [
      Destination(
        name: 'Vịnh Hạ Long',
        province: 'Quảng Ninh',
        price: 'Chỉ từ 290.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/c1/f1/8c/ha-long-bay.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/c1/f1/8c/ha-long-bay.jpg',
        latitude: 20.9101,
        longitude: 107.1839,
      ),
      Destination(
        name: 'Núi Yên Tử',
        province: 'Quảng Ninh',
        price: 'Chỉ từ 40.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/12/32/38/20/dong-pagoda.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/12/32/38/20/dong-pagoda.jpg',
        latitude: 21.1558,
        longitude: 106.7128,
      ),
      Destination(
        name: 'Bán đảo Tuần Châu',
        province: 'Quảng Ninh',
        price: 'Miễn phí vé vào',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/tuan-chau-island.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/tuan-chau-island.jpg',
        latitude: 20.9255,
        longitude: 107.0125,
      ),
      Destination(
        name: 'Đảo Cô Tô',
        province: 'Quảng Ninh',
        price: 'Vé tàu từ 200.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/50/eb/64/co-to-island.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/50/eb/64/co-to-island.jpg',
        latitude: 20.9928,
        longitude: 107.7611,
      ),
      Destination(
        name: 'Đảo Quan Lạn',
        province: 'Quảng Ninh',
        price: 'Vé tàu từ 150.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/quan-lan.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/quan-lan.jpg',
        latitude: 20.9117,
        longitude: 107.5186,
      ),
    ],
    'Thừa Thiên Huế': [
      Destination(
        name: 'Đại Nội Huế (Imperial City)',
        province: 'Thừa Thiên Huế',
        price: 'Chỉ từ 200.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/b3/ef/7c/imperial-city.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/b3/ef/7c/imperial-city.jpg',
        latitude: 16.4691,
        longitude: 107.5789,
      ),
      Destination(
        name: 'Chùa Thiên Mụ',
        province: 'Thừa Thiên Huế',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/fe/bf/bc/thien-mu-pagoda.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/fe/bf/bc/thien-mu-pagoda.jpg',
        latitude: 16.4528,
        longitude: 107.5414,
      ),
      Destination(
        name: 'Lăng Khải Định',
        province: 'Thừa Thiên Huế',
        price: 'Chỉ từ 150.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/fb/99/bd/tomb-of-khai-dinh.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/fb/99/bd/tomb-of-khai-dinh.jpg',
        latitude: 16.3986,
        longitude: 107.5900,
      ),
      Destination(
        name: 'Lăng Tự Đức',
        province: 'Thừa Thiên Huế',
        price: 'Chỉ từ 150.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/be/aa/3f/tomb-of-tu-duc.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/be/aa/3f/tomb-of-tu-duc.jpg',
        latitude: 16.4328,
        longitude: 107.5683,
      ),
      Destination(
        name: 'Cầu Trường Tiền & Sông Hương',
        province: 'Thừa Thiên Huế',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/b5/e8/38/truong-tien-bridge.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/b5/e8/38/truong-tien-bridge.jpg',
        latitude: 16.4678,
        longitude: 107.5939,
      ),
    ],
    'Khánh Hòa': [
      Destination(
        name: 'VinWonders Nha Trang',
        province: 'Khánh Hòa',
        price: 'Chỉ từ 800.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/18/64/34/00/vinwonders-nha-trang.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/18/64/34/00/vinwonders-nha-trang.jpg',
        latitude: 12.2192,
        longitude: 109.2225,
      ),
      Destination(
        name: 'Tháp Bà Po Nagar',
        province: 'Khánh Hòa',
        price: 'Chỉ từ 30.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/48/43/46/ponagar.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/48/43/46/ponagar.jpg',
        latitude: 12.2653,
        longitude: 109.1958,
      ),
      Destination(
        name: 'Đảo Hòn Tằm',
        province: 'Khánh Hòa',
        price: 'Chỉ từ 250.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/89/3e/dc/hon-tam.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/89/3e/dc/hon-tam.jpg',
        latitude: 12.1803,
        longitude: 109.2436,
      ),
      Destination(
        name: 'Chùa Long Sơn',
        province: 'Khánh Hòa',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/long-son.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/long-son.jpg',
        latitude: 12.2508,
        longitude: 109.1800,
      ),
      Destination(
        name: 'Vịnh Ninh Vân',
        province: 'Khánh Hòa',
        price: 'Miễn phí tham quan',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/ninh-van-bay.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/ninh-van-bay.jpg',
        latitude: 12.3586,
        longitude: 109.2783,
      ),
    ],
    'Lào Cai': [
      Destination(
        name: 'Đỉnh Fansipan Sapa',
        province: 'Lào Cai',
        price: 'Chỉ từ 800.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/18/85/67/6f/caption.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/18/85/67/6f/caption.jpg',
        latitude: 22.3033,
        longitude: 103.7744,
      ),
      Destination(
        name: 'Bản Cát Cát Sapa',
        province: 'Lào Cai',
        price: 'Chỉ từ 150.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/c6/12/36/cat-cat.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/c6/12/36/cat-cat.jpg',
        latitude: 22.3278,
        longitude: 103.8344,
      ),
      Destination(
        name: 'Đèo Ô Quy Hồ',
        province: 'Lào Cai',
        price: 'Miễn phí tham quan',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/be/89/3e/o-quy-ho.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/be/89/3e/o-quy-ho.jpg',
        latitude: 22.3556,
        longitude: 103.7725,
      ),
      Destination(
        name: 'Thung lũng Mường Hoa',
        province: 'Lào Cai',
        price: 'Miễn phí tham quan',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/a4/be/83/muong-hoa.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/a4/be/83/muong-hoa.jpg',
        latitude: 22.3056,
        longitude: 103.8825,
      ),
      Destination(
        name: 'Nhà thờ Đá Sapa',
        province: 'Lào Cai',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/f2/8e/31/sapa-stone-church.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/f2/8e/31/sapa-stone-church.jpg',
        latitude: 22.3353,
        longitude: 103.8428,
      ),
    ],
    'Lâm Đồng': [
      Destination(
        name: 'Hồ Tuyền Lâm',
        province: 'Lâm Đồng',
        price: 'Miễn phí tham quan',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/c6/12/36/tuyen-lam-lake.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/c6/12/36/tuyen-lam-lake.jpg',
        latitude: 11.9056,
        longitude: 108.4356,
      ),
      Destination(
        name: 'Thung lũng Tình Yêu Dalat',
        province: 'Lâm Đồng',
        price: 'Chỉ từ 250.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/4a/4a/6a/love-valley.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/4a/4a/6a/love-valley.jpg',
        latitude: 11.9778,
        longitude: 108.4503,
      ),
      Destination(
        name: 'Đồi chè Cầu Đất',
        province: 'Lâm Đồng',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/26/51/7f/cau-dat.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/26/51/7f/cau-dat.jpg',
        latitude: 11.8753,
        longitude: 108.5583,
      ),
      Destination(
        name: 'Thác Datanla',
        province: 'Lâm Đồng',
        price: 'Chỉ từ 50.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/be/aa/3f/datanla.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/be/aa/3f/datanla.jpg',
        latitude: 11.9017,
        longitude: 108.4489,
      ),
      Destination(
        name: 'Chùa Linh Phước (Chùa Ve Chai)',
        province: 'Lâm Đồng',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/linh-phuoc.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/linh-phuoc.jpg',
        latitude: 11.9442,
        longitude: 108.4986,
      ),
    ],
    'Ninh Bình': [
      Destination(
        name: 'Tràng An Eco-Tourism Complex',
        province: 'Ninh Bình',
        price: 'Chỉ từ 250.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/1a/0c/ef/a0/trang-an.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/1a/0c/ef/a0/trang-an.jpg',
        latitude: 20.2522,
        longitude: 105.9083,
      ),
      Destination(
        name: 'Chùa Bái Đính',
        province: 'Ninh Bình',
        price: 'Miễn phí vé vào',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/fe/bf/bc/bai-dinh.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/fe/bf/bc/bai-dinh.jpg',
        latitude: 20.2683,
        longitude: 105.8714,
      ),
      Destination(
        name: 'Tam Cốc - Bích Động',
        province: 'Ninh Bình',
        price: 'Chỉ từ 120.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/fb/99/bd/tam-coc.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/fb/99/bd/tam-coc.jpg',
        latitude: 20.2036,
        longitude: 105.9372,
      ),
      Destination(
        name: 'Hang Múa',
        province: 'Ninh Bình',
        price: 'Chỉ từ 100.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/be/aa/3f/hang-mua.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/be/aa/3f/hang-mua.jpg',
        latitude: 20.2319,
        longitude: 105.9283,
      ),
      Destination(
        name: 'Cố đô Hoa Lư',
        province: 'Ninh Bình',
        price: 'Chỉ từ 20.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/hoa-lu.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/hoa-lu.jpg',
        latitude: 20.2853,
        longitude: 105.9089,
      ),
    ],
    'Bình Thuận': [
      Destination(
        name: 'Đồi cát bay Mũi Né',
        province: 'Bình Thuận',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/c6/12/36/red-sand-dunes.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0f/c6/12/36/red-sand-dunes.jpg',
        latitude: 10.9458,
        longitude: 108.2864,
      ),
      Destination(
        name: 'Đảo Phú Quý',
        province: 'Bình Thuận',
        price: 'Vé tàu từ 350.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/18/64/34/00/phu-quy.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/18/64/34/00/phu-quy.jpg',
        latitude: 10.5192,
        longitude: 108.9225,
      ),
      Destination(
        name: 'Mũi Kê Gà',
        province: 'Bình Thuận',
        price: 'Miễn phí tham quan',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/89/3e/dc/ke-ga.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/89/3e/dc/ke-ga.jpg',
        latitude: 10.6972,
        longitude: 107.9883,
      ),
      Destination(
        name: 'Tháp Po Sah Inư',
        province: 'Bình Thuận',
        price: 'Chỉ từ 15.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/poshanu.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/poshanu.jpg',
        latitude: 10.9328,
        longitude: 108.1364,
      ),
      Destination(
        name: 'Bãi đá Cổ Thạch',
        province: 'Bình Thuận',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/co-thach.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/co-thach.jpg',
        latitude: 11.2189,
        longitude: 108.7283,
      ),
    ],
    'Kiên Giang': [
      Destination(
        name: 'Bãi Sao Phú Quốc',
        province: 'Kiên Giang',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/45/2c/66/sao-beach.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/45/2c/66/sao-beach.jpg',
        latitude: 10.0525,
        longitude: 104.0333,
      ),
      Destination(
        name: 'Hòn Thơm Phú Quốc',
        province: 'Kiên Giang',
        price: 'Cáp treo từ 400.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0c/3e/cf/58/hon-thom.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0c/3e/cf/58/hon-thom.jpg',
        latitude: 9.9525,
        longitude: 104.0133,
      ),
      Destination(
        name: 'Quần đảo Nam Du',
        province: 'Kiên Giang',
        price: 'Vé tàu từ 250.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/50/eb/64/nam-du.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/50/eb/64/nam-du.jpg',
        latitude: 9.6728,
        longitude: 104.3562,
      ),
      Destination(
        name: 'Chợ đêm Phú Quốc',
        province: 'Kiên Giang',
        price: 'Miễn phí tham quan',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/a4/be/83/night-market.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/a4/be/83/night-market.jpg',
        latitude: 10.2189,
        longitude: 103.9583,
      ),
      Destination(
        name: 'Bãi Trường Phú Quốc',
        province: 'Kiên Giang',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/69/cb/09/truong-beach.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/69/cb/09/truong-beach.jpg',
        latitude: 10.1586,
        longitude: 103.9683,
      ),
    ],
    'Bà Rịa - Vũng Tàu': [
      Destination(
        name: 'Tượng Chúa Kitô Vua Vũng Tàu',
        province: 'Bà Rịa - Vũng Tàu',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/be/aa/3f/christ-the-king.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0e/be/aa/3f/christ-the-king.jpg',
        latitude: 10.3236,
        longitude: 107.0842,
      ),
      Destination(
        name: 'Bãi Sau Vũng Tàu',
        province: 'Bà Rịa - Vũng Tàu',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/be/89/3e/back-beach.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/be/89/3e/back-beach.jpg',
        latitude: 10.3392,
        longitude: 107.0983,
      ),
      Destination(
        name: 'Hồ Tràm',
        province: 'Bà Rịa - Vũng Tàu',
        price: 'Miễn phí tham quan',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/fb/99/bd/ho-tram.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/fb/99/bd/ho-tram.jpg',
        latitude: 10.4939,
        longitude: 107.2783,
      ),
      Destination(
        name: 'Bạch Dinh (Villa Blanche)',
        province: 'Bà Rịa - Vũng Tàu',
        price: 'Chỉ từ 15.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/26/51/7f/villa-blanche.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/26/51/7f/villa-blanche.jpg',
        latitude: 10.3478,
        longitude: 107.0728,
      ),
      Destination(
        name: 'Côn Đảo',
        province: 'Bà Rịa - Vũng Tàu',
        price: 'Vé tàu từ 350.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/con-dao.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/13/2e/d0/22/con-dao.jpg',
        latitude: 8.6811,
        longitude: 106.6086,
      ),
    ],
    'Quảng Bình': [
      Destination(
        name: 'Động Phong Nha',
        province: 'Quảng Bình',
        price: 'Chỉ từ 150.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/c1/f1/8c/phong-nha.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/17/c1/f1/8c/phong-nha.jpg',
        latitude: 17.5878,
        longitude: 106.2731,
      ),
      Destination(
        name: 'Động Thiên Đường',
        province: 'Quảng Bình',
        price: 'Chỉ từ 250.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/48/43/46/paradise-cave.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/1c/48/43/46/paradise-cave.jpg',
        latitude: 17.5192,
        longitude: 106.2225,
      ),
      Destination(
        name: 'Bãi biển Nhật Lệ',
        province: 'Quảng Bình',
        price: 'Miễn phí vé',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/nhat-le.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/18/b9/aa/nhat-le.jpg',
        latitude: 17.4853,
        longitude: 106.6283,
      ),
      Destination(
        name: 'Suối Nước Moọc',
        province: 'Quảng Bình',
        price: 'Chỉ từ 80.000đ',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/41/50/41/mooc-stream.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/15/41/50/41/mooc-stream.jpg',
        latitude: 17.5328,
        longitude: 106.2939,
      ),
      Destination(
        name: 'Hang Sơn Đoòng',
        province: 'Quảng Bình',
        price: 'Tour khám phá 3000 USD',
        imagePath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/50/eb/64/son-doong.jpg',
        bgBlurPath: 'https://media-cdn.tripadvisor.com/media/photo-w/0d/50/eb/64/son-doong.jpg',
        latitude: 17.4525,
        longitude: 106.2863,
      ),
    ],
  };

  if (map.containsKey(province)) {
    return map[province]!;
  }

  // Generate 5 generic but beautifully named localized mock locations for any other of the 63 provinces
  final List<String> spotTypes = [
    'Khu du lịch sinh thái',
    'Danh lam thắng cảnh',
    'Khu di tích lịch sử',
    'Khu nghỉ dưỡng thiên nhiên',
    'Quần thể thắng cảnh nghệ thuật'
  ];
  final List<String> spotNames = [
    'Đất Việt Xanh',
    'Bình Yên Sắc Hoa',
    'Vẻ Đẹp Quê Hương',
    'Thiên Nhiên Kỳ Thú',
    'Nét Đẹp Truyền Thống'
  ];
  final List<String> images = [
    destinationPlaceholderPath,
    destinationPlaceholderPath,
    destinationPlaceholderPath,
    destinationPlaceholderPath,
    destinationPlaceholderPath
  ];

  final List<Destination> result = [];
  for (int i = 0; i < 5; i++) {
    result.add(Destination(
      name: '${spotTypes[i]} ${spotNames[i]} $province',
      province: province,
      price: 'Chỉ từ ${(i + 1) * 200}.000đ',
      imagePath: images[i],
      bgBlurPath: images[i],
      latitude: 16.0 + (i * 0.1),
      longitude: 108.0 + (i * 0.1),
    ));
  }
  return result;
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
    imagePath: 'assets/images/hoi_an.jpg',
    bgBlurPath: 'assets/images/hoi_an.jpg',
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

String getLocalFallbackAsset(String query) {
  return destinationPlaceholderPath;
}
