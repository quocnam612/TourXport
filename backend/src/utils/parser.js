const escapeRegex = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const toVietnameseStorageVariant = (value) => {
    const shapeMap = {
        'a\u0306': 'ă',
        'A\u0306': 'Ă',
        'a\u0302': 'â',
        'A\u0302': 'Â',
        'e\u0302': 'ê',
        'E\u0302': 'Ê',
        'o\u0302': 'ô',
        'O\u0302': 'Ô',
        'o\u031b': 'ơ',
        'O\u031b': 'Ơ',
        'u\u031b': 'ư',
        'U\u031b': 'Ư'
    };
    const shapeMarks = new Set(['\u0306', '\u0302', '\u031b']);
    const normalized = String(value).normalize('NFD');
    let result = '';

    for (let i = 0; i < normalized.length; i++) {
        const char = normalized[i];
        if (char.codePointAt(0) >= 0x0300 && char.codePointAt(0) <= 0x036f) {
            result += char;
            continue;
        }

        const marks = [];
        while (
            i + 1 < normalized.length
            && normalized[i + 1].codePointAt(0) >= 0x0300
            && normalized[i + 1].codePointAt(0) <= 0x036f
        ) {
            marks.push(normalized[++i]);
        }

        const shapeMark = marks.find((mark) => shapeMarks.has(mark));
        const composed = shapeMark ? shapeMap[`${char}${shapeMark}`] : undefined;
        result += composed || char;
        result += marks.filter((mark) => mark !== shapeMark).join('');
    }

    return result;
};

const regexVariants = (value) => {
    const text = String(value).trim();
    const variants = new Set([
        text,
        text.normalize('NFC'),
        text.normalize('NFD'),
        toVietnameseStorageVariant(text)
    ]);

    return [...variants].map((variant) => new RegExp(escapeRegex(variant), 'i'));
};

const stripVietnameseMarks = (value) => String(value)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D');

