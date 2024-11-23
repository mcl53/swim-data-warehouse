{% macro duckdb__alter_column_comment(arg1, arg2) %}
-- This macro is blank as dbt artifacts requires it to run, however duckdb does not have column commenting functionality
{% endmacro %}

{% macro duckdb__insert_into_metadata_table(database_name, schema_name, table_name, content) -%}

    {% set insert_into_table_query %}
    insert into {{ database_name }}.{{ schema_name }}.{{ table_name }}
    {{ content }}
    {% endset %}

    {% do run_query(insert_into_table_query) %}

{%- endmacro %}

{% macro duckdb__get_exposures_dml_sql(exposures) -%}

    {% if exposures != [] %}
        {% set exposure_values %}
        select
            *
        from
        (values
        {% for exposure in exposures -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ exposure.unique_id | replace("'","''") }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ exposure.name | replace("'","''") }}', {# name #}
                '{{ exposure.type }}', {# type #}
                '{{ tojson(exposure.owner) }}', {# owner #}
                '{{ exposure.maturity }}', {# maturity #}
                '{{ exposure.original_file_path }}', {# path #}
                '{{ exposure.description }}', {# description #}
                '{{ exposure.url }}', {# url #}
                '{{ exposure.package_name }}', {# package_name #}
                '{{ tojson(exposure.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ tojson(exposure.tags) }}', {# tags #}
                {%- if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {%- else %}
                    '{{ tojson(exposure) | replace("'", "''") }}' {# all_results #}
                {%- endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ exposure_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_invocations_dml_sql() -%}
    {% set invocation_values %}
    select
        *
    from
    (values
    (
        '{{ invocation_id }}', {# command_invocation_id #}
        '{{ dbt_version }}', {# dbt_version #}
        '{{ project_name }}', {# project_name #}
        '{{ run_started_at }}', {# run_started_at #}
        '{{ flags.WHICH }}', {# dbt_command #}
        '{{ flags.FULL_REFRESH }}', {# full_refresh_flag #}
        '{{ target.profile_name }}', {# target_profile_name #}
        '{{ target.name }}', {# target_name #}
        '{{ target.schema }}', {# target_schema #}
        {{- target.threads }}, {# target_threads #}
        '{{ env_var('DBT_CLOUD_PROJECT_ID', '') }}', {# dbt_cloud_project_id #}
        '{{ env_var('DBT_CLOUD_JOB_ID', '') }}', {# dbt_cloud_job_id #}
        '{{ env_var('DBT_CLOUD_RUN_ID', '') }}', {# dbt_cloud_run_id #}
        '{{ env_var('DBT_CLOUD_RUN_REASON_CATEGORY', '') }}', {# dbt_cloud_run_reason_category #}
        '{{ env_var('DBT_CLOUD_RUN_REASON', '') | replace("'","''") }}', {# dbt_cloud_run_reason #}
        {%- if var('env_vars', none) %}
            {%- set env_vars_dict = {} %}
            {%- for env_variable in var('env_vars') %}
                {%- do env_vars_dict.update({env_variable: (env_var(env_variable, '') | replace("'", "''"))}) %}
            {%- endfor %}
            '{{ tojson(env_vars_dict) }}', {# env_vars #}
        {%- else %}
            null, {# env_vars #}
        {%- endif %}
        {%- if var('dbt_vars', none) %}
            {%- set dbt_vars_dict = {} %}
            {%- for dbt_var in var('dbt_vars') %}
                {%- do dbt_vars_dict.update({dbt_var: (var(dbt_var, '') | replace("'", "''"))}) %}
            {%- endfor %}
            '{{ tojson(dbt_vars_dict) }}', {# dbt_vars #}
        {%- else %}
            null, {# dbt_vars #}
        {%- endif %}
        '{{ tojson(invocation_args_dict) | replace("'", "''") }}', {# invocation_args #}
        {%- set metadata_env = {} %}
        {%- for key, value in dbt_metadata_envs.items() %}
            {%- do metadata_env.update({key: (value | replace("'", "''"))}) %}
        {%- endfor %}
        '{{ tojson(metadata_env) }}' {# dbt_custom_envs #}
    )
    )
    {% endset %}
    {{ invocation_values }}

{% endmacro -%}

{% macro duckdb__get_model_executions_dml_sql(models) -%}
    {% if models != [] %}
        {% set model_execution_values %}
        select
            *
        from
        (values
        {% for model in models -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                {%- set config_full_refresh = model.node.config.full_refresh %}
                {%- if config_full_refresh is none %}
                    {%- set config_full_refresh = flags.FULL_REFRESH %}
                {%- endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}
                '{{ model.thread_id }}', {# thread_id #}
                '{{ model.status }}', {# status #}
                {%- set compile_started_at = (model.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {%- if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {%- set query_completed_at = (model.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {%- if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}
                {{ model.execution_time }}, {# total_node_runtime #}
                null, -- rows_affected not available {# Only available in Snowflake & BigQuery #}
                '{{ model.node.config.materialized }}', {# materialization #}
                '{{ model.node.schema }}', {# schema #}
                '{{ model.node.name }}', {# name #}
                '{{ model.node.alias }}', {# alias #}
                '{{ model.message | replace("'", "''") }}', {# message #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ model_execution_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_models_dml_sql(models) -%}

    {% if models != [] %}
        {% set model_values %}
        select
            *
        from
        (values
        {% for model in models -%}
                {%- do model.pop('raw_code', None) %}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ model.database }}', {# database #}
                '{{ model.schema }}', {# schema #}
                '{{ model.name }}', {# name #}
                '{{ tojson(model.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ model.package_name }}', {# package_name #}
                '{{ model.original_file_path }}', {# path #}
                '{{ model.checksum.checksum }}', {# checksum #}
                '{{ model.config.materialized }}', {# materialization #}
                '{{ tojson(model.tags) }}', {# tags #}
                '{{ tojson(model.config.meta) | replace("'","''") }}', {# meta #}
                '{{ model.alias }}', {# alias #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ model_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_seed_executions_dml_sql(seeds) -%}
    {% if seeds != [] %}
        {% set seed_execution_values %}
        select
            *
        from
        (values
        {% for model in seeds -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                {%- set config_full_refresh = model.node.config.full_refresh %}
                {%- if config_full_refresh is none %}
                    {%- set config_full_refresh = flags.FULL_REFRESH %}
                {%- endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}
                '{{ model.thread_id }}', {# thread_id #}
                '{{ model.status }}', {# status #}
                {%- set compile_started_at = (model.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {%- if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {%- set query_completed_at = (model.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {%- if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}
                {{ model.execution_time }}, {# total_node_runtime #}
                null, -- rows_affected not available {# Only available in Snowflake #}
                '{{ model.node.config.materialized }}', {# materialization #}
                '{{ model.node.schema }}', {# schema #}
                '{{ model.node.name }}', {# name #}
                '{{ model.node.alias }}', {# alias #}
                '{{ model.message | replace("'", "''") }}', {# message #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ seed_execution_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_seeds_dml_sql(seeds) -%}

    {% if seeds != [] %}
        {% set seed_values %}
        select
            *
        from
        (values
        {% for seed in seeds -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ seed.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ seed.database }}', {# database #}
                '{{ seed.schema }}', {# schema #}
                '{{ seed.name }}', {# name #}
                '{{ seed.package_name }}', {# package_name #}
                '{{ seed.original_file_path }}', {# path #}
                '{{ seed.checksum.checksum }}', {# checksum #}
                '{{ tojson(seed.config.meta) | replace("'","''") }}', {# meta #}
                '{{ seed.alias }}', {# alias #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ seed_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_snapshot_executions_dml_sql(snapshots) -%}
    {% if snapshots != [] %}
        {% set snapshot_execution_values %}
        select
            *
        from
        (values
        {% for model in snapshots -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                {%- set config_full_refresh = model.node.config.full_refresh %}
                {%- if config_full_refresh is none %}
                    {%- set config_full_refresh = flags.FULL_REFRESH %}
                {%- endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}
                '{{ model.thread_id }}', {# thread_id #}
                '{{ model.status }}', {# status #}
                {%- set compile_started_at = (model.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {%- if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {%- set query_completed_at = (model.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {%- if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}
                {{ model.execution_time }}, {# total_node_runtime #}
                null, -- rows_affected not available {# Only available in Snowflake #}
                '{{ model.node.config.materialized }}', {# materialization #}
                '{{ model.node.schema }}', {# schema #}
                '{{ model.node.name }}', {# name #}
                '{{ model.node.alias }}', {# alias #}
                '{{ model.message | replace("'", "''") }}', {# message #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ snapshot_execution_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_snapshots_dml_sql(snapshots) -%}

    {% if snapshots != [] %}
        {% set snapshot_values %}
        select
            *
        from
        (values
        {% for snapshot in snapshots -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ snapshot.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ snapshot.database }}', {# database #}
                '{{ snapshot.schema }}', {# schema #}
                '{{ snapshot.name }}', {# name #}
                '{{ tojson(snapshot.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ snapshot.package_name }}', {# package_name #}
                '{{ snapshot.original_file_path }}', {# path #}
                '{{ snapshot.checksum.checksum }}', {# checksum #}
                '{{ snapshot.config.strategy }}', {# strategy #}
                '{{ tojson(snapshot.config.meta) | replace("'","''") }}', {# meta #}
                '{{ snapshot.alias }}', {# alias #}
                {%- if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {%- else %}
                    '{{ tojson(snapshot) | replace("'","''") }}' {# all_results #}
                {%- endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ snapshot_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_sources_dml_sql(sources) -%}

    {% if sources != [] %}
        {% set source_values %}
        select
            *
        from
        (values
        {% for source in sources -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ source.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ source.database }}', {# database #}
                '{{ source.schema }}', {# schema #}
                '{{ source.source_name }}', {# source_name #}
                '{{ source.loader }}', {# loader #}
                '{{ source.name }}', {# name #}
                '{{ source.identifier }}', {# identifier #}
                '{{ source.loaded_at_field | replace("'","''") }}', {# loaded_at_field #}
                '{{ tojson(source.freshness) | replace("'","''") }}', {# freshness #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ source_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_test_executions_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_execution_values %}
        select
            *
        from
        (values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                {%- set config_full_refresh = test.node.config.full_refresh %}
                {%- if config_full_refresh is none %}
                    {%- set config_full_refresh = flags.FULL_REFRESH %}
                {%- endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}
                '{{ test.thread_id }}', {# thread_id #}
                '{{ test.status }}', {# status #}
                {%- set compile_started_at = (model.timing | selectattr("name", "eq", "compile") | first | default({}))["started_at"] %}
                {%- if compile_started_at %}'{{ compile_started_at }}'{% else %}null{% endif %}, {# compile_started_at #}
                {%- set query_completed_at = (model.timing | selectattr("name", "eq", "execute") | first | default({}))["completed_at"] %}
                {%- if query_completed_at %}'{{ query_completed_at }}'{% else %}null{% endif %}, {# query_completed_at #}
                {{ test.execution_time }}, {# total_node_runtime #}
                null, {# rows_affected not available in Databricks #}
                {{ 'null' if test.failures is none else test.failures }}, {# failures #}
                '{{ test.message | replace("'", "''") }}', {# message #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ test_execution_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro duckdb__get_tests_dml_sql(tests) -%}

    {% if tests != [] %}
        {% set test_values %}
        select
            *
        from
        (values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ test.name }}', {# name #}
                '{{ tojson(test.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ test.package_name }}', {# package_name #}
                '{{ test.original_file_path | replace('\\', '\\\\') }}', {# test_path #}
                '{{ tojson(test.tags) }}', {# tags #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        )
        {% endset %}
        {{ test_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}
