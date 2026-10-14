$taskGodot = 'D:\Studio\AI\Projects\godot\tools\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
if ($env:GODOT_BIN) { $taskGodot = $env:GODOT_BIN }
if (-not (Test-Path -LiteralPath $taskGodot)) { throw 'Set GODOT_BIN to the Godot executable.' }
Start-Process -FilePath $taskGodot -ArgumentList @('--editor', '--path', ('"' + $PSScriptRoot + '"'))
