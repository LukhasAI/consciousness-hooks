#!/bin/bash
# Example: Commit Message Hook
# Helps users write better commit messages with interactive guidance

# Source the interactive framework
source "$(dirname "$0")/../interactive-hook-framework.sh"

# Configure this hook
HOOK_NAME="Commit Message Helper"
HOOK_DESCRIPTION="Ensures commit messages follow best practices"

# Get the commit message file
COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Validation functions
is_conventional_format() {
    # Check if message follows conventional commits format
    echo "$COMMIT_MSG" | grep -qE "^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+"
}

is_good_length() {
    # Check if first line is appropriate length (50 chars recommended)
    first_line=$(echo "$COMMIT_MSG" | head -n1)
    [[ ${#first_line} -le 72 && ${#first_line} -ge 10 ]]
}

has_description() {
    # Check if commit has a meaningful description
    echo "$COMMIT_MSG" | grep -vqE "^(wip|temp|fix|update|change)$"
}

# Auto-improvement functions
suggest_conventional_format() {
    echo "💡 Suggested conventional format:"
    echo "   feat: add new feature"
    echo "   fix: resolve bug in login"
    echo "   docs: update README"
    echo "   style: format code"
    echo "   refactor: reorganize auth module"
    echo "   test: add unit tests"
    echo "   chore: update dependencies"
}

suggest_improvements() {
    first_line=$(echo "$COMMIT_MSG" | head -n1)
    
    if [[ ${#first_line} -gt 72 ]]; then
        echo "📏 Your message is quite long (${#first_line} chars). Consider shortening to 50-72 characters."
    fi
    
    if [[ ${#first_line} -lt 10 ]]; then
        echo "📝 Your message is very short. Consider adding more detail about what changed."
    fi
    
    if echo "$COMMIT_MSG" | grep -qE "^(wip|temp|fix|update)$"; then
        echo "🔍 Generic message detected. Consider being more specific about what you changed."
    fi
}

# Interactive improvement
improve_message_interactively() {
    echo "✏️ Let's improve your commit message!"
    echo "   Current: $COMMIT_MSG"
    echo
    
    suggest_conventional_format
    suggest_improvements
    echo
    
    read -p "🖊️  Enter improved message (or press Enter to keep current): " new_message
    
    if [[ -n "$new_message" ]]; then
        echo "$new_message" > "$COMMIT_MSG_FILE"
        echo "✅ Commit message updated!"
        return 0
    else
        echo "📝 Keeping original message."
        return 1
    fi
}

# Main hook logic
main() {
    echo "🎭 $HOOK_NAME"
    echo "   $HOOK_DESCRIPTION"
    echo
    
    # Skip if no commit message (merge commits, etc.)
    if [[ -z "$COMMIT_MSG" || "$COMMIT_MSG" =~ ^Merge.* ]]; then
        exit 0
    fi
    
    echo "📝 Your commit message: \"$COMMIT_MSG\""
    
    # Check various quality aspects
    issues=()
    
    if ! is_conventional_format; then
        issues+=("Not using conventional format")
    fi
    
    if ! is_good_length; then
        issues+=("Length could be improved")
    fi
    
    if ! has_description; then
        issues+=("Message is too generic")
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        echo "✅ Great commit message! 🎉"
        exit 0
    fi
    
    echo
    echo "🤔 Your commit message could be improved:"
    for issue in "${issues[@]}"; do
        echo "   • $issue"
    done
    echo
    
    get_user_choice \
        "✏️ Improve message now" "improve_now" \
        "💡 Show suggestions only" "show_suggestions" \
        "✅ Use as-is" "keep_message" \
        "❌ Cancel commit" "cancel_commit"
    
    case $USER_CHOICE in
        "improve_now")
            if improve_message_interactively; then
                echo "✅ Message improved! Proceeding with commit."
            else
                echo "📝 Proceeding with original message."
            fi
            exit 0
            ;;
        "show_suggestions")
            echo
            suggest_conventional_format
            suggest_improvements
            echo
            echo "💡 Feel free to use these suggestions for future commits!"
            exit 0
            ;;
        "keep_message")
            echo "📝 Proceeding with your original message."
            exit 0
            ;;
        "cancel_commit")
            echo "❌ Commit cancelled. Edit your message and try again."
            exit 1
            ;;
    esac
}

# Run the hook
main "$@"
