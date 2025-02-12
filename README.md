# Git Flow 自動化發布腳本 / Git Flow Automated Release Script

這是一個基於 Git Flow 的自動化發布腳本，為了我的團隊所開發，用於簡化軟體發布流程。

This is an automated release script based on Git Flow, developed for my team to simplify the software release process.

## 目錄 / Table of Contents

| 中文                | English               |
|--------------------|------------------------|
| [功能特點](#功能特點) | [Features](#features) |
| [系統要求](#系統要求) | [System Requirements](#system-requirements) |
| [安裝步驟](#安裝步驟) | [Installation](#installation) |
| [配置說明](#配置說明) | [Configuration](#configuration) |
| [使用方法](#使用方法) | [Usage](#usage) |
| [版本號格式](#版本號格式) | [Version Number Format](#version-number-format) |
| [注意事項](#注意事項) | [Important Notes](#important-notes) |
| [疑難排解](#疑難排解) | [Troubleshooting](#troubleshooting) |
| [貢獻指南](#貢獻指南) | [Contributing](#contributing) |

## 功能特點

- 自動檢查並更新主要分支（master/main 和 development）
- 智能版本號管理，支持日期型版本號格式
- 自動生成 Release Notes（基於 commit 記錄）
- 支持手動編輯 Release Notes
- 完整的 Git Flow release 流程管理
- 安全的工作目錄狀態檢查
- 彩色輸出界面，提供清晰的執行狀態提示

## 系統要求

- Git
- Git Flow
- Bash 環境
- 建議使用 macOS 或 Linux 系統

## 安裝步驟

1. 確保已安裝 Git Flow：
   ```bash
   # macOS
   brew install git-flow

   # Linux (Ubuntu/Debian)
   apt-get install git-flow

   # Linux (CentOS/RHEL)
   yum install git-flow
   ```

2. 下載腳本到你的專案目錄

3. 為腳本添加執行權限：
   ```bash
   chmod +x auto_git_flow_release_zh.sh
   ```

## 配置說明

使用前請修改腳本開頭的配置區域：

```bash
# ===== 配置區域 - 使用前請修改以下變量 =====
# 版本號前綴，例如 "v1", "app", "release" 等
VERSION_PREFIX="your_prefix"

# 主要分支名稱配置
MAIN_BRANCH="master"        # 主分支名稱，如 "main" 或 "master"
DEV_BRANCH="development"    # 開發分支名稱，如 "develop" 或 "development"

# 遠端倉庫名稱
REMOTE_NAME="origin"

# Git Flow 配置檢查命令（可根據安裝方式調整）
GIT_FLOW_CHECK_CMD="git-flow"
```

## 使用方法

1. 在專案根目錄執行腳本：
   ```bash
   ./auto_git_flow_release_zh.sh
   ```

2. 按照提示進行操作：
   - 確認是否要暫存當前的修改
   - 確認版本號
   - 檢查並編輯 Release Notes
   - 確認發布流程

## 版本號格式

腳本使用以下格式的版本號：
```
[PREFIX].[YYYYMMDD].[XX]
```
- PREFIX: 在配置中定義的版本號前綴
- YYYYMMDD: 當前日期
- XX: 當天的發布序號（從 00 開始）

例如：`v1.20240211.00`

## 注意事項

1. 執行腳本前請確保：
   - 所有需要發布的更改已經合併到 development 分支
   - Git Flow 已正確初始化
   - 有足夠的權限推送到遠端倉庫

2. 腳本會自動檢查：
   - 工作目錄狀態
   - Git Flow 安裝狀態
   - 分支同步狀態

3. 安全提醒：
   - 建議在執行腳本前先備份重要數據
   - 確保了解當前的 Git 分支狀態
   - 小心處理自動生成的 Release Notes

## 疑難排解

如果遇到以下問題：

1. 權限錯誤：
   ```bash
   chmod +x auto_git_flow_release_zh.sh
   ```

2. Git Flow 未初始化：
   ```bash
   git flow init -d
   ```

3. 分支衝突：
   - 先手動解決衝突
   - 確保本地分支與遠端同步

## 貢獻指南

歡迎提交 Issue 和 Pull Request 來改進這個腳本。

---

## Features

- Automatic checking and updating of main branches (master/main and development)
- Smart version number management with date-based versioning format
- Automatic Release Notes generation (based on commit history)
- Support for manual Release Notes editing
- Complete Git Flow release process management
- Safe working directory status checks
- Colored output interface for clear execution status indication

## System Requirements

- Git
- Git Flow
- Bash environment
- Recommended for macOS or Linux systems

## Installation

1. Ensure Git Flow is installed:
   ```bash
   # macOS
   brew install git-flow

   # Linux (Ubuntu/Debian)
   apt-get install git-flow

   # Linux (CentOS/RHEL)
   yum install git-flow
   ```

2. Download the script to your project directory

3. Add execution permissions to the script:
   ```bash
   chmod +x auto_git_flow_release_en.sh
   ```

## Configuration

Modify the configuration section at the beginning of the script before use:

```bash
# ===== Configuration Section - Please modify the following variables before use =====
# Version number prefix, e.g., "v1", "app", "release"
VERSION_PREFIX="your_prefix"

# Main branch configuration
MAIN_BRANCH="master"        # Main branch name, e.g., "main" or "master"
DEV_BRANCH="development"    # Development branch name, e.g., "develop" or "development"

# Remote repository name
REMOTE_NAME="origin"
```

## Usage

1. Execute the script in your project root directory:
   ```bash
   ./auto_git_flow_release_en.sh
   ```

2. Follow the prompts:
   - Confirm whether to stash current changes
   - Confirm version number
   - Review and edit Release Notes
   - Confirm release process

## Version Number Format

The script uses the following version number format:
```
[PREFIX].[YYYYMMDD].[XX]
```
- PREFIX: Version number prefix defined in configuration
- YYYYMMDD: Current date
- XX: Release sequence number for the day (starting from 00)

Example: `v1.20240211.00`

## Important Notes

1. Before running the script, ensure:
   - All changes to be released are merged into the development branch
   - Git Flow is properly initialized
   - You have sufficient permissions to push to the remote repository

2. The script automatically checks:
   - Working directory status
   - Git Flow installation status
   - Branch synchronization status

3. Safety reminders:
   - Backup important data before running the script
   - Understand your current Git branch status
   - Handle automatically generated Release Notes with care

## Troubleshooting

If you encounter any of these issues:

1. Permission error:
   ```bash
   chmod +x auto_git_flow_release_en.sh
   ```

2. Git Flow not initialized:
   ```bash
   git flow init -d
   ```

3. Branch conflicts:
   - Manually resolve conflicts first
   - Ensure local branches are synchronized with remote

## Contributing

Issues and Pull Requests are welcome to improve this script. Please:
- Clearly describe your changes
- Follow the existing code style
- Update relevant documentation

## License

[Choose an appropriate license]