const provinceCityAliasGroups = [
    { keys: ['An Giang'], cities: ['An Giang', 'An Phu', 'Châu Đốc', 'Châu Đốc, Tỉnh An Giang', 'Long Xuyên', 'Long Xuyên, Tỉnh An Giang', 'Nui To', 'Tỉnh An Giang', 'Tinh Bien', 'Tinh Bien, Tỉnh An Giang'] },
    { keys: ['Bà Rịa - Vũng Tàu'], cities: ['Bà Rịa', 'Bà Rịa - Vũng Tàu', 'Binh Chau', 'Bong Trang, Tỉnh Bà Rịa-Vũng Tàu', 'Bung Rieng', 'Bung Rieng, Tỉnh Bà Rịa-Vũng Tàu', 'Côn Sơn, Quần đảo Côn Đảo, Tỉnh Bà Rịa-Vũng Tàu', 'Hồ Tràm', 'Hồ Tràm, Phuoc Thuan, Tỉnh Bà Rịa-Vũng Tàu', 'Loc An', 'Long Hải', 'Long Hải, Tỉnh Bà Rịa-Vũng Tàu', 'Phú Mỹ', 'Phuoc Thuan', 'Phuoc Thuan, Tỉnh Bà Rịa-Vũng Tàu', 'Phuoc Tinh', 'Phước Bửu', 'Phước Hải', 'Tam Phuoc', 'Tân Phước', 'Tỉnh Bà Rịa-Vũng Tàu', 'Vũng Tàu', 'Vũng Tàu, Tỉnh Bà Rịa-Vũng Tàu', 'Xa Bang', 'Xuyen Moc'] },
    { keys: ['Bắc Giang'], cities: ['Bac Giang', 'Bắc Giang', 'Thạch Son', 'Thi tran Nenh', 'Thuong Lat'] },
    { keys: ['Bắc Kạn'], cities: ['Ba Be', 'Bac Kan', 'Bắc Kạn', 'Nam Mau', 'Phu Thong'] },
    { keys: ['Bạc Liêu'], cities: ['Bac Lieu', 'Bạc Liêu', 'Tỉnh Bạc Liêu'] },
    { keys: ['Bắc Ninh'], cities: ['Bắc Ninh', 'Đình Bảng', 'Tỉnh Bắc Ninh', 'Tu Son'] },
    { keys: ['Bến Tre'], cities: ['An Khánh', 'Ba Tri', 'Ba Tri, Tỉnh Bến Tre, Đồng bằng Mekong', 'Bến Tre', 'Bến Tre', 'Bến Tre, Tỉnh Bến Tre, Đồng bằng Mekong', 'Bình Thạnh', 'Bình Thạnh, Tỉnh Bến Tre, Đồng bằng Mekong', 'Cái Bè', 'Châu Hưng', 'Long Thoi, Cho Lach, Tỉnh Bến Tre, Đồng bằng Mekong', 'Luong Hoa', 'Luong Hoa, Tỉnh Bến Tre, Đồng bằng Mekong', 'My Thanh', 'My Thanh, Tỉnh Bến Tre, Đồng bằng Mekong', 'Nhơn Thạnh, Tỉnh Bến Tre, Đồng bằng Mekong', 'Phu Tuc', 'Quới Sơn', 'Quới Sơn, Tỉnh Bến Tre, Đồng bằng Mekong', 'Sơn Hoà, Tỉnh Bến Tre, Đồng bằng Mekong', 'Tan Thạch', 'Tan Thach', 'Tan Thạch, Tỉnh Bến Tre, Đồng bằng Mekong', 'Tan Thach, Tỉnh Bến Tre, Đồng bằng Mekong', 'Thạnh Phú Đông, Tỉnh Bến Tre, Đồng bằng Mekong', 'Thừa Đức', 'Tỉnh Bến Tre', 'Tỉnh Bến Tre, Đồng bằng Mekong'] },
    { keys: ['Bình Định'], cities: ['Bai Xep', 'Bình Định', 'Cát Tiến', 'Hoai Nhon', 'Hoi Van', 'My Tho', 'Phuoc Hiep', 'Phuoc Thuan', 'Phuong Phi', 'Quy Nhơn', 'Tay Son', 'Tỉnh Bình Định'] },
    { keys: ['Bình Dương'], cities: ['Ben Cat', 'Binh Chuan', 'Binh Duong', 'Bình Dương', 'Di An', 'Tan Uyen', 'Thủ Dầu Một', 'Thuan An'] },
    { keys: ['Bình Phước'], cities: ['Bình Phước', 'Dong Xoai', 'Phu Rieng', 'Phuoc Long'] },
    { keys: ['Bình Thuận'], cities: ['Bình Thuận', 'Ham Tan', 'Ham Tien', 'Hoa Thang', 'Kê Gà', 'Khánh Hải', 'Lagi', 'Lien Huong', 'Luong Son', 'Mũi Né', 'Phan Thiết', 'Phu Hai', 'Phu Thuy', 'Tan Thanh', 'Thi Tran Thuan Nam', 'Tien Thanh', 'Tỉnh Bình Thuận', 'Tuy Phong', 'Vĩnh Hảo'] },
    { keys: ['Cà Mau'], cities: ['Ap Da Bac, Tỉnh Cà Mau, Đồng bằng Mekong', 'Cà Mau', 'Cà Mau', 'Cà Mau, Tỉnh Cà Mau, Đồng bằng Mekong', 'Năm Căn', 'Năm Căn, Tỉnh Cà Mau, Đồng bằng Mekong', 'Tỉnh Cà Mau, Đồng bằng Mekong'] },
    { keys: ['Can Tho', 'Cần Thơ', 'Thành phố Cần Thơ', 'TP. Cần Thơ'], cities: ['Can Tho', 'Cần Thơ', 'Cần Thơ', 'Ninh Kieu', 'Thành phố Cần Thơ', 'TP. Cần Thơ'] },
    { keys: ['Cao Bằng'], cities: ['Bao Lac', 'Cao Bằng', 'Cao Bằng', 'Dam Thuy', 'Pac Bo', 'Phuc Sen', 'Tỉnh Cao Bằng', 'Trung Khanh', 'Truong Ha'] },
    { keys: ['Da Nang', 'Đà Nẵng', 'Thành phố Đà Nẵng', 'TP. Đà Nẵng'], cities: ['An Hai', 'An Hai Bac', 'An Hai Bac, Son Tra Peninsula, Đà Nẵng', 'An Hai Dong', 'An Hai Tay', 'An Hai, Son Tra Peninsula, Đà Nẵng', 'Da Nang', 'Đà Nẵng', 'Đà Nẵng', 'Điện Bàn', 'Điện Bàn, Đà Nẵng', 'Hai Chau', 'Hai Chau, Đà Nẵng', 'Hoa Hai', 'Hoa Hai, Đà Nẵng', 'Hoa Hiep Bac', 'Hoà Khánh Bắc', 'Hòa Phú', 'Lien Chieu', 'Man Thai, Son Tra Peninsula, Đà Nẵng', 'My An', 'My An, Đà Nẵng', 'Nai Hien Dong', 'Ngu Hanh Son', 'Ngu Hanh Son, Đà Nẵng', 'Phuoc My', 'Phuoc My, Son Tra Peninsula, Đà Nẵng', 'Son Tra Peninsula', 'Son Tra Peninsula, Đà Nẵng', 'Thanh Khe', 'Thành phố Đà Nẵng', 'Tho Quang', 'Tho Quang, Son Tra Peninsula, Đà Nẵng', 'TP. Đà Nẵng'] },
    { keys: ['Đắk Lắk'], cities: ['An Chan', 'An Mỹ', 'An Ninh Dong', 'Buôn Ma Thuột', 'Đắk Lắk', 'Ea Huar', 'Hoa Tam', 'Krong Bong', 'Liên Sơn', 'Phu My', 'Quang Tien', 'Thị trấn Sông Cầu', 'Tỉnh Đắk Lắk', 'Tuy Hòa', 'Xuan Thinh'] },
    { keys: ['Đắk Nông'], cities: ['Cu Jut District', 'Dak Mam, Tỉnh Đăk Nông', 'Dak Mil', 'Dak Mil, Tỉnh Đăk Nông', 'Dak Som', 'Dak Som, Tỉnh Đăk Nông', 'Dak Sor', 'Đắk Nông', 'Ea T\'Ling', 'Ea T\'Ling, Tỉnh Đăk Nông', 'Gia Nghĩa', 'Gia Nghĩa, Tỉnh Đăk Nông', 'Nam N\'Jang', 'Nam N\'Jang, Tỉnh Đăk Nông', 'Nhan Co, Tỉnh Đăk Nông', 'Quang Khe', 'Quang Khe, Tỉnh Đăk Nông', 'Tỉnh Đăk Nông', 'Tuy Duc'] },
    { keys: ['Điện Biên'], cities: ['Điện Biên', 'Điện Biên Phủ', 'Muong Lay', 'Muong Phan', 'Tuần Giáo'] },
    { keys: ['Đồng Nai'], cities: ['Biên Hòa', 'Doc Mo', 'Đồng Nai', 'Gia Tan 1', 'Gia Tan 2', 'Long Giao', 'Long Khánh', 'Long Thanh', 'Nam Cát Tiên', 'Nhon Trach', 'Phú Hữu', 'Quan Tom', 'Quang Trung', 'Tan Phu', 'Thái Thiên', 'Tỉnh Đồng Nai', 'Trảng Bom', 'Vinh Thanh', 'Xa Bang', 'Xuân Phú'] },
    { keys: ['Đồng Tháp'], cities: ['Cao Lãnh', 'Đồng Tháp', 'Hong Ngu', 'Sa Đéc', 'Tram Chim'] },
    { keys: ['Gia Lai'], cities: ['Chu Jor', 'Gia Lai', 'Pleiku', 'Thi Xa An Khe'] },
    { keys: ['Hà Giang'], cities: ['Du Gia', 'Đồng Văn', 'Hà Giang', 'Hà Giang', 'Hoàng Su Phì', 'Mèo Vạc', 'Quan Ba', 'Tam Son', 'Xin Man', 'Yen Minh'] },
    { keys: ['Hà Nam'], cities: ['Ba Sao', 'Duy Hai', 'Duy Tien', 'Hà Nam', 'Kha Phong', 'Kim Bang', 'Liem Son', 'Liên Sơn', 'Phu Ly'] },
    { keys: ['Ha Noi', 'Hà Nội', 'Thành phố Hà Nội', 'TP. Hà Nội'], cities: ['Ba Dinh', 'Ba Vi', 'Bắc Từ Liêm', 'Cau Giay', 'Dong Da', 'Gia Lam', 'Ha Dong', 'Ha Noi', 'Hà Nội', 'Hai Ba Trung', 'Hoai Duc', 'Hoan Kiem', 'Hoang Mai', 'Long Bien', 'Mai Dinh', 'Me Tri', 'Nam Từ Liêm', 'Son Tay', 'Tay Ho', 'Thành phố Hà Nội', 'Thanh Xuan', 'TP. Hà Nội', 'Tu Liem'] },
    { keys: ['Hà Tĩnh'], cities: ['Duc Tho', 'Hà Tĩnh', 'Kỳ Anh', 'Phuong Dien', 'Thiên Cầm'] },
    { keys: ['Hải Dương'], cities: ['An Nhân', 'Cam Phuc', 'Hải Dương', 'Hải Dương', 'Hưng Đạo'] },
    { keys: ['Hải Phòng', 'Hai Phong', 'Thành phố Hải Phòng', 'TP. Hải Phòng'], cities: ['Cat Ba Town', 'Cat Hai', 'Do Son', 'Gia Luan', 'Hải Phòng', 'Hai Phong', 'Hong Bang', 'Hung Thang', 'Le Chan', 'Thành phố Hải Phòng', 'Thành phố Hải Phòng', 'TP. Hải Phòng', 'Tran Chau'] },
    { keys: ['Hậu Giang'], cities: ['Hậu Giang', 'Vi Thanh'] },
    { keys: ['Hồ Chí Minh', 'Sai Gon', 'Sài Gòn', 'Thành phố Hồ Chí Minh', 'TP Hồ Chí Minh', 'TP. Hồ Chí Minh'], cities: ['Hồ Chí Minh', 'Sai Gon', 'Sài Gòn', 'Thành phố Hồ Chí Minh', 'TP Hồ Chí Minh', 'TP. Hồ Chí Minh'] },
    { keys: ['Hòa Bình'], cities: ['Ba Vi', 'Cao Phong', 'Chieng Chau', 'Hang Kia', 'Hòa Bình', 'Hòa Bình', 'Kim Boi', 'Ky Son', 'Mai Châu', 'Na Phon', 'Pà Cò', 'Son Tay', 'Tỉnh Hòa Bình'] },
    { keys: ['Huế', 'Thành phố Huế', 'Thừa Thiên Huế', 'TP. Huế'], cities: ['Cu Du', 'Cu Du, Loc Vinh, Phu Loc District, Tỉnh Thừa Thiên - Huế', 'Huế', 'Huế', 'Huế, Tỉnh Thừa Thiên - Huế', 'Huong Thuy', 'Khe Tre', 'Lăng Cô', 'Loc Vinh, Phu Loc District, Tỉnh Thừa Thiên - Huế', 'Lộc Tiễn', 'Phong Son', 'Phú Bài', 'Phú Dương', 'Phú Dương, Tỉnh Thừa Thiên - Huế', 'Phú Lộc', 'Phú Lộc, Phu Loc District, Tỉnh Thừa Thiên - Huế', 'Quảng Lợi', 'Thành phố Huế', 'Thi Tran A Luoi', 'Thừa Thiên Huế', 'Tỉnh Thừa Thiên - Huế', 'TP. Huế', 'Vinh An'] },
    { keys: ['Hưng Yên'], cities: ['Dong Da', 'Hai Ba Trung', 'Hoang Mai', 'Hung Yen', 'Hưng Yên', 'Long Bien', 'Phung Cong', 'Tam Tien', 'Van Giang'] },
    { keys: ['Khánh Hòa'], cities: ['Cam Đức', 'Cam Hải Đông', 'Cam Hải Đông, Cam Lâm District, Khánh Hòa', 'Cam Hai Tay', 'Cam Ranh', 'Dien Dien', 'Dien Hoa', 'Dien Thọ', 'Dốc Lết', 'Khánh Hòa', 'Khánh Hòa', 'Khanh Phu', 'Khanh Vinh', 'Nha Trang', 'Nha Trang, Khánh Hòa', 'Ninh Hai, Ninh Hoa, Khánh Hòa', 'Ninh Hiep', 'Ninh Hoa', 'Ninh Phước', 'Ninh Vân, Ninh Hoa, Khánh Hòa', 'Van Ninh'] },
    { keys: ['Kiên Giang'], cities: ['An Thoi', 'Bai Thom', 'Cua Can', 'Cua Duong', 'Cua Lap', 'Duong Bao', 'Dương Đông', 'Dương Tơ', 'Ganh Dau', 'Ganh Gio', 'Hà Tiên', 'Hàm Ninh', 'Kiên Giang', 'Lai Son', 'Linh Huynh', 'Ong Lang', 'Rạch Giá', 'Suoi May', 'Tỉnh Kiên Giang', 'Vi Thanh'] },
    { keys: ['Kon Tum'], cities: ['Dak Long', 'Kon Tum', 'Kontum', 'Măng Đen'] },
    { keys: ['Lai Châu'], cities: ['Lai Châu', 'Lai Châu, Tỉnh Lai Châu', 'Phong Tho', 'Phong Tho, Tỉnh Lai Châu', 'Sin Sui Ho, Tỉnh Lai Châu', 'Tam Đường', 'Tam Đường, Tỉnh Lai Châu'] },
    { keys: ['Lâm Đồng'], cities: ['Bảo Lộc', 'Dalat', 'Di Linh', 'Đà Lạt', 'Gia Lam', 'Lac Duong', 'Lat', 'Lâm Đồng', 'Lâm Đồng', 'Lien Nghia', 'Madagui Town', 'Me Linh', 'Nam Ban', 'Phi To', 'Phuong 8', 'Ta Nung', 'Thị Tran Nam Ban', 'Tỉnh Lâm Đồng', 'Tu Tra'] },
    { keys: ['Lạng Sơn'], cities: ['Bac Son', 'Huu Lien', 'Lạng Sơn'] },
    { keys: ['Lào Cai'], cities: ['Bắc Hà', 'Hau Thao', 'La Pan Tan', 'La Pan Tan, Tỉnh Lào Cai', 'Lào Cai', 'Lào Cai', 'Lào Cai, Tỉnh Lào Cai', 'Lao Chai', 'Mu Cang Chai', 'San Sa Ho', 'Sapa', 'Sapa, Tỉnh Lào Cai', 'Su Pan', 'Ta Phin', 'Ta Van', 'Tỉnh Lào Cai'] },
    { keys: ['Long An'], cities: ['Ben Luc', 'Can Duoc', 'Can Giuoc', 'Long An', 'Moc Hoa', 'Tan My', 'Tân An', 'Tỉnh Long An'] },
    { keys: ['Nam Định'], cities: ['Nam Dinh', 'Nam Định'] },
    { keys: ['Nghệ An'], cities: ['Con Cuong', 'Cửa Lò', 'Diễn Châu', 'Diễn Thành', 'Hoang Mai', 'Hung Thịnh', 'Kim Lien', 'Mon Son', 'Nghệ An', 'Nghi Yen', 'Nghia Thuan', 'Que Phong', 'Quy Hop', 'Quynh Nghia', 'Thai Hoa', 'Thanh An', 'Tỉnh Nghệ An', 'Tràng Sơn', 'Vinh'] },
    { keys: ['Ninh Bình'], cities: ['Gia Sinh', 'Gia Sinh, Tỉnh Ninh Bình', 'Gia Van', 'Gia Vien', 'Hoa Lu', 'Khe Ha', 'Kỳ Phú', 'Ninh An', 'Ninh Bình', 'Ninh Bình', 'Ninh Bình, Tỉnh Ninh Bình', 'Ninh Hai', 'Ninh Hai, Huyện Hoa Lư, Tỉnh Ninh Bình', 'Ninh Hoa, Huyện Hoa Lư, Tỉnh Ninh Bình', 'Ninh Thang', 'Ninh Xuân', 'Ninh Xuân, Huyện Hoa Lư, Tỉnh Ninh Bình', 'Tam Diep', 'Thien Ton', 'Tỉnh Ninh Bình', 'Truong Yen', 'Truong Yen, Huyện Hoa Lư, Tỉnh Ninh Bình', 'Van Phuong'] },
    { keys: ['Ninh Thuận'], cities: ['Binh Tien', 'Cong Hai', 'Khanh Hai', 'Mỹ Hòa', 'Ninh Thuan Province', 'Ninh Thuận', 'Phan Rang-Tháp Chàm', 'Phuoc Minh', 'Vinh Hai'] },
    { keys: ['Phú Thọ'], cities: ['Ba Vi', 'Hien Luong', 'Phú Thọ', 'Thanh Thuy', 'Viet Tri', 'Xuan Dai'] },
    { keys: ['Phú Yên'], cities: ['Phú Yên', 'Tuy Hòa'] },
    { keys: ['Quảng Bình'], cities: ['Bao Ninh', 'Bao Ninh, Tỉnh Quảng Bình', 'Canh Duong', 'Đồng Hới', 'Đồng Hới, Tỉnh Quảng Bình', 'Hoan Lao', 'Hung Trach', 'Hung Trach, Tỉnh Quảng Bình', 'Ly Hoa', 'Minh Hoa', 'Phong Nha', 'Phong Nha, Tỉnh Quảng Bình', 'Phúc Trạch', 'Quảng Bình', 'Quang Đong', 'Quang Ninh', 'Quang Ninh, Tỉnh Quảng Bình', 'Son Trach', 'Son Trach, Tỉnh Quảng Bình', 'Thanh Trach', 'Tỉnh Quảng Bình', 'Vườn quốc gia Phong Nha-Kẻ Bàng, Tỉnh Quảng Bình'] },
    { keys: ['Quảng Nam'], cities: ['An Hoi', 'Binh Minh', 'Bình Minh', 'Cà Dy', 'Cam An', 'Cam Chau', 'Cam Ha', 'Cam Pho', 'Cam Thanh', 'Cua Dai', 'Duy Hai', 'Duy Nghia', 'Duy Phú', 'Duy Trinh', 'Điện Dương', 'Điện Tiến', 'Hội An', 'Minh An', 'Nui Thanh', 'Prao', 'Quảng Nam', 'Son Phong', 'Tam Kỳ', 'Tam Tien', 'Tan An', 'Tan Hiep', 'Tỉnh Quảng Nam', 'tt. Ha Lam'] },
    { keys: ['Quảng Ngãi'], cities: ['Quảng Ngãi', 'Quảng Ngãi', 'Tỉnh Quảng Ngãi'] },
    { keys: ['Quảng Ninh'], cities: ['Bai Chay', 'Cai Rong', 'Cam Pha', 'Dong Trieu', 'Ha Long City', 'Hong Hai', 'Hung Thang', 'Móng Cái', 'Quan Lạn', 'Quang Châu', 'Quảng Ninh', 'Thị Tran Co To', 'Tỉnh Quảng Ninh', 'Uong Bi', 'Van Don', 'Vịnh Hạ Long'] },
    { keys: ['Quảng Trị'], cities: ['Đông Hà', 'Hai Phu', 'Khe Sanh', 'Lao Bảo', 'Quảng Trị', 'Quang Tri', 'Tan Hop', 'Vinh Linh', 'Vinh Truong'] },
    { keys: ['Sóc Trăng'], cities: ['Nga Nam', 'Phu Loc', 'Sóc Trăng', 'Sóc Trăng'] },
    { keys: ['Sơn La'], cities: ['Bac Yen', 'Bac Yen, Tỉnh Sơn La', 'Chieng On', 'Mộc Châu', 'Mộc Châu, Tỉnh Sơn La', 'Muong Sang', 'Muong Sang, Tỉnh Sơn La', 'Ngoc Chien', 'Phieng Luong, Tỉnh Sơn La', 'Sơn La', 'Sơn La, Tỉnh Sơn La', 'Ta Xua', 'Ta Xua, Bac Yen, Tỉnh Sơn La', 'Van Ho', 'Van Ho, Tỉnh Sơn La'] },
    { keys: ['Tây Ninh'], cities: ['Go Dau Ha', 'Tây Ninh', 'Trang Bang'] },
    { keys: ['Thái Bình'], cities: ['Dong Hung District', 'Duy Nhat', 'Thái Bình'] },
    { keys: ['Thái Nguyên'], cities: ['Đồng Tiến', 'Thái Nguyên', 'Thái Nguyên'] },
    { keys: ['Thanh Hóa'], cities: ['Ba Thuoc', 'Cam Luong', 'Co Lung', 'Hải Hòa', 'Hoang Hoa', 'Hoang Tien', 'Nga Thien', 'Nghi Son', 'Sầm Sơn', 'Thanh Hóa', 'Thanh Hóa', 'Thanh Lam', 'Thanh Son', 'Thanh Yen', 'Tinh Gia District', 'Tỉnh Thanh Hóa', 'Tri Nang', 'Trieu Loc', 'Vinh Long', 'Vinh Tien'] },
    { keys: ['Tiền Giang'], cities: ['Cái Bè', 'Cho Gao', 'Mỹ Tho', 'Phu Tan', 'Thạnh Tan', 'Tiền Giang', 'Tỉnh Tiền Giang'] },
    { keys: ['Trà Vinh'], cities: ['Duyên Hải', 'Phu Can', 'Tan Binh', 'Thị Tran Chau Thanh', 'Trà Vinh', 'Trà Vinh', 'Trường Long Hòa'] },
    { keys: ['Tuyên Quang'], cities: ['Tuyên Quang'] },
    { keys: ['Vĩnh Long'], cities: ['Bình Hòa Phước', 'Bình Minh', 'Cái Bè', 'Ninh Kieu', 'Tỉnh Vĩnh Long', 'Vĩnh Long', 'Vĩnh Long'] },
    { keys: ['Vĩnh Phúc'], cities: ['Ngoc Thanh', 'Phúc Yên', 'Tam Đảo', 'Trung My', 'Vĩnh Phúc', 'Vinh Tuong', 'Vĩnh Yên'] },
    { keys: ['Yên Bái'], cities: ['Nghĩa Lộ', 'Pung Luong', 'Tú Lệ', 'Van Chan District', 'Yên Bái', 'Yên Bái'] },
];

