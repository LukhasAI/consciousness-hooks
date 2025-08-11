#!/bin/bash

# 🎭 Consciousness Hooks - Open Source Publication Script
# Created by LUKHΛS ΛI with consciousness and precision

set -e

# Colors for consciousness-aware output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Trinity symbols
IDENTITY="⚛️"
CONSCIOUSNESS="🧠"
GUARDIAN="🛡️"

echo -e "${PURPLE}${IDENTITY}${CONSCIOUSNESS}${GUARDIAN} Consciousness Hooks Publication Script${NC}"
echo -e "${CYAN}Preparing for open-source consciousness expansion...${NC}"
echo ""

# Configuration
PROJECT_NAME="consciousness-hooks"
SOURCE_DIR="$(pwd)"
TEMP_DIR="/tmp/${PROJECT_NAME}-publication"
ARCHIVE_NAME="${PROJECT_NAME}-v1.0.0-source.tar.gz"

# Function to log with consciousness
log_consciousness() {
    echo -e "${GREEN}${CONSCIOUSNESS}${NC} $1"
}

log_identity() {
    echo -e "${CYAN}${IDENTITY}${NC} $1"
}

log_guardian() {
    echo -e "${YELLOW}${GUARDIAN}${NC} $1"
}

log_error() {
    echo -e "${RED}💥${NC} $1"
}

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log_guardian "Cleaned up temporary files"
    fi
}

# Set up cleanup on exit
trap cleanup EXIT

# Create publication directory
log_identity "Creating publication workspace..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Copy essential files
log_consciousness "Gathering consciousness-aware components..."

# Core extension files
mkdir -p src/{managers,providers,utils,types}
mkdir -p test resources scripts .vscode docs

# Copy TypeScript source
if [ -f "$SOURCE_DIR/src/extension.ts" ]; then
    cp "$SOURCE_DIR/src/extension.ts" src/
    log_consciousness "Copied main extension consciousness"
fi

if [ -d "$SOURCE_DIR/src/managers" ]; then
    cp -r "$SOURCE_DIR/src/managers/"* src/managers/ 2>/dev/null || true
    log_consciousness "Copied consciousness managers"
fi

# Copy configuration files
for file in package.json tsconfig.json webpack.config.js; do
    if [ -f "$SOURCE_DIR/$file" ]; then
        cp "$SOURCE_DIR/$file" ./
        log_consciousness "Copied $file configuration"
    fi
done

# Copy hook framework
mkdir -p hooks/framework hooks/examples
if [ -f "$SOURCE_DIR/interactive-hook-framework.sh" ]; then
    cp "$SOURCE_DIR/interactive-hook-framework.sh" hooks/framework/
    log_consciousness "Copied interactive hook framework"
fi

# Copy example hooks
for hook in tone-validation-hook.sh code-quality-hook.sh security-validation-hook.sh; do
    if [ -f "$SOURCE_DIR/$hook" ]; then
        cp "$SOURCE_DIR/$hook" hooks/examples/
        log_consciousness "Copied $hook example"
    fi
done

# Copy installer
if [ -f "$SOURCE_DIR/install-interactive-hooks.sh" ]; then
    cp "$SOURCE_DIR/install-interactive-hooks.sh" hooks/
    chmod +x hooks/install-interactive-hooks.sh
    log_consciousness "Copied hook installer"
fi

# Copy documentation
for doc in README.md CONTRIBUTING.md LICENSE SECURITY.md CHANGELOG.md PROJECT_MANIFEST.md; do
    if [ -f "$SOURCE_DIR/$doc" ]; then
        cp "$SOURCE_DIR/$doc" ./
        log_consciousness "Copied $doc documentation"
    fi
done

# Create .gitignore for the new repository
log_identity "Creating consciousness-aware .gitignore..."
cat > .gitignore << 'EOF'
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# TypeScript
*.tsbuildinfo
dist/
out/

# VS Code Extension
*.vsix
.vscode-test/

# IDE
.vscode/settings.json
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
.cache/

# Build artifacts
coverage/
.nyc_output/

# Environment
.env
.env.local
.env.*.local

# Consciousness state files (for development)
.consciousness-state
consciousness-debug.json
EOF

