import datetime
import os
import sys

import duckdb
import pandas
import PyPDF2

# Unpack script arguments
load_folder = sys.argv[1]

# Load environment variables
source_data_directory = os.environ.get("SOURCE_DATA_DIRECTORY")
if source_data_directory is None:
    raise KeyError("No environment variable set for 'SOURCE_DATA_DIRECTORY'")

database_directory = os.path.join(load_folder, '..', 'data')
if database_directory is None:
    raise KeyError("No environment variable set for 'DUCKDB_DIRECTORY'")

# Connect to duckDB and create blank source table to load into
database = duckdb.connect(database=os.path.join(database_directory, "swim_data.duckdb"))

database.execute("""
    DROP SCHEMA IF EXISTS isl_raw CASCADE;
    CREATE SCHEMA isl_raw;
""")

with open(os.path.join(load_folder, "table_definitions", "isl_raw", "pdf_page.sql"), "r") as create_source_table_file:
    create_source_table_stmt = create_source_table_file.read()

database.execute(create_source_table_stmt)

# Read PDF files and create pandas dataframe in the correct shape for the source table
data_to_insert = []

pdf_files = os.scandir(source_data_directory)
load_datetime = datetime.datetime.now()

for pdf_file in pdf_files:
    reader = PyPDF2.PdfReader(pdf_file.path)

    for page_num, page in enumerate(reader.pages):
        data_to_insert.append({
            "loaded_datetime": load_datetime,
            "file_name": pdf_file.name,
            "page_number": page_num + 1,
            "page_text": page.extract_text()
        })

dataframe_to_insert = pandas.DataFrame(data_to_insert)

# Insert data from pandas dataframe into the source table in duckDB
duckdb.register(view_name="dataframe_to_insert", python_object=dataframe_to_insert)

database.execute("""
    INSERT INTO isl_raw.pdf_page
    SELECT
        *
    FROM
        dataframe_to_insert;
""")

# Fix discrepancies in PDF data
database.execute("""
    UPDATE isl_raw.pdf_page
    SET
        page_text = REPLACE(page_text, '19:28Women''s', '19:28 Women''s')
    WHERE
        file_name = '20191012_13_11_naples-results-day-1_final.pdf'
    AND page_number = 7;
    
    UPDATE isl_raw.pdf_page
    SET
        page_text = REPLACE(page_text, '19:57Women''s', '19:57 Women''s')
    WHERE
        file_name = '20191012_13_11_naples-results-day-1_final.pdf'
    AND page_number = 11;
    
    UPDATE isl_raw.pdf_page
    SET
        page_text = REPLACE(page_text, '20:27Women''s', '20:27 Women''s')
    WHERE
        file_name = '20191012_13_11_naples-results-day-1_final.pdf'
    AND page_number = 15;
""")
