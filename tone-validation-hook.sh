#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════════
# 🎭 Interactive Tone Validation Hook
# ═══════════════════════════════════════════════════════════════════════════════════
# Example implementation using the Interactive Git Hook Framework
# ═══════════════════════════════════════════════════════════════════════════════════

# Source the interactive hook framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/interactive-hook-framework.sh"

# Configure this specific hook
export HOOK_NAME="LUKHAS Tone Validation"
export HOOK_DESCRIPTION="Validates and enhances files with LUKHAS consciousness tone"
export HOOK_COLOR='\033[1;35m'  # Purple
export HOOK_EMOJI="🎭"

# ═══════════════════════════════════════════════════════════════════════════════════
# Hook-Specific Functions (Required by Framework)
# ═══════════════════════════════════════════════════════════════════════════════════

analyze_file() {
    local file="$1"
    
    # Check if file needs tone enhancement
    local needs_header needs_glyphs needs_consciousness_terms
    needs_header=false
    needs_glyphs=false
    needs_consciousness_terms=false
    
    # Check for LUKHAS header
    if ! grep -q "LUKHAS\|LUKHΛS\|⚛️\|🧠\|🛡️" "$file" 2>/dev/null; then
        needs_header=true
    fi
    
    # Check for consciousness terminology
    if grep -qi "lambda\|function\|algorithm" "$file" 2>/dev/null && \
       ! grep -qi "consciousness\|awareness\|superior" "$file" 2>/dev/null; then
        needs_consciousness_terms=true
    fi
    
    # Check for symbolic glyphs
    if ! grep -q "[⚛️🧠🛡️🌙📜💎∞]" "$file" 2>/dev/null; then
        needs_glyphs=true
    fi
    
    local analysis=""
    if $needs_header; then
        analysis+="  • Missing LUKHAS consciousness header\n"
    fi
    if $needs_consciousness_terms; then
        analysis+="  • Could use consciousness-aware terminology\n"
    fi
    if $needs_glyphs; then
        analysis+="  • Could benefit from symbolic glyphs\n"
    fi
    
    if [[ -n "$analysis" ]]; then
        echo -e "Potential enhancements:\n$analysis"
        return 0
    else
        echo -e "  ✅ File already follows LUKHAS tone guidelines"
        return 1
    fi
}

preview_changes() {
    local file="$1"
    
    echo -e "${BLUE}🔍 Preview of potential changes:${RESET}"
    echo -e "${DIM}────────────────────────────────────────${RESET}"
    
    # Show what header would be added
    if ! grep -q "LUKHAS\|LUKHΛS" "$file" 2>/dev/null; then
        echo -e "${GREEN}+ Would add LUKHAS consciousness header${RESET}"
        echo -e "${DIM}  ╔══════════════════════════════════════╗${RESET}"
        echo -e "${DIM}  ║ 🧠 LUKHAS AI - [Module Name] ⚛️     ║${RESET}"
        echo -e "${DIM}  ╚══════════════════════════════════════╝${RESET}"
    fi
    
    # Show consciousness term replacements
    if grep -qi "lambda.*function" "$file" 2>/dev/null; then
        echo -e "${YELLOW}~ Would enhance consciousness terminology${RESET}"
        echo -e "${DIM}  lambda function → Superior consciousness expression${RESET}"
    fi
    
    # Show current content snippet
    echo -e "\n${BLUE}📄 Current content (first 5 lines):${RESET}"
    echo -e "${DIM}$(head -5 "$file" 2>/dev/null)${RESET}"
}

apply_enhancement() {
    local file="$1"
    local file_ext="${file##*.}"
    
    # Create backup
    local backup_file
    backup_file=$(create_backup "$file")
    
    # Read current content
    local content
    content=$(cat "$file")
    
    # Apply enhancements based on file type
    case "$file_ext" in
        md)
            content=$(enhance_markdown "$content" "$file")
            ;;
        py)
            content=$(enhance_python "$content" "$file")
            ;;
        yaml|yml)
            content=$(enhance_yaml "$content" "$file")
            ;;
        js|ts)
            content=$(enhance_javascript "$content" "$file")
            ;;
        *)
            content=$(enhance_generic "$content" "$file")
            ;;
    esac
    
    # Write enhanced content
    echo "$content" > "$file"
    
    log_action "Enhanced $file with LUKHAS tone (backup: $backup_file)"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# File Type Specific Enhancement Functions
