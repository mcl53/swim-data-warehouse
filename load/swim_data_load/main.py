import datetime
import os
import sys

import duckdb
import json
import pandas
from pypdf import PdfReader
import xmltodict

import utils

# Unpack script arguments
load_folder = sys.argv[1]

# Load environment variables
source_data_directory = os.environ.get("SOURCE_DATA_DIRECTORY")
if source_data_directory is None:
    raise KeyError("No environment variable set for 'SOURCE_DATA_DIRECTORY'")

database = utils.connect_to_duckdb(load_folder)

database.execute("""
    DROP SCHEMA IF EXISTS raw CASCADE;
    CREATE SCHEMA raw;
""")

table_defs_folder = os.path.join(load_folder, "table_definitions")
for table_def_file in os.scandir(table_defs_folder):
    with open(table_def_file.path) as table_def:
        table_def_stmt = table_def.read()
        database.execute(table_def_stmt)

# Read PDF files and create pandas dataframe in the correct shape for the source table
data_to_insert = []

pdf_files = os.scandir(os.path.join(source_data_directory, "PDF"))

for pdf_file in pdf_files:
    reader = PdfReader(pdf_file.path)

    for page_num, page in enumerate(reader.pages):
        data_to_insert.append({
            "file_name": pdf_file.name,
            "page_number": page_num + 1,
            "page_text": page.extract_text()
        })

dataframe_to_insert = pandas.DataFrame(data_to_insert)

# Insert data from pandas dataframe into the source table in duckDB
duckdb.register(view_name="dataframe_to_insert", python_object=dataframe_to_insert)

database.execute("""
    INSERT INTO raw.pdf_page
    SELECT
        *,
        CURRENT_LOCALTIMESTAMP() AS loaded_datetime
    FROM
        dataframe_to_insert;
""")

# Fix discrepancies in PDF data
database.execute("""
    UPDATE raw.pdf_page
    SET
        page_text = REPLACE(page_text, '19:28Women''s', '19:28 Women''s')
    WHERE
        file_name = '20191012_13_11_naples-results-day-1_final.pdf'
    AND page_number = 7;
    
    UPDATE raw.pdf_page
    SET
        page_text = REPLACE(page_text, '19:57Women''s', '19:57 Women''s')
    WHERE
        file_name = '20191012_13_11_naples-results-day-1_final.pdf'
    AND page_number = 11;
    
    UPDATE raw.pdf_page
    SET
        page_text = REPLACE(page_text, '20:27Women''s', '20:27 Women''s')
    WHERE
        file_name = '20191012_13_11_naples-results-day-1_final.pdf'
    AND page_number = 15;
""")

# Read LENEX files and create pandas dataframe in the correct shape for the source table
data_to_insert = []

lenex_files = os.scandir(os.path.join(source_data_directory, "LENEX"))

for lenex_file in lenex_files:
    with open(lenex_file.path, "rb") as lenex:
        lenex_data = lenex.read()

    lenex_json_str = json.dumps(xmltodict.parse(lenex_data))
    data_to_insert.append({
        "file_name": lenex_file.name,
        "file_contents": lenex_json_str
    })

dataframe_to_insert = pandas.DataFrame(data_to_insert)
duckdb.register(view_name="dataframe_to_insert", python_object=dataframe_to_insert)

database.execute("""
    INSERT INTO raw.lenex
    SELECT
        *,
        CURRENT_LOCALTIMESTAMP() AS loaded_datetime
    FROM
        dataframe_to_insert;
""")
