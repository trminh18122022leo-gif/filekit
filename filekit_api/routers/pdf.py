from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import FileResponse
from typing import List
import pikepdf, fitz
from reportlab.pdfgen import canvas
from utils.file_handler import tmp, cleanup
import zipfile, uuid
from pathlib import Path
import tempfile
import uuid
from pathlib import Path

router = APIRouter()

# ── MERGE ─────────────────────────────────────────────────────────────────────
@router.post("/merge")
async def merge_pdfs(files: List[UploadFile] = File(...)):
    if len(files) < 2:
        raise HTTPException(400, "Cần ít nhất 2 file PDF")

    input_paths = []
    try:
        for f in files:
            p = tmp(".pdf")
            p.write_bytes(await f.read())
            input_paths.append(p)

        output = tmp(".pdf")
        merger = pikepdf.Pdf.new()
        for p in input_paths:
            with pikepdf.Pdf.open(p) as src:
                merger.pages.extend(src.pages)
        merger.save(output)

        return FileResponse(output, media_type="application/pdf", filename="merged.pdf")
    finally:
        cleanup(*input_paths)

# ── SPLIT ─────────────────────────────────────────────────────────────────────
@router.post("/split")
async def split_pdf(
    file: UploadFile = File(...),
    page_ranges: str = Form("1,2,3"),  # "1-3,5,7-9"
):
    input_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    output_dir = Path(tempfile.gettempdir()) / "filekit" / str(uuid.uuid4())
    output_dir.mkdir(parents=True)

    with pikepdf.Pdf.open(input_path) as pdf:
        total = len(pdf.pages)
        groups = []
        for part in page_ranges.split(","):
            part = part.strip()
            if "-" in part:
                s, e = part.split("-")
                groups.append(list(range(int(s) - 1, int(e))))
            else:
                groups.append([int(part) - 1])

        zip_path = tmp(".zip")
        with zipfile.ZipFile(zip_path, "w") as zf:
            for i, group in enumerate(groups):
                out = pikepdf.Pdf.new()
                for idx in group:
                    if 0 <= idx < total:
                        out.pages.append(pdf.pages[idx])
                out_path = output_dir / f"split_{i+1}.pdf"
                out.save(out_path)
                zf.write(out_path, out_path.name)

    cleanup(input_path)
    import shutil; shutil.rmtree(output_dir, ignore_errors=True)
    return FileResponse(zip_path, media_type="application/zip", filename="split.zip")

# ── COMPRESS ──────────────────────────────────────────────────────────────────
@router.post("/compress")
async def compress_pdf(
    file: UploadFile = File(...),
    quality: str = Form("medium"),  # low | medium | high
):
    dpi_map   = {"low": 72,  "medium": 120, "high": 150}
    qual_map  = {"low": 40,  "medium": 65,  "high": 85}

    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    dpi   = dpi_map.get(quality, 120)
    qual  = qual_map.get(quality, 65)
    mat   = fitz.Matrix(dpi / 72, dpi / 72)

    src = fitz.open(str(input_path))
    out = fitz.open()

    for page in src:
        pix       = page.get_pixmap(matrix=mat, colorspace=fitz.csRGB)
        img_bytes = pix.tobytes("jpg", jpg_quality=qual)  # không cần ghi file tạm

        new_page = out.new_page(width=page.rect.width, height=page.rect.height)
        new_page.insert_image(new_page.rect, stream=img_bytes)  # show_pdf_page() lỗi "is no PDF" trên ảnh, phải dùng insert_image()

    out.save(str(output_path), garbage=4, deflate=True, clean=True)
    src.close(); out.close()
    cleanup(input_path)

    return FileResponse(output_path, media_type="application/pdf", filename="compressed.pdf")

# ── WATERMARK ─────────────────────────────────────────────────────────────────
@router.post("/watermark")
async def add_watermark(
    file: UploadFile = File(...),
    text: str   = Form("CONFIDENTIAL"),
    opacity: float = Form(0.3),
    angle: float   = Form(45),
    color: str     = Form("#FF0000"),
    font_size: int = Form(60),
):
    r = int(color[1:3], 16) / 255
    g = int(color[3:5], 16) / 255
    b = int(color[5:7], 16) / 255

    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    doc = fitz.open(str(input_path))
    for page in doc:
        center = fitz.Point(page.rect.width / 2, page.rect.height / 2)
        page.insert_text(
            center, text, fontsize=font_size, color=(r, g, b),
            morph=(center, fitz.Matrix(angle)),  # rotate= chỉ nhận bội số 90, muốn góc bất kỳ (45°) phải dùng morph
            overlay=True,
        )
    doc.save(str(output_path))
    doc.close()
    cleanup(input_path)
    return FileResponse(output_path, media_type="application/pdf", filename="watermarked.pdf")

# ── PROTECT ───────────────────────────────────────────────────────────────────
@router.post("/protect")
async def protect_pdf(
    file: UploadFile = File(...),
    password: str    = Form(...),
    allow_print: bool = Form(True),
    allow_copy: bool  = Form(False),
):
    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    with pikepdf.Pdf.open(input_path) as pdf:
        perms = pikepdf.Permissions(
            print_lowres=allow_print,
            print_highres=allow_print,
            extract=allow_copy,
            modify_annotation=False,
            modify_other=False,
        )
        pdf.save(output_path, encryption=pikepdf.Encryption(
            user=password, owner=password + "_admin", R=6, allow=perms
        ))

    cleanup(input_path)
    return FileResponse(output_path, media_type="application/pdf", filename="protected.pdf")

# ── PAGE NUMBERS ──────────────────────────────────────────────────────────────
@router.post("/page-numbers")
async def add_page_numbers(
    file: UploadFile = File(...),
    position: str   = Form("bottom-center"),
    start_from: int = Form(1),
    fmt: str        = Form("{n}"),
):
    input_path  = tmp(".pdf")
    output_path = tmp(".pdf")
    input_path.write_bytes(await file.read())

    doc   = fitz.open(str(input_path))
    total = len(doc)

    for i, page in enumerate(doc):
        text = fmt.replace("{n}", str(i + start_from)).replace("{total}", str(total))
        w, h = page.rect.width, page.rect.height
        pts  = {
            "bottom-center": fitz.Point(w / 2,     h - 20),
            "bottom-left":   fitz.Point(40,         h - 20),
            "bottom-right":  fitz.Point(w - 40,     h - 20),
            "top-center":    fitz.Point(w / 2,      20),
            "top-left":      fitz.Point(40,          20),
            "top-right":     fitz.Point(w - 40,      20),
        }
        page.insert_text(pts.get(position, pts["bottom-center"]), text, fontsize=10)

    doc.save(str(output_path))
    doc.close()
    cleanup(input_path)
    return FileResponse(output_path, media_type="application/pdf", filename="numbered.pdf")