#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════════
# 🎯 Interactive Git Hook Framework
# ═══════════════════════════════════════════════════════════════════════════════════
# A reusable framework for creating interactive git hooks that gracefully ask
# users for permission instead of blocking commits.
#
# Usage: source this framework in your hook and call interactive_hook_main
# ═══════════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration variables that hooks can customize
HOOK_NAME="${HOOK_NAME:-Generic Hook}"
HOOK_DESCRIPTION="${HOOK_DESCRIPTION:-This hook performs validation}"
HOOK_COLOR="${HOOK_COLOR:-\033[1;36m}"  # Cyan by default
HOOK_EMOJI="${HOOK_EMOJI:-🔧}"
LOG_FILE="${LOG_FILE:-/tmp/git-hook-$(basename "$0").log}"

# Color definitions
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'

# ═══════════════════════════════════════════════════════════════════════════════════
# Core Framework Functions
# ═══════════════════════════════════════════════════════════════════════════════════

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_header() {
    echo -e "\n${HOOK_COLOR}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${HOOK_COLOR}║${RESET} ${HOOK_EMOJI} ${BOLD}${HOOK_NAME}${RESET} ${HOOK_COLOR}║${RESET}"
    echo -e "${HOOK_COLOR}║${RESET} ${DIM}${HOOK_DESCRIPTION}${RESET} ${HOOK_COLOR}║${RESET}"
    echo -e "${HOOK_COLOR}╚════════════════════════════════════════════════════════════════════╝${RESET}\n"
}

print_separator() {
    echo -e "${DIM}────────────────────────────────────────────────────────────────────${RESET}"
}

# Function to get user choice with timeout
get_user_choice() {
    local prompt="$1"
    local default="${2:-y}"
    local timeout="${3:-30}"
    local choices="${4:-y/n}"
    
    echo -e "${YELLOW}${prompt}${RESET}"
    echo -e "${DIM}Choices: [${choices}] (default: ${default}, timeout: ${timeout}s)${RESET}"
    
    local choice
    if read -t "$timeout" -p "❯ " choice; then
        choice="${choice:-$default}"
    else
        echo -e "\n${DIM}⏱️  Timeout reached, using default: ${default}${RESET}"
        choice="$default"
    fi
    
    echo "$choice"
}

# Function to display file changes
show_changes() {
    local file="$1"
    local description="$2"
    
    echo -e "${BLUE}📄 ${description}:${RESET} ${BOLD}$file${RESET}"
    echo -e "${DIM}$(head -3 "$file" 2>/dev/null || echo "File preview unavailable")${RESET}"
    print_separator
}

# Function to create a backup of files
create_backup() {
    local file="$1"
    local backup_dir="${BACKUP_DIR:-/tmp/git-hook-backups}"
    
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/$(basename "$file").$(date +%Y%m%d_%H%M%S).backup"
    cp "$file" "$backup_file" 2>/dev/null || true
    echo "$backup_file"
}

# Function to apply changes with user confirmation
apply_changes() {
    local file="$1"
    local new_content="$2"
    local description="$3"
    
    local backup_file
    backup_file=$(create_backup "$file")
    
    echo -e "${GREEN}✅ Applying changes to: ${BOLD}$file${RESET}"
    echo -e "${DIM}Backup created: $backup_file${RESET}"
    
    echo "$new_content" > "$file"
    log_action "Applied $description to $file (backup: $backup_file)"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Hook Execution Modes
# ═══════════════════════════════════════════════════════════════════════════════════

# Interactive mode - asks user for each action
interactive_mode() {
    local files=("$@")
    local processed=0
    local applied=0
    
    print_header
    echo -e "${CYAN}🔍 Found ${#files[@]} file(s) that could be enhanced${RESET}\n"
    
    for file in "${files[@]}"; do
        processed=$((processed + 1))
        
        echo -e "${BOLD}File $processed/${#files[@]}:${RESET} $file"
        
        # Call the hook's analysis function
        if declare -f "analyze_file" > /dev/null; then
            local analysis
            analysis=$(analyze_file "$file")
            echo -e "${DIM}$analysis${RESET}"
        fi
        
        # Ask user what to do
        local choice
        choice=$(get_user_choice "What would you like to do?" "s" 30 "a)pply/s)kip/v)iew/q)uit")
        
        case "${choice,,}" in
            a|apply)
                if declare -f "apply_enhancement" > /dev/null; then
                    apply_enhancement "$file"
                    applied=$((applied + 1))
                    echo -e "${GREEN}✅ Enhanced $file${RESET}"
                else
                    echo -e "${RED}❌ Enhancement function not defined${RESET}"
                fi
                ;;
            v|view)
                if declare -f "preview_changes" > /dev/null; then
                    preview_changes "$file"
                else
                    echo -e "${BLUE}📖 Current content:${RESET}"
                    head -20 "$file" 2>/dev/null || echo "Cannot preview file"
                fi
                # Ask again after viewing
                choice=$(get_user_choice "Apply changes?" "s" 15 "a)pply/s)kip")
                if [[ "${choice,,}" =~ ^(a|apply)$ ]]; then
                    apply_enhancement "$file"
                    applied=$((applied + 1))
                fi
                ;;
            q|quit)
                echo -e "${YELLOW}⏹️  Stopping at user request${RESET}"
                break
                ;;
            *)
                echo -e "${DIM}⏭️  Skipping $file${RESET}"
                ;;
        esac
        
        echo ""
    done
    
    echo -e "${BOLD}📊 Summary:${RESET}"
    echo -e "  • Files processed: $processed"
    echo -e "  • Files enhanced: $applied"
    echo -e "  • Files skipped: $((processed - applied))"
    
    log_action "Interactive mode: processed $processed, applied $applied"
}

