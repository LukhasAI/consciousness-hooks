#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════════
# 🚀 Interactive Git Hooks Installer
# ═══════════════════════════════════════════════════════════════════════════════════
# Easy installation and configuration of the Interactive Git Hook Framework
# ═══════════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# The original installer uses associative arrays, unavailable in macOS's
# system Bash 3.2. Fail with a clear explanation before touching any hooks.
if (( BASH_VERSINFO[0] < 4 )); then
    echo 'This experimental installer requires Bash 4+; macOS system Bash 3.2 is unsupported.' >&2
    exit 2
fi

# Colors
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"

# Available hooks
declare -A AVAILABLE_HOOKS=(
    ["tone"]="Tone Validation - LUKHAS consciousness enhancement"
    ["quality"]="Code Quality - Documentation and best practices"
    ["security"]="Security Validation - Security vulnerability scanning"
)

declare -A HOOK_FILES=(
    ["tone"]="tone-validation-hook.sh"
    ["quality"]="code-quality-hook.sh"
    ["security"]="security-validation-hook.sh"
)

# Fail-safe validation: missing sources must not yield a partial install.
preflight_sources() {
    local hook_type source
    if [[ ! -f "$SCRIPT_DIR/interactive-hook-framework.sh" ]]; then
        echo "Missing framework: $SCRIPT_DIR/interactive-hook-framework.sh" >&2
        return 2
    fi
    for hook_type in "$@"; do
        if [[ -z "${HOOK_FILES[$hook_type]+available}" ]]; then
            echo "Unknown hook type: $hook_type" >&2
            return 2
        fi
        source="$SCRIPT_DIR/${HOOK_FILES[$hook_type]}"
        if [[ ! -f "$source" ]]; then
            echo "Missing hook source: $source; no hooks were installed." >&2
            return 2
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════════════════════

print_header() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} 🚀 ${BOLD}Interactive Git Hooks Framework Installer${RESET} ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} ${DIM}Easy setup for intelligent, user-friendly git hooks${RESET} ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${RESET}\n"
}

print_separator() {
    echo -e "${DIM}────────────────────────────────────────────────────────────────────${RESET}"
}

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

check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: Not in a git repository${RESET}"
        echo -e "${DIM}Please run this installer from within a git repository${RESET}"
        exit 1
    fi
}

