#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════════
# 🔍 Interactive Code Quality Hook
# ═══════════════════════════════════════════════════════════════════════════════════
# Example showing how to adapt the framework for code quality checks
# ═══════════════════════════════════════════════════════════════════════════════════

# Source the interactive hook framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/interactive-hook-framework.sh"

# Configure this specific hook
export HOOK_NAME="Code Quality Assistant"
export HOOK_DESCRIPTION="Analyzes and improves code quality, documentation, and testing"
export HOOK_COLOR='\033[1;32m'  # Green
export HOOK_EMOJI="🔍"

# ═══════════════════════════════════════════════════════════════════════════════════
# Hook-Specific Functions
# ═══════════════════════════════════════════════════════════════════════════════════

analyze_file() {
    local file="$1"
    local issues=()
    
    case "${file##*.}" in
        py)
            # Python-specific checks
            if ! grep -q "^def\|^class" "$file" 2>/dev/null; then
                return 1  # No functions or classes to analyze
            fi
            
            # Check for docstrings
            if grep -q "^def\|^class" "$file" && ! grep -q '"""' "$file"; then
                issues+=("Missing docstrings")
            fi
            
            # Check for type hints
            if grep -q "def " "$file" && ! grep -q ": " "$file"; then
                issues+=("Missing type hints")
            fi
            
            # Check for long lines
            if awk 'length > 88' "$file" | head -1 >/dev/null; then
                issues+=("Lines exceed 88 characters")
            fi
            ;;
            
        js|ts)
            # JavaScript/TypeScript checks
            if ! grep -q "function\|=>" "$file" 2>/dev/null; then
                return 1
            fi
            
            # Check for JSDoc
            if grep -q "function\|=>" "$file" && ! grep -q "/\*\*" "$file"; then
                issues+=("Missing JSDoc comments")
            fi
            
            # Check for console.log
            if grep -q "console\.log" "$file"; then
                issues+=("Debug console.log statements found")
            fi
            ;;
            
        *)
            return 1  # Unsupported file type
            ;;
    esac
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        printf "Potential improvements:\n"
        printf "  • %s\n" "${issues[@]}"
        return 0
    else
        echo "  ✅ Code quality looks good"
        return 1
    fi
}

preview_changes() {
    local file="$1"
    
    echo -e "${BLUE}🔍 Preview of potential improvements:${RESET}"
    echo -e "${DIM}────────────────────────────────────────${RESET}"
    
    case "${file##*.}" in
        py)
            if ! grep -q '"""' "$file"; then
                echo -e "${GREEN}+ Would add docstring templates${RESET}"
                echo -e "${DIM}  def function_name():\n      \"\"\"Brief description.\n      \n      Returns:\n          type: Description\n      \"\"\"${RESET}"
            fi
            
            if ! grep -q ": " "$file" && grep -q "def " "$file"; then
                echo -e "${YELLOW}~ Would add type hints${RESET}"
                echo -e "${DIM}  def function_name(param: str) -> bool:${RESET}"
            fi
            ;;
            
        js|ts)
            if ! grep -q "/\*\*" "$file"; then
                echo -e "${GREEN}+ Would add JSDoc comments${RESET}"
                echo -e "${DIM}  /**\n   * Function description\n   * @param {string} param - Parameter description\n   * @returns {boolean} Return description\n   */${RESET}"
            fi
            ;;
    esac
    
    echo -e "\n${BLUE}📄 Current content (first 10 lines):${RESET}"
    echo -e "${DIM}$(head -10 "$file" 2>/dev/null)${RESET}"
}

apply_enhancement() {
    local file="$1"
    
    # Create backup
    local backup_file
    backup_file=$(create_backup "$file")
    
    case "${file##*.}" in
        py)
            enhance_python_quality "$file"
            ;;
        js|ts)
            enhance_javascript_quality "$file"
            ;;
    esac
    
    log_action "Enhanced code quality for $file (backup: $backup_file)"
}

enhance_python_quality() {
    local file="$1"
    local temp_file="/tmp/enhanced_$(basename "$file")"
    
    python3 << EOF > "$temp_file"
import re
import sys

def enhance_python_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    enhanced_lines = []
    
    for i, line in enumerate(lines):
        # Add docstring to functions without them
        if re.match(r'^def ', line.strip()) and i < len(lines) - 1:
            func_name = re.search(r'def (\w+)', line).group(1)
            if not any('"""' in lines[j] for j in range(i+1, min(i+5, len(lines)))):
                enhanced_lines.append(line)
                enhanced_lines.append('    """')
                enhanced_lines.append(f'    Brief description of {func_name}.')
                enhanced_lines.append('    ')
                enhanced_lines.append('    Returns:')
                enhanced_lines.append('        type: Description of return value')
                enhanced_lines.append('    """')
                continue
        
        enhanced_lines.append(line)
    
    return '\n'.join(enhanced_lines)

if __name__ == "__main__":
    enhanced = enhance_python_file("$file")
    print(enhanced)
EOF
    
    if [[ -s "$temp_file" ]]; then
        mv "$temp_file" "$file"
    else
        rm -f "$temp_file"
    fi
}

enhance_javascript_quality() {
    local file="$1"
    
    # Simple sed-based enhancement for JavaScript
    sed -i.bak -E '
        /^function / {
            i\
/**\
 * Function description\
 * @returns {*} Return description\
 */
        }
        /console\.log/s/console\.log/\/\/ DEBUG: console.log/
    ' "$file"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════════════════════════

main() {
    ensure_git_repo
    
    # Get code files that might need quality improvements
    local files=()
    readarray -t staged_files < <(get_staged_files '\.(py|js|ts)$')
    
    for file in "${staged_files[@]}"; do
        if [[ -f "$file" ]] && analyze_file "$file" >/dev/null; then
            files+=("$file")
        fi
    done
    
    interactive_hook_main "${files[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
