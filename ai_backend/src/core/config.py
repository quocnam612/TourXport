from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    jwt_key: str ="hello"
    openai_api_key: str = "hello"
    mongo_uri: str = "hello"

    # uu tien lay bien env cua docker hon, neu khong co moi lay tu file .env cua thu muc ai_backend
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )

settings = Settings()

