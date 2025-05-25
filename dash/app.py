import os
import sys

from dash import Dash, html, dcc, callback, Output, Input, dash_table
import dash_ag_grid
import duckdb

# Unpack script arguments
project_root_dir = sys.argv[1]

database_directory = os.path.join(project_root_dir, "data", "swim_data.duckdb")
with duckdb.connect(database=database_directory) as database:
    event_types = database.execute("""
        WITH unique_event AS (
            SELECT DISTINCT
                CONCAT(distance, ' ', stroke) AS event_type,
                stroke,
                distance
            FROM
                swim_data_lenex.event
        )
        SELECT
            event_type,
            ROW_NUMBER() OVER (
                ORDER BY
                    stroke,
                    distance
            ) AS display_order
        FROM
            unique_event
        ORDER BY
            display_order;
    """).df().event_type

    sexes = database.execute("""
        SELECT DISTINCT
            sex
        FROM
            swim_data_lenex.athlete
        ORDER BY
            sex ASC;
    """).df().sex

app = Dash()

app.layout = [
    html.Div(
        id="whole-screen",
        children=[
            html.H1(
                children="Top Event Times",
            ),

            html.Div(
                id="main-content",
                children=[
                    html.Div(
                        id="filter-pane",
                        children=[
                            # Event filter
                            html.H2(
                                children="Event",
                                className="filter-header",
                            ),
                            dcc.Dropdown(
                                event_types,
                                id="event-selection",
                                className="filter-dropdown",
                                style={
                                    "font-family": "sans-serif",
                                    "font-size": "20px",
                                    "text-align": "center",
                                    "margin-top": "10px",
                                    "margin-bottom": "10px",
                                },
                                searchable=False,
                                clearable=False,
                                placeholder="Select event",
                            ),

                            # Sex filter
                            html.H2(
                                children="Sex",
                                className="filter-header",
                            ),
                            dcc.Dropdown(
                                sexes,
                                id="sex-selection",
                                className="filter-dropdown",
                                style={
                                    "font-family": "sans-serif",
                                    "font-size": "20px",
                                    "text-align": "center",
                                    "margin-top": "10px",
                                    "margin-bottom": "10px",
                                },
                                searchable=False,
                                clearable=False,
                                placeholder="Select sex",
                            ),
                        ],
                    ),

                    dash_ag_grid.AgGrid(
                        id="results-table",
                        columnDefs=[
                            {"field": "Place"        },
                            {"field": "Athlete"      },
                            {"field": "Time"         },
                            {"field": "Reaction Time"},
                            {"field": "Points"       },
                            {"field": "Club"         },
                            {"field": "Meet"         },
                        ],
                    ),

                    # dash_table.DataTable(
                    #     columns=[
                    #         {"name": "Place"        , "id": "Place"        },
                    #         {"name": "Athlete"      , "id": "Athlete"      },
                    #         {"name": "Time"         , "id": "Time"         },
                    #         {"name": "Reaction Time", "id": "Reaction Time"},
                    #         {"name": "Points"       , "id": "Points"       },
                    #         {"name": "Club"         , "id": "Club"         },
                    #         {"name": "Meet"         , "id": "Meet"         },
                    #     ],
                    #     id="results-table",
                    #     style_header={
                    #         "backgroundColor": "rgb(220, 220, 220)",
                    #         "fontWeight": "bold",
                    #         "fontSize": "17px",
                    #     },
                    #     style_cell={
                    #         "font-family": "sans-serif",
                    #         "textAlign": "center",
                    #     },
                    #     style_cell_conditional=[
                    #         {
                    #             "if": {"column_id": "Place"},
                    #             "width": "60px",
                    #         },
                    #         {
                    #             "if": {"column_id": "Athlete"},
                    #             "width": "180px",
                    #         },
                    #         {
                    #             "if": {"column_id": "Time"},
                    #             "width": "90px",
                    #         },
                    #         {
                    #             "if": {"column_id": "Reaction Time"},
                    #             "width": "130px",
                    #         },
                    #         {
                    #             "if": {"column_id": "Points"},
                    #             "width": "70px",
                    #         },
                    #         {
                    #             "if": {"column_id": "Club"},
                    #             "width": "150px",
                    #         },
                    #         {
                    #             "if": {"column_id": "Meet"},
                    #             "width": "200px",
                    #         },
                    #     ],
                    #     style_data_conditional=[
                    #         {
                    #             "if": {"row_index": "odd"},
                    #             "backgroundColor": "rgb(230, 230, 230)"
                    #         }
                    #     ],
                    #     style_as_list_view=True,
                    #     page_size=1000,
                    #     fixed_rows={
                    #         "headers": True,
                    #     },
                    #     cell_selectable=False,
                    # ),

                    html.Div(
                        id="results-detail",
                        children=[
                            html.H2(children="Details")
                        ]
                    ),
                ],
            ),
        ],
    ),
]
@callback(
    Output(component_id = "results-table"  , component_property = "rowData" ),
    Input( component_id = "event-selection", component_property = "value"),
    Input( component_id = "sex-selection"  , component_property = "value")
)
def update_graph(event, sex):
    with duckdb.connect(database=database_directory) as database:
        df = database.execute(f"""
            SELECT
                ROW_NUMBER() OVER (
                    ORDER BY
                        r.finish_time ASC
                ) AS Place,
                CONCAT(a.first_name, ' ', a.last_name) AS Athlete,
                CONCAT(
                    IF(
                        EXTRACT(MINUTES FROM r.finish_time) > 0,
                        CONCAT(CAST(EXTRACT(MINUTES FROM r.finish_time) AS VARCHAR), ':'),
                        ''
                    ),
                    LPAD(CAST(EXTRACT(SECONDS FROM r.finish_time) AS VARCHAR), 2, '0'),
                    '.',
                    LEFT(
                        LPAD(
                            CAST(
                                EXTRACT(MILLISECONDS FROM r.finish_time)
                              - (1000 * EXTRACT(SECONDS FROM r.finish_time))
                                AS VARCHAR
                            ),
                            3,
                            '0'
                        ),
                        2
                    )
                ) AS "Time",
                CONCAT(
                    CAST(EXTRACT(SECONDS FROM r.reaction_time) AS VARCHAR),
                    '.',
                    LEFT(
                        LPAD(
                            CAST(
                                EXTRACT(MILLISECONDS FROM r.reaction_time)
                              - (1000 * EXTRACT(SECONDS FROM r.reaction_time))
                                AS VARCHAR
                            ),
                            3,
                            '0'
                        ),
                        2
                    )
                ) AS "Reaction Time",
                r.fina_points AS Points,
                c.club_name AS Club,
                r.meet_name AS Meet
            FROM
                swim_data_lenex.result r
            INNER JOIN
                swim_data_lenex.athlete a
            ON
                r.meet_name = a.meet_name
            AND r.athlete_id = a.athlete_id
            INNER JOIN
                swim_data_lenex.club c
            ON
                a.meet_name = c.meet_name
            AND a.club_code = c.club_code
            INNER JOIN
                swim_data_lenex.event e
            ON
                r.meet_name = e.meet_name
            AND r.event_id = e.event_id
            WHERE
                CONCAT(e.distance, ' ', e.stroke) = '{event}'
            AND a.sex = '{sex}'
            AND r.finish_time IS NOT NULL
            ORDER BY
                r.finish_time ASC;
        """).df()

    return df.to_dict('records')

app.run(debug=True)
