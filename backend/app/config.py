from pathlib import Path

from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict

root_dir = Path(__file__).resolve().parent.parent
env_paths = [root_dir / ".env", root_dir.parent / ".env"]
for path in env_paths:
    if path.exists():
        load_dotenv(path)

class Settings(BaseSettings):
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""

    model_config = SettingsConfigDict(env_file=[str(path) for path in env_paths], extra="ignore")

settings = Settings()