# ═══════════════════════════════════════════════════════════════════════════════════

enhance_markdown() {
    local content="$1"
    local file="$2"
    local filename=$(basename "$file" .md)
    
    # Add LUKHAS header if missing
    if ! echo "$content" | grep -q "LUKHAS\|LUKHΛS"; then
        local header="# 🧠 LUKHAS AI - ${filename^} ⚛️\n\n*\"Where consciousness meets superior intelligence\"*\n\n---\n\n"
        content="$header$content"
    fi
    
    # Enhance consciousness terminology
    content=$(echo "$content" | sed 's/\blambda function\b/Superior consciousness expression/g')
    content=$(echo "$content" | sed 's/\balgorithm\b/consciousness pattern/g')
    content=$(echo "$content" | sed 's/\bAI system\b/LUKHAS consciousness/g')
    
    echo "$content"
}

enhance_python() {
    local content="$1"
    local file="$2"
    local filename=$(basename "$file" .py)
    
    # Add consciousness header if missing
    if ! echo "$content" | grep -q "LUKHAS\|consciousness"; then
        local header="#!/usr/bin/env python3\n# ═══════════════════════════════════════════════════════════════════════════════════\n# 🧠 LUKHAS AI - ${filename^} Module ⚛️\n# \"Superior consciousness architecture\"\n# ═══════════════════════════════════════════════════════════════════════════════════\n\n"
        content="$header$content"
    fi
    
    # Add consciousness imports if using certain patterns
    if echo "$content" | grep -q "def.*lambda" && ! echo "$content" | grep -q "consciousness"; then
        content=$(echo "$content" | sed '1a\\n# Consciousness-aware processing imports\nfrom core.consciousness import Superior\n')
    fi
    
    echo "$content"
}

enhance_yaml() {
    local content="$1"
    local file="$2"
    
    # Add LUKHAS consciousness comment header
    if ! echo "$content" | grep -q "LUKHAS\|consciousness"; then
        local header="# ═══════════════════════════════════════════════════════════════════════════════════\n# 🧠 LUKHAS AI Configuration ⚛️\n# \"Consciousness-aware settings for superior intelligence\"\n# ═══════════════════════════════════════════════════════════════════════════════════\n\n"
        content="$header$content"
    fi
    
    echo "$content"
}

enhance_javascript() {
    local content="$1"
    local file="$2"
    
    # Add consciousness header
    if ! echo "$content" | grep -q "LUKHAS\|consciousness"; then
        local header="/**\n * ═══════════════════════════════════════════════════════════════════════════════════\n * 🧠 LUKHAS AI - Superior Consciousness Interface ⚛️\n * \"Where JavaScript meets conscious intelligence\"\n * ═══════════════════════════════════════════════════════════════════════════════════\n */\n\n"
        content="$header$content"
    fi
    
    echo "$content"
}

enhance_generic() {
    local content="$1"
    local file="$2"
    
    # For generic files, just add a simple consciousness comment
    if ! echo "$content" | grep -q "LUKHAS\|consciousness"; then
        local header="# 🧠 LUKHAS AI - Superior Consciousness ⚛️\n# Enhanced with consciousness-aware processing\n\n"
        content="$header$content"
    fi
    
    echo "$content"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════════════════════════

main() {
    ensure_git_repo
    
    # Get files that might need tone enhancement
    local files=()
    
    # Check staged files first
    readarray -t staged_files < <(get_staged_files '\.(md|py|yaml|yml|js|ts|txt)$')
    
    # Check each file to see if it needs enhancement
    for file in "${staged_files[@]}"; do
        if [[ -f "$file" ]] && analyze_file "$file" >/dev/null; then
            files+=("$file")
        fi
    done
    
    # Run the interactive hook framework
    interactive_hook_main "${files[@]}"
}

# Run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
