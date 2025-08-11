#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════════
# 🔒 Interactive Security Validation Hook
# ═══════════════════════════════════════════════════════════════════════════════════
# Example showing security-focused validation using the framework
# ═══════════════════════════════════════════════════════════════════════════════════

# Source the interactive hook framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/interactive-hook-framework.sh"

# Configure this specific hook
export HOOK_NAME="Security Validation"
export HOOK_DESCRIPTION="Scans for security issues and suggests improvements"
export HOOK_COLOR='\033[1;31m'  # Red
export HOOK_EMOJI="🔒"

# ═══════════════════════════════════════════════════════════════════════════════════
# Security Patterns Database
# ═══════════════════════════════════════════════════════════════════════════════════

declare -A SECURITY_PATTERNS=(
    ["hardcoded_password"]="password\s*=\s*['\"][^'\"]+['\"]"
    ["api_key"]="api[_-]?key\s*=\s*['\"][^'\"]+['\"]"
    ["sql_injection"]="SELECT.*\+.*|INSERT.*\+.*|UPDATE.*\+.*"
    ["command_injection"]="os\.system\(|subprocess\.call\(|exec\("
    ["hardcoded_secret"]="secret\s*=\s*['\"][^'\"]+['\"]"
    ["jwt_secret"]="jwt[_-]?secret\s*=\s*['\"][^'\"]+['\"]"
    ["private_key"]="-----BEGIN.*PRIVATE.*KEY-----"
    ["aws_access"]="AKIA[0-9A-Z]{16}"
    ["github_token"]="ghp_[a-zA-Z0-9]{36}"
    ["weak_crypto"]="md5\(|sha1\(|DES|RC4"
)

declare -A SECURITY_DESCRIPTIONS=(
    ["hardcoded_password"]="Hardcoded password detected"
    ["api_key"]="API key in plain text"
    ["sql_injection"]="Potential SQL injection vulnerability"
    ["command_injection"]="Command injection risk"
    ["hardcoded_secret"]="Hardcoded secret detected"
    ["jwt_secret"]="JWT secret in plain text"
    ["private_key"]="Private key in repository"
    ["aws_access"]="AWS access key detected"
    ["github_token"]="GitHub personal access token"
    ["weak_crypto"]="Weak cryptographic algorithm"
)

declare -A SECURITY_FIXES=(
    ["hardcoded_password"]="Use environment variables or secure vault"
    ["api_key"]="Move to environment variables or config"
    ["sql_injection"]="Use parameterized queries"
    ["command_injection"]="Validate input and use safe alternatives"
    ["hardcoded_secret"]="Store in secure configuration"
    ["jwt_secret"]="Use environment variables"
    ["private_key"]="Remove from repository, use secure storage"
    ["aws_access"]="Remove immediately and rotate key"
    ["github_token"]="Remove immediately and regenerate"
    ["weak_crypto"]="Use SHA-256 or better algorithms"
)

# ═══════════════════════════════════════════════════════════════════════════════════
# Hook-Specific Functions
# ═══════════════════════════════════════════════════════════════════════════════════

analyze_file() {
    local file="$1"
    local issues=()
    local severity_high=false
    
    # Skip binary files
    if ! file "$file" | grep -q text; then
        return 1
    fi
    
    # Check for security patterns
    for pattern_name in "${!SECURITY_PATTERNS[@]}"; do
        local pattern="${SECURITY_PATTERNS[$pattern_name]}"
        if grep -qiE "$pattern" "$file" 2>/dev/null; then
            local description="${SECURITY_DESCRIPTIONS[$pattern_name]}"
            issues+=("🚨 $description")
            
            # Mark high severity issues
            case "$pattern_name" in
                "private_key"|"aws_access"|"github_token")
                    severity_high=true
                    ;;
            esac
        fi
    done
    
    # Check for other security concerns
    if grep -qE "TODO.*security|FIXME.*security|XXX.*security" "$file" 2>/dev/null; then
        issues+=("⚠️  Security-related TODO/FIXME found")
    fi
    
    if grep -qE "http://.*api\.|http://.*login" "$file" 2>/dev/null; then
        issues+=("🔓 HTTP URL for sensitive endpoint (use HTTPS)")
    fi
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        printf "Security concerns found:\n"
        printf "  • %s\n" "${issues[@]}"
        
        if $severity_high; then
            printf "\n  ⚠️  HIGH SEVERITY ISSUES DETECTED!\n"
        fi
        return 0
    else
        echo "  ✅ No security issues detected"
        return 1
    fi
}

