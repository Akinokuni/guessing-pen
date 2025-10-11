# PowerShell版本的敏感信息管理脚本
# 脚本名称: secrets-manager.ps1
# 脚本描述: 敏感信息管理和加密存储工具 (Windows版本)
# 作者: DevOps团队
# 创建日期: 2025-10-11
# 版本: 1.0.0

param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$EnvFile,
    
    [Parameter(Position=2)]
    [string]$Environment = "production",
    
    [switch]$Help
)

# 脚本配置
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$SecretsDir = Join-Path $ProjectRoot ".secrets"
$LogFile = Join-Path $ProjectRoot "logs\secrets-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# 创建日志目录
$LogDir = Split-Path -Parent $LogFile
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

#==============================================================================
# 日志函数
#==============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Level] $Timestamp - $Message"
    
    switch ($Level) {
        "INFO" { Write-Host $LogMessage -ForegroundColor Blue }
        "SUCCESS" { Write-Host $LogMessage -ForegroundColor Green }
        "WARNING" { Write-Host $LogMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
    }
    
    Add-Content -Path $LogFile -Value $LogMessage
}

function Write-Info { param([string]$Message) Write-Log $Message "INFO" }
function Write-Success { param([string]$Message) Write-Log $Message "SUCCESS" }
function Write-Warning { param([string]$Message) Write-Log $Message "WARNING" }
function Write-Error { param([string]$Message) Write-Log $Message "ERROR"; exit 1 }

#==============================================================================
# 工具函数
#==============================================================================

function Test-Command {
    param([string]$CommandName)
    
    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        Write-Error "命令 '$CommandName' 未找到，请先安装"
    }
}

function Test-FileExists {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "文件 '$FilePath' 不存在"
    }
}

function New-EncryptionKey {
    param([string]$KeyFile)
    
    if (-not (Test-Path $KeyFile)) {
        Write-Info "生成新的加密密钥..."
        
        # 生成32字节随机密钥并转换为Base64
        $Key = New-Object byte[] 32
        [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
        $Base64Key = [Convert]::ToBase64String($Key)
        
        Set-Content -Path $KeyFile -Value $Base64Key
        Write-Success "加密密钥已生成: $KeyFile"
    } else {
        Write-Info "使用现有加密密钥: $KeyFile"
    }
}

#==============================================================================
# 加密解密函数
#==============================================================================

function Protect-File {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$KeyFile
    )
    
    Test-FileExists $InputFile
    Test-FileExists $KeyFile
    
    Write-Info "加密文件: $InputFile"
    
    try {
        # 读取密钥和文件内容
        $Key = Get-Content $KeyFile
        $Content = Get-Content $InputFile -Raw
        
        # 使用AES加密
        $SecureString = ConvertTo-SecureString -String $Content -AsPlainText -Force
        $EncryptedString = ConvertFrom-SecureString -SecureString $SecureString -Key ([Convert]::FromBase64String($Key))
        
        # 保存加密内容
        Set-Content -Path $OutputFile -Value $EncryptedString
        
        Write-Success "文件加密成功: $OutputFile"
        
        # 删除原始文件
        Remove-Item $InputFile -Force
        Write-Info "原始文件已删除: $InputFile"
        
    } catch {
        Write-Error "文件加密失败: $($_.Exception.Message)"
    }
}

function Unprotect-File {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$KeyFile
    )
    
    Test-FileExists $InputFile
    Test-FileExists $KeyFile
    
    Write-Info "解密文件: $InputFile"
    
    try {
        # 读取密钥和加密内容
        $Key = Get-Content $KeyFile
        $EncryptedString = Get-Content $InputFile -Raw
        
        # 解密
        $SecureString = ConvertTo-SecureString -String $EncryptedString -Key ([Convert]::FromBase64String($Key))
        $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString))
        
        # 保存解密内容
        Set-Content -Path $OutputFile -Value $PlainText
        
        Write-Success "文件解密成功: $OutputFile"
        
    } catch {
        Write-Error "文件解密失败: $($_.Exception.Message)"
    }
}

