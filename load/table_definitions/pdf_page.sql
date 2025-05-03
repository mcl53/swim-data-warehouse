CREATE TABLE raw.pdf_page
(
    file_name       VARCHAR   NOT NULL,
    page_number     INT       NOT NULL,
    page_text       VARCHAR   NOT NULL,
    loaded_datetime TIMESTAMP NOT NULL
);
