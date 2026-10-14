param(
    [ValidateSet('forward_plus', 'mobile', 'gl_compatibility')]
    [string]$Renderer = 'forward_plus'
)
$taskGodot = 'D:\Studio\AI\Projects\godot\tools\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
if ($env:GODOT_BIN) { $taskGodot = $env:GODOT_BIN }
if (-not (Test-Path -LiteralPath $taskGodot)) { throw 'Godot executable missing. Set GODOT_BIN to its absolute path.' }
Start-Process -FilePath $taskGodot -ArgumentList @('--path', ('"' + $PSScriptRoot + '"'), '--rendering-method', $Renderer)
