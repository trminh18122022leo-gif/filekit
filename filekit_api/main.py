from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from routers import pdf, convert, image, advanced

app = FastAPI(title="FileKit Pro API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(pdf.router,      prefix="/api/pdf",      tags=["PDF"])
app.include_router(convert.router,  prefix="/api/convert",  tags=["Convert"])
app.include_router(image.router,    prefix="/api/image",    tags=["Image"])
app.include_router(advanced.router, prefix="/api/advanced", tags=["Advanced"])

@app.get("/health")
async def health(): return {"status": "ok"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)