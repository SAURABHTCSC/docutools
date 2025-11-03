import subprocess
import shutil
import pandas as pd
import os
import io
# import pythoncom # <-- REMOVED, this is for Windows only
from flask import Flask, request, send_file
from flask_cors import CORS
# from pdf2docx import Converter # <-- REMOVED
from docx2pdf import convert as convert_docx_to_pdf
from PyPDF2 import PdfMerger, PdfReader, PdfWriter
from docxcompose.composer import Composer
from docx import Document
import tabula

# --- Setup ---
app = Flask(__name__)
# Allow all origins to talk to this server
CORS(app, resources={r"/*": {"origins": "*"}})
UPLOAD_FOLDER = 'temp_uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# --- Helper Function ---
def get_file_path(filename):
    return os.path.join(UPLOAD_FOLDER, filename)

# --- 1. PDF to Word (REMOVED) ---
# This feature was removed.

# --- 2. Word to PDF ---
@app.route('/convert/word-to-pdf', methods=['POST'])
def word_to_pdf():
    # pythoncom.CoInitialize() # <-- REMOVED, this is for Windows only

    file = request.files['file']
    input_path = get_file_path(file.filename)
    output_path = get_file_path('converted.pdf')
    file.save(input_path)

    try:
        # Note: This will be VERY slow on a free server, but it will work.
        convert_docx_to_pdf(input_path, output_path)
        return send_file(output_path, as_attachment=True)
    except Exception as e:
        print(f"Word-to-PDF Error: {e}")
        return "Error converting file.", 500

# --- 3. PDF to Excel (CORRECTED) ---
@app.route('/convert/pdf-to-excel', methods=['POST'])
def pdf_to_excel():
    file = request.files['file']
    input_path = get_file_path(file.filename)
    output_path = get_file_path('converted.xlsx')
    file.save(input_path)

    try:
        # Read all tables from all pages of the PDF into a list of DataFrames
        dfs = tabula.read_pdf(input_path, pages='all', multiple_tables=True)

        if not dfs:
            # If no tables are found, create an Excel file with a message
            with pd.ExcelWriter(output_path) as writer:
                pd.DataFrame({"Status": ["No tables were found in this PDF."]}).to_excel(writer, index=False)
            return send_file(output_path, as_attachment=True)

        # If tables are found, write each one to a different sheet
        with pd.ExcelWriter(output_path) as writer:
            for i, df in enumerate(dfs):
                df.to_excel(writer, sheet_name=f'Table_Page_{i+1}', index=False)

        return send_file(output_path, as_attachment=True)

    except Exception as e:
        print(f"PDF to Excel Error: {e}")
        # If any other error happens, create an Excel file with the error message
        with pd.ExcelWriter(output_path) as writer:
            pd.DataFrame({"Error": [f"An error occurred: {str(e)}"]}).to_excel(writer, index=False)
        return send_file(output_path, as_attachment=True)

# --- 4. PDF Merger ---
@app.route('/merge/pdf', methods=['POST'])
def merge_pdf():
    files = request.files.getlist('files')
    merger = PdfMerger()

    try:
        for file in files:
            input_path = get_file_path(file.filename)
            file.save(input_path)
            merger.append(input_path)

        output_path = get_file_path('merged.pdf')
        merger.write(output_path)
        merger.close()
        return send_file(output_path, as_attachment=True)
    except Exception as e:
        print(f"PDF Merge Error: {e}")
        return "Error merging files.", 500

# --- 5. Word Merger ---
@app.route('/merge/word', methods=['POST'])
def merge_word():
    # pythoncom.CoInitialize() # <-- REMOVED, this is for Windows only

    files = request.files.getlist('files')

    try:
        # Save the first file
        master_file = files[0]
        master_path = get_file_path(master_file.filename)
        master_file.save(master_path)

        master_doc = Document(master_path)
        composer = Composer(master_doc)

        # Append the other files
        for i in range(1, len(files)):
            file = files[i]
            input_path = get_file_path(file.filename)
            file.save(input_path)

            doc_to_append = Document(input_path)
            composer.append(doc_to_append)

        output_path = get_file_path('merged.docx')
        composer.save(output_path)
        return send_file(output_path, as_attachment=True)
    except Exception as e:
        print(f"Word Merge Error: {e}")
        return "Error merging files.", 500

# --- 6. PDF Compressor (UPGRADED for Server) ---
@app.route('/compress/pdf', methods=['POST'])
def compress_pdf():
    file = request.files['file']
    input_path = get_file_path(file.filename)
    output_path = get_file_path('compressed.pdf')
    file.save(input_path)

    # --- THIS IS THE FIX ---
    # This finds 'gs' (Ghostscript) on the server automatically
    gs_command = shutil.which('gs')

    if not gs_command:
        print("!!! FATAL ERROR: Ghostscript is not installed on the server.")
        # This should not happen if your build.sh file is correct
        return send_file(input_path, as_attachment=True)

    print(f"Found Ghostscript at: {gs_command}")

    try:
        # This is the command that does the REAL compression
        subprocess.run([
            gs_command,
            '-sDEVICE=pdfwrite',
            '-dCompatibilityLevel=1.4',
            '-dPDFSETTINGS=/ebook',  # /screen = high, /ebook = medium
            '-dNOPAUSE',
            '-dQUIET',
            '-dBATCH',
            f'-sOutputFile={output_path}',
            input_path
        ], check=True)

        print(f"Ghostscript compression successful: {input_path} -> {output_path}")
        return send_file(output_path, as_attachment=True)

    except Exception as e:
        print(f"Ghostscript Error: {e}")
        # If Ghostscript fails, send the original file back
        return send_file(input_path, as_attachment=True)

# --- Run the Server ---
# This line allows Render to choose the correct port
if __name__ == '__main__':
    app.run(port=int(os.environ.get("PORT", 8080)), host='0.0.0.0')

