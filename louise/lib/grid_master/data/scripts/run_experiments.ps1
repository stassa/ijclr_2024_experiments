# Run with:
# . .\lib\grid_master\data\scripts\run_experiments.ps1

$swipl=$(Get-Command swipl).Path
$louise_root="../../../../.."
$scripts_path="lib/grid_master/data/scripts/"

& 'C:\Program Files\swipl\bin\swipl.exe' -s "$scripts_path/ijclr_2024_experiment_1a.pl" -g experiment_1a -t halt
& 'C:\Program Files\swipl\bin\swipl.exe' -s "$scripts_path/ijclr_2024_experiments_1b-2x.pl" -g run_experiments -t halt