#==============================================================================
# 环境变量管理
#==============================================================================

function Protect-EnvFile {
    param(
        [string]$EnvFile,
        [string]$Environment = "production"
    )
    
    Test-FileExists $EnvFile
    
    # 创建secrets目录
    if (-not (Test-Path $SecretsDir)) {
        New-Item -ItemType Directory -Path $SecretsDir -Force | Out-Null
    }
    
    # 生成或使用现有密钥
    $KeyFile = Join-Path $SecretsDir "$Environment.key"
    New-EncryptionKey $KeyFile
    
    # 加密环境文件
    $EncryptedFile = Join-Path $SecretsDir "$Environment.env.enc"
    Protect-File $EnvFile $EncryptedFile $KeyFile
    
    Write-Success "环境文件已加密存储"
}

function Unprotect-EnvFile {
    param(
        [string]$Environment = "production",
        [string]$OutputFile = ".env.$Environment"
    )
    
    $KeyFile = Join-Path $SecretsDir "$Environment.key"
    $EncryptedFile = Join-Path $SecretsDir "$Environment.env.enc"
    
    Test-FileExists $KeyFile
    Test-FileExists $EncryptedFile
    
    Unprotect-File $EncryptedFile $OutputFile $KeyFile
    
    Write-Success "环境文件已解密: $OutputFile"
}

#==============================================================================
# GitHub Secrets管理
#==============================================================================

function Test-GitHubSecrets {
    param([string]$EnvFile)
    
    Test-FileExists $EnvFile
    
    Write-Info "验证GitHub Secrets配置..."
    
    # 必需的secrets列表
    $RequiredSecrets = @(
        "ACR_REGISTRY",
        "ACR_NAMESPACE", 
        "ACR_USERNAME",
        "ACR_PASSWORD",
        "SERVER_HOST",
        "SERVER_USER",
        "SERVER_SSH_KEY",
        "DB_HOST",
        "DB_USER",
        "DB_PASSWORD",
        "DB_NAME"
    )
    
    $Content = Get-Content $EnvFile
    $MissingSecrets = @()
    
    # 检查每个必需的secret
    foreach ($Secret in $RequiredSecrets) {
        if (-not ($Content | Where-Object { $_ -match "^$Secret=" })) {
            $MissingSecrets += $Secret
        }
    }
    
    if ($MissingSecrets.Count -gt 0) {
        Write-Error "缺少以下必需的secrets: $($MissingSecrets -join ', ')"
    } else {
        Write-Success "所有必需的secrets都已配置"
    }
}

function New-GitHubSecretsScript {
    param(
        [string]$EnvFile,
        [string]$OutputScript = "github-secrets-setup.ps1"
    )
    
    Test-FileExists $EnvFile
    
    Write-Info "生成GitHub Secrets设置脚本..."
    
    $ScriptContent = @"
# GitHub Secrets 自动设置脚本 (PowerShell版本)
# 使用 GitHub CLI 批量设置 secrets

# 检查 GitHub CLI 是否已安装
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "错误: GitHub CLI 未安装，请先安装 gh 命令"
    exit 1
}

# 检查是否已登录
try {
    gh auth status | Out-Null
} catch {
    Write-Error "错误: 请先使用 'gh auth login' 登录 GitHub"
    exit 1
}

Write-Host "开始设置 GitHub Secrets..."

