from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import FileResponse, JSONResponse
import fitz, re, os, qrcode, io, requests
from utils.file_handler import tmp, cleanup

router = APIRouter()

# ── FEATURE 16: FONT → HANDWRITING ───────────────────────────────────────────
@router.post("/font-to-handwriting")
async def font_to_handwriting(
    file: UploadFile = File(...),
    style: str = Form("caveat"),  # caveat | kalam | dancingscript
):
    """
    Đổi chữ in sang font viết tay bằng Google Fonts (free).
    Download TTF về cache, dùng PyMuPDF redact + re-render.
    """
    FONT_DOWNLOAD = {
        "caveat":        "https://fonts.gstatic.com/s/caveat/v17/WnznHAc5bAfYB2QRah7pcpNvOx-pjcJ9eIKjYBxPigs.ttf",
        "kalam":         "https://fonts.gstatic.com/s/kalam/v16/YA9dr0Wd4kDdMuhWMibDszkAqA.ttf",
        "dancingscript": "https://fonts.gstatic.com/s/dancingscript/v25/If2cXTr6YS-zF4S-kcSWSVi_sxjsohD9F50Ruu7BMSo3ROp6.ttf",
    }

    cache_dir = tmp("").parent / "fonts"
    cache_dir.mkdir(exist_ok=True)
    font_path = cache_dir / f"{style}.ttf"

    if not font_path.exists():
        url = FONT_DOWNLOAD.get(style, FONT_DOWNLOAD["caveat"])
        resp = requests.get(url, timeout=15)
        if resp.status_code == 200:
            font_path.write_bytes(resp.content)

    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    doc = fitz.open(str(input_path))
    for page in doc:
        blocks = page.get_text("dict")["blocks"]
        for block in blocks:
            if block["type"] != 0:
                continue
            for line in block["lines"]:
                for span in line["spans"]:
                    text = span["text"]
                    if not text.strip():
                        continue
                    rect  = fitz.Rect(span["bbox"])
                    color = _int_to_rgb(span.get("color", 0))
                    page.add_redact_annot(rect, fill=(1, 1, 1))
                    page.apply_redactions()
                    kwargs = dict(
                        point=fitz.Point(rect.x0, rect.y1 - 1),
                        text=text,
                        fontsize=span["size"],
                        color=color,
                    )
                    if font_path.exists():
                        kwargs["fontfile"] = str(font_path)
                    page.insert_text(**kwargs)

    doc.save(str(output_path))
    doc.close()
    cleanup(input_path)
    return FileResponse(output_path, media_type="application/pdf", filename="handwriting.pdf")

def _int_to_rgb(c: int):
    return ((c >> 16 & 0xFF) / 255, (c >> 8 & 0xFF) / 255, (c & 0xFF) / 255)

# ── FEATURE 17: AI SUMMARIZER (Gemini Flash — free tier thật, không phải trial) ─
@router.post("/ai-summarize")
async def ai_summarize(
    file: UploadFile = File(...),
    language: str = Form("vi"),      # vi | en
    length: str   = Form("medium"),  # short | medium | detailed
    style: str    = Form("bullets"), # bullets | paragraph | mindmap
):
    from google import genai

    key = os.getenv("GEMINI_API_KEY")
    if not key:
        raise HTTPException(500, "GEMINI_API_KEY chưa được cấu hình")

    input_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    doc  = fitz.open(str(input_path))
    text = "\n".join(page.get_text() for page in doc)[:15000]
    doc.close()
    cleanup(input_path)

    length_map = {
        "short":    "3-5 ý chính, mỗi ý 1 câu ngắn",
        "medium":   "7-10 ý có phân mục, mỗi ý 1-2 câu",
        "detailed": "Tóm tắt chi tiết theo từng phần, 400-600 từ",
    }
    style_map = {
        "bullets":   "danh sách bullet points với ký hiệu •",
        "paragraph": "đoạn văn mạch lạc có liên kết ý",
        "mindmap":   "sơ đồ tư duy text dùng ký tự ASCII (─, ├, └)",
    }
    lang_map = {"vi": "tiếng Việt", "en": "English"}

    client = genai.Client(api_key=key)
    prompt = (
        f"Tóm tắt tài liệu bằng {lang_map.get(language, 'tiếng Việt')}, "
        f"theo format {style_map.get(style)}, "
        f"độ dài {length_map.get(length)}.\n\nTài liệu:\n{text}\n\n"
        f"Chỉ trả về bản tóm tắt, không giải thích thêm."
    )

    response = client.models.generate_content(
        model=os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
        contents=prompt,
    )

    return JSONResponse({"summary": response.text, "char_count": len(text)})