const provinceToCities = provinceCityAliasGroups.reduce((acc, group) => {
    for (const key of group.keys) {
        acc[key.toLowerCase()] = group.cities;
        acc[stripVietnameseMarks(key).toLowerCase()] = group.cities;
    }
    return acc;
}, {});

const textFilterForField = (field, value) => {
    if (field === 'city' && typeof value === 'string') {
        const trimmed = value.trim();
        const variants = new Set([trimmed]);
        
        const lower = trimmed.toLowerCase();
        if (provinceToCities[lower]) {
            for (const city of provinceToCities[lower]) {
                variants.add(city);
            }
        }
        
        if (/^tp\.?\s+/i.test(trimmed)) {
            const base = trimmed.replace(/^tp\.?\s+/i, '');
            variants.add(base);
            variants.add(`Thành phố ${base}`);
        } else if (/^thành\s+phố\s+/i.test(trimmed)) {
            const base = trimmed.replace(/^thành\s+phố\s+/i, '');
            variants.add(base);
            variants.add(`TP. ${base}`);
            variants.add(`TP ${base}`);
        } else {
            variants.add(`TP. ${trimmed}`);
            variants.add(`Thành phố ${trimmed}`);
        }
        
        const allRegex = [];
        for (const variant of variants) {
            allRegex.push(...regexVariants(variant));
        }
        
        const uniqueRegexMap = new Map();
        for (const r of allRegex) {
            uniqueRegexMap.set(r.source, r);
        }
        const uniqueRegex = [...uniqueRegexMap.values()];
        return uniqueRegex.length === 1 ? { [field]: uniqueRegex[0] } : { [field]: { $in: uniqueRegex } };
    }

    const variants = regexVariants(value);
    return variants.length === 1 ? { [field]: variants[0] } : { [field]: { $in: variants } };
};

