from pathlib import Path
import PyPDF2
pdf_path = r"C:\Users\user\Downloads\1762917222-STUDENT HANDBOOK 2025-2026.pdf"
out_path = r"C:\Users\user\Desktop\FLUTTER\GappiMobileApp\mobileapp\assets\student_handbook_2025_2026.txt"
reader = PyPDF2.PdfReader(pdf_path)
text = "\n".join(page.extract_text() or "" for page in reader.pages)
Path(out_path).write_text(text, encoding="utf-8")
print("Wrote", out_path, "chars", len(text))
