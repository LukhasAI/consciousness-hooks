#!/bin/bash
# Example: Documentation Check Hook
# Ensures documentation is updated when code changes

# Source the interactive framework
source "$(dirname "$0")/../interactive-hook-framework.sh"

# Configure this hook
HOOK_NAME="Documentation Check"
HOOK_DESCRIPTION="Reminds you to update documentation when code changes"

# Check what types of files are being committed
get_changed_files() {
    git diff --cached --name-only
}

has_code_changes() {
    get_changed_files | grep -qE "\.(js|ts|py|java|cpp|c|go|rs|php|rb)$"
}

has_new_features() {
    # Check if any new public functions/classes are added
    git diff --cached | grep -qE "^\+.*((function|class|def|public|export).*(function|class))"
}

has_readme_update() {
    get_changed_files | grep -qiE "(readme|changelog|docs/)"
}

has_api_changes() {
    get_changed_files | grep -qE "(api|routes|endpoints|controllers)"
}

# Documentation suggestions
suggest_documentation_updates() {
    echo "📚 Documentation suggestions:"
    
    if has_new_features; then
        echo "   • Update README.md with new features"
        echo "   • Add code examples for new functions"
        echo "   • Update API documentation if applicable"
    fi
    
    if has_api_changes; then
        echo "   • Update API documentation"
        echo "   • Add endpoint examples"
        echo "   • Update OpenAPI/Swagger specs"
    fi
    
    echo "   • Consider updating CHANGELOG.md"
    echo "   • Add inline code comments for complex logic"
}

# Quick documentation generators
generate_readme_section() {
    echo "📝 Generating README section..."
    
    # This is a simple example - you could integrate with AI tools here
    echo "## New Features" > temp_readme_section.md
    echo "" >> temp_readme_section.md
    
    if has_new_features; then
        echo "### Added in this commit:" >> temp_readme_section.md
        git diff --cached | grep -E "^\+.*((function|def|class))" | sed 's/^+/- /' >> temp_readme_section.md
    fi
    
    echo "📄 Generated temp_readme_section.md - review and merge into your README!"
}

create_changelog_entry() {
    echo "📋 Creating changelog entry..."
    
    commit_msg=$(git log --format=%B -n 1 HEAD 2>/dev/null || echo "Pending commit")
    date=$(date +"%Y-%m-%d")
    
    echo "## [$date] - Unreleased" > temp_changelog.md
    echo "" >> temp_changelog.md
    echo "### Changed" >> temp_changelog.md
    echo "- $commit_msg" >> temp_changelog.md
    echo "" >> temp_changelog.md
    
    echo "📄 Generated temp_changelog.md - review and merge into your CHANGELOG!"
}

# Main hook logic
main() {
    echo "🎭 $HOOK_NAME"
    echo "   $HOOK_DESCRIPTION"
    echo
    
    if ! has_code_changes; then
        echo "📝 No code changes detected. Skipping documentation check."
        exit 0
    fi
    
    echo "🔍 Code changes detected in:"
    get_changed_files | grep -E "\.(js|ts|py|java|cpp|c|go|rs|php|rb)$" | sed 's/^/   • /'
    echo
    
    if has_readme_update; then
        echo "✅ Documentation updates detected! Great job! 🎉"
        exit 0
    fi
    
    echo "🤔 No documentation updates found. Consider updating docs!"
    echo
    
    suggest_documentation_updates
    echo
    
    get_user_choice \
        "📝 Generate README section" "generate_readme" \
        "📋 Create changelog entry" "create_changelog" \
        "💡 Just show reminders" "show_reminders" \
        "⏭️ Skip documentation check" "skip_docs" \
        "❌ Cancel and update docs" "cancel_commit"
    
    case $USER_CHOICE in
        "generate_readme")
            generate_readme_section
            echo "📝 Review the generated files and commit them separately."
            exit 0
            ;;
        "create_changelog")
            create_changelog_entry
            echo "📋 Review the generated changelog and commit it separately."
            exit 0
            ;;
        "show_reminders")
            echo
            echo "📚 Documentation reminders for future:"
            suggest_documentation_updates
            echo
            echo "💡 Consider setting up documentation templates in your project!"
            exit 0
            ;;
        "skip_docs")
            echo "⏭️ Skipping documentation check."
            echo "💡 Remember: Good documentation helps your future self and teammates!"
            exit 0
            ;;
        "cancel_commit")
            echo "❌ Commit cancelled. Update your documentation and try again."
            echo "📚 Good documentation makes your project more valuable!"
            exit 1
            ;;
    esac
}

# Run the hook
main "$@"
