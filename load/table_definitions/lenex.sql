CREATE TABLE raw.lenex
(
    file_name       VARCHAR   NOT NULL,
    file_contents   JSON      NOT NULL,
    loaded_datetime TIMESTAMP NOT NULL
);
