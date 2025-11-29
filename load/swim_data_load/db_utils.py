import duckdb
import os

def connect_to_duckdb(root_directory):
    database_directory = os.path.join(root_directory, 'data')

    # Connect to duckDB and create blank source table to load into
    return duckdb.connect(database=os.path.join(database_directory, "swim_data.duckdb"))