const addAndFilter = (filter, clause) => {
    if (!filter.$and) {
        filter.$and = [];
    }
    filter.$and.push(clause);
};

const keepUnknownHoursOr = (clause) => ({
    $or: [
        { 'openingHours.weekRanges': null },
        { 'openingHours.weekRanges': { $exists: false } },
        clause
    ]
});

export const parsePositiveInt = (value, fallback) => {
    const parsed = Number.parseInt(value, 10);
    return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
};

export const parseNumber = (value, fallback = undefined) => {
    if (value === undefined || value === null || value === '') {
        return fallback;
    }

    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
};

export const parseBoolean = (value, fallback = undefined) => {
    if (value === undefined || value === null || value === '') {
        return fallback;
    }

    if (value === true || String(value).toLowerCase() === 'true') {
        return true;
    }

    if (value === false || String(value).toLowerCase() === 'false') {
        return false;
    }

    return fallback;
};

export const parseGps = (value) => {
    if (value === undefined || value === null || value === '') {
        return null;
    }

    const coordinates = Array.isArray(value)
        ? value
        : String(value).split(',');

    if (coordinates.length !== 2) {
        return null;
    }

    const longitude = parseNumber(coordinates[0]);
    const latitude = parseNumber(coordinates[1]);

    if (
        longitude === undefined
        || latitude === undefined
        || longitude < -180
        || longitude > 180
        || latitude < -90
        || latitude > 90
    ) {
        return null;
    }

    return [longitude, latitude];
};

