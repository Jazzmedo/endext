# ✅ لازم تشغيل كـ Administrator

Write-Host ">> Restoring Edge Update Services & Tasks..." -ForegroundColor Cyan

# 1. إعادة تفعيل الخدمات
$services = @("edgeupdate", "edgeupdatem")
foreach ($svc in $services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Host "Restored and started service: $svc" -ForegroundColor Green
    } else {
        Write-Host "Service $svc not found." -ForegroundColor Yellow
    }
}

# 2. إنشاء المهام التلقائية الأساسية (Core + UA)
# ملف EXE الخاص بالتحديث:
$edgeUpdateExe = "$env:ProgramFiles(x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"

if (Test-Path $edgeUpdateExe) {
    schtasks /Create /TN "MicrosoftEdgeUpdateTaskMachineCore" /TR "`"$edgeUpdateExe`" /c" /SC HOURLY /RU SYSTEM /RL HIGHEST /F | Out-Null
    schtasks /Create /TN "MicrosoftEdgeUpdateTaskMachineUA" /TR "`"$edgeUpdateExe`" /ua" /SC DAILY /RU SYSTEM /RL HIGHEST /F | Out-Null
    Write-Host "Recreated Edge scheduled tasks." -ForegroundColor Green
} else {
    Write-Host "Edge update executable not found at: $edgeUpdateExe" -ForegroundColor Red
}

# 3. استرجاع صلاحيات مجلد المهام
$taskFolder = "$env:windir\System32\Tasks\Microsoft\EdgeUpdate"
if (Test-Path $taskFolder) {
    icacls $taskFolder /reset /T /C | Out-Null
    icacls $taskFolder /grant:r "SYSTEM:(OI)(CI)(F)" /T /C | Out-Null
    icacls $taskFolder /grant:r "Users:(OI)(CI)(RX)" /T /C | Out-Null
    Write-Host "Restored permissions for task folder." -ForegroundColor Yellow
}

# 4. إعادة مفاتيح الريجستري الأساسية (فارغة بدون سياسات)
$regPaths = @(
    "HKLM:\SOFTWARE\Policies\BraveSoftware",
    "HKCU:\SOFTWARE\Policies\BraveSoftware",
    "HKLM:\SOFTWARE\Policies\Google",
    "HKCU:\SOFTWARE\Policies\Google",
    "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
)

foreach ($regPath in $regPaths) {
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Host "Restored empty registry key: $regPath" -ForegroundColor Gray
    }
}

Write-Host "`n✅ Done. Edge update environment restored." -ForegroundColor Cyan
