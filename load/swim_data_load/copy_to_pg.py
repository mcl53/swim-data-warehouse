import utils

import os
import sys

load_folder = sys.argv[1]

# Load environment variables
postgres_user = os.environ.get("POSTGRES_USER")
if postgres_user is None:
    raise KeyError("No environment variable set for 'POSTGRES_USER'")

postgres_password = os.environ.get("POSTGRES_PASSWORD")
if postgres_password is None:
    raise KeyError("No environment variable set for 'POSTGRES_PASSWORD'")

csv_out_directory = os.path.join(load_folder, '..', 'data', 'csv')

duck_db_database = utils.connect_to_duckdb(load_folder)

duck_db_database.execute(f"""
    ATTACH 'host=localhost dbname=swim_data user={postgres_user} password={postgres_password}' AS postgres_db (TYPE POSTGRES);

    DROP SCHEMA IF EXISTS postgres_db.raw           CASCADE;
    DROP SCHEMA IF EXISTS postgres_db.swim_data     CASCADE;
    DROP SCHEMA IF EXISTS postgres_db.swim_data_isl CASCADE;

    CREATE SCHEMA postgres_db.raw;
    CREATE SCHEMA postgres_db.swim_data;
    CREATE SCHEMA postgres_db.swim_data_isl;

    COPY FROM DATABASE swim_data TO postgres_db (SCHEMA);
""")

tables = duck_db_database.execute("""
    SELECT
        table_schema,
        table_name
    FROM
        information_schema.tables
    WHERE
        table_catalog = 'swim_data';
""").fetchall()

for table in tables:
    schema_name = table[0]
    table_name = table[1]
    duck_db_database.execute(f"""
        INSERT INTO postgres_db.{schema_name}.{table_name}
        SELECT
            *
        FROM
            swim_data.{schema_name}.{table_name};
    """)
