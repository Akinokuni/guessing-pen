#==============================================================================
# 脚本名称: failure-handler.ps1
# 脚本描述: 部署失败处理逻辑 (Windows PowerShell版本)
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$FailureType,
    
    [Parameter(Mandatory=$true)]
    [string]$Stage,
    
    [int]$ExitCode = 1,
    [string]$LogFile = "",
    [switch]$NoRollback = $false,
    [int]$MaxRetries = 3,
    [switch]$Help = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 脚本配置
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$FailureLogFile = Join-Path $ProjectRoot "logs\failure-handler-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# 全局变量
$script:ErrorMessage = ""
$script:RetryCount = 0

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
    $LogDir = Split-Path -Parent $FailureLogFile
    if (!(Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    
    Add-Content -Path $FailureLogFile -Value $LogMessage
}

function Write-Info { param([string]$Message) Write-Log $Message "INFO" }
function Write-Success { param([string]$Message) Write-Log $Message "SUCCESS" }
function Write-Warning { param([string]$Message) Write-Log $Message "WARNING" }
function Write-ErrorLog { param([string]$Message) Write-Log $Message "ERROR" }

#==============================================================================
# 失败检测函数
#==============================================================================

function Test-BuildFailure {
    param(
        [int]$ExitCode,
        [string]$BuildLog
    )
    
    if ($ExitCode -ne 0) {
        Write-ErrorLog "构建失败，退出码: $ExitCode"
        
        if ($BuildLog -and (Test-Path $BuildLog)) {
            Write-Info "分析构建日志..."
            $LogContent = Get-Content $BuildLog -Raw
            
            if ($LogContent -match "npm ERR!") {
                $script:ErrorMessage = "NPM依赖安装失败"
            } elseif ($LogContent -match "TypeScript error") {
                $script:ErrorMessage = "TypeScript编译错误"
            } elseif ($LogContent -match "ENOSPC") {
                $script:ErrorMessage = "磁盘空间不足"
            } elseif ($LogContent -match "ECONNRESET|ETIMEDOUT") {
                $script:ErrorMessage = "网络连接问题"
            } else {
                $script:ErrorMessage = "未知构建错误"
            }
        } else {
            $script:ErrorMessage = "构建失败，无法获取详细信息"
        }
        
        return $true
    }
    
    return $false
}

function Test-DeploymentFailure {
    param(
        [int]$ExitCode,
        [string]$DeployLog
    )
    
    if ($ExitCode -ne 0) {
        Write-ErrorLog "部署失败，退出码: $ExitCode"
        
        if ($DeployLog -and (Test-Path $DeployLog)) {
            Write-Info "分析部署日志..."
            $LogContent = Get-Content $DeployLog -Raw
            
            if ($LogContent -match "docker: Error response from daemon") {
                $script:ErrorMessage = "Docker守护进程错误"
            } elseif ($LogContent -match "pull access denied") {
                $script:ErrorMessage = "镜像拉取权限被拒绝"
            } elseif ($LogContent -match "network is unreachable") {
                $script:ErrorMessage = "网络不可达"
            } elseif ($LogContent -match "port is already allocated") {
                $script:ErrorMessage = "端口已被占用"
            } elseif ($LogContent -match "insufficient memory") {
                $script:ErrorMessage = "内存不足"
            } else {
                $script:ErrorMessage = "未知部署错误"
            }
        } else {
            $script:ErrorMessage = "部署失败，无法获取详细信息"
        }
        
        return $true
    }
    
    return $false
}

function Test-HealthFailure {
    param([string]$HealthStatus)
    
    if ($HealthStatus -ne "healthy") {
        Write-ErrorLog "健康检查失败，状态: $HealthStatus"
        
        switch ($HealthStatus) {
            "unhealthy" { $script:ErrorMessage = "服务健康检查失败" }
            "timeout" { $script:ErrorMessage = "健康检查超时" }
            "connection_refused" { $script:ErrorMessage = "服务连接被拒绝" }
            default { $script:ErrorMessage = "未知健康检查错误" }
        }
        
        return $true
    }
    
    return $false
}

#==============================================================================
# 失败处理策略
#==============================================================================

function Resolve-BuildFailure {
    Write-Info "处理构建失败..."
    
    switch -Wildcard ($script:ErrorMessage) {
        "*NPM依赖安装失败*" {
            Write-Info "尝试清理NPM缓存并重试..."
            npm cache clean --force
            if (Test-Path "node_modules") { Remove-Item -Recurse -Force "node_modules" }
            if (Test-Path "package-lock.json") { Remove-Item -Force "package-lock.json" }
            return $true
        }
        "*磁盘空间不足*" {
            Write-Info "清理Docker镜像和容器..."
            docker system prune -f
            docker image prune -a -f
            return $true
        }
        "*网络连接问题*" {
            Write-Info "等待网络恢复..."
            Start-Sleep -Seconds 30
            return $true
        }
        "*TypeScript编译错误*" {
            Write-ErrorLog "TypeScript编译错误需要手动修复"
            return $false
        }
        default {
            return $true
        }
    }
}

function Resolve-DeploymentFailure {
    Write-Info "处理部署失败..."
    
    switch -Wildcard ($script:ErrorMessage) {
        "*Docker守护进程错误*" {
            Write-Info "重启Docker服务..."
            try {
                Restart-Service docker -Force
                Start-Sleep -Seconds 10
                return $true
            } catch {
                Write-Warning "无法重启Docker服务: $($_.Exception.Message)"
                return $false
            }
        }
        "*镜像拉取权限被拒绝*" {
            Write-Info "重新登录镜像仓库..."
            if ($env:ACR_REGISTRY -and $env:ACR_USERNAME -and $env:ACR_PASSWORD) {
                docker login $env:ACR_REGISTRY -u $env:ACR_USERNAME -p $env:ACR_PASSWORD
                return $true
            } else {
                Write-Warning "缺少ACR登录凭据"
                return $false
            }
        }
        "*端口已被占用*" {
            Write-Info "停止占用端口的进程..."
            docker-compose down --remove-orphans
            return $true
        }
        "*内存不足*" {
            Write-Info "清理系统内存..."
            docker system prune -f
            [System.GC]::Collect()
            return $true
        }
        default {
            return $true
        }
    }
}

function Resolve-HealthFailure {
    Write-Info "处理健康检查失败..."
    
    switch -Wildcard ($script:ErrorMessage) {
        "*服务健康检查失败*" {
            Write-Info "检查服务日志..."
            docker-compose logs --tail=50
            return $true
        }
        "*健康检查超时*" {
            Write-Info "延长等待时间..."
            Start-Sleep -Seconds 60
            return $true
        }
        "*服务连接被拒绝*" {
            Write-Info "检查服务端口和网络配置..."
            docker-compose ps
            return $true
        }
        default {
            return $true
        }
    }
}

#==============================================================================
# 重试机制
#==============================================================================

function Invoke-Retry {
    param(
        [scriptblock]$Command,
        [int]$MaxRetries,
        [int]$RetryDelay = 30
    )
    
    $attempt = 1
    
    while ($attempt -le $MaxRetries) {
        Write-Info "执行重试 $attempt/$MaxRetries"
        
        try {
            $result = & $Command
            Write-Success "重试成功"
            return $true
        } catch {
            Write-Warning "重试 $attempt 失败: $($_.Exception.Message)"
            
            if ($attempt -lt $MaxRetries) {
                Write-Info "等待 $RetryDelay 秒后重试..."
                Start-Sleep -Seconds $RetryDelay
            }
            
            $attempt++
        }
    }
    
    Write-ErrorLog "所有重试都失败了"
    return $false
}

function Invoke-SmartRetry {
    param([string]$FailureType)
    
    $resolved = $false
    
    switch ($FailureType) {
        "build" {
            $resolved = Resolve-BuildFailure
            if ($resolved) {
                return Invoke-Retry { npm run build } 2 60
            }
        }
        "deployment" {
            $resolved = Resolve-DeploymentFailure
            if ($resolved) {
                return Invoke-Retry { docker-compose up -d } 3 30
            }
        }
        "health" {
            $resolved = Resolve-HealthFailure
            if ($resolved) {
                $HealthScript = Join-Path $ScriptDir "health-monitor.ps1"
                if (Test-Path $HealthScript) {
                    return Invoke-Retry { & $HealthScript } 3 60
                }
            }
        }
        default {
            Write-ErrorLog "未知的失败类型: $FailureType"
            return $false
        }
    }
    
    return $false
}

#==============================================================================
# 自动回滚
#==============================================================================

function Invoke-AutoRollback {
    Write-Info "执行自动回滚..."
    
    if ($NoRollback) {
        Write-Info "自动回滚已禁用"
        return $false
    }
    
    $RollbackScript = Join-Path $ScriptDir "rollback.ps1"
    if (!(Test-Path $RollbackScript)) {
        Write-ErrorLog "回滚脚本不存在: $RollbackScript"
        return $false
    }
    
    Write-Info "开始自动回滚到上一个稳定版本..."
    try {
        & $RollbackScript -Force
        Write-Success "自动回滚成功"
        return $true
    } catch {
        Write-ErrorLog "自动回滚失败: $($_.Exception.Message)"
        return $false
    }
}

#==============================================================================
# 通知和报告
#==============================================================================

function Send-FailureNotification {
    param(
        [string]$FailureType,
        [string]$Stage,
        [string]$ErrorMsg,
        [bool]$RetryAttempted,
        [bool]$RollbackAttempted
    )
    
    Write-Info "发送失败通知..."
    
    $Message = @"
❌ 部署失败
阶段: $Stage
类型: $FailureType
错误: $ErrorMsg
重试: $RetryAttempted
回滚: $RollbackAttempted
时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    $NotificationScript = Join-Path $ScriptDir "notification-system.ps1"
    if (Test-Path $NotificationScript) {
        & $NotificationScript -Type "deployment_failure" -Status "failed" -Message $Message -Stage $Stage -Error $ErrorMsg
    }
}

function New-FailureReport {
    $ReportFile = Join-Path $ProjectRoot "logs\failure-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    
    Write-Info "生成失败报告: $ReportFile"
    
    $Report = @{
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        failure_type = $FailureType
        failure_stage = $Stage
        error_message = $script:ErrorMessage
        retry_count = $script:RetryCount
        max_retries = $MaxRetries
        auto_rollback = !$NoRollback
        log_file = $FailureLogFile
        environment = @{
            hostname = $env:COMPUTERNAME
            user = $env:USERNAME
            pwd = (Get-Location).Path
            docker_version = try { docker --version } catch { "N/A" }
            compose_version = try { docker-compose --version } catch { "N/A" }
        }
    }
    
    $Report | ConvertTo-Json -Depth 3 | Set-Content $ReportFile
    Write-Success "失败报告已生成: $ReportFile"
}

#==============================================================================
# 主函数
#==============================================================================

function Show-Help {
    @"
用法: .\failure-handler.ps1 -FailureType <type> -Stage <stage> [选项]

参数:
    -FailureType    失败类型 (build|deployment|health)
    -Stage          失败阶段描述
    -ExitCode       退出码 (可选，默认为1)
    -LogFile        相关日志文件 (可选)

选项:
    -NoRollback     禁用自动回滚
    -MaxRetries     设置最大重试次数 (默认3)
    -Help           显示此帮助信息

示例:
    .\failure-handler.ps1 -FailureType build -Stage "npm install" -ExitCode 1 -LogFile "C:\path\to\build.log"
    .\failure-handler.ps1 -FailureType deployment -Stage "docker-compose up" -ExitCode 1
    .\failure-handler.ps1 -FailureType health -Stage "unhealthy"

"@
}

function Main {
    if ($Help) {
        Show-Help
        exit 0
    }
    
    Write-Info "开始处理部署失败..."
    
    # 检测具体失败原因
    switch ($FailureType) {
        "build" {
            $null = Test-BuildFailure $ExitCode $LogFile
        }
        "deployment" {
            $null = Test-DeploymentFailure $ExitCode $LogFile
        }
        "health" {
            $null = Test-HealthFailure $Stage
        }
        default {
            $script:ErrorMessage = "未知失败类型: $FailureType"
        }
    }
    
    Write-ErrorLog "检测到失败: $($script:ErrorMessage)"
    
    # 尝试智能重试
    $RetryAttempted = $false
    if (Invoke-SmartRetry $FailureType) {
        Write-Success "重试成功，问题已解决"
        $RetryAttempted = $true
        return
    } else {
        Write-Warning "重试失败，准备执行回滚"
        $RetryAttempted = $true
    }
    
    # 执行自动回滚
    $RollbackAttempted = $false
    if (Invoke-AutoRollback) {
        Write-Success "自动回滚成功"
        $RollbackAttempted = $true
    } else {
        Write-ErrorLog "自动回滚失败"
        $RollbackAttempted = $true
    }
    
    # 发送通知和生成报告
    Send-FailureNotification $FailureType $Stage $script:ErrorMessage $RetryAttempted $RollbackAttempted
    New-FailureReport
    
    Write-ErrorLog "部署失败处理完成，请检查日志: $FailureLogFile"
    exit 1
}

# 执行主函数
Main