<#
  把 Edge / Chrome 書籤轉成 MyIndex 預設內容 JSON（每個書籤資料夾 → 一個書籤區塊）
  用法：
    .\bookmarks-to-config.ps1 -List                                   # 只列資料夾路徑與連結數（不輸出網址）
    .\bookmarks-to-config.ps1 -Folders '書籤列/工作','書籤列/DevOps' -Out .\startpage-default.json
    .\bookmarks-to-config.ps1 -Browser Chrome -Folders '書籤列' -Out .\a.json
  -Folders 比對規則：資料夾路徑「等於」或「以它開頭」即納入（含子資料夾）。
  只讀「書籤列」與「其他書籤」，不讀行動裝置書籤（synced）。
#>
param(
  [ValidateSet('Edge', 'Chrome')][string]$Browser = 'Edge',
  [string]$Path,                 # 直接指定 Bookmarks 檔（測試或非 Default 設定檔用）
  [switch]$List,
  [string[]]$Folders,
  [string]$PageName = '首頁',
  [string]$Out
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

if (-not $Path) {
  $Path = if ($Browser -eq 'Edge') { "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks" }
          else { "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks" }
}
if (-not (Test-Path $Path)) { throw "找不到書籤檔：$Path" }
$bm = [IO.File]::ReadAllText($Path, $utf8) | ConvertFrom-Json

function New-Uid { -join ((48..57) + (97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ }) }

# 攤平成 (path, links[]) 清單
$folderList = New-Object System.Collections.Generic.List[object]
function Walk($node, [string]$path) {
  $links = New-Object System.Collections.Generic.List[object]
  foreach ($c in $node.children) {
    if ($c.type -eq 'url' -and $c.url -match '^(https?|file):') {
      $links.Add([ordered]@{ id = (New-Uid); name = $(if ($c.name) { $c.name } else { $c.url }); url = $c.url })
    }
  }
  if ($links.Count) { $folderList.Add([pscustomobject]@{ Path = $path; Links = $links }) }
  foreach ($c in $node.children) { if ($c.type -eq 'folder') { Walk $c "$path/$($c.name)" } }
}
Walk $bm.roots.bookmark_bar '書籤列'
Walk $bm.roots.other '其他書籤'

if ($List) {
  $folderList | ForEach-Object { [pscustomobject]@{ 資料夾 = $_.Path; 連結數 = $_.Links.Count } } | Format-Table -AutoSize
  return
}
if (-not $Folders) { throw '請用 -Folders 指定要匯入的資料夾（先用 -List 查看）' }

$widgets = New-Object System.Collections.Generic.List[object]
foreach ($f in $folderList) {
  $hit = $Folders | Where-Object { $f.Path -eq $_ -or $f.Path.StartsWith("$_/") }
  if (-not $hit) { continue }
  $title = ($f.Path -split '/')[-1]
  $widgets.Add([ordered]@{ id = (New-Uid); type = 'links'; title = $title; links = $f.Links })
}
if (-not $widgets.Count) { throw '沒有符合 -Folders 的資料夾（名稱需與 -List 顯示的路徑一致）' }

$widgets.Add([ordered]@{ id = (New-Uid); type = 'notes'; title = '筆記'; text = '' })
$widgets.Add([ordered]@{ id = (New-Uid); type = 'todo'; title = '待辦'; items = @() })

$state = [ordered]@{
  theme = 'light'; engine = 0; current = 0
  pages = @([ordered]@{ id = (New-Uid); name = $PageName; widgets = $widgets })
}
$json = $state | ConvertTo-Json -Depth 10
if ($Out) {
  [IO.File]::WriteAllText($Out, $json, $utf8)
  Write-Host "已輸出 $($widgets.Count - 2) 個書籤區塊 → $Out"
} else { $json }
