import asyncio
import json
import os
import sys
import uuid
import time

# Ensure we can import from src
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from openai import AsyncOpenAI
from pymongo import AsyncMongoClient
from src.core.config import settings
from src.services.chat.manager import GuideChatService
from src.schemas.request.guide_chat import GuideChatRequest

# Prompt for the Judge LLM
JUDGE_PROMPT = """
Bạn là một Giám khảo chấm điểm độ chính xác cho câu trả lời của Trợ lý ảo AI.
Bạn được cung cấp CÂU HỎI của người dùng, CÂU TRẢ LỜI MONG ĐỢI (Expected Answer), và CÂU TRẢ LỜI THỰC TẾ (AI Answer).
Dựa trên mức độ trùng khớp về mặt NỘI DUNG VÀ Ý NGHĨA (không cần giống y hệt từng từ), hãy chấm điểm độ chính xác theo thang điểm từ 0 đến 100.

Hãy trả về kết quả định dạng JSON với cấu trúc:
{
    "score": 100,
    "reason": "Giải thích ngắn gọn tại sao lại cho điểm này."
}
"""

async def evaluate_answer(client: AsyncOpenAI, question: str, expected: str, actual: str) -> dict:
    prompt = f"""
    CÂU HỎI: {question}
    
    CÂU TRẢ LỜI MONG ĐỢI: 
    {expected}
    
    CÂU TRẢ LỜI THỰC TẾ:
    {actual}
    """
    
    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": JUDGE_PROMPT},
                {"role": "user", "content": prompt}
            ],
            temperature=0.0,
            response_format={ "type": "json_object" },
            max_tokens=300
        )
        result = json.loads(response.choices[0].message.content)
        return {
            "score": result.get("score", 0),
            "reason": result.get("reason", "")
        }
    except Exception as e:
        print(f"Error evaluating: {e}")
        return {"score": 0, "reason": f"Lỗi gọi OpenAI Judge: {e}"}

async def process_item(item: dict, service: GuideChatService, client: AsyncOpenAI):
    question = item["question"]
    expected = item["expected_answer"]
    
    # Tạo payload ảo, dùng session_id riêng để không bị dính lịch sử
    payload = GuideChatRequest(session_id=uuid.uuid4(), content=question)
    
    # Gọi service (thay vì qua API HTTP)
    start_time = time.time()
    try:
        ai_answer = await service.handle_chat(payload=payload, user_id="benchmark")
    except Exception as e:
        ai_answer = f"Lỗi hệ thống: {e}"
        
    latency = time.time() - start_time
    
    # Chấm điểm
    evaluation = await evaluate_answer(client, question, expected, ai_answer)
    
    return {
        "id": item.get("id"),
        "question": question,
        "expected_answer": expected,
        "ai_answer": ai_answer,
        "score": evaluation["score"],
        "reason": evaluation["reason"],
        "latency_sec": round(latency, 2)
    }

async def main():
    dataset_path = os.path.join(os.path.dirname(__file__), "dataset.json")
    if not os.path.exists(dataset_path):
        print(f"File {dataset_path} không tồn tại!")
        return

    with open(dataset_path, "r", encoding="utf-8") as f:
        dataset = json.load(f)

    # Khởi tạo OpenAI Client và Database Client
    client = AsyncOpenAI(api_key=settings.openai_api_key)
    
    db_client = AsyncMongoClient(settings.mongo_uri)
    db = db_client[settings.mongo_db_name]
    
    service = GuideChatService(db=db, openai_client=client)

    print(f"Bắt đầu Benchmark cho {len(dataset)} câu hỏi...")
    
    results = []
    # Xử lý đồng thời (concurrently) 10 câu một lúc để tăng tốc độ
    semaphore = asyncio.Semaphore(10)
    
    async def sem_process(item):
        async with semaphore:
            res = await process_item(item, service, client)
            print(f"Câu {res['id']}: Score = {res['score']}")
            return res

    tasks = [sem_process(item) for item in dataset]
    results = await asyncio.gather(*tasks)
    
    # Đóng kết nối
    db_client.close()
    
    # Tính toán kết quả
    total_score = sum(r["score"] for r in results)
    avg_score = total_score / len(results) if results else 0
    avg_latency = sum(r["latency_sec"] for r in results) / len(results) if results else 0
    
    print("-" * 30)
    print(f"Đã hoàn thành! Điểm trung bình (Accuracy): {avg_score:.2f}%")
    print(f"Tốc độ phản hồi trung bình: {avg_latency:.2f}s")
    print("-" * 30)
    
    # Lưu báo cáo
    report = {
        "summary": {
            "total_questions": len(results),
            "average_score": avg_score,
            "average_latency_sec": avg_latency
        },
        "details": results
    }
    
    out_path = os.path.join(os.path.dirname(__file__), "benchmark_results_6.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(f"Đã lưu kết quả tại {out_path}")

if __name__ == "__main__":
    asyncio.run(main())
