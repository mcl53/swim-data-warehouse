# Run data load script
$pythonScript = [IO.Path]::Combine($PSScriptRoot, 'swim_data_load', 'main.py')
python $pythonScript $PSSCriptRoot