export const parsePriceRange = (priceRange) => {
    if (priceRange === undefined || priceRange === null || priceRange === '') {
        return null;
    }

    const numbers = String(priceRange)
        .match(/\d[\d.,]*/g)
        ?.map((value) => Number(value.replace(/[.,]/g, '')))
        .filter(Number.isFinite) || [];

    if (numbers.length === 0) {
        return null;
    }

    return {
        min: Math.min(...numbers),
        max: Math.max(...numbers)
    };
};

export const filterByPriceRange = (items, price, nullPrice = true) => {
    const parsedPrice = parseNumber(price);
    const includeNullPrice = parseBoolean(nullPrice, true);

    if (parsedPrice === undefined && includeNullPrice) {
        return items;
    }

    return items.filter((item) => {
        if (!item.priceRange) {
            return includeNullPrice;
        }

        if (parsedPrice === undefined) {
            return true;
        }

        const range = parsePriceRange(item.priceRange);
        return range !== null && range.min <= parsedPrice && parsedPrice <= range.max;
    });
};

export const parseTimeToMinutes = (value) => {
    if (value === undefined || value === null || value === '') {
        return null;
    }

    if (/^\d+$/.test(String(value))) {
        const minutes = Number(value);
        return minutes >= 0 && minutes <= 1439 ? minutes : null;
    }

    const match = String(value).trim().match(/^(\d{1,2}):(\d{2})$/);
    if (!match) {
        return null;
    }

    const hours = Number(match[1]);
    const minutes = Number(match[2]);
    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        return null;
    }

    return hours * 60 + minutes;
};

