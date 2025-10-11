#==============================================================================
# 脚本名称: rollback.ps1
# 脚本描述: 自动回滚到上一个稳定版本 (Windows PowerShell版本)
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

param(
    [string]$Target = "",
    [switch]$DryRun = $false,
    [switch]$Force = $false,
    [switch]$List = $false,
    [switch]$Help = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 脚本配置
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$LogFile = Join-Path $ProjectRoot "logs\rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

#==============================================================================
# 日志和输出函数
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
    
    # 确保日志目录存在
    $LogDir = Split-Path -Parent $LogFile
    if (!(Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
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
    param([string]$Command)
    
    if (!(Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-Error "命令 '$Command' 未找到，请先安装"
    }
}

function Confirm-Action {
    param([string]$Message)
    
    if ($Force) {
        Write-Info "强制模式：跳过确认"
        return $true
    }
    
    Write-Host $Message -ForegroundColor Yellow
    $Response = Read-Host "是否继续? (y/N)"
    
    if ($Response -match "^[Yy]$") {
        return $true
    } else {
        Write-Info "回滚操作已取消"
        exit 0
    }
}

function Get-CurrentVersion {
    try {
        $Images = docker ps --format "table {{.Image}}" | Select-String -Pattern "(frontend|api)" | Select-Object -First 1
        if ($Images) {
            $Version = ($Images.ToString() -split ':')[1]
            return $Version
        }
        return "unknown"
    } catch {
        return "unknown"
    }
}

function Get-AvailableVersions {
    Write-Info "获取可用的镜像版本..."
    
    try {
        $Versions = docker images --format "table {{.Tag}}" | 
                   Where-Object { $_ -notmatch "TAG|latest|<none>" } |
                   Sort-Object { [Version]$_ } -Descending |
                   Select-Object -First 10
        
        if (!$Versions) {
            Write-Warning "未找到可用的历史版本"
            return $null
        }
        
        return $Versions
    } catch {
        Write-Warning "获取版本列表失败: $($_.Exception.Message)"
        return $null
    }
}

function Select-RollbackTarget {
    if ($Target) {
        Write-Info "使用指定的回滚目标: $Target"
        return $Target
    }
    
    $CurrentVersion = Get-CurrentVersion
    Write-Info "当前版本: $CurrentVersion"
    
    $Versions = Get-AvailableVersions
    if (!$Versions) {
        Write-Error "没有可用的版本进行回滚"
    }
    
    Write-Host "可用的版本:" -ForegroundColor Blue
    for ($i = 0; $i -lt $Versions.Count; $i++) {
        Write-Host "$($i + 1)) $($Versions[$i])"
    }
    
    $Selection = Read-Host "请选择要回滚到的版本 (输入序号或版本号)"
    
    if ($Selection -match "^\d+$") {
        $Index = [int]$Selection - 1
        if ($Index -ge 0 -and $Index -lt $Versions.Count) {
            return $Versions[$Index]
        } else {
            Write-Error "无效的序号"
        }
    } else {
        return $Selection
    }
}

#==============================================================================
# 回滚功能函数
#==============================================================================

function Test-RollbackTarget {
    param([string]$Version)
    
    Write-Info "验证回滚目标版本: $Version"
    
    $Images = docker images --format "table {{.Tag}}" | Where-Object { $_ -eq $Version }
    if (!$Images) {
        Write-Error "目标版本 '$Version' 的镜像不存在"
    }
    
    Write-Success "回滚目标版本验证通过"
}

function Backup-CurrentState {
    Write-Info "备份当前部署状态..."
    
    $BackupDir = Join-Path $ProjectRoot "backups\rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    
    # 备份docker-compose配置
    $ComposeFile = Join-Path $ProjectRoot "docker-compose.yml"
    if (Test-Path $ComposeFile) {
        Copy-Item $ComposeFile $BackupDir
    }
    
    # 备份当前运行的容器信息
    docker ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}" | 
        Out-File -FilePath (Join-Path $BackupDir "running-containers.txt")
    
    # 备份环境变量
    $EnvFile = Join-Path $ProjectRoot ".env.production"
    if (Test-Path $EnvFile) {
        Copy-Item $EnvFile $BackupDir
    }
    
    Write-Success "当前状态已备份到: $BackupDir"
    $BackupDir | Out-File -FilePath (Join-Path $ProjectRoot ".last-backup")
}

function Stop-CurrentServices {
    Write-Info "停止当前运行的服务..."
    
    if ($DryRun) {
        Write-Info "[DRY RUN] 将执行: docker-compose down"
        return
    }
    
    Push-Location $ProjectRoot
    try {
        $RunningContainers = docker-compose ps -q
        if ($RunningContainers) {
            docker-compose down --timeout 30
            Write-Success "服务已停止"
        } else {
            Write-Info "没有运行中的服务"
        }
    } finally {
        Pop-Location
    }
}

function Update-ImageTags {
    param([string]$Version)
    
    Write-Info "更新镜像标签到版本: $Version"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] 将更新镜像标签到: $Version"
        return
    }
    
    $EnvFile = Join-Path $ProjectRoot ".env.production"
    if (Test-Path $EnvFile) {
        $Content = Get-Content $EnvFile
        $Content = $Content -replace "IMAGE_TAG=.*", "IMAGE_TAG=$Version"
        $Content | Set-Content $EnvFile
        Write-Success "已更新环境变量中的镜像版本"
    }
}

