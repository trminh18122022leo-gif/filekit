from fastapi import APIRouter, UploadFile, File, Form
from fastapi.responses import FileResponse
import fitz, img2pdf, os, zipfile, uuid
from pathlib import Path
from pdf2docx import Converter
from PIL import Image
from utils.file_handler import tmp, cleanup

router  = APIRouter()

# ── PDF → WORD ────────────────────────────────────────────────────────────────
@router.post("/pdf-to-word")
async def pdf_to_word(file: UploadFile = File(...)):
    input_path  = tmp(".pdf")
    output_path = tmp(".docx")
    input_path.write_bytes(await file.read())

    cv = Converter(str(input_path))
    cv.convert(str(output_path))
    cv.close()
    cleanup(input_path)

    return FileResponse(
        output_path,
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        filename="converted.docx",
    )

# ── PDF → IMAGES ──────────────────────────────────────────────────────────────
@router.post("/pdf-to-images")
async def pdf_to_images(
    file: UploadFile = File(...),
    fmt: str  = Form("png"),
    dpi: int  = Form(150),
    pages: str = Form("all"),
):
    input_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    doc   = fitz.open(str(input_path))
    total = len(doc)
    mat   = fitz.Matrix(dpi / 72, dpi / 72)

    idxs = (
        list(range(total))
        if pages == "all"
        else [
            n
            for part in pages.split(",")
            for n in (
                range(int(part.split("-")[0]) - 1, int(part.split("-")[1]))
                if "-" in part
                else [int(part) - 1]
            )
        ]
    )

    zip_path = tmp(".zip")
    with zipfile.ZipFile(zip_path, "w") as zf:
        for idx in idxs:
            if 0 <= idx < total:
                pix      = doc[idx].get_pixmap(matrix=mat)
                img_path = tmp(f".{fmt}")
                pix.save(str(img_path), jpg_quality=90 if fmt == "jpg" else None)
                zf.write(img_path, f"page_{idx+1}.{fmt}")
                cleanup(img_path)

    doc.close()
    cleanup(input_path)
    return FileResponse(zip_path, media_type="application/zip", filename="pages.zip")

# ── IMAGES → PDF ──────────────────────────────────────────────────────────────
@router.post("/images-to-pdf")
async def images_to_pdf(files: list[UploadFile] = File(...)):
    img_paths = []
    for f in files:
        ext = os.path.splitext(f.filename)[1].lower() or ".png"
        raw = tmp(ext)
        raw.write_bytes(await f.read())
        jpg = tmp(".jpg")
        Image.open(raw).convert("RGB").save(jpg, quality=95)
        img_paths.append(jpg)
        cleanup(raw)

    output_path = tmp(".pdf")
    with open(output_path, "wb") as out:
        out.write(img2pdf.convert([str(p) for p in img_paths]))

    cleanup(*img_paths)
    return FileResponse(output_path, media_type="application/pdf", filename="images.pdf")

# ── WORD → PDF ────────────────────────────────────────────────────────────────
@router.post("/word-to-pdf")
async def word_to_pdf(file: UploadFile = File(...)):
    import subprocess
    input_path = tmp(".docx")
    input_path.write_bytes(await file.read())
    out_dir = input_path.parent

    try:
        subprocess.run(
            ["libreoffice", "--headless", "--convert-to", "pdf",
             "--outdir", str(out_dir), str(input_path)],
            timeout=30, capture_output=True, check=True,
        )
        out = out_dir / (input_path.stem + ".pdf")
        if out.exists():
            cleanup(input_path)
            return FileResponse(out, media_type="application/pdf", filename="converted.pdf")
    except Exception:
        pass

    # Fallback đơn giản bằng reportlab
    from docx import Document
    from reportlab.platypus import SimpleDocTemplate, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet

    doc    = Document(str(input_path))
    out    = tmp(".pdf")
    styles = getSampleStyleSheet()
    story  = [
        Paragraph(p.text, styles["Heading1"] if p.style.name.startswith("Heading") else styles["Normal"])
        for p in doc.paragraphs if p.text.strip()
    ]
    SimpleDocTemplate(str(out)).build(story)
    cleanup(input_path)
    return FileResponse(out, media_type="application/pdf", filename="converted.pdf")