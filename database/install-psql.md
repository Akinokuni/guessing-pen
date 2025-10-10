# 安装 PostgreSQL 客户端工具

## Windows 安装方法

### 方法1：使用 Chocolatey（推荐）
```powershell
choco install postgresql
```

### 方法2：使用 Scoop
```powershell
scoop install postgresql
```

### 方法3：手动下载
1. 访问：https://www.postgresql.org/download/windows/
2. 下载 PostgreSQL 安装包
3. 安装时只选择"Command Line Tools"组件即可

## 安装后执行初始化

```powershell
# 设置密码环境变量（避免交互式输入）
$env:PGPASSWORD="20138990398QGL@gmailcom"

# 执行初始化脚本
psql -h pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com -p 5432 -U aki -d postgres -f database/init_simple.sql
```

## 验证安装
```powershell
psql --version
```
