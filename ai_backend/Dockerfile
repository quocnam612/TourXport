# 1. Khởi tạo môi trường gốc (Base Image)
FROM python:3.10-slim

# 2. Tạo thư mục làm việc bên trong Container
WORKDIR /app

# 3. Copy TRƯỚC file danh sách thư viện
COPY requirements.txt .

# 4. Cài đặt thư viện
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy TOÀN BỘ mã nguồn còn lại vào Container
COPY . .

# 6. Mở cổng giao tiếp
EXPOSE 8000

# 7. Lệnh khởi chạy server (Lưu ý đường dẫn src.main)
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]