# Auto mode - applies all changes without asking
auto_mode() {
    local files=("$@")
    
    print_header
    echo -e "${CYAN}🚀 Auto-applying enhancements to ${#files[@]} file(s)${RESET}\n"
    
    local applied=0
    for file in "${files[@]}"; do
        if declare -f "apply_enhancement" > /dev/null; then
            apply_enhancement "$file"
            applied=$((applied + 1))
            echo -e "${GREEN}✅ Enhanced $file${RESET}"
        fi
    done
    
    echo -e "\n${BOLD}📊 Applied enhancements to $applied file(s)${RESET}"
    log_action "Auto mode: applied enhancements to $applied files"
}

# Preview mode - shows what would be changed without applying
preview_mode() {
    local files=("$@")
    
    print_header
    echo -e "${CYAN}👀 Preview mode - showing potential changes${RESET}\n"
    
    for file in "${files[@]}"; do
        echo -e "${BOLD}📄 $file${RESET}"
        if declare -f "preview_changes" > /dev/null; then
            preview_changes "$file"
        else
            echo -e "${DIM}No preview function defined${RESET}"
        fi
        print_separator
    done
    
    log_action "Preview mode: showed changes for ${#files[@]} files"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Configuration Management
# ═══════════════════════════════════════════════════════════════════════════════════

load_config() {
    local config_file="${1:-$(git rev-parse --git-dir)/hooks/interactive-hook.conf}"
    
    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
        log_action "Loaded config from $config_file"
    fi
}

save_user_preference() {
    local key="$1"
    local value="$2"
    local config_file="${3:-$(git rev-parse --git-dir)/hooks/interactive-hook.conf}"
    
    mkdir -p "$(dirname "$config_file")"
    
    # Remove existing setting and add new one
    grep -v "^$key=" "$config_file" 2>/dev/null > "${config_file}.tmp" || touch "${config_file}.tmp"
    echo "$key=$value" >> "${config_file}.tmp"
    mv "${config_file}.tmp" "$config_file"
    
    log_action "Saved preference: $key=$value"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Main Entry Point
# ═══════════════════════════════════════════════════════════════════════════════════

interactive_hook_main() {
    local files=("$@")
    
    # Load configuration
    load_config
    
    # Skip if no files to process
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${DIM}ℹ️  No files to process${RESET}"
        return 0
    fi
    
    # Check for mode override from environment or config
    local mode="${HOOK_MODE:-${DEFAULT_MODE:-interactive}}"
    
    # Allow user to choose mode if not set
    if [[ "$mode" == "ask" ]] || [[ -z "$mode" ]]; then
        echo -e "${YELLOW}🤔 How would you like to proceed?${RESET}"
        mode=$(get_user_choice "Choose mode:" "i" 20 "i)nteractive/a)uto/p)review/s)kip")
        
        # Ask if they want to remember this choice
        local remember
        remember=$(get_user_choice "Remember this choice for future commits?" "n" 10 "y/n")
        if [[ "${remember,,}" =~ ^(y|yes)$ ]]; then
            save_user_preference "DEFAULT_MODE" "$mode"
        fi
    fi
    
    case "${mode,,}" in
        i|interactive)
            interactive_mode "${files[@]}"
            ;;
        a|auto)
            auto_mode "${files[@]}"
            ;;
        p|preview)
            preview_mode "${files[@]}"
            ;;
        s|skip)
            echo -e "${DIM}⏭️  Skipping hook execution${RESET}"
            ;;
        *)
            echo -e "${RED}❌ Unknown mode: $mode${RESET}"
            return 1
            ;;
    esac
    
    # Always exit successfully to not block commits
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Utility Functions for Hook Implementers
# ═══════════════════════════════════════════════════════════════════════════════════

# Function to check if we're in a git repository
ensure_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}❌ Not in a git repository${RESET}"
        exit 1
    fi
}

# Function to get staged files matching a pattern
get_staged_files() {
    local pattern="${1:-.*}"
    git diff --cached --name-only --diff-filter=ACM | grep -E "$pattern" || true
}

# Function to get modified files matching a pattern
get_modified_files() {
    local pattern="${1:-.*}"
    git diff --name-only --diff-filter=ACM | grep -E "$pattern" || true
}

# Export functions for use by implementing hooks
export -f log_action print_header print_separator get_user_choice
export -f show_changes create_backup apply_changes
export -f interactive_mode auto_mode preview_mode
export -f load_config save_user_preference
export -f interactive_hook_main ensure_git_repo
export -f get_staged_files get_modified_files

echo -e "${DIM}📚 Interactive Git Hook Framework loaded${RESET}"
