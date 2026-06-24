import asyncio
import json
import os
import sys

# Ensure we can import from src
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from openai import AsyncOpenAI
from src.core.config import settings

async def main():
    client = AsyncOpenAI(api_key=settings.openai_api_key)
    print("Bắt đầu sinh 100 câu hỏi và trả lời...")

    prompt = """
    Bạn là một chuyên gia tạo dữ liệu kiểm thử. Dựa vào tài liệu Hướng dẫn sử dụng của ứng dụng TourXport dưới đây, hãy sinh ra ĐÚNG 100 câu hỏi thường gặp của người dùng và câu trả lời mong muốn cho mỗi câu hỏi.

    [TÀI LIỆU HƯỚNG DẪN SỬ DỤNG TOURXPORT]
    1. Tài khoản & Cài đặt: Đăng ký/Đăng nhập để dùng app. Chỉnh profile, đổi ngôn ngữ, bật thông báo, đặt mã PIN.
    2. Khám phá địa điểm: Xem tỉnh thành, khách sạn, nhà hàng. Xem bản đồ, thời tiết.
    3. Lên lịch trình: Làm khảo sát (Survey) để tạo Tour thông minh. Xem chi tiết lộ trình, lưu (Save) địa điểm và Tour.
    4. Tương tác & Cộng đồng: Viết Đánh giá (Review) cho địa điểm. Viết Nhật ký du lịch (Travel Memory).
    (Lưu ý: Không bịa đặt tính năng như thanh toán hay đặt vé máy bay).

    [YÊU CẦU]
    - Sinh ra đúng 100 câu khác nhau.
    - Trả về danh sách theo định dạng JSON hợp lệ, có cấu trúc như sau (chỉ trả về JSON, không kèm markdown code block):
    [
        {
            "id": 1,
            "question": "Làm sao để tạo một lịch trình mới?",
            "expected_answer": "Bạn có thể vào tính năng Tạo lịch trình, làm một bài khảo sát ngắn về sở thích và ngân sách, ứng dụng sẽ tự động sinh lịch trình cho bạn."
        },
        ...
    ]
    """

    response = await client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": "You are a helpful assistant that strictly outputs JSON."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        max_tokens=16000,
        response_format={ "type": "json_object" } # Using json_object requires the prompt to specify it. Wait, the schema above is a list. json_object requires dict. Let's adjust prompt.
    )

    # Note: if using response_format="json_object", the output MUST be a JSON object, not an array. Let's fix the prompt to output an object with a "dataset" key.
    pass

async def main_fixed():
    client = AsyncOpenAI(api_key=settings.openai_api_key)
    print("Bắt đầu sinh 100 câu hỏi và trả lời...")

    wiki_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "tourxport_wiki.md")
    with open(wiki_path, "r", encoding="utf-8") as f:
        wiki_content = f.read()

    prompt = f"""
    Bạn là một chuyên gia tạo dữ liệu kiểm thử. Dựa vào TÀI LIỆU HƯỚNG DẪN SỬ DỤNG siêu chi tiết của ứng dụng TourXport dưới đây, hãy sinh ra ĐÚNG 100 câu hỏi thường gặp của người dùng và câu trả lời mong muốn cho mỗi câu hỏi.
    
    [TÀI LIỆU WIKI CHI TIẾT]
    {wiki_content}

    [YÊU CẦU QUAN TRỌNG]
    - Tuyệt đối chỉ sinh ra các câu hỏi và câu trả lời dựa trên thông tin CÓ THẬT trong tài liệu.
    - KHÔNG được bịa đặt các tính năng không có (như thanh toán, kết bạn, đặt vé, lịch điện thoại).
    - Câu trả lời phải bám sát chính xác từng bước, từng nút bấm được miêu tả trong tài liệu.
    - Sinh ra đúng 100 câu khác nhau.
    
    Hãy trả về một đối tượng JSON duy nhất chứa mảng "dataset". Ví dụ:
    {{
      "dataset": [
        {{"id": 1, "question": "Làm sao tạo lịch trình?", "expected_answer": "Bạn chọn Tab Tạo Lịch Trình ở thanh điều hướng..."}},
        ...
      ]
    }}
    """

    response = await client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You strictly output valid JSON."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        response_format={ "type": "json_object" },
        max_tokens=10000
    )

    content = response.choices[0].message.content
    try:
        data = json.loads(content)
        dataset = data.get("dataset", [])
        print(f"Đã sinh được {len(dataset)} câu.")
        
        out_path = os.path.join(os.path.dirname(__file__), "dataset.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(dataset, f, ensure_ascii=False, indent=2)
        print(f"Đã lưu vào {out_path}")
    except Exception as e:
        print("Lỗi parse JSON:", e)
        print(content)

if __name__ == "__main__":
    asyncio.run(main_fixed())
