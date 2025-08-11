#!/bin/bash

# 🚀 Interactive Git Hooks VS Code Extension Setup
# This script sets up the complete development environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Header
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                🚀 Interactive Git Hooks Setup                ║"
echo "║                      VS Code Extension                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
log_info "Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed. Please install Node.js 18+ and try again."
    exit 1
fi

node_version=$(node --version | sed 's/v//')
node_major=$(echo "$node_version" | cut -d. -f1)
if [ "$node_major" -lt 18 ]; then
    log_error "Node.js version $node_version found. Please install Node.js 18+ and try again."
    exit 1
fi
log_success "Node.js $node_version found"

# Check npm
if ! command -v npm &> /dev/null; then
    log_error "npm is not installed. Please install npm and try again."
    exit 1
fi
log_success "npm $(npm --version) found"

# Check if VS Code is installed
if ! command -v code &> /dev/null; then
    log_warning "VS Code CLI not found. You may need to install the 'code' command."
    log_info "In VS Code: Cmd+Shift+P → 'Shell Command: Install code command in PATH'"
else
    log_success "VS Code CLI found"
fi

# Install dependencies
log_info "Installing dependencies..."
if npm install; then
    log_success "Dependencies installed successfully"
else
    log_error "Failed to install dependencies"
    exit 1
fi

# Create resources directory
log_info "Setting up resources..."
mkdir -p resources

# Create placeholder icon if it doesn't exist
if [ ! -f "resources/icon.png" ]; then
    log_info "Creating placeholder icon..."
    # Create a simple SVG and convert it (requires ImageMagick or similar)
    if command -v convert &> /dev/null; then
        # Create SVG
        cat > resources/icon.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" fill="#007ACC"/>
  <text x="64" y="64" text-anchor="middle" dominant-baseline="middle" font-family="Arial" font-size="48" fill="white">🚀</text>
  <text x="64" y="90" text-anchor="middle" dominant-baseline="middle" font-family="Arial" font-size="12" fill="white">Git Hooks</text>
</svg>
EOF
        convert resources/icon.svg resources/icon.png
        rm resources/icon.svg
        log_success "Created extension icon"
    else
        log_warning "ImageMagick not found. Creating simple text icon."
        # Create a simple text file as placeholder
        echo "🚀 Git Hooks Extension Icon" > resources/icon.txt
    fi
fi

# Compile the extension
log_info "Compiling TypeScript..."
if npm run compile; then
    log_success "TypeScript compilation successful"
else
    log_error "TypeScript compilation failed"
    exit 1
fi

# Run linter
log_info "Running linter..."
if npm run lint; then
    log_success "Linting passed"
else
    log_warning "Linting found issues (check output above)"
fi

# Package the extension
log_info "Packaging extension..."
if npm run vsce-package; then
    log_success "Extension packaged successfully"
    VSIX_FILE=$(ls *.vsix 2>/dev/null | head -n1)
    if [ -n "$VSIX_FILE" ]; then
        log_success "Created: $VSIX_FILE"
    fi
else
    log_warning "Extension packaging failed (may need manual installation)"
fi

# Setup workspace integration
log_info "Setting up workspace integration..."

# Check if we're in a git repository
WORKSPACE_ROOT="$(pwd)"
while [ "$WORKSPACE_ROOT" != "/" ]; do
    if [ -d "$WORKSPACE_ROOT/.git" ]; then
        break
    fi
    WORKSPACE_ROOT="$(dirname "$WORKSPACE_ROOT")"
done

if [ "$WORKSPACE_ROOT" = "/" ]; then
    log_warning "Not in a git repository - hooks won't work without git"
else
    log_success "Found git repository at: $WORKSPACE_ROOT"
    
    # Check if interactive hook framework exists
    HOOK_FRAMEWORK_PATH="$WORKSPACE_ROOT/tools/git-hooks/interactive-hook-framework.sh"
    if [ -f "$HOOK_FRAMEWORK_PATH" ]; then
        log_success "Found interactive hook framework"
    else
        log_warning "Interactive hook framework not found at: $HOOK_FRAMEWORK_PATH"
        log_info "The extension will work but hooks need to be installed separately"
    fi
fi

# Create launch configuration for development
log_info "Creating VS Code launch configuration..."
mkdir -p .vscode
cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Run Extension",
            "type": "extensionHost",
            "request": "launch",
            "args": [
                "--extensionDevelopmentPath=${workspaceFolder}"
            ],
            "outFiles": [
                "${workspaceFolder}/out/**/*.js"
            ],
            "preLaunchTask": "${workspaceFolder}/npm: compile"
        },
        {
            "name": "Extension Tests",
            "type": "extensionHost",
            "request": "launch",
            "args": [
                "--extensionDevelopmentPath=${workspaceFolder}",
                "--extensionTestsPath=${workspaceFolder}/out/test/suite/index"
            ],
            "outFiles": [
                "${workspaceFolder}/out/test/**/*.js"
            ],
            "preLaunchTask": "${workspaceFolder}/npm: compile"
        }
    ]
}
EOF

# Create tasks configuration
cat > .vscode/tasks.json << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "type": "npm",
            "script": "compile",
            "group": "build",
            "presentation": {
                "reveal": "silent"
            },
            "problemMatcher": [
                "$tsc"
            ]
        },
        {
            "type": "npm",
            "script": "watch",
            "group": "build",
            "presentation": {
                "reveal": "silent"
            },
            "problemMatcher": [
                "$tsc-watch"
            ],
            "isBackground": true
        }
    ]
}
EOF

log_success "Created VS Code development configuration"

# Installation instructions
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║                    🎉 Setup Complete!                        ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Next steps:"
echo "  1. Install the extension:"
if [ -n "${VSIX_FILE:-}" ]; then
    echo "     code --install-extension $VSIX_FILE"
else
    echo "     - Open VS Code in this directory"
    echo "     - Press F5 to run the extension in a new Extension Host window"
fi

echo ""
echo "  2. Or develop the extension:"
echo "     - Open this folder in VS Code"
echo "     - Press F5 to launch Extension Host"
echo "     - Make changes and reload to test"

echo ""
echo "  3. Use the extension:"
echo "     - Open a git repository in VS Code"
echo "     - Stage some files (git add or Source Control panel)"
echo "     - Click the Git Hooks icon in the Activity Bar"
echo "     - Click '⚡ Run Hooks on Staged Files'"

echo ""
log_info "Development commands:"
echo "  npm run compile    - Compile TypeScript"
echo "  npm run watch      - Watch for changes"
echo "  npm run lint       - Run linter"
echo "  npm run package    - Build production bundle"
echo "  npm run vsce-package - Create .vsix file"

echo ""
log_success "Happy coding! 🚀"
