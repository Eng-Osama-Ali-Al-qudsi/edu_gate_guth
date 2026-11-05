[CmdletBinding()]
param(
    [string]$FlutterExecutable = '',
    [string]$OutputDirectory = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$ExpectedPackageName = 'edu_gate_guth'
$ExpectedTestCount = 33
$FontRelativePath = 'assets\fonts\Cairo-Variable.ttf'
$FontPath = Join-Path $ProjectRoot $FontRelativePath
$FontLicensePath = Join-Path $ProjectRoot 'assets\fonts\OFL.txt'
$ApkInBuild = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path (Split-Path -Parent $ProjectRoot) 'EDU_GATE_DELIVERY'
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$ProjectPrefix = $ProjectRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
if ($OutputDirectory.Equals($ProjectRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
    $OutputDirectory.StartsWith($ProjectPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must be outside the project root. The script never packages into or writes delivery files over source files.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$RunId = Get-Date -Format 'yyyyMMdd_HHmmss'
$RunDirectory = Join-Path $OutputDirectory ('.edu_gate_run_' + $RunId + '_' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$StageRoot = Join-Path $RunDirectory 'stage'
$StageProject = Join-Path $StageRoot 'edu_gate_guth'
$ReportPath = Join-Path $RunDirectory 'TEST_REPORT.md'
$BuildLogPath = Join-Path $RunDirectory 'BUILD_LOG.txt'
$ArchiveTempPath = Join-Path $RunDirectory 'edu_gate_guht_FINAL_SUBMISSION.tmp.zip'
$ArchivePath = Join-Path $OutputDirectory 'edu_gate_guht_FINAL_SUBMISSION.zip'

$Results = [ordered]@{
    'Environment preflight' = 'NOT RUN'
    'Cairo TTF and license verification' = 'NOT RUN'
    'flutter pub get' = 'NOT RUN'
    'flutter analyze' = 'NOT RUN'
    'flutter test' = 'NOT RUN'
    'flutter build apk --release' = 'NOT RUN'
    'APK content verification' = 'NOT RUN'
    'ZIP creation and verification' = 'NOT RUN'
}
$FlutterVersion = 'NOT DETECTED'
$DartVersion = 'NOT DETECTED'
$JavaVersion = 'NOT DETECTED'
$AndroidSdkPath = 'NOT DETECTED'
$DoctorExitCode = 'NOT RUN'
$TestCount = 0
$PassedCount = 0
$FailedCount = 0
$SkippedCount = 0
$ApkSizeBytes = 0
$ApkSha256 = 'NOT GENERATED'
$CairoSha1 = 'NOT VERIFIED'
$CairoSha256 = 'NOT VERIFIED'
$CairoGitBlobSha1 = 'NOT VERIFIED'
$FailureMessage = ''
$script:LastNativeExitCode = 0
$script:ArchiveValidated = $false

function Write-LogLine {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $line
    Add-Content -LiteralPath $BuildLogPath -Value $line -Encoding UTF8
}

function Get-GitBlobSha1 {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)
    # Git object hash = SHA1(ASCII("blob <length>\0") + raw file bytes).
    # This is deliberately distinct from SHA1(raw file bytes).
    $header = [System.Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [System.Array]::Copy($header, 0, $payload, 0, $header.Length)
    [System.Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        return ([System.BitConverter]::ToString($sha1.ComputeHash($payload))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha1.Dispose()
    }
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$WorkingDirectory = $ProjectRoot,
        [switch]$AllowNonZeroExit
    )
    Write-LogLine "START: $Label"
    Push-Location -LiteralPath $WorkingDirectory
    try {
        $output = @(& $Executable @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        $script:LastNativeExitCode = $exitCode
        foreach ($item in $output) {
            $line = [string]$item
            Add-Content -LiteralPath $BuildLogPath -Value $line -Encoding UTF8
            Write-Host $line
        }
        if ($exitCode -ne 0) {
            Write-LogLine "FAIL: $Label (exit code $exitCode)"
            if (-not $AllowNonZeroExit) {
                throw "$Label failed with exit code $exitCode. Review BUILD_LOG.txt in $RunDirectory."
            }
        } else {
            Write-LogLine "PASS: $Label"
        }
        return $output
    }
    finally {
        Pop-Location
    }
}

function Resolve-FlutterExecutable {
    $candidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($FlutterExecutable)) {
        if (Test-Path -LiteralPath $FlutterExecutable -PathType Container) {
            $candidates.Add((Join-Path $FlutterExecutable 'bin\flutter.bat'))
        } else {
            $candidates.Add($FlutterExecutable)
        }
    }
    foreach ($name in @('FLUTTER_ROOT', 'FLUTTER_HOME')) {
        $root = [Environment]::GetEnvironmentVariable($name)
        if (-not [string]::IsNullOrWhiteSpace($root)) { $candidates.Add((Join-Path $root 'bin\flutter.bat')) }
    }
    foreach ($commandName in @('flutter.bat', 'flutter')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace($command.Source)) { $candidates.Add($command.Source) }
    }
    $localProperties = Join-Path $ProjectRoot 'android\local.properties'
    if (Test-Path -LiteralPath $localProperties) {
        $line = Get-Content -LiteralPath $localProperties | Where-Object { $_ -match '^flutter\.sdk=' } | Select-Object -First 1
        if ($line) {
            $root = ($line -replace '^flutter\.sdk=', '').Trim().Replace('\\', '\')
            $candidates.Add((Join-Path $root 'bin\flutter.bat'))
        }
    }
    $userProfile = [Environment]::GetFolderPath('UserProfile')
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    foreach ($candidate in @(
        'C:\src\flutter\bin\flutter.bat',
        'C:\flutter\bin\flutter.bat',
        (Join-Path $userProfile 'flutter\bin\flutter.bat'),
        (Join-Path $userProfile 'development\flutter\bin\flutter.bat'),
        (Join-Path $localAppData 'Programs\Flutter\bin\flutter.bat')
    )) { if (-not [string]::IsNullOrWhiteSpace($candidate)) { $candidates.Add($candidate) } }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    throw 'Flutter SDK was not found. Install Flutter or pass -FlutterExecutable with the full path to flutter.bat. No installation is attempted.'
}

function Resolve-AndroidSdk {
    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($name in @('ANDROID_SDK_ROOT', 'ANDROID_HOME')) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if (-not [string]::IsNullOrWhiteSpace($value)) { $candidates.Add($value) }
    }
    $localProperties = Join-Path $ProjectRoot 'android\local.properties'
    if (Test-Path -LiteralPath $localProperties) {
        $line = Get-Content -LiteralPath $localProperties | Where-Object { $_ -match '^sdk\.dir=' } | Select-Object -First 1
        if ($line) { $candidates.Add((($line -replace '^sdk\.dir=', '').Trim().Replace('\\', '\'))) }
    }
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if (-not [string]::IsNullOrWhiteSpace($localAppData)) { $candidates.Add((Join-Path $localAppData 'Android\Sdk')) }
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
        $platforms = Join-Path $candidate 'platforms'
        $buildTools = Join-Path $candidate 'build-tools'
        $hasPlatform = (Test-Path -LiteralPath $platforms) -and
            (@(Get-ChildItem -LiteralPath $platforms -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^android-\d+$' }).Count -gt 0)
        $hasBuildTools = (Test-Path -LiteralPath $buildTools) -and
            (@(Get-ChildItem -LiteralPath $buildTools -Directory -ErrorAction SilentlyContinue).Count -gt 0)
        if ($hasPlatform -and $hasBuildTools) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    throw 'Android SDK was not found or has no installed Android platform/build-tools. Set ANDROID_SDK_ROOT or ANDROID_HOME and install the required SDK components.'
}

function Write-TestReport {
    $lines = @(
        '# تقرير ضمان الجودة — EDU GATE', '',
        "تاريخ التقرير: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')", '',
        '## النتيجة التنفيذية', '', '| المرحلة | الحالة |', '|---|---|'
    )
    foreach ($key in $Results.Keys) { $lines += "| $key | $($Results[$key]) |" }
    $lines += @(
        '', '## هوية المشروع', '',
        '- اسم مجلد المشروع وحزمة Dart: `edu_gate_guth` (مطابق للأصل).',
        '- Android namespace/applicationId: `com.example.edu_gate_guth`.',
        '- اسم أرشيف التسليم المطلوب: `edu_gate_guht_FINAL_SUBMISSION.zip` (كما طلبه المستخدم).',
        '', '## بيئة البناء', '',
        "- نظام التشغيل: $([Environment]::OSVersion.VersionString)",
        "- Flutter: $FlutterVersion", "- Dart: $DartVersion", "- Java: $JavaVersion",
        "- Android SDK: $AndroidSdkPath", "- flutter doctor -v exit code (diagnostic): $DoctorExitCode",
        '', '## الاختبارات', '',
        "- الحالات التي أبلغ عنها Flutter: $TestCount", "- الناجحة: $PassedCount",
        "- الفاشلة: $FailedCount", "- المتجاوزة: $SkippedCount", "- العدد المتوقع: $ExpectedTestCount",
        '', '## Cairo TTF — بصمات منفصلة', '',
        '- Raw file SHA-1: `c6c60f666700c17bd38833483b5b14e7a2ebf029`.',
        '- Raw file SHA-256: `667c987182391c91f4e57a2f455b1794fb5e3ee6ca4ef3383e86bb690fa9c964`.',
        '- Git blob SHA-1: `25641b1c828857698457bcd9f5a102616b4e8033` (hash of `blob <length> NUL + bytes`, not raw file SHA-1).',
        "- Actual raw SHA-1 observed: $CairoSha1", "- Actual raw SHA-256 observed: $CairoSha256",
        "- Actual Git blob SHA-1 observed: $CairoGitBlobSha1", '',
        '## APK', '', "- الحجم بالبايت: $ApkSizeBytes", "- SHA-256: $ApkSha256", '',
        '## Remember Me — السلوك المعتمد', '',
        '- يحفظ التطبيق معرّف الحساب الأخير فقط في تفضيلات Android الخاصة بالتطبيق (SharedPreferences MODE_PRIVATE).',
        '- لا تُحفظ كلمة المرور ولا رمز جلسة ولا يتم تسجيل الدخول تلقائياً بعد إعادة التشغيل.',
        '- حسابات الطلاب وكلمات المرور ورموز OTP تبقى داخل AuthRepositoryImpl في الذاكرة وتُفقد عند إغلاق العملية؛ لذلك لا يمكن استعادة جلسة مصادقة حقيقية مع هذا المستودع.',
        '- بعد إعادة التشغيل يظهر المعرّف السابق، لكن الحساب نفسه غير موجود في المستودع الذاكري؛ يجب إنشاء الحساب مجدداً قبل تسجيل الدخول.',
        '', '## حدود النظام التجريبي', '',
        '- المستودع التجريبي يحتفظ بالحسابات ورموز الاستعادة في الذاكرة فقط.',
        '- كلمات المرور نص صريح داخل الذاكرة لأغراض التكليف فقط؛ لا يُوصى بهذا في نظام إنتاجي.',
        '- OTP ثابت للاختبار: `123456`، ولا تُرسل رسالة بريد أو SMS فعلية.',
        '- لا يوجد خادم أو قاعدة بيانات أو حزم خارجية من pub.dev.',
        '', '## ملاحظات التنفيذ', ''
    )
    if ([string]::IsNullOrWhiteSpace($FailureMessage)) { $lines += '- لم يسجل السكربت خطأ تنفيذياً.' }
    else { $lines += "- سبب التوقف: $FailureMessage" }
    $encoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    [System.IO.File]::WriteAllLines($ReportPath, [string[]]$lines, $encoding)
}

function Test-ArchiveContents {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$ExpectedApkSha256)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entries = @($zip.Entries)
        $names = @($entries | ForEach-Object { $_.FullName })
        $required = @(
            'edu_gate_guth/pubspec.yaml', 'edu_gate_guth/lib/main.dart',
            'edu_gate_guth/lib/services/remembered_identifier_store.dart',
            'edu_gate_guth/assets/fonts/Cairo-Variable.ttf', 'edu_gate_guth/assets/fonts/OFL.txt',
            'edu_gate_guth/test/widget_test.dart', 'edu_gate_guth/test/controllers/auth_controller_test.dart',
            'edu_gate_guth/test/repositories/auth_repository_impl_test.dart', 'edu_gate_guth/test/utils/form_validators_test.dart',
            'edu_gate_guth/README_AR.md', 'edu_gate_guth/TEST_REPORT.md',
            'edu_gate_guth/BUILD_AND_PACKAGE.ps1', 'edu_gate_guth/app-release.apk'
        )
        foreach ($name in $required) { if ($names -notcontains $name) { throw "Required archive entry is missing: $name" } }
        $apkEntry = $zip.GetEntry('edu_gate_guth/app-release.apk')
        if ($apkEntry.Length -le 0) { throw 'APK inside ZIP is empty.' }
        $apkStream = $apkEntry.Open()
        try {
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try { $embeddedApkSha = ([System.BitConverter]::ToString($sha.ComputeHash($apkStream))).Replace('-', '').ToLowerInvariant() }
            finally { $sha.Dispose() }
        }
        finally { $apkStream.Dispose() }
        if ($embeddedApkSha -ne $ExpectedApkSha256.ToLowerInvariant()) { throw 'APK SHA-256 inside ZIP does not match the separately delivered APK.' }
        foreach ($entry in $entries) {
            if ($entry.FullName.EndsWith('/')) { continue }
            $stream = $entry.Open()
            try { $stream.CopyTo([System.IO.Stream]::Null) }
            finally { $stream.Dispose() }
        }
        return $names.Count
    }
    finally { $zip.Dispose() }
}

function Copy-ProjectToStage {
    param([Parameter(Mandatory = $true)][string]$DestinationProject)
    $excludedDirectories = @('.dart_tool', 'build', '.git', '.idea', '.vscode', '.gradle', 'Pods')
    foreach ($item in Get-ChildItem -LiteralPath $ProjectRoot -Recurse -Force) {
        $relative = $item.FullName.Substring($ProjectRoot.Length).TrimStart('\', '/')
        $segments = $relative -split '[\\/]'
        if (@($segments | Where-Object { $excludedDirectories -contains $_ }).Count -gt 0) { continue }
        if (-not $item.PSIsContainer -and ($item.Name -in @('local.properties', 'BUILD_LOG.txt', 'app-release.apk', 'SHA256SUMS.txt') -or $item.Extension -in @('.iml', '.log'))) { continue }
        $destination = Join-Path $DestinationProject $relative
        if ($item.PSIsContainer) {
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
        } else {
            $parent = Split-Path -Parent $destination
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            Copy-Item -LiteralPath $item.FullName -Destination $destination
        }
    }
}

function Publish-FileSafely {
    param([Parameter(Mandatory = $true)][string]$Source, [Parameter(Mandatory = $true)][string]$Destination)
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        $backup = "$Destination.previous_$RunId"
        $suffix = 1
        while (Test-Path -LiteralPath $backup) { $backup = "$Destination.previous_$RunId`_$suffix"; $suffix++ }
        Move-Item -LiteralPath $Destination -Destination $backup
        Write-LogLine "Existing delivery file preserved as: $backup"
    }
    Copy-Item -LiteralPath $Source -Destination $Destination
}

try {
    New-Item -ItemType Directory -Path $RunDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $StageProject -Force | Out-Null
    if ($env:OS -ne 'Windows_NT') { throw 'Run this script on Windows PowerShell/PowerShell with Flutter, Java, and Android SDK installed.' }
    if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'PowerShell 5.1 or newer is required.' }

    $pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
    $pubspecText = Get-Content -LiteralPath $pubspecPath -Raw
    if ($pubspecText -notmatch ('(?m)^name:\s*' + [regex]::Escape($ExpectedPackageName) + '\s*$')) { throw 'pubspec.yaml package name must remain edu_gate_guth.' }
    if ($pubspecText -notmatch 'family:\s*Cairo' -or $pubspecText -notmatch 'asset:\s*assets/fonts/Cairo-Variable\.ttf') { throw 'pubspec.yaml must register the local Cairo TTF.' }
    $allowedPackageNames = @('flutter', 'flutter_localizations', 'flutter_test')
    $dependencyNames = @()
    foreach ($sectionName in @('dependencies', 'dev_dependencies')) {
        $sectionMatch = [regex]::Match($pubspecText, '(?ms)^' + $sectionName + ':\s*\r?\n(?<body>.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\z)')
        if ($sectionMatch.Success) {
            foreach ($dependencyMatch in [regex]::Matches($sectionMatch.Groups['body'].Value, '(?m)^\s{2}([A-Za-z0-9_]+):')) { $dependencyNames += $dependencyMatch.Groups[1].Value }
        }
    }
    $unexpectedPackages = @($dependencyNames | Where-Object { $allowedPackageNames -notcontains $_ })
    if ($unexpectedPackages.Count -gt 0) { throw ('External Flutter/Dart packages are not permitted: ' + ($unexpectedPackages -join ', ')) }
    $gradleText = Get-Content -LiteralPath (Join-Path $ProjectRoot 'android\app\build.gradle') -Raw
    if ($gradleText -notmatch 'namespace\s*=\s*"com\.example\.edu_gate_guth"' -or $gradleText -notmatch 'applicationId\s*=\s*"com\.example\.edu_gate_guth"') { throw 'Android namespace/applicationId do not match the original edu_gate_guth identity.' }

    $flutter = Resolve-FlutterExecutable
    $flutterRoot = Split-Path -Parent (Split-Path -Parent $flutter)
    $dart = Join-Path $flutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
    if (-not (Test-Path -LiteralPath $dart -PathType Leaf)) {
        $dartCommand = Get-Command 'dart' -ErrorAction SilentlyContinue
        if ($null -ne $dartCommand -and $dartCommand.Source) { $dart = $dartCommand.Source }
        else { throw 'Flutter was found but its bundled Dart SDK was not found.' }
    }

    $javaPath = ''
    if (-not [string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
        $candidateJava = Join-Path $env:JAVA_HOME 'bin\java.exe'
        if (-not (Test-Path -LiteralPath $candidateJava -PathType Leaf)) { throw "JAVA_HOME is set but java.exe is missing: $candidateJava" }
        $javaPath = $candidateJava
        $javaBin = Join-Path $env:JAVA_HOME 'bin'
        if ($env:PATH -notlike "*$javaBin*") { $env:PATH = $javaBin + ';' + $env:PATH }
    } else {
        $javaCommand = Get-Command 'java' -ErrorAction SilentlyContinue
        if ($null -ne $javaCommand -and $javaCommand.Source) { $javaPath = $javaCommand.Source }
    }
    if ([string]::IsNullOrWhiteSpace($javaPath)) { throw 'Java not found. Install JDK 17+ and configure JAVA_HOME/PATH.' }
    $javaText = ((& $javaPath -version 2>&1) | ForEach-Object { [string]$_ }) -join ' '
    $javaMatch = [regex]::Match($javaText, 'version\s+"(?<major>\d+)')
    if (-not $javaMatch.Success) { $javaMatch = [regex]::Match($javaText, 'openjdk\s+(?<major>\d+)') }
    if (-not $javaMatch.Success) { throw 'Unable to determine Java version.' }
    $javaMajor = [int]$javaMatch.Groups['major'].Value
    $JavaVersion = $javaText.Trim()
    if ($javaMajor -lt 17) { throw "Java $javaMajor detected; JDK 17 or newer is required." }

    $AndroidSdkPath = Resolve-AndroidSdk
    $env:ANDROID_SDK_ROOT = $AndroidSdkPath
    $env:ANDROID_HOME = $AndroidSdkPath
    $Results['Environment preflight'] = 'PASS'

    if (-not (Test-Path -LiteralPath $FontPath -PathType Leaf)) { throw "Official Cairo TTF missing: $FontPath. Download it from https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf and save as Cairo-Variable.ttf." }
    if (-not (Test-Path -LiteralPath $FontLicensePath -PathType Leaf)) { throw "Cairo OFL license missing: $FontLicensePath" }
    $fontBytes = [System.IO.File]::ReadAllBytes($FontPath)
    if ($fontBytes.Length -ne 599548 -or -not ($fontBytes[0] -eq 0 -and $fontBytes[1] -eq 1 -and $fontBytes[2] -eq 0 -and $fontBytes[3] -eq 0)) { throw 'Cairo TTF size or SFNT signature mismatch.' }
    $CairoSha1 = (Get-FileHash -LiteralPath $FontPath -Algorithm SHA1).Hash.ToLowerInvariant()
    $CairoSha256 = (Get-FileHash -LiteralPath $FontPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $CairoGitBlobSha1 = Get-GitBlobSha1 -Bytes $fontBytes
    if ($CairoSha1 -ne 'c6c60f666700c17bd38833483b5b14e7a2ebf029') { throw "Cairo raw-file SHA-1 mismatch: $CairoSha1" }
    if ($CairoSha256 -ne '667c987182391c91f4e57a2f455b1794fb5e3ee6ca4ef3383e86bb690fa9c964') { throw "Cairo raw-file SHA-256 mismatch: $CairoSha256" }
    if ($CairoGitBlobSha1 -ne '25641b1c828857698457bcd9f5a102616b4e8033') { throw "Cairo Git blob SHA-1 mismatch: $CairoGitBlobSha1" }

    $licenseBytes = [System.IO.File]::ReadAllBytes($FontLicensePath)
    if ($licenseBytes.Length -ne 4473) { throw 'Cairo OFL license length mismatch.' }
    $licenseGitBlobSha1 = Get-GitBlobSha1 -Bytes $licenseBytes
    if ($licenseGitBlobSha1 -ne 'f6e87d489b3f459dde4e0f457fdd63e1f39bfe67') { throw "Cairo license Git blob SHA-1 mismatch: $licenseGitBlobSha1" }
    $licenseText = [System.Text.Encoding]::UTF8.GetString($licenseBytes)
    if ($licenseText -notmatch 'SIL OPEN FONT LICENSE Version 1\.1' -or $licenseText -notmatch 'The Cairo Project Authors') { throw 'Cairo OFL license header validation failed.' }
    $Results['Cairo TTF and license verification'] = 'PASS'

    $version = Invoke-NativeCommand -Executable $flutter -Arguments @('--version') -Label 'Flutter version check'
    $FlutterVersion = (($version | ForEach-Object { [string]$_ }) -join ' ').Trim()
    $dartVersion = Invoke-NativeCommand -Executable $dart -Arguments @('--version') -Label 'Dart version check'
    $DartVersion = (($dartVersion | ForEach-Object { [string]$_ }) -join ' ').Trim()
    $doctor = @(& $flutter doctor -v 2>&1)
    $DoctorExitCode = $LASTEXITCODE
    foreach ($line in $doctor) { Add-Content -LiteralPath $BuildLogPath -Value ([string]$line) -Encoding UTF8 }

    Invoke-NativeCommand -Executable $flutter -Arguments @('pub', 'get') -Label 'flutter pub get' | Out-Null
    $Results['flutter pub get'] = 'PASS'
    Invoke-NativeCommand -Executable $flutter -Arguments @('analyze') -Label 'flutter analyze' | Out-Null
    $Results['flutter analyze'] = 'PASS'

    $testOutput = Invoke-NativeCommand -Executable $flutter -Arguments @('test', '--reporter', 'json') -Label 'flutter test' -AllowNonZeroExit
    foreach ($item in $testOutput) {
        $line = ([string]$item).Trim()
        if (-not $line.StartsWith('{')) { continue }
        try {
            $event = ConvertFrom-Json -InputObject $line -ErrorAction Stop
            if ($event.type -eq 'testDone') {
                $TestCount++
                if ($event.result -eq 'success') { $PassedCount++ }
                elseif ($event.skipped -eq $true) { $SkippedCount++ }
                else { $FailedCount++ }
            }
        } catch { }
    }
    if ($script:LastNativeExitCode -ne 0) { throw "flutter test failed (exit code $script:LastNativeExitCode)." }
    if ($TestCount -ne $ExpectedTestCount) { throw "Flutter reported $TestCount test cases; expected exactly $ExpectedTestCount. Review test discovery and suite." }
    if ($FailedCount -gt 0 -or $SkippedCount -gt 0) { throw "Flutter tests: $FailedCount failed, $SkippedCount skipped." }
    $Results['flutter test'] = 'PASS'


    Invoke-NativeCommand -Executable $flutter -Arguments @('build', 'apk', '--release') -Label 'flutter build apk --release' | Out-Null
    if (-not (Test-Path -LiteralPath $ApkInBuild -PathType Leaf)) { throw "Release build reported success but APK is missing: $ApkInBuild" }
    $ApkSizeBytes = (Get-Item -LiteralPath $ApkInBuild).Length
    if ($ApkSizeBytes -le 0) { throw 'Release APK is empty.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $apkZip = [System.IO.Compression.ZipFile]::OpenRead($ApkInBuild)
    try {
        $apkNames = @($apkZip.Entries | ForEach-Object { $_.FullName })
        foreach ($requiredEntry in @('AndroidManifest.xml', 'classes.dex', 'assets/flutter_assets/FontManifest.json', 'assets/flutter_assets/assets/fonts/Cairo-Variable.ttf')) {
            if ($apkNames -notcontains $requiredEntry) { throw "APK missing required entry: $requiredEntry" }
        }
        $fontEntry = $apkZip.GetEntry('assets/flutter_assets/assets/fonts/Cairo-Variable.ttf')
        $fontStream = $fontEntry.Open()
        try {
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try { $apkFontSha256 = ([System.BitConverter]::ToString($sha.ComputeHash($fontStream))).Replace('-', '').ToLowerInvariant() }
            finally { $sha.Dispose() }
        } finally { $fontStream.Dispose() }
        if ($apkFontSha256 -ne $CairoSha256) { throw 'Cairo font bytes embedded in APK do not match the verified local TTF.' }
        $manifestStream = $apkZip.GetEntry('assets/flutter_assets/FontManifest.json').Open()
        try {
            $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $manifestStream
            try { $fontManifest = $reader.ReadToEnd() } finally { $reader.Dispose() }
        } finally { $manifestStream.Dispose() }
        if ($fontManifest -notmatch '"family"\s*:\s*"Cairo"' -or $fontManifest -notmatch 'assets/fonts/Cairo-Variable\.ttf') { throw 'Cairo font family is not correctly registered in the APK FontManifest.' }
        foreach ($entry in $apkZip.Entries) {
            if ($entry.FullName.EndsWith('/')) { continue }
            $stream = $entry.Open()
            try { $stream.CopyTo([System.IO.Stream]::Null) } finally { $stream.Dispose() }
        }
    } finally { $apkZip.Dispose() }
    $ApkSha256 = (Get-FileHash -LiteralPath $ApkInBuild -Algorithm SHA256).Hash.ToLowerInvariant()
    $Results['flutter build apk --release'] = 'PASS'
    $Results['APK content verification'] = 'PASS'

    # Prepare a clean staging copy. The original source tree is never cleaned or overwritten by this script.
    Copy-ProjectToStage -DestinationProject $StageProject
    Copy-Item -LiteralPath (Join-Path $ProjectRoot 'README_AR.md') -Destination (Join-Path $StageProject 'README_AR.md') -Force
    Copy-Item -LiteralPath $ApkInBuild -Destination (Join-Path $StageProject 'app-release.apk')

    $Results['ZIP creation and verification'] = 'IN PROGRESS'
    Write-TestReport
    Copy-Item -LiteralPath $ReportPath -Destination (Join-Path $StageProject 'TEST_REPORT.md') -Force
    Compress-Archive -Path $StageProject -DestinationPath $ArchiveTempPath -CompressionLevel Optimal -Force
    [void](Test-ArchiveContents -Path $ArchiveTempPath -ExpectedApkSha256 $ApkSha256)
    $Results['ZIP creation and verification'] = 'PASS'
    Write-TestReport
    Copy-Item -LiteralPath $ReportPath -Destination (Join-Path $StageProject 'TEST_REPORT.md') -Force
    Remove-Item -LiteralPath $ArchiveTempPath -Force
    Compress-Archive -Path $StageProject -DestinationPath $ArchiveTempPath -CompressionLevel Optimal -Force
    $entryCount = Test-ArchiveContents -Path $ArchiveTempPath -ExpectedApkSha256 $ApkSha256
    $script:ArchiveValidated = $true

    # Publish only verified artifacts. Existing delivery files are renamed to .previous_* first.
    $publishMap = @(
        @{ Source = $ArchiveTempPath; Name = 'edu_gate_guht_FINAL_SUBMISSION.zip' },
        @{ Source = $ApkInBuild; Name = 'app-release.apk' },
        @{ Source = (Join-Path $ProjectRoot 'README_AR.md'); Name = 'README_AR.md' },
        @{ Source = $ReportPath; Name = 'TEST_REPORT.md' },
        @{ Source = (Join-Path $ProjectRoot 'BUILD_AND_PACKAGE.ps1'); Name = 'BUILD_AND_PACKAGE.ps1' },
        @{ Source = $BuildLogPath; Name = 'BUILD_LOG.txt' }
    )
    foreach ($item in $publishMap) { Publish-FileSafely -Source $item.Source -Destination (Join-Path $OutputDirectory $item.Name) }

    $hashLines = @()
    foreach ($name in @('edu_gate_guht_FINAL_SUBMISSION.zip', 'app-release.apk', 'README_AR.md', 'TEST_REPORT.md', 'BUILD_AND_PACKAGE.ps1')) {
        $path = Join-Path $OutputDirectory $name
        $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        $hashLines += "$hash  $name"
    }
    $hashTemp = Join-Path $RunDirectory 'SHA256SUMS.txt'
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    [System.IO.File]::WriteAllLines($hashTemp, [string[]]$hashLines, $utf8)
    Publish-FileSafely -Source $hashTemp -Destination (Join-Path $OutputDirectory 'SHA256SUMS.txt')

    Write-LogLine "SUCCESS: all checks passed. Tests: $PassedCount/$TestCount. APK bytes: $ApkSizeBytes. ZIP entries: $entryCount."
    Copy-Item -LiteralPath $BuildLogPath -Destination (Join-Path $OutputDirectory 'BUILD_LOG.txt') -Force
    Write-Host ''
    Write-Host 'Verified delivery files:' -ForegroundColor Green
    foreach ($name in @('edu_gate_guht_FINAL_SUBMISSION.zip', 'app-release.apk', 'README_AR.md', 'TEST_REPORT.md', 'BUILD_AND_PACKAGE.ps1', 'SHA256SUMS.txt', 'BUILD_LOG.txt')) {
        Write-Host (Join-Path $OutputDirectory $name)
    }
}
catch {
    $FailureMessage = $_.Exception.Message
    if ($Results['Environment preflight'] -eq 'NOT RUN') { $Results['Environment preflight'] = 'FAIL/BLOCKED' }
    elseif ($Results['Cairo TTF and license verification'] -eq 'NOT RUN') { $Results['Cairo TTF and license verification'] = 'FAIL/BLOCKED' }
    elseif ($Results['flutter pub get'] -eq 'NOT RUN') { $Results['flutter pub get'] = 'FAIL/BLOCKED' }
    elseif ($Results['flutter analyze'] -eq 'NOT RUN') { $Results['flutter analyze'] = 'FAIL/BLOCKED' }
    elseif ($Results['flutter test'] -eq 'NOT RUN') { $Results['flutter test'] = 'FAIL/BLOCKED' }
    elseif ($Results['flutter build apk --release'] -eq 'NOT RUN') { $Results['flutter build apk --release'] = 'FAIL/BLOCKED' }
    elseif ($Results['APK content verification'] -eq 'NOT RUN') { $Results['APK content verification'] = 'FAIL/BLOCKED' }
    elseif (-not $script:ArchiveValidated) { $Results['ZIP creation and verification'] = 'FAIL/BLOCKED' }
    try {
        if (-not (Test-Path -LiteralPath $RunDirectory)) { New-Item -ItemType Directory -Path $RunDirectory -Force | Out-Null }
        Write-TestReport
        $failedReport = Join-Path $OutputDirectory 'TEST_REPORT.md'
        Publish-FileSafely -Source $ReportPath -Destination $failedReport
        if (Test-Path -LiteralPath $BuildLogPath -PathType Leaf) {
            Publish-FileSafely -Source $BuildLogPath -Destination (Join-Path $OutputDirectory 'BUILD_LOG.txt')
        }
    } catch { Write-Host "Could not publish failure report: $($_.Exception.Message)" }
    try { Write-LogLine "STOP: $FailureMessage" } catch { Write-Host $FailureMessage }
    Write-Host "ERROR: $FailureMessage" -ForegroundColor Red
    exit 1
}
finally {
    if (Test-Path -LiteralPath $StageRoot) { Remove-Item -LiteralPath $StageRoot -Recurse -Force }
}
