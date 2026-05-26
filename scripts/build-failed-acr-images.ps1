$ErrorActionPreference = 'Stop'

$az = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd'
$registry = 'opslorapres944337'
$repoRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $repoRoot

$builds = @(
  @{ Image = 'opslora-frontend-service:latest'; Context = Join-Path $repoRoot 'opslora-frontend-service'; Dockerfile = 'Dockerfile.ec2' },
  @{ Image = 'pronunt-frontend-service:latest'; Context = Join-Path $repoRoot 'pronunt\pronunt-frontend-service'; Dockerfile = 'Dockerfile' },
  @{ Image = 'pronunt-config-service:latest'; Context = Join-Path $repoRoot 'pronunt\pronunt-config-service'; Dockerfile = 'Dockerfile' },
  @{ Image = 'pronunt-aggregator-service:latest'; Context = Join-Path $repoRoot 'pronunt\pronunt-aggregator-service'; Dockerfile = 'Dockerfile' },
  @{ Image = 'pronunt-worker-service:latest'; Context = Join-Path $repoRoot 'pronunt\pronunt-worker-service'; Dockerfile = 'Dockerfile' },
  @{ Image = 'pronunt-ingestion-service:latest'; Context = Join-Path $repoRoot 'pronunt\pronunt-ingestion-service'; Dockerfile = 'Dockerfile' },
  @{ Image = 'pronunt-ai-service:latest'; Context = Join-Path $repoRoot 'pronunt\pronunt-ai-service'; Dockerfile = 'Dockerfile' },
  @{ Image = 'pronunt-auth-service:latest'; Context = Join-Path $repoRoot 'pronunt\pronunt-auth-service'; Dockerfile = 'Dockerfile' }
)

$results = foreach ($build in $builds) {
  Write-Host "=== Building $($build.Image) ==="
  & $az acr build `
    --registry $registry `
    --image $build.Image `
    --file (Join-Path $build.Context $build.Dockerfile) `
    --no-logs `
    -o json `
    $build.Context

  [pscustomobject]@{
    Image = $build.Image
    Context = $build.Context
  }
}

$results | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $PSScriptRoot '..\acr-failed-build-retry.json')
