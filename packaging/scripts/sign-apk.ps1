# 本地签名：把 CI 产出的未签名 APK 用现有 keystore 签成可覆盖安装的 APK。
# 密钥始终留在本机，不上传任何地方。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File packaging\scripts\sign-apk.ps1 -InApk "C:\path\app-release-unsigned.apk"
param(
  [Parameter(Mandatory = $true)][string]$InApk,
  [string]$OutApk = ''
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$keystore = Join-Path $repoRoot 'releases\猫事 CatCare - Google Play package\signing.keystore'
$alias = 'my-key-alias'
$storePass = 'XEMHfI2e4lsM'
$expectedFp = 'fe0d43f77bb7cc8df75a5247c3025ea5add9172855d59d4a5993c032457da66a'

$javaHome = 'D:\DevEco Studio\jbr'
$buildTools = 'C:\Users\caicx\AppData\Local\Temp\android-bt\android-14'
$zipalign = Join-Path $buildTools 'zipalign.exe'
$apksigner = Join-Path $buildTools 'apksigner.bat'

if (-not (Test-Path $InApk)) { throw "输入 APK 不存在：$InApk" }
if (-not (Test-Path $keystore)) { throw "keystore 不存在：$keystore" }
if (-not (Test-Path $javaHome)) { throw "未找到 JDK：$javaHome" }
foreach ($tool in @($zipalign, $apksigner)) {
  if (-not (Test-Path $tool)) {
    throw "缺少 Android build-tools 组件：$tool`n请安装 build-tools 后重试（例如：sdkmanager ""build-tools;34.0.0""），或把脚本里的 -buildTools 路径改成实际位置。"
  }
}
if (-not $OutApk) {
  # 版本号取自 build.gradle 的 versionName，统一归档到 releases\apk\ 下的版本化文件名。
  $gradleFile = Join-Path $repoRoot 'packaging\android\app\build.gradle'
  $version = 'unknown'
  if (Test-Path $gradleFile) {
    $m = [regex]::Match((Get-Content $gradleFile -Raw), 'versionName\s+"([^"]+)"')
    if ($m.Success) { $version = $m.Groups[1].Value }
  }
  $OutApk = Join-Path $repoRoot "releases\apk\猫事CatCare-v$version-离线版.apk"
}

$env:JAVA_HOME = $javaHome
$env:PATH = (Join-Path $javaHome 'bin') + ';' + $env:PATH

$outDir = Split-Path -Parent $OutApk
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$tmp = Join-Path $env:TEMP ('catcare-sign-' + [guid]::NewGuid().ToString('N') + '.apk')

Write-Host '[1/3] zipalign ...' -ForegroundColor Cyan
& $zipalign -p -f 4 $InApk $tmp
if ($LASTEXITCODE -ne 0) { throw 'zipalign 失败' }

Write-Host '[2/3] apksigner sign ...' -ForegroundColor Cyan
if (Test-Path $OutApk) { Remove-Item $OutApk -Force }
& $apksigner sign --ks $keystore --ks-key-alias $alias --ks-pass "pass:$storePass" --key-pass "pass:$storePass" --v1-signing-enabled true --v2-signing-enabled true --out $OutApk $tmp
if ($LASTEXITCODE -ne 0) { throw 'apksigner 签名失败' }
Remove-Item $tmp -Force -ErrorAction SilentlyContinue

Write-Host '[3/3] 校验签名 ...' -ForegroundColor Cyan
$certs = (& $apksigner verify --print-certs $OutApk) -join "`n"
Write-Host $certs
$normalized = ($certs -replace '[^0-9a-fA-F]', '').ToLower()
if ($normalized -notmatch $expectedFp) {
  throw "签名指纹与旧版不一致（预期含 $expectedFp），无法覆盖安装，请检查 keystore。"
}

$size = (Get-Item $OutApk).Length
Write-Host ("完成：{0}（{1:N0} 字节）" -f $OutApk, $size) -ForegroundColor Green
