import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from openai import AsyncOpenAI
from dotenv import load_dotenv

load_dotenv()  # tao file .env ngang hang voi thu muc src de luu OPENAI_API_KEY

app = FastAPI(title="AI Recommendation Service")

client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

class PromptRequest(BaseModel):
    prompt: str

@app.post("/api/v1/ai/generate")
async def generate_response(request: PromptRequest):
    """
    Endpoint nhận prompt từ người dùng và trả về kết quả từ gpt-4o-mini.
    """
    if not request.prompt:
        raise HTTPException(status_code=400, detail="Prompt không được để trống")

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Bạn là trợ lý du lịch thông minh, chuyên gợi ý địa điểm ăn uống tại TP.HCM."},
                {"role": "user", "content": request.prompt}
            ],
            temperature=0.7
        )

        return {
            "status": "success",
            "data": response.choices[0].message.content
        }

    except Exception as e:
        print(f"Lỗi OpenAI: {e}")
        raise HTTPException(status_code=500, detail="Lỗi xử lý AI")
