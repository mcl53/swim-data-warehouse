# Run data load script
$projectRootDir = [IO.Path]::Combine($PSScriptRoot, '..')
$pythonScript = [IO.Path]::Combine($projectRootDir, 'dash', 'app.py')
python $pythonScript $projectRootDir
