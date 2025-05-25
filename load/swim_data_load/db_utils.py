import duckdb
import os

def connect_to_duckdb(load_folder):
    database_directory = os.path.join(load_folder, '..', 'data')

    # Connect to duckDB and create blank source table to load into
    return duckdb.connect(database=os.path.join(database_directory, "swim_data.duckdb"))
