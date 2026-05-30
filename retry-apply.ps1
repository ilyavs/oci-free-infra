param(
  [int]$IntervalMinutes = 15,
  [string]$TerraformDir = "$env:USERPROFILE\github\oci-free-infra"
)

$Terraform = "$env:USERPROFILE\terraform\terraform.exe"
$Attempt = 0
$VarArgs = @("--", "-var=allow_amd_micro=true", "-var=amd_availability_domain_index=2")

while ($true) {
  $Attempt++
  $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$now] Attempt $Attempt -- running terraform apply..."

  $result = & $Terraform "-chdir=$TerraformDir" apply -auto-approve "-var=allow_amd_micro=true" "-var=amd_availability_domain_index=2" 2>&1 | Out-String

  $state = & $Terraform "-chdir=$TerraformDir" state list 2>&1 | Out-String
  $hasAmpere = $state -match "oci_core_instance\.this\["
  $hasAmd = $state -match "oci_core_instance\.amd\["

  if ($hasAmpere) {
    $ampIp = & $Terraform "-chdir=$TerraformDir" output -json instance_public_ip 2>&1 | ConvertFrom-Json
    Write-Host "Ampere A1 provisioned at $ampIp"
  }
  if ($hasAmd) {
    $amdIp = & $Terraform "-chdir=$TerraformDir" output -json amd_public_ip 2>&1 | ConvertFrom-Json
    Write-Host "AMD micro provisioned at $amdIp"
  }

  if ($hasAmpere -or $hasAmd) {
    Write-Host "SUCCESS! At least one instance provisioned."
    break
  }

  if ($result -match "Out of host capacity") {
    Write-Host "  -> Out of host capacity. Retrying in ${IntervalMinutes}m..."
  } else {
    Write-Host "  -> Unexpected error. Retrying in ${IntervalMinutes}m..."
    Write-Host $result
  }

  $sec = $IntervalMinutes * 60
  if ($sec -gt 2147483) { $sec = 2147483 }
  Start-Sleep -Seconds $sec
}