function Start-RollbackServices {
    param([string]$Version)
    
    Write-Info "启动回滚版本的服务..."
    
    if ($DryRun) {
        Write-Info "[DRY RUN] 将执行: docker-compose up -d"
        return
    }
    
    Push-Location $ProjectRoot
    try {
        $env:IMAGE_TAG = $Version
        docker-compose up -d
        Write-Success "回滚版本服务已启动"
    } finally {
        Pop-Location
    }
}

function Test-Rollback {
    Write-Info "验证回滚结果..."
    
    if ($DryRun) {
        Write-Info "[DRY RUN] 将执行健康检查"
        return $true
    }
    
    Write-Info "等待服务启动..."
    Start-Sleep -Seconds 10
    
    $HealthScript = Join-Path $ScriptDir "health-monitor.ps1"
    if (Test-Path $HealthScript) {
        try {
            & $HealthScript -Timeout 60
            Write-Success "回滚验证成功"
            return $true
        } catch {
            Write-Error "回滚验证失败"
            return $false
        }
    } else {
        Write-Warning "健康检查脚本不存在，跳过验证"
        return $true
    }
}

function Send-RollbackNotification {
    param(
        [string]$Status,
        [string]$CurrentVersion,
        [string]$TargetVersion
    )
    
    Write-Info "发送回滚通知..."
    
    $Message = if ($Status -eq "success") {
        "🔄 回滚成功: $CurrentVersion → $TargetVersion"
    } else {
        "❌ 回滚失败: $CurrentVersion → $TargetVersion"
    }
    
    $NotificationScript = Join-Path $ScriptDir "notification-system.ps1"
    if (Test-Path $NotificationScript) {
        & $NotificationScript -Type "rollback" -Status $Status -Message $Message -Version $TargetVersion
    }
}

#==============================================================================
# 主函数
#==============================================================================

function Show-Help {
    @"
用法: .\rollback.ps1 [选项]

选项:
    -Target VERSION     指定回滚目标版本
    -DryRun            试运行模式（不执行实际操作）
    -Force             强制回滚（跳过确认）
    -List              列出可用版本
    -Help              显示此帮助信息

示例:
    .\rollback.ps1                      # 交互式选择回滚版本
    .\rollback.ps1 -Target v1.2.0       # 回滚到指定版本
    .\rollback.ps1 -DryRun              # 试运行模式
    .\rollback.ps1 -List                # 列出可用版本

"@
}

function Show-Versions {
    Write-Info "可用的版本列表:"
    $Versions = Get-AvailableVersions
    if ($Versions) {
        $Versions | ForEach-Object { Write-Host $_ }
    }
    exit 0
}

function Main {
    if ($Help) {
        Show-Help
        exit 0
    }
    
    if ($List) {
        Show-Versions
    }
    
    Write-Info "开始执行自动回滚..."
    
    # 检查环境
    Test-Command "docker"
    Test-Command "docker-compose"
    
    # 获取当前版本
    $CurrentVersion = Get-CurrentVersion
    
    # 选择回滚目标
    $RollbackTarget = Select-RollbackTarget
    
    # 验证回滚目标
    Test-RollbackTarget $RollbackTarget
    
    # 确认回滚操作
    Confirm-Action "即将回滚到版本 $RollbackTarget，当前版本 $CurrentVersion 将被替换。"
    
    try {
        # 执行回滚步骤
        Backup-CurrentState
        Stop-CurrentServices
        Update-ImageTags $RollbackTarget
        Start-RollbackServices $RollbackTarget
        
        # 验证回滚结果
        if (Test-Rollback) {
            Write-Success "回滚操作完成！"
            Send-RollbackNotification "success" $CurrentVersion $RollbackTarget
            Write-Info "日志文件: $LogFile"
        } else {
            Write-Error "回滚验证失败"
            Send-RollbackNotification "failed" $CurrentVersion $RollbackTarget
        }
    } catch {
        Write-Error "回滚过程中发生错误: $($_.Exception.Message)"
        Send-RollbackNotification "failed" $CurrentVersion $RollbackTarget
    }
}

# 执行主函数
Main