CREATE TABLE isl_raw.pdf_page
(
    loaded_datetime TIMESTAMP NOT NULL
  , file_name       VARCHAR   NOT NULL
  , page_number     INT       NOT NULL
  , page_text       VARCHAR   NOT NULL
);
