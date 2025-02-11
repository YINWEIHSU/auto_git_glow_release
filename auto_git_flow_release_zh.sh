#!/bin/bash

# ===== 配置區域 - 使用前請修改以下變量 =====
VERSION_PREFIX="your_prefix"

# 主要分支名稱配置
MAIN_BRANCH="master"        # 主分支名稱，如 "main" 或 "master"
DEV_BRANCH="development"    # 開發分支名稱，如 "develop" 或 "development"

# 遠端倉庫名稱
REMOTE_NAME="origin"
# ============================================

# 設置顏色代碼
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 錯誤處理函數
handle_error() {
    echo -e "${RED}❌ 錯誤：$1${NC}"
    exit 1
}

# 成功提示函數
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 警告提示函數
show_warning() {
    echo -e "${YELLOW}❗  $1${NC}"
}

# 訊息提示函數
show_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 檢查分支狀態的函數
check_branch_status() {
    local branch=$1
    local remote="$REMOTE_NAME/$branch"
    
    # 確保遠端分支訊息是最新的
    git fetch $REMOTE_NAME $branch

    # 獲取本地分支與遠端分支的差異訊息
    local ahead=$(git rev-list $remote..$branch --count)
    local behind=$(git rev-list $branch..$remote --count)
    
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        show_warning "分支 $branch 既有領先又有落後於遠端的提交"
        show_info "領先 $ahead 個提交，落後 $behind 個提交"
        handle_error "請先同步分支狀態（可能需要 rebase 或 merge）"
    elif [ "$ahead" -gt 0 ]; then
        show_warning "分支 $branch 領先遠端 $ahead 個提交"
        handle_error "請先確認分支狀態"
    elif [ "$behind" -gt 0 ]; then
        show_info "分支 $branch 落後遠端 $behind 個提交，準備更新..."
        return 0
    else
        show_success "分支 $branch 已經是最新的"
        return 0
    fi
}

# 初始化 stash 標記
stash_changes=false

# 確保錯誤時停止執行
set -e

# 檢查必要條件
echo -e "\n${BLUE}=== 檢查環境配置 ===${NC}"

# 檢查 git-flow 安裝
if ! command -v git-flow &> /dev/null; then
    handle_error "未安裝 git-flow，請先執行：brew install git-flow 或相應的安裝命令"
fi
show_success "git-flow 已安裝"

# 檢查 git 倉庫狀態
show_info "檢查工作目錄狀態..."
tracked_changes=$(git diff --name-status HEAD || true)

if [ -n "$tracked_changes" ]; then
    show_warning "發現已追蹤文件的變更："
    echo -e "${YELLOW}$tracked_changes${NC}"
    read -p "$(echo -e ${YELLOW}"是否要暫存(stash)這些變更？[y/N] "${NC})" response
    if [[ $response =~ ^[Yy]$ ]]; then
        git stash
        stash_changes=true
        show_success "變更已暫存"
    else
        handle_error "請先提交或暫存變更"
    fi
else
    show_success "工作目錄乾淨，沒有已追蹤文件的變更，即將開始更新分支"
fi

# 更新分支
echo -e "\n${BLUE}=== 更新分支 ===${NC}"

# 更新開發分支
show_info "檢查 $DEV_BRANCH 分支狀態..."
git checkout $DEV_BRANCH || handle_error "無法切換到 $DEV_BRANCH 分支"
check_branch_status "$DEV_BRANCH"
git pull || handle_error "無法更新 $DEV_BRANCH 分支"
show_success "$DEV_BRANCH 分支已更新"

# 更新主分支
show_info "檢查 $MAIN_BRANCH 分支狀態..."
git checkout $MAIN_BRANCH || handle_error "無法切換到 $MAIN_BRANCH 分支"
check_branch_status "$MAIN_BRANCH"
git pull || handle_error "無法更新 $MAIN_BRANCH 分支"
show_success "$MAIN_BRANCH 分支已更新"