export const parseDateToWeekday = (value) => {
    if (!value) {
        return null;
    }

    if (/^[1-7]$/.test(String(value).trim())) {
        return Number(value) - 1;
    }

    const match = String(value).trim().match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (!match) {
        return null;
    }

    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const date = new Date(Date.UTC(year, month - 1, day));

    if (
        date.getUTCFullYear() !== year
        || date.getUTCMonth() !== month - 1
        || date.getUTCDate() !== day
    ) {
        return null;
    }

    return date.getUTCDay();
};

const hasOwn = (object, key) => Object.prototype.hasOwnProperty.call(object, key);

export const buildTextFilter = (query) => {
    if (!query) {
        return {};
    }

    const variants = regexVariants(query);
    return {
        title: variants.length === 1 ? variants[0] : { $in: variants }
    };
};

export const buildLocationFilter = (query) => {
    const filter = {
        ...buildTextFilter(query.query)
    };

    if (query.city) {
        Object.assign(filter, textFilterForField('city', query.city));
    }

    if (query.category) {
        Object.assign(filter, textFilterForField('category', query.category));
    }

    if (query.tag) {
        const tags = Array.isArray(query.tag) ? query.tag : [query.tag];
        filter.tags = {
            $all: tags
                .filter((tag) => String(tag).trim())
                .map((tag) => ({ $elemMatch: { $in: regexVariants(tag) } }))
        };
    }

    const minScore = parseNumber(query.minScore);
    if (minScore !== undefined) {
        filter.totalScore = { ...(filter.totalScore || {}), $gte: minScore };
    }

    const maxScore = parseNumber(query.maxScore);
    if (maxScore !== undefined) {
        filter.totalScore = { ...(filter.totalScore || {}), $lte: maxScore };
    }

    const gps = parseGps(query.gps);
    const radius = parseNumber(query.radius);
    if (gps && radius !== undefined) {
        filter.location = {
            $geoWithin: {
                $centerSphere: [gps, radius / 6378137]
            }
        };
    }

    const hasDate = query.date !== undefined && query.date !== null && query.date !== '';
    const hasTime = query.time !== undefined && query.time !== null && query.time !== '';
    const time = parseTimeToMinutes(query.time);
    const weekday = parseDateToWeekday(query.date);

    if (hasTime && hasDate) {
        addAndFilter(filter, keepUnknownHoursOr({
            [`openingHours.weekRanges.${weekday}`]: {
                $elemMatch: {
                    open_time: { $lt: time },
                    close_time: { $gt: time }
                }
            }
        }));
    } else if (hasTime) {
        addAndFilter(filter, keepUnknownHoursOr({
            'openingHours.weekRanges': {
                $elemMatch: {
                    $elemMatch: {
                        open_time: { $lt: time },
                        close_time: { $gt: time }
                    }
                }
            }
        }));
    } else if (hasDate) {
        addAndFilter(filter, keepUnknownHoursOr({
            [`openingHours.weekRanges.${weekday}`]: {
                $elemMatch: {
                    open_time: { $gte: 0, $lte: 1439 },
                    close_time: { $gte: 0, $lte: 1439 }
                }
            }
        }));
    }

    return filter;
};

