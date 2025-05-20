from fastapi import FastAPI

app = FastAPI(title="CodexContinue API", description="API for the CodexContinue project")

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "CodexContinue Backend"}

@app.get("/")
async def root():
    return {"message": "Welcome to CodexContinue API", "docs": "/docs"}