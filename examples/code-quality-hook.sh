#!/bin/bash
# Example: Code Quality Check Hook
# This is a template that you can customize for your project's needs

# Source the interactive framework
source "$(dirname "$0")/../interactive-hook-framework.sh"

# Configure this hook
HOOK_NAME="Code Quality Check"
HOOK_DESCRIPTION="Ensures code meets quality standards before commit"

# Your custom validation logic goes here
validate_code_quality() {
    echo "🔍 Checking code quality..."
    
    # Example: Check if package.json exists (customize this!)
    if [[ -f "package.json" ]]; then
        echo "✅ Node.js project detected"
        
        # Example: Run npm lint if available
        if npm run lint --silent 2>/dev/null; then
            echo "✅ Linting passed"
            return 0
        else
            echo "❌ Linting issues found"
            return 1
        fi
    fi
    
    # Example: Check Python files
    if find . -name "*.py" -type f | head -1 | grep -q .; then
        echo "✅ Python project detected"
        
        # Example: Basic Python syntax check
        if python -m py_compile $(find . -name "*.py" -type f) 2>/dev/null; then
            echo "✅ Python syntax check passed"
            return 0
        else
            echo "❌ Python syntax errors found"
            return 1
        fi
    fi
    
    echo "✅ No specific quality checks configured"
    return 0
}

# Auto-fix function (optional)
auto_fix_quality() {
    echo "🔧 Attempting to auto-fix issues..."
    
    if [[ -f "package.json" ]]; then
        npm run lint:fix 2>/dev/null && echo "✅ Auto-fixed JavaScript/TypeScript issues"
    fi
    
    if command -v black >/dev/null 2>&1; then
        black . 2>/dev/null && echo "✅ Auto-formatted Python files"
    fi
}

# Main hook logic
main() {
    echo "🎭 $HOOK_NAME"
    echo "   $HOOK_DESCRIPTION"
    echo
    
    if validate_code_quality; then
        echo "✅ Code quality check passed!"
        exit 0
    fi
    
    echo
    echo "🤔 Code quality issues detected. What would you like to do?"
    
    get_user_choice \
        "🔧 Try to auto-fix" "auto_fix" \
        "👀 Review manually" "manual_review" \
        "⏭️ Skip this time" "skip_check" \
        "❌ Cancel commit" "cancel_commit"
    
    case $USER_CHOICE in
        "auto_fix")
            auto_fix_quality
            if validate_code_quality; then
                echo "✅ Issues fixed! Proceeding with commit."
                exit 0
            else
                echo "⚠️ Some issues remain. Please review manually."
                exit 1
            fi
            ;;
        "manual_review")
            echo "📝 Please fix the issues and run 'git commit' again."
            echo "💡 Tip: Use your editor's linting features or run quality tools manually."
            exit 1
            ;;
        "skip_check")
            echo "⏭️ Skipping quality check. Proceeding with commit."
            echo "💡 Remember to fix quality issues before pushing!"
            exit 0
            ;;
        "cancel_commit")
            echo "❌ Commit cancelled. Fix issues and try again."
            exit 1
            ;;
    esac
}

# Run the hook
main "$@"
