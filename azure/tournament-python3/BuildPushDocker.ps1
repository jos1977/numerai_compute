#Set Execution polict setting
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Push-Location $PSScriptRoot
Write-Host CurrentDirectory $CurDir

$image = Read-Host "Please enter the Docker Hub Image (example: user/name:latest)"

#Docker Build
docker build --pull --rm -f "Dockerfile" -t $image "."
docker push $image