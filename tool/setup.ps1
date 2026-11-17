# One-time setup for Windows (PowerShell). Same as tool/setup.sh.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$org = "za.co.spongebubble"

function New-App($dir, $name, $platforms) {
  Push-Location $dir
  flutter create --org $org --project-name $name --platforms=$platforms . | Out-Null
  if (Test-Path "test/widget_test.dart") { Remove-Item "test/widget_test.dart" }
  flutter pub get
  Pop-Location
  Write-Host "OK $dir"
}

Push-Location packages/sb_core; dart pub get; Pop-Location
Push-Location packages/sb_ui; flutter pub get; Pop-Location
New-App "apps/customer" "spongebubble_customer" "android,ios,web"
New-App "apps/partner" "spongebubble_partner" "android,ios"
New-App "apps/admin" "spongebubble_admin" "web"
Write-Host "Done. Try:  cd apps/customer; flutter run -d chrome"