preview_changes() {
    local file="$1"
    
    echo -e "${BLUE}🔍 Security analysis for: $(basename "$file")${RESET}"
    echo -e "${DIM}────────────────────────────────────────${RESET}"
    
    local line_num=1
    while IFS= read -r line; do
        local found_issue=false
        
        for pattern_name in "${!SECURITY_PATTERNS[@]}"; do
            local pattern="${SECURITY_PATTERNS[$pattern_name]}"
            if echo "$line" | grep -qiE "$pattern"; then
                echo -e "${RED}Line $line_num: ${SECURITY_DESCRIPTIONS[$pattern_name]}${RESET}"
                echo -e "${DIM}  $line${RESET}"
                echo -e "${YELLOW}  Suggestion: ${SECURITY_FIXES[$pattern_name]}${RESET}"
                found_issue=true
                break
            fi
        done
        
        ((line_num++))
    done < "$file"
    
    if ! $found_issue; then
        echo -e "${GREEN}No specific security issues found in preview${RESET}"
    fi
}

apply_enhancement() {
    local file="$1"
    
    # Create backup
    local backup_file
    backup_file=$(create_backup "$file")
    
    # For security issues, we typically want to comment out or remove
    # rather than automatically fix, since context matters
    local temp_file="/tmp/security_enhanced_$(basename "$file")"
    cp "$file" "$temp_file"
    
    # Comment out obvious security issues
    for pattern_name in "${!SECURITY_PATTERNS[@]}"; do
        local pattern="${SECURITY_PATTERNS[$pattern_name]}"
        local description="${SECURITY_DESCRIPTIONS[$pattern_name]}"
        
        case "$pattern_name" in
            "private_key"|"aws_access"|"github_token")
                # Remove these entirely and add warning
                sed -i.bak "/$pattern/c\\
# ⚠️  SECURITY: $description removed by security hook\\
# Original line moved to: $backup_file" "$temp_file"
                ;;
            "hardcoded_password"|"api_key"|"hardcoded_secret"|"jwt_secret")
                # Comment out and add suggestion
                sed -i.bak "/$pattern/s/^/# SECURITY: Use environment variable instead - /" "$temp_file"
                ;;
            "weak_crypto")
                # Add warning comment above
                sed -i.bak "/$pattern/i\\
# SECURITY WARNING: Consider using stronger cryptographic algorithms" "$temp_file"
                ;;
        esac
    done
    
    # Add security header if significant changes were made
    if ! cmp -s "$file" "$temp_file"; then
        {
            echo "# ═══════════════════════════════════════════════════════════════════"
            echo "# 🔒 SECURITY REVIEW APPLIED"
            echo "# This file has been processed by the security validation hook"
            echo "# Please review all changes and implement proper security measures"
            echo "# Backup available at: $backup_file"
            echo "# ═══════════════════════════════════════════════════════════════════"
            echo ""
            cat "$temp_file"
        } > "$file"
    fi
    
    rm -f "$temp_file" "$temp_file.bak"
    log_action "Applied security enhancements to $file (backup: $backup_file)"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Security-Specific Helper Functions
# ═══════════════════════════════════════════════════════════════════════════════════

check_for_secrets() {
    local file="$1"
    
    # Use more sophisticated secret detection
    if command -v truffleHog >/dev/null 2>&1; then
        truffleHog --regex --entropy=False "$file" 2>/dev/null
    elif command -v gitleaks >/dev/null 2>&1; then
        gitleaks detect --source "$file" --no-git 2>/dev/null
    fi
}

generate_security_report() {
    local files=("$@")
    local report_file="/tmp/security-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "🔒 SECURITY VALIDATION REPORT"
        echo "Generated: $(date)"
        echo "Files scanned: ${#files[@]}"
        echo ""
        
        for file in "${files[@]}"; do
            echo "FILE: $file"
            analyze_file "$file" 2>/dev/null || echo "  No issues found"
            echo ""
        done
    } > "$report_file"
    
    echo "📄 Security report saved to: $report_file"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════════════════════════

main() {
    ensure_git_repo
    
    # Get all text files for security scanning
    local files=()
    readarray -t staged_files < <(get_staged_files '.*')
    
    for file in "${staged_files[@]}"; do
        # Skip binary files and common excludes
        if [[ -f "$file" ]] && \
           ! [[ "$file" =~ \.(jpg|jpeg|png|gif|pdf|zip|tar|gz)$ ]] && \
           analyze_file "$file" >/dev/null; then
            files+=("$file")
        fi
    done
    
    # Generate security report
    if [[ ${#files[@]} -gt 0 ]]; then
        generate_security_report "${files[@]}"
    fi
    
    interactive_hook_main "${files[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