"@
    
    # 读取环境文件并生成设置命令
    $Content = Get-Content $EnvFile
    foreach ($Line in $Content) {
        # 跳过注释和空行
        if ($Line -match "^\s*#" -or $Line -match "^\s*$") {
            continue
        }
        
        if ($Line -match "^([^=]+)=(.*)$") {
            $Key = $Matches[1]
            $Value = $Matches[2] -replace '^["'']|["'']$', ''  # 移除引号
            
            $ScriptContent += "`ngh secret set $Key --body `"$Value`""
        }
    }
    
    $ScriptContent += "`n`nWrite-Host `"GitHub Secrets 设置完成!`""
    
    Set-Content -Path $OutputScript -Value $ScriptContent
    
    Write-Success "GitHub Secrets设置脚本已生成: $OutputScript"
}

#==============================================================================
# 安全检查函数
#==============================================================================

function Invoke-SecurityAudit {
    Write-Info "执行安全审计..."
    
    $Issues = 0
    
    # 检查是否有明文密码文件
    Write-Info "检查明文密码文件..."
    $EnvFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.env" -Recurse | Where-Object { 
        $_.FullName -notmatch "node_modules" -and $_.Name -notmatch "\.template$" 
    }
    
    if ($EnvFiles) {
        Write-Warning "发现明文环境文件，建议加密存储"
        $Issues++
    }
    
    # 检查Git忽略配置
    Write-Info "检查Git忽略配置..."
    $GitIgnoreFile = Join-Path $ProjectRoot ".gitignore"
    if (Test-Path $GitIgnoreFile) {
        $GitIgnoreContent = Get-Content $GitIgnoreFile -Raw
        
        if ($GitIgnoreContent -notmatch "\.env$") {
            Write-Warning ".gitignore 中缺少 .env 文件忽略规则"
            $Issues++
        }
        
        if ($GitIgnoreContent -notmatch "\.secrets/") {
            Write-Warning ".gitignore 中缺少 .secrets/ 目录忽略规则"
            $Issues++
        }
    }
    
    if ($Issues -eq 0) {
        Write-Success "安全审计通过，未发现问题"
    } else {
        Write-Warning "安全审计发现 $Issues 个问题，请及时处理"
    }
}

#==============================================================================
# 主函数
#==============================================================================

function Show-Help {
    Write-Host @"
用法: .\secrets-manager.ps1 [命令] [选项]

命令:
    encrypt <env_file> [environment]     加密环境文件
    decrypt <environment> [output_file]  解密环境文件
    validate <env_file>                  验证GitHub Secrets配置
    generate-script <env_file> [output]  生成GitHub Secrets设置脚本
    audit                                执行安全审计
    
选项:
    -Help           显示此帮助信息

示例:
    .\secrets-manager.ps1 encrypt .env.production production
    .\secrets-manager.ps1 decrypt production .env.production
    .\secrets-manager.ps1 validate .env.production
    .\secrets-manager.ps1 generate-script .env.production
    .\secrets-manager.ps1 audit

"@
}

# 主逻辑
if ($Help) {
    Show-Help
    exit 0
}

switch ($Command) {
    "encrypt" {
        if (-not $EnvFile) {
            Write-Error "encrypt 命令需要环境文件参数"
        }
        Protect-EnvFile $EnvFile $Environment
    }
    "decrypt" {
        if (-not $EnvFile) {
            Write-Error "decrypt 命令需要环境名称参数"
        }
        $OutputFile = if ($Environment -ne "production") { $Environment } else { ".env.$EnvFile" }
        Unprotect-EnvFile $EnvFile $OutputFile
    }
    "validate" {
        if (-not $EnvFile) {
            Write-Error "validate 命令需要环境文件参数"
        }
        Test-GitHubSecrets $EnvFile
    }
    "generate-script" {
        if (-not $EnvFile) {
            Write-Error "generate-script 命令需要环境文件参数"
        }
        $OutputScript = if ($Environment -ne "production") { $Environment } else { "github-secrets-setup.ps1" }
        New-GitHubSecretsScript $EnvFile $OutputScript
    }
    "audit" {
        Invoke-SecurityAudit
    }
    default {
        if ($Command) {
            Write-Error "未知命令: $Command，使用 -Help 查看帮助"
        } else {
            Show-Help
        }
    }
}