backup_existing_hooks() {
    local backup_dir="$GIT_HOOKS_DIR/backup-$(date +%Y%m%d_%H%M%S)"
    
    if [[ -n "$(ls -A "$GIT_HOOKS_DIR" 2>/dev/null | grep -v '\.sample$')" ]]; then
        echo -e "${YELLOW}📦 Backing up existing hooks...${RESET}"
        mkdir -p "$backup_dir"
        
        for hook in "$GIT_HOOKS_DIR"/*; do
            if [[ -f "$hook" ]] && [[ ! "$hook" =~ \.sample$ ]]; then
                cp "$hook" "$backup_dir/"
                echo -e "${DIM}  Backed up: $(basename "$hook")${RESET}"
            fi
        done
        
        echo -e "${GREEN}✅ Backup created: $backup_dir${RESET}"
        return 0
    else
        echo -e "${DIM}ℹ️  No existing hooks to backup${RESET}"
        return 1
    fi
}

install_framework() {
    echo -e "${BLUE}📚 Installing Interactive Hook Framework...${RESET}"
    
    # Copy the framework
    cp "$SCRIPT_DIR/interactive-hook-framework.sh" "$GIT_HOOKS_DIR/"
    chmod +x "$GIT_HOOKS_DIR/interactive-hook-framework.sh"
    
    echo -e "${GREEN}✅ Framework installed${RESET}"
}

install_hook() {
    local hook_type="$1"
    local hook_name="$2"
    local source_file="$SCRIPT_DIR/${HOOK_FILES[$hook_type]}"
    local target_file="$GIT_HOOKS_DIR/$hook_name"
    
    if [[ ! -f "$source_file" ]]; then
        echo -e "${RED}❌ Hook file not found: $source_file${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}🔧 Installing $hook_type hook as $hook_name...${RESET}"
    
    # Copy and make executable
    cp "$source_file" "$target_file"
    chmod +x "$target_file"
    
    echo -e "${GREEN}✅ Hook installed: $hook_name${RESET}"
}

create_hook_config() {
    local config_file="$GIT_HOOKS_DIR/interactive-hook.conf"
    
    echo -e "${BLUE}⚙️  Creating configuration file...${RESET}"
    
    cat > "$config_file" << 'EOF'
# ═══════════════════════════════════════════════════════════════════════════════════
# Interactive Git Hooks Configuration
# ═══════════════════════════════════════════════════════════════════════════════════

# Default mode for all hooks (interactive/auto/preview/skip)
DEFAULT_MODE=interactive

# Timeout for user input (seconds)
INPUT_TIMEOUT=30

# Backup directory for modified files
BACKUP_DIR=/tmp/git-hook-backups

# Enable logging
ENABLE_LOGGING=true
LOG_FILE=/tmp/git-hooks.log

# Hook-specific settings
TONE_HOOK_ENABLED=true
QUALITY_HOOK_ENABLED=true
SECURITY_HOOK_ENABLED=true

# Tone validation settings
TONE_AUTO_ENHANCE=false
TONE_REQUIRE_CONSCIOUSNESS_TERMS=true
TONE_ADD_HEADERS=true

# Security settings
SECURITY_STRICT_MODE=false
SECURITY_AUTO_COMMENT=true
SECURITY_GENERATE_REPORTS=true

# Quality settings
QUALITY_ADD_DOCSTRINGS=true
QUALITY_ADD_TYPE_HINTS=true
QUALITY_CHECK_LINE_LENGTH=true
EOF

    echo -e "${GREEN}✅ Configuration created: $config_file${RESET}"
}

test_hook_installation() {
    local hook_name="$1"
    local hook_file="$GIT_HOOKS_DIR/$hook_name"
    
    echo -e "${BLUE}🧪 Testing hook installation...${RESET}"
    
    if [[ -x "$hook_file" ]]; then
        # Test if the hook can run
        if "$hook_file" --help >/dev/null 2>&1 || [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Hook test passed${RESET}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Hook installed but may have issues${RESET}"
            return 1
        fi
    else
        echo -e "${RED}❌ Hook test failed${RESET}"
        return 1
    fi
}

show_usage_instructions() {
    echo -e "\n${BOLD}🎉 Installation Complete!${RESET}\n"
    
    echo -e "${CYAN}📖 How to use your new interactive hooks:${RESET}"
    echo -e "${DIM}────────────────────────────────────────${RESET}"
    echo -e "• Make changes to your files"
    echo -e "• Run ${BOLD}git add <files>${RESET} to stage them"
    echo -e "• Run ${BOLD}git commit${RESET} to trigger the hooks"
    echo -e "• Follow the interactive prompts to apply enhancements"
    echo ""
    
    echo -e "${CYAN}⚙️  Configuration:${RESET}"
    echo -e "• Config file: ${BOLD}$GIT_HOOKS_DIR/interactive-hook.conf${RESET}"
    echo -e "• Logs: ${BOLD}/tmp/git-hooks.log${RESET}"
    echo -e "• Backups: ${BOLD}/tmp/git-hook-backups${RESET}"
    echo ""
    
    echo -e "${CYAN}🔧 Available modes:${RESET}"
    echo -e "• ${BOLD}interactive${RESET} - Ask for each action (default)"
    echo -e "• ${BOLD}auto${RESET} - Apply all enhancements automatically"
    echo -e "• ${BOLD}preview${RESET} - Show what would be changed"
    echo -e "• ${BOLD}skip${RESET} - Skip hook execution"
    echo ""
    
    echo -e "${CYAN}💡 Pro tips:${RESET}"
    echo -e "• Set ${BOLD}HOOK_MODE=auto${RESET} environment variable for batch processing"
    echo -e "• Use ${BOLD}git commit --no-verify${RESET} to bypass hooks temporarily"
    echo -e "• Edit the config file to customize behavior"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Interactive Installation Menu
# ═══════════════════════════════════════════════════════════════════════════════════

show_hook_selection_menu() {
    echo -e "${BOLD}📋 Available Hooks:${RESET}"
    print_separator
    
    local i=1
    for hook_type in "${!AVAILABLE_HOOKS[@]}"; do
        echo -e "${CYAN}$i)${RESET} ${BOLD}${hook_type^}${RESET} - ${AVAILABLE_HOOKS[$hook_type]}"
        ((i++))
    done
    
    echo -e "${CYAN}$i)${RESET} ${BOLD}All${RESET} - Install all available hooks"
    echo -e "${CYAN}$((i+1)))${RESET} ${BOLD}Custom${RESET} - Let me choose which hooks to install"
    print_separator
}

select_hooks_to_install() {
    local selected_hooks=()
    
    show_hook_selection_menu
    
    local choice
    choice=$(get_user_choice "Which hooks would you like to install?" "4" 30 "1-$((${#AVAILABLE_HOOKS[@]}+2))")
    
    case "$choice" in
        "1")
            selected_hooks=("tone")
            ;;
        "2")
            selected_hooks=("quality")
            ;;
        "3")
            selected_hooks=("security")
            ;;
        "4"|"all"|"a")
            selected_hooks=("tone" "quality" "security")
            ;;
        "5"|"custom"|"c")
            echo -e "\n${YELLOW}🎯 Custom installation:${RESET}"
            for hook_type in "${!AVAILABLE_HOOKS[@]}"; do
                local install_hook
                install_hook=$(get_user_choice "Install ${hook_type} hook? (${AVAILABLE_HOOKS[$hook_type]})" "y" 15 "y/n")
                if [[ "${install_hook,,}" =~ ^(y|yes)$ ]]; then
                    selected_hooks+=("$hook_type")
                fi
            done
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${RESET}"
            exit 1
            ;;
    esac
    
    printf '%s\n' "${selected_hooks[@]}"
}

select_git_hooks() {
    echo -e "\n${YELLOW}🔗 Which git hook should trigger the enhancements?${RESET}"
    echo -e "${DIM}────────────────────────────────────────${RESET}"
    echo -e "1) ${BOLD}pre-commit${RESET} - Run before each commit (recommended)"
    echo -e "2) ${BOLD}post-commit${RESET} - Run after each commit"
    echo -e "3) ${BOLD}pre-push${RESET} - Run before pushing to remote"
    echo -e "4) ${BOLD}custom${RESET} - I'll specify the hook name"
    
    local choice
    choice=$(get_user_choice "Select git hook:" "1" 20 "1-4")
    
    case "$choice" in
        "1"|"pre-commit")
            echo "pre-commit"
            ;;
        "2"|"post-commit")
            echo "post-commit"
            ;;
        "3"|"pre-push")
            echo "pre-push"
            ;;
        "4"|"custom")
            local custom_hook
            read -p "Enter hook name: " custom_hook
            echo "${custom_hook:-pre-commit}"
            ;;
        *)
            echo "pre-commit"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Main Installation Flow
# ═══════════════════════════════════════════════════════════════════════════════════

main() {
    print_header
    
    # Verify we're in a git repository
    check_git_repo
    
    echo -e "${GREEN}📂 Git repository detected: $(git rev-parse --show-toplevel)${RESET}"
    echo -e "${DIM}Hooks will be installed to: $GIT_HOOKS_DIR${RESET}\n"
    
    # Confirm installation
    local proceed
    proceed=$(get_user_choice "🚀 Ready to install interactive git hooks?" "y" 30 "y/n")
    
    if [[ ! "${proceed,,}" =~ ^(y|yes)$ ]]; then
        echo -e "${YELLOW}👋 Installation cancelled${RESET}"
        exit 0
    fi
    
    # Abort before writing anything while promised hook sources are missing.
    preflight_sources "${!AVAILABLE_HOOKS[@]}" || return 2

    # Backup existing hooks
    backup_existing_hooks || true
    echo ""
    
    # Install the framework
    install_framework
    echo ""
    
    # Select hooks to install
    echo -e "${BOLD}🎯 Hook Selection${RESET}"
    mapfile -t selected_hooks < <(select_hooks_to_install)
    
    if [[ ${#selected_hooks[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No hooks selected for installation${RESET}"
        exit 0
    fi
    
    # Select git hook type
    git_hook=$(select_git_hooks)
    echo ""
    
    # Install selected hooks
    echo -e "${BOLD}🔧 Installing Hooks${RESET}"
    print_separator
    
    for hook_type in "${selected_hooks[@]}"; do
        install_hook "$hook_type" "$git_hook"
    done
    
    echo ""
    
    # Create configuration
    create_hook_config
    echo ""
    
    # Test installation
    test_hook_installation "$git_hook"
    echo ""
    
    # Show usage instructions
    show_usage_instructions
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Command Line Interface
# ═══════════════════════════════════════════════════════════════════════════════════

show_help() {
    echo -e "${BOLD}Interactive Git Hooks Installer${RESET}"
    echo ""
    echo -e "${BOLD}USAGE:${RESET}"
    echo "  $0 [OPTIONS]"
    echo ""
    echo -e "${BOLD}OPTIONS:${RESET}"
    echo "  --auto              Install all hooks automatically"
    echo "  --hook=<name>       Specify git hook name (default: pre-commit)"
    echo "  --type=<type>       Install specific hook type (tone|quality|security)"
    echo "  --config-only       Only create configuration file"
    echo "  --help              Show this help"
    echo ""
    echo -e "${BOLD}EXAMPLES:${RESET}"
    echo "  $0                      # Interactive installation"
    echo "  $0 --auto              # Install all hooks automatically"
    echo "  $0 --type=tone         # Install only tone validation hook"
    echo "  $0 --hook=pre-push     # Install hooks for pre-push"
}

# Parse command line arguments
AUTO_INSTALL=false
HOOK_TYPE=""
GIT_HOOK="pre-commit"
CONFIG_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            AUTO_INSTALL=true
            shift
            ;;
        --hook=*)
            GIT_HOOK="${1#*=}"
            shift
            ;;
        --type=*)
            HOOK_TYPE="${1#*=}"
            shift
            ;;
        --config-only)
            CONFIG_ONLY=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${RESET}"
            show_help
            exit 1
            ;;
    esac
done

# Run main installation or handle special cases
if [[ "$CONFIG_ONLY" == true ]]; then
    check_git_repo
    create_hook_config
elif [[ "$AUTO_INSTALL" == true ]]; then
    # Automated installation
    check_git_repo
    # Preflight every selected hook before creating backups, configs or hooks.
    if [[ -n "$HOOK_TYPE" ]]; then
        preflight_sources "$HOOK_TYPE" || exit 2
    else
        preflight_sources "${!AVAILABLE_HOOKS[@]}" || exit 2
    fi
    backup_existing_hooks >/dev/null 2>&1 || true
    install_framework
    
    if [[ -n "$HOOK_TYPE" ]]; then
        install_hook "$HOOK_TYPE" "$GIT_HOOK"
    else
        for hook_type in "${!AVAILABLE_HOOKS[@]}"; do
            install_hook "$hook_type" "$GIT_HOOK"
        done
    fi
    
    create_hook_config
    echo -e "${GREEN}✅ Automated installation complete${RESET}"
else
    # Interactive installation
    main "$@"
fi