# 版本號處理
echo -e "\n${BLUE}=== 版本號管理 ===${NC}"
today=$(date +%Y%m%d)

# 獲取最新版本號
latest_version=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "")

if [ -z "$latest_version" ]; then
    new_version="${VERSION_PREFIX}.${today}.00"
    show_info "首次發布，初始版本號：$new_version"
else
    show_info "當前最新版本：$latest_version"
    
    # 解析版本號
    latest_date=$(echo $latest_version | cut -d'.' -f2)
    latest_seq=$(echo $latest_version | cut -d'.' -f3)
    
    # 版本號邏輯處理
    if [ "$latest_date" == "$today" ]; then
        seq_num=$((10#$latest_seq + 1))
        new_seq=$(printf "%02d" $seq_num)
        new_version="${VERSION_PREFIX}.${today}.${new_seq}"
        show_info "同一天發布，序號遞增"
    elif [ "$latest_date" -lt "$today" ]; then
        new_version="${VERSION_PREFIX}.${today}.00"
        show_info "新的一天，序號重置"
    else
        handle_error "版本號日期異常：最新版本日期($latest_date)比今天($today)還新"
    fi
fi

# 確認版本號
echo -e "\n${BLUE}=== 版本確認 ===${NC}"
show_info "預計發布版本：$new_version"
read -p "$(echo -e ${YELLOW}"確認使用此版本號？[Y/n] "${NC})" confirm_version
if [[ ! $confirm_version =~ ^[Yy]$ ]] && [[ ! -z $confirm_version ]]; then
    read -p "請輸入新的版本號(格式：${VERSION_PREFIX}.YYYYMMDD.XX): " new_version
    show_info "使用自定義版本號：$new_version"
fi

# 準備 Release Notes
echo -e "\n${BLUE}=== 準備 Release Notes ===${NC}"
temp_note_file=$(mktemp)
echo "$new_version" > "$temp_note_file"
echo "" >> "$temp_note_file"
git log --oneline --format="%s" $MAIN_BRANCH..$DEV_BRANCH >> "$temp_note_file"

# 編輯 Release Notes
while true; do
    show_info "當前 Release Notes 內容："
    echo -e "${YELLOW}------------------------${NC}"
    cat "$temp_note_file"
    echo -e "${YELLOW}------------------------${NC}"
    
    read -p "$(echo -e ${YELLOW}"確認 Release Notes 內容正確？[Y/n] "${NC})" confirm_note
    if [[ $confirm_note =~ ^[Yy]$ ]] || [[ -z $confirm_note ]]; then
        break
    else
        show_info "請編輯 Release Notes..."
        ${EDITOR:-vim} "$temp_note_file"
    fi
done

# 執行發布流程
echo -e "\n${BLUE}=== 執行發布流程 ===${NC}"
show_info "開始 release 分支：$new_version"
git flow release start $new_version || handle_error "無法創建 release 分支"

# 設置自動合併訊息
export GIT_MERGE_AUTOEDIT=no
note_content=$(cat "$temp_note_file")

show_info "完成 release 流程..."
git flow release finish $new_version -f "$temp_note_file" || handle_error "release 完成失敗"

# 清理
rm "$temp_note_file"
git checkout $MAIN_BRANCH || handle_error "無法切換到 $MAIN_BRANCH 分支"

# 推送更新
echo -e "\n${BLUE}=== 推送更新 ===${NC}"
show_info "推送 $MAIN_BRANCH 分支和標籤..."
git push && git push --tags || handle_error "推送失敗"

show_success "發布流程完成！版本：$new_version"
echo -e "\n${GREEN}🎉 自動化發布流程已完成${NC}\n"

# 恢復暫存的變更
if [ "$stash_changes" = true ]; then
    show_info "恢復暫存的變更..."
    git stash pop && show_success "變更已恢復" || handle_error "恢復暫存變更失敗"
fi

exit 0
