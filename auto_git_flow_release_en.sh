#!/bin/bash

# ===== Configuration Section - Please modify the following variables before use =====
# Version number prefix, e.g., "v1", "app", "release"
VERSION_PREFIX="your_prefix"

# Main branch configuration
MAIN_BRANCH="master"        # Main branch name, e.g., "main" or "master"
DEV_BRANCH="development"    # Development branch name, e.g., "develop" or "development"

# Remote repository name
REMOTE_NAME="origin"
# ============================================

# Color code settings
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handling function
handle_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

# Success message function
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message function
show_warning() {
    echo -e "${YELLOW}❗ $1${NC}"
}

# Information message function
show_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check branch status
check_branch_status() {
    local branch=$1
    local remote="$REMOTE_NAME/$branch"
    
    # Ensure remote branch information is up to date
    git fetch $REMOTE_NAME $branch

    # Get difference information between local and remote branches
    local ahead=$(git rev-list $remote..$branch --count)
    local behind=$(git rev-list $branch..$remote --count)
    
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        show_warning "Branch $branch has both ahead and behind commits from remote"
        show_info "$ahead commits ahead, $behind commits behind"
        handle_error "Please synchronize branch status first (may need rebase or merge)"
    elif [ "$ahead" -gt 0 ]; then
        show_warning "Branch $branch is $ahead commits ahead of remote"
        handle_error "Please verify branch status first"
    elif [ "$behind" -gt 0 ]; then
        show_info "Branch $branch is $behind commits behind remote, preparing to update..."
        return 0
    else
        show_success "Branch $branch is up to date"
        return 0
    fi
}

# Initialize stash flag
stash_changes=false

# Ensure script stops on error
set -e

# Check prerequisites
echo -e "\n${BLUE}=== Checking Environment Configuration ===${NC}"

# Check git-flow installation
if ! command -v git-flow &> /dev/null; then
    handle_error "git-flow not installed. Please run: brew install git-flow or corresponding installation command"
fi
show_success "git-flow is installed"

# Check git repository status
show_info "Checking working directory status..."
tracked_changes=$(git diff --name-status HEAD || true)

if [ -n "$tracked_changes" ]; then
    show_warning "Found changes in tracked files:"
    echo -e "${YELLOW}$tracked_changes${NC}"
    read -p "$(echo -e ${YELLOW}"Do you want to stash these changes? [y/N] "${NC})" response
    if [[ $response =~ ^[Yy]$ ]]; then
        git stash
        stash_changes=true
        show_success "Changes have been stashed"
    else
        handle_error "Please commit or stash changes first"
    fi
else
    show_success "Working directory is clean, no tracked file changes, proceeding with branch updates"
fi

# Update branches
echo -e "\n${BLUE}=== Updating Branches ===${NC}"

# Update development branch
show_info "Checking $DEV_BRANCH branch status..."
git checkout $DEV_BRANCH || handle_error "Unable to switch to $DEV_BRANCH branch"
check_branch_status "$DEV_BRANCH"
git pull || handle_error "Unable to update $DEV_BRANCH branch"
show_success "$DEV_BRANCH branch has been updated"

# Update main branch
show_info "Checking $MAIN_BRANCH branch status..."
git checkout $MAIN_BRANCH || handle_error "Unable to switch to $MAIN_BRANCH branch"
check_branch_status "$MAIN_BRANCH"
git pull || handle_error "Unable to update $MAIN_BRANCH branch"
show_success "$MAIN_BRANCH branch has been updated"

# Version number processing
echo -e "\n${BLUE}=== Version Management ===${NC}"
today=$(date +%Y%m%d)

# Get latest version number
latest_version=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "")

if [ -z "$latest_version" ]; then
    new_version="${VERSION_PREFIX}.${today}.00"
    show_info "First release, initial version: $new_version"
else
    show_info "Current latest version: $latest_version"
    
    # Parse version number
    latest_date=$(echo $latest_version | cut -d'.' -f2)
    latest_seq=$(echo $latest_version | cut -d'.' -f3)
    
    # Version number logic processing
    if [ "$latest_date" == "$today" ]; then
        seq_num=$((10#$latest_seq + 1))
        new_seq=$(printf "%02d" $seq_num)
        new_version="${VERSION_PREFIX}.${today}.${new_seq}"
        show_info "Same day release, incrementing sequence number"
    elif [ "$latest_date" -lt "$today" ]; then
        new_version="${VERSION_PREFIX}.${today}.00"
        show_info "New day, resetting sequence number"
    else
        handle_error "Version date anomaly: latest version date ($latest_date) is newer than today ($today)"
    fi
fi

# Confirm version number
echo -e "\n${BLUE}=== Version Confirmation ===${NC}"
show_info "Planned release version: $new_version"
read -p "$(echo -e ${YELLOW}"Confirm using this version number? [Y/n] "${NC})" confirm_version
if [[ ! $confirm_version =~ ^[Yy]$ ]] && [[ ! -z $confirm_version ]]; then
    read -p "Please enter new version number (format: ${VERSION_PREFIX}.YYYYMMDD.XX): " new_version
    show_info "Using custom version number: $new_version"
fi

# Prepare Release Notes
echo -e "\n${BLUE}=== Preparing Release Notes ===${NC}"
temp_note_file=$(mktemp)
echo "$new_version" > "$temp_note_file"
echo "" >> "$temp_note_file"
git log --oneline --format="%s" $MAIN_BRANCH..$DEV_BRANCH >> "$temp_note_file"

# Edit Release Notes
while true; do
    show_info "Current Release Notes content:"
    echo -e "${YELLOW}------------------------${NC}"
    cat "$temp_note_file"
    echo -e "${YELLOW}------------------------${NC}"
    
    read -p "$(echo -e ${YELLOW}"Confirm Release Notes content is correct? [Y/n] "${NC})" confirm_note
    if [[ $confirm_note =~ ^[Yy]$ ]] || [[ -z $confirm_note ]]; then
        break
    else
        show_info "Please edit Release Notes..."
        ${EDITOR:-vim} "$temp_note_file"
    fi
done

# Execute release process
echo -e "\n${BLUE}=== Executing Release Process ===${NC}"
show_info "Starting release branch: $new_version"
git flow release start $new_version || handle_error "Unable to create release branch"

# Set automatic merge message
export GIT_MERGE_AUTOEDIT=no
note_content=$(cat "$temp_note_file")

show_info "Completing release process..."
git flow release finish $new_version -f "$temp_note_file" || handle_error "Release completion failed"

# Cleanup
rm "$temp_note_file"
git checkout $MAIN_BRANCH || handle_error "Unable to switch to $MAIN_BRANCH branch"

# Push updates
echo -e "\n${BLUE}=== Pushing Updates ===${NC}"
show_info "Pushing $MAIN_BRANCH branch and tags..."
git push && git push --tags || handle_error "Push failed"

show_success "Release process completed! Version: $new_version"
echo -e "\n${GREEN}🎉 Automated release process completed${NC}\n"

# Restore stashed changes
if [ "$stash_changes" = true ]; then
    show_info "Restoring stashed changes..."
    git stash pop && show_success "Changes restored" || handle_error "Failed to restore stashed changes"
fi

exit 0
