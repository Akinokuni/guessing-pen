#!/usr/bin/env pwsh

<#
.SYNOPSIS
    生成SSH密钥对用于GitHub Actions部署
.DESCRIPTION
    为自动部署生成ED25519 SSH密钥对
#>

$ErrorActionPreference = "Stop"

Write-Host "🔑 生成SSH密钥对..." -ForegroundColor Cyan

# 密钥文件路径
$keyFile = "guessing-pen-deploy-key"
$privateKeyFile = $keyFile
$publicKeyFile = "$keyFile.pub"

# 删除已存在的密钥
if (Test-Path $privateKeyFile) {
    Remove-Item $privateKeyFile -Force
    Write-Host "已删除旧的私钥文件" -ForegroundColor Yellow
}
if (Test-Path $publicKeyFile) {
    Remove-Item $publicKeyFile -Force
    Write-Host "已删除旧的公钥文件" -ForegroundColor Yellow
}

# 生成密钥（交互式，需要按Enter跳过密码）
Write-Host "`n请按3次Enter键（不设置密码）：" -ForegroundColor Yellow
& ssh-keygen -t ed25519 -C "github-actions@guessing-pen" -f $keyFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ SSH密钥生成失败" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ SSH密钥生成成功！" -ForegroundColor Green

# 读取密钥内容
$privateKey = Get-Content $privateKeyFile -Raw
$publicKey = Get-Content $publicKeyFile -Raw

Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "📋 私钥内容（用于GitHub Secret: SERVER_SSH_KEY）" -ForegroundColor Cyan
Write-Host "="*80 -ForegroundColor Cyan
Write-Host $privateKey -ForegroundColor White

Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "📋 公钥内容（需要添加到服务器 ~/.ssh/authorized_keys）" -ForegroundColor Cyan
Write-Host "="*80 -ForegroundColor Cyan
Write-Host $publicKey -ForegroundColor White

Write-Host "`n📝 下一步操作：" -ForegroundColor Yellow
Write-Host "1. 复制上面的私钥内容" -ForegroundColor White
Write-Host "2. 在GitHub仓库设置中添加Secret: SERVER_SSH_KEY" -ForegroundColor White
Write-Host "3. 登录服务器 47.115.146.78" -ForegroundColor White
Write-Host "4. 运行以下命令添加公钥：" -ForegroundColor White
Write-Host "   mkdir -p ~/.ssh" -ForegroundColor Gray
Write-Host "   echo '$publicKey' >> ~/.ssh/authorized_keys" -ForegroundColor Gray
Write-Host "   chmod 600 ~/.ssh/authorized_keys" -ForegroundColor Gray
Write-Host "   chmod 700 ~/.ssh" -ForegroundColor Gray

Write-Host "`n💾 密钥文件已保存到当前目录：" -ForegroundColor Yellow
Write-Host "   私钥: $privateKeyFile" -ForegroundColor White
Write-Host "   公钥: $publicKeyFile" -ForegroundColor White
Write-Host "`n⚠️  请妥善保管私钥，不要提交到Git仓库！" -ForegroundColor Red
