Import-Module AWS.Tools.S3

$region = "ap-south-1"

$bucketName = Read-Host -Prompt 'Enter the S3 bucket name '

function BucketExists{
    $bucket = Get-S3bucket -BucketName $bucketName -ErrorAction SilentlyContinue
    return $null -ne $bucket
}

if (-not (BucketExists))
{
    Write-Host "Bucket does Exist.... "
    New-S3Bucket -BucketName $bucketName -Region $region
}else {
    Write-Host "Bucket already Exist.... "
} 


$fileName = 'myronfile.txt'
$fileContent = 'Hello world '
Set-Content  -Path $fileName -Value $fileContent

Write-S3Object -BucketName $bucketName -File $fileName -Key fileName 
