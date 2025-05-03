# Run copy to Postgres script
$pythonScript = [IO.Path]::Combine($PSScriptRoot, 'swim_data_load', 'copy_to_pg.py')
python $pythonScript $PSSCriptRoot
