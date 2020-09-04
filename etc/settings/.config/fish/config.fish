{$CONDA_HOME}/bin/conda config --set changeps1 True
eval {$CONDA_HOME}/bin/conda "shell.fish" "hook" $argv | source