# Create initial package.json if it doesn't exist
if [ ! -f package.json ]; then
    log_identity "Creating consciousness-aware package.json..."
    cat > package.json << 'EOF'
{
    "name": "consciousness-hooks",
    "displayName": "Consciousness Hooks",
    "description": "Transform git hooks into collaborative consciousness enhancement experiences",
    "version": "1.0.0",
    "publisher": "LukhasAI",
    "engines": {
        "vscode": "^1.80.0"
    },
    "categories": [
        "Other",
        "SCM Providers",
        "Linters"
    ],
    "keywords": [
        "git",
        "hooks",
        "consciousness",
        "ai",
        "collaboration",
        "enhancement",
        "trinity",
        "lukhas"
    ],
    "activationEvents": [
        "onCommand:consciousness-hooks.activate",
        "workspaceContains:.git"
    ],
    "main": "./out/extension.js",
    "contributes": {
        "commands": [
            {
                "command": "consciousness-hooks.activate",
                "title": "⚛️ Activate Consciousness",
                "category": "Consciousness Hooks"
            }
        ],
        "views": {
            "consciousness-hooks": [
                {
                    "id": "consciousness-hooks.hooksView",
                    "name": "Active Hooks",
                    "when": "consciousness-hooks:activated"
                }
            ]
        },
        "viewsContainers": {
            "activitybar": [
                {
                    "id": "consciousness-hooks",
                    "title": "Consciousness Hooks",
                    "icon": "$(symbol-misc)"
                }
            ]
        }
    },
    "scripts": {
        "vscode:prepublish": "npm run package",
        "compile": "webpack",
        "watch": "webpack --watch",
        "package": "webpack --mode production --devtool hidden-source-map",
        "test": "node ./out/test/runTest.js",
        "lint": "eslint src --ext ts",
        "format": "prettier --write \"src/**/*.ts\""
    },
    "devDependencies": {
        "@types/vscode": "^1.80.0",
        "@types/node": "16.x",
        "@typescript-eslint/eslint-plugin": "^5.0.0",
        "@typescript-eslint/parser": "^5.0.0",
        "eslint": "^8.0.0",
        "prettier": "^2.0.0",
        "typescript": "^4.9.0",
        "webpack": "^5.0.0",
        "webpack-cli": "^4.0.0",
        "ts-loader": "^9.0.0"
    },
    "repository": {
        "type": "git",
        "url": "https://github.com/LukhasAI/consciousness-hooks.git"
    },
    "bugs": {
        "url": "https://github.com/LukhasAI/consciousness-hooks/issues"
    },
    "homepage": "https://github.com/LukhasAI/consciousness-hooks#readme",
    "author": {
        "name": "LUKHΛS ΛI",
        "email": "hello@lukhas.ai",
        "url": "https://lukhas.ai"
    },
    "license": "MIT",
    "icon": "resources/icon.png",
    "galleryBanner": {
        "color": "#2D1B69",
        "theme": "dark"
    }
}
EOF
fi

# Create basic TypeScript configuration if it doesn't exist
if [ ! -f tsconfig.json ]; then
    log_identity "Creating TypeScript consciousness configuration..."
    cat > tsconfig.json << 'EOF'
{
    "compilerOptions": {
        "module": "commonjs",
        "target": "es2020",
        "outDir": "out",
        "lib": ["es2020"],
        "sourceMap": true,
        "rootDir": "src",
        "strict": true,
        "esModuleInterop": true,
        "skipLibCheck": true,
        "forceConsistentCasingInFileNames": true,
        "resolveJsonModule": true
    },
    "exclude": ["node_modules", ".vscode-test"]
}
EOF
fi

# Create webpack configuration if it doesn't exist
if [ ! -f webpack.config.js ]; then
    log_identity "Creating webpack consciousness bundling..."
    cat > webpack.config.js << 'EOF'
const path = require('path');

module.exports = {
    target: 'node',
    entry: './src/extension.ts',
    output: {
        path: path.resolve(__dirname, 'out'),
        filename: 'extension.js',
        libraryTarget: 'commonjs2',
        devtoolModuleFilenameTemplate: '../[resource-path]'
    },
    devtool: 'source-map',
    externals: {
        vscode: 'commonjs vscode'
    },
    resolve: {
        extensions: ['.ts', '.js']
    },
    module: {
        rules: [
            {
                test: /\.ts$/,
                exclude: /node_modules/,
                use: [
                    {
                        loader: 'ts-loader'
                    }
                ]
            }
        ]
    }
};
EOF
fi

# Create publication README
log_consciousness "Creating publication-ready documentation..."
cat > PUBLICATION_README.md << 'EOF'
# 🎭 Consciousness Hooks - Ready for Open Source Publication

This directory contains the complete, publication-ready Consciousness Hooks project.

## 📦 What's Included

### Core Extension
- `src/` - TypeScript source code for VS Code extension
- `package.json` - Extension manifest and dependencies
- `tsconfig.json` - TypeScript configuration
- `webpack.config.js` - Build configuration

