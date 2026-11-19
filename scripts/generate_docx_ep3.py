import os
import re
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>'))

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def create_report_docx(md_path, output_docx_path):
    doc = Document()
    
    # Page setup - Margins (1 inch all around)
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        section.different_first_page_header_footer = True
        
        # Header / Footer
        footer = section.footer
        f_p = footer.paragraphs[0]
        f_p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        f_run = f_p.add_run("FreshBox SpA - Modernización Serverless Híbrida (EP3 / ARY1102) | Duoc UC")
        f_run.font.size = Pt(8.5)
        f_run.font.color.rgb = RGBColor(128, 128, 128)

    # Styles
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = RGBColor(33, 37, 41)
    normal_style.paragraph_format.line_spacing = 1.15
    normal_style.paragraph_format.space_after = Pt(6)

    # --- COVER PAGE ---
    cover_p0 = doc.add_paragraph()
    cover_p0.paragraph_format.space_before = Pt(40)
    cover_p0.paragraph_format.space_after = Pt(10)
    inst_run = cover_p0.add_run("DUOC UC • ESCUELA DE INFORMÁTICA Y TELECOMUNICACIONES\nINGENIERÍA EN CONECTIVIDAD Y REDES / ARQUITECTURA CLOUD")
    inst_run.font.size = Pt(11)
    inst_run.font.bold = True
    inst_run.font.color.rgb = RGBColor(0, 43, 73) # Deep Blue
    
    title_p = doc.add_paragraph()
    title_p.paragraph_format.space_before = Pt(30)
    title_p.paragraph_format.space_after = Pt(8)
    title_run = title_p.add_run("INFORME TÉCNICO DE ARQUITECTURA CLOUD")
    title_run.font.size = Pt(24)
    title_run.font.bold = True
    title_run.font.color.rgb = RGBColor(0, 43, 73)
    
    subtitle_p = doc.add_paragraph()
    subtitle_p.paragraph_format.space_after = Pt(25)
    sub_run = subtitle_p.add_run("Evolución hacia Modelos Serverless e Híbridos: Desacoplamiento, Escalabilidad y Resiliencia en AWS Learner Lab")
    sub_run.font.size = Pt(14)
    sub_run.font.color.rgb = RGBColor(227, 108, 10) # Duoc Orange/Gold

    # Decorative Line
    p_line = doc.add_paragraph()
    p_line.paragraph_format.space_after = Pt(40)
    line_run = p_line.add_run("―" * 45)
    line_run.font.bold = True
    line_run.font.color.rgb = RGBColor(200, 205, 215)

    # Metadata Box Table
    meta_table = doc.add_table(rows=6, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_data = [
        ("Caso de Estudio:", "FreshBox SpA – Plataforma de Alimentos Orgánicos y Canastas Saludables"),
        ("Instancia Evaluativa:", "Evaluación Parcial 3 (EP3 - 30% Ponderación Semestral)"),
        ("Asignatura:", "Arquitectura Cloud (Sigla: ARY1102)"),
        ("Estudiante:", "Gaston Mardones González"),
        ("Docente Diseñador:", "Ignacio A. Pastenet M."),
        ("Fecha de Entrega:", "Noviembre 2026")
    ]
    for row_idx, (label, val) in enumerate(meta_data):
        cell_lbl = meta_table.cell(row_idx, 0)
        cell_val = meta_table.cell(row_idx, 1)
        cell_lbl.width = Inches(2.2)
        cell_val.width = Inches(4.3)
        
        set_cell_background(cell_lbl, "F1F5F9")
        set_cell_background(cell_val, "FFFFFF")
        set_cell_margins(cell_lbl, 80, 80, 100, 100)
        set_cell_margins(cell_val, 80, 80, 100, 100)
        
        p_l = cell_lbl.paragraphs[0]
        p_l.paragraph_format.space_after = Pt(2)
        r_l = p_l.add_run(label)
        r_l.font.bold = True
        r_l.font.size = Pt(10)
        r_l.font.color.rgb = RGBColor(0, 43, 73)
        
        p_v = cell_val.paragraphs[0]
        p_v.paragraph_format.space_after = Pt(2)
        r_v = p_v.add_run(val)
        r_v.font.size = Pt(10)

    doc.add_page_break()

    # Read markdown content
    with open(md_path, 'r', encoding='utf-8') as f:
        md_text = f.read()

    lines = md_text.split('\n')
    in_table = False
    table_lines = []
    in_code = False
    code_lines = []

    def flush_table(lines_to_flush):
        if not lines_to_flush:
            return
        parsed_rows = []
        for l in lines_to_flush:
            stripped = l.strip()
            if not stripped.startswith('|'):
                continue
            cells = [c.strip() for c in stripped.split('|')[1:-1]]
            # Skip separator line (e.g. :--- | :---)
            if all(re.match(r'^:?-+:?$', c) for c in cells):
                continue
            parsed_rows.append(cells)
        if not parsed_rows:
            return
        
        num_cols = max(len(r) for r in parsed_rows)
        # Pad shorter rows
        for r in parsed_rows:
            while len(r) < num_cols:
                r.append('')
        
        t = doc.add_table(rows=len(parsed_rows), cols=num_cols)
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        for r_idx, row in enumerate(parsed_rows):
            is_header = (r_idx == 0)
            for c_idx, cell_txt in enumerate(row):
                cell = t.cell(r_idx, c_idx)
                set_cell_margins(cell, 80, 80, 100, 100)
                if is_header:
                    set_cell_background(cell, "002B49")
                elif r_idx % 2 == 1:
                    set_cell_background(cell, "F8FAFC")
                else:
                    set_cell_background(cell, "FFFFFF")
                
                cp = cell.paragraphs[0]
                cp.paragraph_format.space_after = Pt(2)
                c_run = cp.add_run(cell_txt)
                c_run.font.size = Pt(9)
                if is_header:
                    c_run.font.bold = True
                    c_run.font.color.rgb = RGBColor(255, 255, 255)
        doc.add_paragraph() # Spacing

    def flush_code(lines_to_flush):
        if not lines_to_flush:
            return
        code_box = doc.add_table(rows=1, cols=1)
        code_box.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = code_box.cell(0, 0)
        cell.width = Inches(6.5)
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, 100, 100, 120, 120)
        cp = cell.paragraphs[0]
        cp.paragraph_format.space_after = Pt(0)
        c_run = cp.add_run("\n".join(lines_to_flush))
        c_run.font.name = 'Consolas'
        c_run.font.size = Pt(8.5)
        c_run.font.color.rgb = RGBColor(30, 41, 59)
        doc.add_paragraph()

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Handle Code Blocks
        if stripped.startswith('```'):
            if in_code:
                in_code = False
                flush_code(code_lines)
                code_lines = []
            else:
                if in_table:
                    in_table = False
                    flush_table(table_lines)
                    table_lines = []
                in_code = True
                code_lines = []
            i += 1
            continue

        if in_code:
            code_lines.append(line)
            i += 1
            continue

        # Handle Tables
        if stripped.startswith('|'):
            if not in_table:
                in_table = True
                table_lines = []
            table_lines.append(line)
            i += 1
            continue
        elif in_table:
            in_table = False
            flush_table(table_lines)
            table_lines = []

        # Skip main markdown H1 (handled in cover) and horizontal rules
        if stripped.startswith('# INFORME TÉCNICO') or stripped.startswith('## CASO EMPRESARIAL') or stripped.startswith('### Evaluación'):
            i += 1
            continue
        if stripped == '---':
            i += 1
            continue

        # Headings
        if stripped.startswith('# '):
            h_text = stripped[2:].strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(18)
            p.paragraph_format.space_after = Pt(6)
            p.paragraph_format.keep_with_next = True
            r = p.add_run(h_text)
            r.font.size = Pt(16)
            r.font.bold = True
            r.font.color.rgb = RGBColor(0, 43, 73)
        elif stripped.startswith('## '):
            h_text = stripped[3:].strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(14)
            p.paragraph_format.space_after = Pt(4)
            p.paragraph_format.keep_with_next = True
            r = p.add_run(h_text)
            r.font.size = Pt(14)
            r.font.bold = True
            r.font.color.rgb = RGBColor(0, 43, 73)
        elif stripped.startswith('### '):
            h_text = stripped[4:].strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(10)
            p.paragraph_format.space_after = Pt(3)
            p.paragraph_format.keep_with_next = True
            r = p.add_run(h_text)
            r.font.size = Pt(12)
            r.font.bold = True
            r.font.color.rgb = RGBColor(227, 108, 10)
        elif stripped.startswith('#### '):
            h_text = stripped[5:].strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(8)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.keep_with_next = True
            r = p.add_run(h_text)
            r.font.size = Pt(11)
            r.font.bold = True
            r.font.color.rgb = RGBColor(51, 65, 85)
        elif stripped.startswith('> '):
            # Callout
            quote_text = stripped[2:].replace('[!NOTE]', 'NOTA:').strip()
            q_box = doc.add_table(rows=1, cols=1)
            q_box.alignment = WD_TABLE_ALIGNMENT.CENTER
            cell = q_box.cell(0, 0)
            cell.width = Inches(6.5)
            set_cell_background(cell, "EFF6FF")
            set_cell_margins(cell, 80, 80, 120, 120)
            qp = cell.paragraphs[0]
            qp.paragraph_format.space_after = Pt(0)
            qr = qp.add_run(quote_text)
            qr.font.italic = True
            qr.font.size = Pt(9.5)
            qr.font.color.rgb = RGBColor(30, 64, 175)
            doc.add_paragraph()
        elif stripped.startswith('* ') or stripped.startswith('- '):
            bullet_text = stripped[2:].strip()
            p = doc.add_paragraph(style='List Bullet')
            p.paragraph_format.space_after = Pt(3)
            # Parse bold inside bullet
            parts = re.split(r'(\*\*.*?\*\*)', bullet_text)
            for part in parts:
                if part.startswith('**') and part.endswith('**'):
                    r = p.add_run(part[2:-2])
                    r.font.bold = True
                else:
                    p.add_run(part)
        elif re.match(r'^\d+\.\s', stripped):
            num_match = re.match(r'^(\d+\.)\s(.*)', stripped)
            p = doc.add_paragraph()
            p.paragraph_format.space_after = Pt(3)
            p.paragraph_format.left_indent = Inches(0.25)
            r_num = p.add_run(num_match.group(1) + " ")
            r_num.font.bold = True
            parts = re.split(r'(\*\*.*?\*\*)', num_match.group(2))
            for part in parts:
                if part.startswith('**') and part.endswith('**'):
                    r = p.add_run(part[2:-2])
                    r.font.bold = True
                else:
                    p.add_run(part)
        elif stripped != '':
            p = doc.add_paragraph()
            p.paragraph_format.space_after = Pt(5)
            parts = re.split(r'(\*\*.*?\*\*)', stripped)
            for part in parts:
                if part.startswith('**') and part.endswith('**'):
                    r = p.add_run(part[2:-2])
                    r.font.bold = True
                else:
                    p.add_run(part)

        i += 1

    if in_table:
        flush_table(table_lines)
    if in_code:
        flush_code(code_lines)

    doc.save(output_docx_path)
    print(f"Document saved successfully at: {output_docx_path}")

if __name__ == '__main__':
    md_file = r'G:\Duoc\Semestre VI\Arquitecto Cloud y Diseño de Soluciones en La Nube\EVA1\freshbox-cloud-architecture\docs\informe-tecnico-ep3.md'
    docx_file = r'G:\Duoc\Semestre VI\Arquitecto Cloud y Diseño de Soluciones en La Nube\EVA1\freshbox-cloud-architecture\docs\Informe_Tecnico_EP3_FreshBox.docx'
    create_report_docx(md_file, docx_file)
