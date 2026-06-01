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
    { keys: ['An Giang'], cities: [ 'An Giang', 'Châu Đốc', 'Long Xuyên', 'Nui To', 'Tỉnh An Giang', 'Tinh Bien'] },
    { keys: ['Bà Rịa - Vũng Tàu'], cities: [ 'Bà Rịa', 'Bà Rịa - Vũng Tàu', 'Binh Chau', 'Bung Rieng', 'Hồ Tràm', 'Long Hải', 'Phú Mỹ', 'Phuoc Thuan', 'Phước Hải', 'Tam Phuoc', 'Tỉnh Bà Rịa - Vũng Tàu', 'Tỉnh Bà Rịa-Vũng Tàu', 'Vũng Tàu', 'Xuyen Moc'] },
    { keys: ['Bắc Giang'], cities: [ 'Bac Giang', 'Bắc Giang', 'Thạch Son', 'Thi tran Nenh', 'Thuong Lat', 'Tỉnh Bắc Giang'] },
    { keys: ['Bắc Kạn'], cities: [ 'Ba Be', 'Bắc Kạn', 'Nam Mau', 'Tỉnh Bắc Kạn'] },
    { keys: ['Bạc Liêu'], cities: [ 'Bac Lieu', 'Bạc Liêu', 'Tỉnh Bạc Liêu'] },
    { keys: ['Bắc Ninh'], cities: [ 'Bắc Ninh', 'Đình Bảng', 'Tỉnh Bắc Ninh'] },
    { keys: ['Bến Tre'], cities: [ 'An Khánh', 'Ba Tri', 'Bến Tre', 'Bến Tre', 'Châu Hưng', 'Tỉnh Bến Tre'] },
    { keys: ['Bình Định'], cities: [ 'Bình Định', 'Cát Tiến', 'Hoi Van', 'My Tho', 'Phuoc Hiep', 'Phuoc Thuan', 'Quy Nhơn', 'Tay Son', 'Tỉnh Bình Định'] },
    { keys: ['Bình Dương'], cities: [ 'Bình Dương', 'Di An', 'Tan Uyen', 'Thủ Dầu Một', 'Thuan An', 'Tỉnh Bình Dương'] },
    { keys: ['Bình Phước'], cities: [ 'Bình Phước', 'Phu Rieng', 'Phuoc Long', 'Tỉnh Bình Phước'] },
    { keys: ['Bình Thuận'], cities: [ 'Bình Thuận', 'Ham Tien', 'Hoa Thang', 'Kê Gà', 'Khánh Hải', 'Lagi', 'Mũi Né', 'Phan Thiết', 'Phu Hai', 'Tan Thanh', 'Thi Tran Thuan Nam', 'Tien Thanh', 'Tỉnh Bình Thuận', 'Vĩnh Hảo'] },
    { keys: ['Cà Mau'], cities: [ 'Cà Mau', 'Cà Mau', 'Tỉnh Cà Mau'] },
    { keys: ['Can Tho', 'Cần Thơ', 'Thành phố Cần Thơ', 'TP. Cần Thơ'], cities: [ 'Can Tho', 'Cần Thơ', 'Cần Thơ', 'Thành phố Cần Thơ', 'Tỉnh Cần Thơ', 'TP. Cần Thơ'] },
    { keys: ['Cao Bằng'], cities: [ 'Bao Lac', 'Cao Bằng', 'Cao Bằng', 'Dam Thuy', 'Phuc Sen', 'Tỉnh Cao Bằng', 'Trung Khanh', 'Truong Ha'] },
    { keys: ['Da Nang', 'Đà Nẵng', 'Thành phố Đà Nẵng', 'TP. Đà Nẵng'], cities: [ 'Da Nang', 'Đà Nẵng', 'Đà Nẵng', 'Điện Bàn', 'Hai Chau', 'Hoa Hai', 'Hòa Phú', 'My An', 'Phuoc My', 'Son Tra Peninsula', 'Thành phố Đà Nẵng', 'Tho Quang', 'Tỉnh Đà Nẵng', 'TP. Đà Nẵng'] },
    { keys: ['Đắk Lắk'], cities: [ 'An Chan', 'An Ninh Dong', 'Buôn Ma Thuột', 'Đắk Lắk', 'Ea Huar', 'Hoa Tam', 'Krong Bong', 'Phu My', 'Thị trấn Sông Cầu', 'Tỉnh Đắk Lắk', 'Tỉnh Đắk Lắk', 'Tuy Hòa', 'Xuan Thinh'] },
    { keys: ['Đắk Nông'], cities: [ 'Cu Jut District', 'Dak Mil', 'Dak Som', 'Đắk Nông', 'Gia Nghĩa', 'Nam N\'Jang', 'Quang Khe', 'Tỉnh Đắk Nông', 'Tuy Duc'] },
    { keys: ['Điện Biên'], cities: [ 'Điện Biên', 'Điện Biên Phủ', 'Muong Phan', 'Tỉnh Điện Biên'] },
    { keys: ['Đồng Nai'], cities: [ 'Biên Hòa', 'Doc Mo', 'Đồng Nai', 'Gia Tan 1', 'Nam Cát Tiên', 'Nhon Trach', 'Tan Phu', 'Thái Thiên', 'Tỉnh Đồng Nai', 'Trảng Bom'] },
    { keys: ['Đồng Tháp'], cities: [ 'Cao Lãnh', 'Đồng Tháp', 'Hong Ngu', 'Sa Đéc', 'Tỉnh Đồng Tháp', 'Tram Chim'] },
    { keys: ['Gia Lai'], cities: [ 'Gia Lai', 'Pleiku', 'Tỉnh Gia Lai'] },
    { keys: ['Hà Giang'], cities: [ 'Đồng Văn', 'Hà Giang', 'Hà Giang', 'Mèo Vạc', 'Quan Ba', 'Tỉnh Hà Giang', 'Xin Man'] },
    { keys: ['Hà Nam'], cities: [ 'Ba Sao', 'Duy Hai', 'Hà Nam', 'Kim Bang', 'Liem Son', 'Phu Ly', 'Tỉnh Hà Nam'] },
    { keys: ['Ha Noi', 'Hà Nội', 'Thành phố Hà Nội', 'TP. Hà Nội'], cities: [ 'Ba Dinh', 'Bắc Từ Liêm', 'Cau Giay', 'Gia Lam', 'Ha Dong', 'Ha Noi', 'Hà Nội', 'Hoai Duc', 'Hoan Kiem', 'Mai Dinh', 'Me Tri', 'Nam Từ Liêm', 'Tay Ho', 'Thành phố Hà Nội', 'Thanh Xuan', 'Tỉnh Hà Nội', 'TP. Hà Nội'] },
    { keys: ['Hà Tĩnh'], cities: [ 'Hà Tĩnh', 'Thiên Cầm', 'Tỉnh Hà Tĩnh'] },
    { keys: ['Hải Dương'], cities: [ 'An Nhân', 'Hải Dương', 'Hải Dương', 'Tỉnh Hải Dương'] },
    { keys: ['Hai Phong', 'Hải Phòng', 'Thành phố Hải Phòng', 'TP. Hải Phòng'], cities: [ 'Cat Ba Town', 'Cat Hai', 'Do Son', 'Gia Luan', 'Hai Phong', 'Hải Phòng', 'Thành phố Hải Phòng', 'Thành phố Hải Phòng', 'Tỉnh Hải Phòng', 'TP. Hải Phòng'] },
    { keys: ['Hậu Giang'], cities: [ 'Hậu Giang', 'Tỉnh Hậu Giang', 'Vi Thanh'] },
    { keys: ['Hồ Chí Minh', 'Sai Gon', 'Sài Gòn', 'Thành phố Hồ Chí Minh', 'TP Hồ Chí Minh', 'TP. Hồ Chí Minh'], cities: [ 'Hồ Chí Minh', 'Sai Gon', 'Sài Gòn', 'Thành phố Hồ Chí Minh', 'Tỉnh TP. Hồ Chí Minh', 'TP Hồ Chí Minh', 'TP. Hồ Chí Minh'] },
    { keys: ['Hòa Bình'], cities: [ 'Cao Phong', 'Hang Kia', 'Hòa Bình', 'Hòa Bình', 'Mai Châu', 'Pà Cò', 'Tỉnh Hòa Bình'] },
    { keys: ['Huế', 'Thành phố Huế', 'Thừa Thiên Huế', 'TP. Huế'], cities: [ 'Huế', 'Huế', 'Huong Thuy', 'Lăng Cô', 'Lộc Tiễn', 'Phong Son', 'Phú Lộc', 'Quảng Lợi', 'Thành phố Huế', 'Thừa Thiên Huế', 'Tỉnh Thừa Thiên - Huế', 'Tỉnh Thừa Thiên Huế', 'TP. Huế', 'Vinh An'] },
    { keys: ['Hưng Yên'], cities: [ 'Hưng Yên', 'Tỉnh Hưng Yên'] },
    { keys: ['Khánh Hòa'], cities: [ 'Cam Đức', 'Cam Hải Đông', 'Cam Ranh', 'Dien Thọ', 'Khánh Hòa', 'Khánh Hòa', 'Khanh Phu', 'Khanh Vinh', 'Nha Trang', 'Ninh Hiep', 'Ninh Hoa', 'Tỉnh Khánh Hòa', 'Van Ninh'] },
    { keys: ['Kiên Giang'], cities: [ 'An Thoi', 'Cua Can', 'Dương Đông', 'Dương Tơ', 'Ganh Dau', 'Hà Tiên', 'Hàm Ninh', 'Kiên Giang', 'Ong Lang', 'Rạch Giá', 'Suoi May', 'Tỉnh Kiên Giang', 'Vi Thanh'] },
    { keys: ['Kon Tum'], cities: [ 'Dak Long', 'Kon Tum', 'Kontum', 'Măng Đen', 'Tỉnh Kon Tum'] },
    { keys: ['Lai Châu'], cities: [ 'Lai Châu', 'Phong Tho', 'Tam Đường', 'Tỉnh Lai Châu'] },
    { keys: ['Lâm Đồng'], cities: [ 'Bảo Lộc', 'Dalat', 'Di Linh', 'Đà Lạt', 'Gia Lam', 'Lac Duong', 'Lat', 'Lâm Đồng', 'Lâm Đồng', 'Madagui Town', 'Me Linh', 'Phi To', 'Phuong 8', 'Thị Tran Nam Ban', 'Tỉnh Lâm Đồng', 'Tu Tra'] },
    { keys: ['Lạng Sơn'], cities: [ 'Bac Son', 'Lạng Sơn', 'Tỉnh Lạng Sơn'] },
    { keys: ['Lào Cai'], cities: [ 'Bắc Hà', 'Hau Thao', 'Lào Cai', 'Lào Cai', 'Lao Chai', 'Mu Cang Chai', 'Sapa', 'Ta Phin', 'Tỉnh Lào Cai'] },
    { keys: ['Long An'], cities: [ 'Ben Luc', 'Can Duoc', 'Long An', 'Moc Hoa', 'Tan My', 'Tân An', 'Tỉnh Long An'] },
    { keys: ['Nam Định'], cities: [ 'Nam Dinh', 'Nam Định', 'Tỉnh Nam Định'] },
    { keys: ['Nghệ An'], cities: [ 'Con Cuong', 'Cửa Lò', 'Hung Thịnh', 'Nghệ An', 'Nghia Thuan', 'Que Phong', 'Quy Hop', 'Quynh Nghia', 'Thanh An', 'Tỉnh Nghệ An', 'Vinh'] },
    { keys: ['Ninh Bình'], cities: [ 'Gia Sinh', 'Gia Vien', 'Ninh Bình', 'Ninh Bình', 'Ninh Hai', 'Ninh Xuân', 'Tỉnh Ninh Bình', 'Truong Yen'] },
    { keys: ['Ninh Thuận'], cities: [ 'Cong Hai', 'Khanh Hai', 'Ninh Thuan Province', 'Ninh Thuận', 'Phan Rang-Tháp Chàm', 'Tỉnh Ninh Thuận', 'Vinh Hai'] },
    { keys: ['Phú Thọ'], cities: [ 'Hien Luong', 'Phú Thọ', 'Thanh Thuy', 'Tỉnh Phú Thọ', 'Viet Tri', 'Xuan Dai'] },
    { keys: ['Phú Yên'], cities: [ 'Phú Yên', 'Tỉnh Phú Yên', 'Tuy Hòa'] },
    { keys: ['Quảng Bình'], cities: [ 'Canh Duong', 'Đồng Hới', 'Hung Trach', 'Minh Hoa', 'Phong Nha', 'Phúc Trạch', 'Quảng Bình', 'Quang Đong', 'Quang Ninh', 'Son Trach', 'Tỉnh Quảng Bình'] },
    { keys: ['Quảng Nam'], cities: [ 'An Hoi', 'Binh Minh', 'Cam Ha', 'Cam Pho', 'Duy Hai', 'Duy Phú', 'Điện Dương', 'Điện Tiến', 'Hội An', 'Minh An', 'Prao', 'Quảng Nam', 'Tam Kỳ', 'Tan An', 'Tỉnh Quảng Nam'] },
    { keys: ['Quảng Ngãi'], cities: [ 'Quảng Ngãi', 'Quảng Ngãi', 'Tỉnh Quảng Ngãi'] },
    { keys: ['Quảng Ninh'], cities: [ 'Bai Chay', 'Cam Pha', 'Dong Trieu', 'Ha Long City', 'Móng Cái', 'Quan Lạn', 'Quảng Ninh', 'Thị Tran Co To', 'Tỉnh Quảng Ninh', 'Uong Bi', 'Van Don', 'Vịnh Hạ Long'] },
    { keys: ['Quảng Trị'], cities: [ 'Đông Hà', 'Hai Phu', 'Khe Sanh', 'Quang Tri', 'Quảng Trị', 'Tỉnh Quảng Trị', 'Vinh Linh', 'Vinh Truong'] },
    { keys: ['Sóc Trăng'], cities: [ 'Nga Nam', 'Phu Loc', 'Sóc Trăng', 'Sóc Trăng', 'Tỉnh Sóc Trăng'] },
    { keys: ['Sơn La'], cities: [ 'Chieng On', 'Mộc Châu', 'Muong Sang', 'Ngoc Chien', 'Sơn La', 'Tỉnh Sơn La', 'Van Ho'] },
    { keys: ['Tây Ninh'], cities: [ 'Tây Ninh', 'Tỉnh Tây Ninh'] },
    { keys: ['Thái Bình'], cities: [ 'Dong Hung District', 'Duy Nhat', 'Thái Bình', 'Tỉnh Thái Bình'] },
    { keys: ['Thái Nguyên'], cities: [ 'Thái Nguyên', 'Thái Nguyên', 'Tỉnh Thái Nguyên'] },
    { keys: ['Thanh Hóa'], cities: [ 'Ba Thuoc', 'Cam Luong', 'Co Lung', 'Nga Thien', 'Sầm Sơn', 'Thanh Hóa', 'Thanh Hóa', 'Thanh Yen', 'Tỉnh Thanh Hóa', 'Tri Nang', 'Trieu Loc', 'Vinh Long', 'Vinh Tien'] },
    { keys: ['Tiền Giang'], cities: [ 'Mỹ Tho', 'Phu Tan', 'Thạnh Tan', 'Tiền Giang', 'Tỉnh Tiền Giang'] },
    { keys: ['Trà Vinh'], cities: [ 'Duyên Hải', 'Phu Can', 'Tan Binh', 'Thị Tran Chau Thanh', 'Tỉnh Trà Vinh', 'Trà Vinh', 'Trà Vinh', 'Trường Long Hòa'] },
    { keys: ['Tuyên Quang'], cities: [ 'Tỉnh Tuyên Quang', 'Tuyên Quang'] },
    { keys: ['Vĩnh Long'], cities: [ 'Bình Minh', 'Tỉnh Vĩnh Long', 'Vĩnh Long', 'Vĩnh Long'] },
    { keys: ['Vĩnh Phúc'], cities: [ 'Ngoc Thanh', 'Phúc Yên', 'Tam Đảo', 'Tỉnh Vĩnh Phúc', 'Trung My', 'Vĩnh Phúc', 'Vinh Tuong', 'Vĩnh Yên'] },
    { keys: ['Yên Bái'], cities: [ 'Pung Luong', 'Tỉnh Yên Bái', 'Van Chan District', 'Yên Bái', 'Yên Bái'] },
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