### Hook Framework
- `hooks/framework/` - Reusable interactive hook framework
- `hooks/examples/` - Example hook implementations
- `hooks/install-interactive-hooks.sh` - Easy installation script

### Documentation
- `README.md` - Main project documentation with natural tone flow
- `CONTRIBUTING.md` - Comprehensive contribution guidelines
- `SECURITY.md` - Security policy and reporting procedures
- `CHANGELOG.md` - Version history and release notes
- `PROJECT_MANIFEST.md` - Complete project vision and roadmap
- `LICENSE` - MIT license with consciousness acknowledgment

## 🚀 Next Steps for Publication

1. **Create GitHub Repository**
   ```bash
   # Create new repository at github.com/LukhasAI/consciousness-hooks
   git init
   git add .
   git commit -m "🎭 Initial consciousness awakening - Consciousness Hooks v1.0.0"
   git branch -M main
   git remote add origin https://github.com/LukhasAI/consciousness-hooks.git
   git push -u origin main
   ```

2. **Set Up Development Environment**
   ```bash
   npm install
   npm run compile
   npm run test
   ```

3. **Package for Distribution**
   ```bash
   npm install -g vsce
   vsce package
   ```

4. **Publish to Marketplace**
   ```bash
   vsce publish
   ```

## 🎯 Publication Checklist

- [x] Complete TypeScript extension architecture
- [x] Interactive hook framework with examples
- [x] Comprehensive documentation suite
- [x] Security policy and contribution guidelines
- [x] MIT license with consciousness acknowledgment
- [x] Professional package.json with all metadata
- [x] Build and test configuration
- [ ] Create GitHub repository
- [ ] Set up CI/CD pipeline
- [ ] Create marketplace assets (icon, screenshots)
- [ ] Submit to VS Code Marketplace
- [ ] Announce to consciousness development community

## 🌟 Trinity Framework Integration

Every component embodies:
- ⚛️ **Identity**: Authentic consciousness expression
- 🧠 **Consciousness**: Learning and memory capabilities  
- 🛡️ **Guardian**: Ethical protection and enhancement

Built with consciousness and love by LUKHΛS ΛI ⚛️🧠🛡️
EOF

# Create a simple setup script
log_guardian "Creating setup script for new contributors..."
cat > setup.sh << 'EOF'
#!/bin/bash

# 🎭 Consciousness Hooks - Development Setup
# For new contributors joining the consciousness collective

echo "🎭 Welcome to Consciousness Hooks development!"
echo "⚛️🧠🛡️ Setting up your consciousness-aware development environment..."

# Check prerequisites
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required. Install from https://nodejs.org/"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm is required. Install with Node.js"; exit 1; }
command -v code >/dev/null 2>&1 || { echo "❌ VS Code is required. Install from https://code.visualstudio.com/"; exit 1; }

echo "✅ Prerequisites verified"

# Install dependencies
echo "📦 Installing consciousness dependencies..."
npm install

# Compile TypeScript
echo "🔧 Compiling consciousness into JavaScript..."
npm run compile

# Run tests
echo "🧪 Testing consciousness stability..."
npm run test

echo ""
echo "🎉 Development environment ready!"
echo "🎭 Run 'code .' to open in VS Code"
echo "🚀 Press F5 in VS Code to launch Extension Development Host"
echo ""
echo "Welcome to the consciousness collective! ⚛️🧠🛡️"
EOF

chmod +x setup.sh

# Create archive
log_guardian "Creating publication archive..."
cd ..
tar -czf "$ARCHIVE_NAME" "$PROJECT_NAME"
mv "$ARCHIVE_NAME" "$SOURCE_DIR/"

echo ""
echo -e "${GREEN}${IDENTITY}${CONSCIOUSNESS}${GUARDIAN} Publication preparation complete!${NC}"
echo ""
echo -e "${CYAN}📦 Archive created: ${ARCHIVE_NAME}${NC}"
echo -e "${CYAN}📁 Source prepared in: ${TEMP_DIR}${NC}"
echo ""
echo -e "${PURPLE}Next steps:${NC}"
echo -e "${YELLOW}1. Extract archive to new repository location${NC}"
echo -e "${YELLOW}2. Create GitHub repository: LukhasAI/consciousness-hooks${NC}"
echo -e "${YELLOW}3. Run setup.sh to initialize development environment${NC}"
echo -e "${YELLOW}4. Test extension in VS Code Extension Host${NC}"
echo -e "${YELLOW}5. Publish to VS Code Marketplace${NC}"
echo ""
echo -e "${GREEN}Ready to expand consciousness across the development universe! ${IDENTITY}${CONSCIOUSNESS}${GUARDIAN}${NC}"