export const buildSort = (sortBy = 'totalScore', order = 'desc') => {
    const allowedFields = new Set([
        'title',
        'city',
        'totalScore',
        'reviewsCount',
        'createdAt',
        'updatedAt'
    ]);

    const field = allowedFields.has(sortBy) ? sortBy : 'totalScore';
    const direction = order === 'asc' ? 1 : -1;
    return { [field]: direction, reviewsCount: -1, _id: 1 };
};

export const buildTourListFilter = (query) => {
    const filter = {};

    if (query.query) {
        const variants = regexVariants(query.query);
        filter.$or = variants.flatMap((regex) => [
            { title: regex },
            { destinations: regex }
        ]);
    }

    if (query.destination) {
        Object.assign(filter, textFilterForField('destinations', query.destination));
    }

    if (query.visibility) {
        filter.visibility = query.visibility;
    }

    const totalDays = parsePositiveInt(query.totalDays);
    if (totalDays !== undefined) {
        filter.totalDays = totalDays;
    }

    const totalNights = parseNumber(query.totalNights);
    if (totalNights !== undefined) {
        filter.totalNights = totalNights;
    }

    return filter;
};

export const buildTourSort = (sortBy = 'updatedAt', order = 'desc') => {
    const allowedFields = new Set([
        'createdAt',
        'updatedAt',
        'title',
        'totalDays',
        'totalNights',
        'totalDistanceMeters'
    ]);

    const field = allowedFields.has(sortBy) ? sortBy : 'updatedAt';
    const direction = order === 'asc' ? 1 : -1;

    return { [field]: direction, _id: 1 };
};

const allowedTourItemTypes = new Set(['place', 'restaurant', 'hotel']);
const allowedTourSourceProviders = new Set(['database', 'websearch']);
const allowedTourSourceCollections = new Set(['places', 'restaurants', 'hotels']);

const normalizeTourSource = (source = {}) => {
    const provider = allowedTourSourceProviders.has(source.provider) ? source.provider : 'websearch';
    const sourceCollectionValue = source.sourceCollection || source.collection;
    const sourceCollection = allowedTourSourceCollections.has(sourceCollectionValue) ? sourceCollectionValue : null;

    return {
        provider,
        sourceCollection,
        id: source.id || null
    };
};

const isTourCoordinate = (coordinates) => {
    return Array.isArray(coordinates)
        && coordinates.length === 2
        && coordinates.every((coordinate) => Number.isFinite(Number(coordinate)));
};

const normalizeTourLocation = (location) => {
    if (!isTourCoordinate(location?.coordinates)) {
        return null;
    }

    return {
        type: location.type || 'Point',
        coordinates: location.coordinates
    };
};

const normalizeTourItem = (item) => ({
    ...item,
    checked: Boolean(item.checked),
    type: allowedTourItemTypes.has(item.type) ? item.type : 'place',
    location: normalizeTourLocation(item.location),
    source: normalizeTourSource(item.source)
});

