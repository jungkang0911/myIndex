<#
  安裝 / 更新 MyIndex 起始頁
  用法：
    .\install.ps1                                  # 裝到 %USERPROFILE%\MyIndex
    .\install.ps1 -Target D:\MyStart               # 指定資料夾
    .\install.ps1 -Config .\startpage-default.json # 一併產生 config.js（首次開啟的預設內容）
  既有 index.html / config.js 會先備份成 .bak；使用者在瀏覽器裡的自訂內容存在 localStorage，不受影響。
#>
param(
  [string]$Target = (Join-Path $env:USERPROFILE 'MyIndex'),
  [string]$Config
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$src = Join-Path $PSScriptRoot '..\assets\index.html'
if (-not (Test-Path $src)) { throw "找不到範本：$src" }

# Validate and re-serialize JSON before changing installation files.
if ($Config) {
  $json = [IO.File]::ReadAllText((Resolve-Path $Config), $utf8)
  $obj = $json | ConvertFrom-Json
  if (-not $obj.pages) { throw 'Invalid configuration: pages required' }
  $json = $obj | ConvertTo-Json -Depth 50
}

New-Item -ItemType Directory -Force $Target | Out-Null
$dst = Join-Path $Target 'index.html'
if (Test-Path $dst) { Copy-Item $dst "$dst.bak" -Force; Write-Host "已備份舊版 → $dst.bak" }
Copy-Item $src $dst -Force
Write-Host "已安裝 → $dst"

if ($Config) {
  $cfg = Join-Path $Target 'config.js'
  if (Test-Path $cfg) { Copy-Item $cfg "$cfg.bak" -Force; Write-Host "已備份舊 config.js → $cfg.bak" }
  [IO.File]::WriteAllText($cfg, "window.STARTPAGE_DEFAULT = $json;`n", $utf8)
  Write-Host "已產生 → $cfg"
}

$url = ([Uri](Resolve-Path $dst).Path).AbsoluteUri
Write-Host ""
Write-Host "起始頁網址：$url"
$url
