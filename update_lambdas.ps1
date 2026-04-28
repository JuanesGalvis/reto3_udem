$STAGE = "dev"
$REGION = "us-east-1"
$BUCKET = "reto3-dev-lambda-code-097669200415"
$lambdas = @("auth-signup","buyer-reserve-seat","buyer-cancel-reservation","buyer-confirm-attendance","buyer-edit-reservation")

New-Item -ItemType Directory -Force -Path zips | Out-Null

foreach ($func in $lambdas) {
    Write-Host "--- Procesando: $func ---"
    $src = "codes/$func/*"
    $dst = "zips/$func.zip"
    if (Test-Path $dst) { Remove-Item $dst }
    Compress-Archive -Path $src -DestinationPath $dst
    aws s3 cp $dst "s3://$BUCKET/lambdas/$func.zip" --region $REGION
    aws lambda update-function-code --function-name "reto3-$STAGE-$func" --s3-bucket $BUCKET --s3-key "lambdas/$func.zip" --region $REGION --no-cli-pager
    Write-Host "OK: $func actualizada"
}