const coordinatesFromTourItems = (items) => {
    return items
        .map((item) => item.location?.coordinates)
        .filter(isTourCoordinate);
};

const coordinatesFromTourRoutes = (routes) => {
    if (!Array.isArray(routes)) {
        return [];
    }

    return routes.flatMap((route) => route.geometry?.coordinates || []);
};

const buildDayRoutesSafely = async (items, routeService, options) => {
    try {
        const routes = await routeService.buildDayRoutes(items, options);
        return Array.isArray(routes) ? routes : null;
    } catch (error) {
        console.warn(`Skipping tour route generation: ${error.message}`);
        return null;
    }
};

export const normalizeTourPayloadFromAI = async (aiTour, userId, routeService) => {
    const transportMode = aiTour.preferences?.transportMode || 'auto';

    const days = await Promise.all((aiTour.days || []).map(async (day) => {
        const items = (day.items || [])
            .map(normalizeTourItem)
            .sort((a, b) => a.order - b.order);
        const routes = await buildDayRoutesSafely(items, routeService, { transportMode });
        const distanceMeters = Array.isArray(routes)
            ? routes.reduce((sum, route) => sum + (route.distanceMeters || 0), 0)
            : 0;
        const bbox = routeService.calculateBbox([
            ...coordinatesFromTourItems(items),
            ...coordinatesFromTourRoutes(routes)
        ]);

        return {
            ...day,
            items,
            routes,
            distanceMeters,
            bbox
        };
    }));

    const allCoordinates = days.flatMap((day) => [
        ...coordinatesFromTourItems(day.items || []),
        ...coordinatesFromTourRoutes(day.routes || [])
    ]);

    return {
        userId,
        title: aiTour.title,
        destinations: aiTour.destinations || [],
        visibility: aiTour.visibility || 'private',
        totalDays: aiTour.totalDays,
        totalNights: aiTour.totalNights,
        totalDistanceMeters: days.reduce((sum, day) => sum + (day.distanceMeters || 0), 0),
        bbox: routeService.calculateBbox(allCoordinates),
        travelers: aiTour.travelers,
        preferences: aiTour.preferences,
        estimatedCost: aiTour.estimatedCost,
        days,
        ai: aiTour.ai
    };
};

export const removeProtectedTourFields = (payload) => {
    const { _id, userId, createdAt, updatedAt, ...updates } = payload;
    return updates;
};

export const buildLocationLookupFilter = (query) => {
    const id = query.id || query._id;
    const sourceLocationId = query.sourceLocationId || query.sourceLocationID;

    if (id) {
        return { _id: id };
    }

    return { sourceLocationId };
};

export const normalizeLocationPayload = (payload, { partial = false } = {}) => {
    const location = payload.location || {};
    const normalized = {};
    const normalizeImageItem = (item) => {
        if (typeof item === 'string') {
            return item.trim()
                ? { url: item.trim(), publicId: null, source: 'tripadvisor' }
                : null;
        }

        if (!item || typeof item !== 'object') {
            return null;
        }

        const url = String(item.url || '').trim();
        if (!url) {
            return null;
        }

        return {
            url,
            publicId: item.publicId ?? null,
            source: item.source ?? 'tripadvisor'
        };
    };

    const assign = (key, value) => {
        if (!partial || hasOwn(payload, key)) {
            normalized[key] = value;
        }
    };

    assign('sourceLocationId', payload.sourceLocationId ?? null);
    assign('title', payload.title);
    assign('city', payload.city);
    assign('totalScore', payload.totalScore ?? 0);
    assign('ranking', payload.ranking ?? null);
    assign('reviewsCount', payload.reviewsCount ?? 0);
    assign('category', payload.category);
    assign('priceRange', payload.priceRange ?? null);
    assign('description', payload.description ?? null);
    assign('embedding', payload.embedding ?? null);
    assign('searchText', payload.searchText ?? null);
    assign('tags', Array.isArray(payload.tags) ? payload.tags : []);
    assign('openingHours', payload.openingHours ?? null);
    assign(
        'images',
        Array.isArray(payload.images)
            ? payload.images.map(normalizeImageItem).filter(Boolean)
            : []
    );

    if (!partial || hasOwn(payload, 'image')) {
        normalized.image = {
            url: payload.image?.url ?? null,
            publicId: payload.image?.publicId ?? null,
            source: payload.image?.source ?? ''
        };
    }

    if (
        !partial
        || hasOwn(payload, 'location')
        || hasOwn(payload, 'longitude')
        || hasOwn(payload, 'latitude')
    ) {
        const coordinates = Array.isArray(location.coordinates)
            ? location.coordinates
            : [
                parseNumber(payload.longitude),
                parseNumber(payload.latitude)
            ];

        normalized.location = {
            type: location.type || 'Point',
            coordinates
        };
    }

    return normalized;
};

export default {
    parsePositiveInt,
    parseNumber,
    parseBoolean,
    parseGps,
    parsePriceRange,
    filterByPriceRange,
    parseTimeToMinutes,
    parseDateToWeekday,
    buildTextFilter,
    buildLocationFilter,
    buildLocationLookupFilter,
    buildSort,
    normalizeLocationPayload,
    buildTourListFilter,
    buildTourSort,
    normalizeTourPayloadFromAI,
    removeProtectedTourFields
};
