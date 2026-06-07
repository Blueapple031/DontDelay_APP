# DontDelay Windows 설치 프로그램 빌드
# 사용법: .\installer\build_setup.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $ProjectRoot

Write-Host "==> Flutter Windows 릴리스 빌드 (flutter build windows)..." -ForegroundColor Cyan
flutter build windows
if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows 실패"
}

$ReleaseExe = Join-Path $ProjectRoot "build\windows\x64\runner\Release\dontdelay.exe"
if (-not (Test-Path $ReleaseExe)) {
    throw "릴리스 exe 없음: $ReleaseExe"
}

$IsccCandidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "${env:LocalAppData}\Programs\Inno Setup 6\ISCC.exe"
)

$Iscc = $IsccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Iscc) {
    Write-Host ""
    Write-Host "Inno Setup 6이 설치되어 있지 않습니다." -ForegroundColor Yellow
    Write-Host "1. https://jrsoftware.org/isdl.php 에서 Inno Setup 6 설치"
    Write-Host "2. 설치 후 다시 실행: .\installer\build_setup.ps1"
    Write-Host ""
    Write-Host "또는 Inno Setup Compiler에서 installer\dontdelay.iss 를 직접 열고 Compile 하세요."
    exit 1
}

Write-Host "==> 설치 프로그램 컴파일 ($Iscc)..." -ForegroundColor Cyan
& $Iscc (Join-Path $PSScriptRoot "dontdelay.iss")
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup 컴파일 실패"
}

$OutputDir = Join-Path $PSScriptRoot "output"
$SetupFile = Get-ChildItem $OutputDir -Filter "DontDelay_Setup_*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($SetupFile) {
    Write-Host ""
    Write-Host "완료: $($SetupFile.FullName)" -ForegroundColor Green
} else {
    Write-Host "컴파일은 끝났지만 output 폴더에서 setup exe를 찾지 못했습니다." -ForegroundColor Yellow
}