# ── FEATURE 18: SMART TRANSLATE ───────────────────────────────────────────────
@router.post("/translate")
async def translate_pdf(
    file: UploadFile = File(...),
    target_lang: str = Form("VI"),  # VI | EN | JA | KO | FR | DE
):
    import deepl

    key = os.getenv("DEEPL_API_KEY")
    if not key:
        raise HTTPException(500, "DEEPL_API_KEY chưa được cấu hình")

    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    translator = deepl.Translator(key)
    doc        = fitz.open(str(input_path))

    for page in doc:
        for block in page.get_text("dict")["blocks"]:
            if block["type"] != 0:
                continue
            for line in block["lines"]:
                for span in line["spans"]:
                    text = span["text"].strip()
                    if len(text) < 3:
                        continue
                    try:
                        translated = translator.translate_text(text, target_lang=target_lang).text
                        rect  = fitz.Rect(span["bbox"])
                        color = _int_to_rgb(span.get("color", 0))
                        page.add_redact_annot(rect, fill=(1, 1, 1))
                        page.apply_redactions()
                        page.insert_text(
                            fitz.Point(rect.x0, rect.y1 - 1),
                            translated, fontsize=span["size"], color=color,
                        )
                    except Exception:
                        pass

    doc.save(str(output_path))
    doc.close()
    cleanup(input_path)
    return FileResponse(output_path, media_type="application/pdf", filename="translated.pdf")

# ── FEATURE 20: SMART REDACT ──────────────────────────────────────────────────
@router.post("/smart-redact")
async def smart_redact(
    file: UploadFile = File(...),
    redact_types: str = Form("phone,email,cccd"),
):
    PATTERNS = {
        "phone":       r"(\+?84|0)[35789]\d{8}",
        "email":       r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b",
        "cccd":        r"\b\d{9}(\d{3})?\b",
        "credit_card": r"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b",
    }

    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    types = [t.strip() for t in redact_types.split(",")]
    doc   = fitz.open(str(input_path))
    count = 0

    for page in doc:
        text = page.get_text()
        for t in types:
            if t not in PATTERNS:
                continue
            for m in re.finditer(PATTERNS[t], text):
                for rect in page.search_for(m.group()):
                    page.add_redact_annot(rect, fill=(0, 0, 0))
                    count += 1
        page.apply_redactions()

    doc.save(str(output_path))
    doc.close()
    cleanup(input_path)
    return FileResponse(
        output_path, media_type="application/pdf", filename="redacted.pdf",
        headers={"X-Redaction-Count": str(count)},
    )

# ── FEATURE 23: QR INJECTOR ───────────────────────────────────────────────────
@router.post("/inject-qr")
async def inject_qr(
    file: UploadFile = File(...),
    qr_data: str   = Form(...),
    position: str  = Form("bottom-right"),
    size: int      = Form(80),
    pages: str     = Form("all"),
):
    qr  = qrcode.QRCode(box_size=2, border=1)
    qr.add_data(qr_data)
    qr.make(fit=True)
    buf = io.BytesIO()
    qr.make_image(fill_color="black", back_color="white").save(buf, format="PNG")
    qr_bytes = buf.getvalue()

    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    doc     = fitz.open(str(input_path))
    n       = len(doc)
    indices = list(range(n)) if pages == "all" else [int(p) - 1 for p in pages.split(",")]

    for idx in indices:
        if 0 <= idx < n:
            page = doc[idx]
            w, h = page.rect.width, page.rect.height
            m    = 20
            pos  = {
                "top-left":     fitz.Rect(m,       m,       m+size,   m+size),
                "top-right":    fitz.Rect(w-size-m, m,       w-m,      m+size),
                "bottom-left":  fitz.Rect(m,        h-size-m, m+size,  h-m),
                "bottom-right": fitz.Rect(w-size-m, h-size-m, w-m,     h-m),
            }
            page.insert_image(pos.get(position, pos["bottom-right"]), stream=qr_bytes)

    doc.save(str(output_path))
    doc.close()
    cleanup(input_path)
    return FileResponse(output_path, media_type="application/pdf", filename="with_qr.pdf")

# ── FEATURE 27: DARK MODE ─────────────────────────────────────────────────────
@router.post("/dark-mode")
async def dark_mode_pdf(file: UploadFile = File(...)):
    from PIL import ImageOps, Image as PILImage

    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    src = fitz.open(str(input_path))
    out = fitz.open()

    for page in src:
        pix = page.get_pixmap(matrix=fitz.Matrix(1.5, 1.5), colorspace=fitz.csRGB)
        img = PILImage.open(io.BytesIO(pix.tobytes("png"))).convert("RGB")
        inv = ImageOps.invert(img)

        buf = io.BytesIO()
        inv.save(buf, format="PNG")

        new_page = out.new_page(width=page.rect.width, height=page.rect.height)
        new_page.insert_image(new_page.rect, stream=buf.getvalue())

    out.save(str(output_path))
    src.close(); out.close()
    cleanup(input_path)
    return FileResponse(output_path, media_type="application/pdf", filename="dark_mode.pdf")