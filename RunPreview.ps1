param(
    [ValidateSet('forward_plus', 'mobile', 'gl_compatibility')]
    [string]$Renderer = 'forward_plus'
)
$taskGodot = 'D:\Studio\AI\Projects\godot\tools\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
if ($env:GODOT_BIN) { $taskGodot = $env:GODOT_BIN }
if (-not (Test-Path -LiteralPath $taskGodot)) { throw 'Godot executable missing. Set GODOT_BIN to its absolute path.' }
$taskImport = Start-Process -FilePath $taskGodot -ArgumentList @('--headless', '--editor', '--path', ('"' + $PSScriptRoot + '"'), '--import', '--quit') -WindowStyle Hidden -Wait -PassThru
if ($taskImport.ExitCode -ne 0) { throw 'Godot resource import failed. Open the editor to inspect diagnostics.' }
Start-Process -FilePath $taskGodot -ArgumentList @('--path', ('"' + $PSScriptRoot + '"'), '--rendering-method', $Renderer)
