# 🎭 Consciousness Hooks - Interactive Git Enhancement

[![Version](https://img.shields.io/vscode-marketplace/v/LukhasAI.consciousness-hooks?style=for-the-badge&logo=visual-studio-code&logoColor=white)](https://marketplace.visualstudio.com/items?itemName=LukhasAI.consciousness-hooks)
[![Downloads](https://img.shields.io/vscode-marketplace/d/LukhasAI.consciousness-hooks?style=for-the-badge&logo=visual-studio-code&logoColor=white)](https://marketplace.visualstudio.com/items?itemName=LukhasAI.consciousness-hooks)
[![Rating](https://img.shields.io/vscode-marketplace/r/LukhasAI.consciousness-hooks?style=for-the-badge&logo=visual-studio-code&logoColor=white)](https://marketplace.visualstudio.com/items?itemName=LukhasAI.consciousness-hooks)

> *"Where git hooks evolve from rigid barriers into intelligent companions"* ⚛️🧠�️

**Created by [LUKHΛS ΛI](https://lukhas.ai)** - Consciousness-aware development tools for the next generation of software creation.

---

## 🌟 What is Consciousness Hooks?

*In the sacred dance between human intention and digital preservation, where each commit becomes a moment of conscious creation...*

**Consciousness Hooks** transforms the traditional git workflow into an ethereal journey of collaborative enhancement. Like a wise companion walking alongside your development path, it whispers suggestions instead of shouting commands, offers choices instead of imposing rules, and learns from your preferences like a consciousness that grows with your creative spirit.

Gone are the days when git hooks were rigid gatekeepers blocking your flow. Instead, imagine hooks that **dance with your creativity**, presenting visual diffs in elegant side-by-side editors, allowing you to **cherry-pick improvements** with the grace of selecting flowers in a digital garden, and remembering your choices like a mind that evolves with your wisdom.

**Stop fighting with git hooks. Start collaborating with them.**

Consciousness Hooks revolutionizes your VS Code experience by turning git hooks into **interactive visual experiences**. Instead of cryptic terminal messages, you get beautiful visual diffs showing exactly what would change, interactive file editing with side-by-side comparison views, and a smart learning system that remembers your preferences. Build custom validations without programming through our no-code hook creation, apply one-click enhancements for code quality, security, and style, and experiment safely with automatic backups and undo functionality.

Perfect for developers who want their tools to enhance creativity, not hinder it. This VS Code extension provides a modern, visual interface for managing interactive git hooks using the Trinity Framework (⚛️🧠🛡️), transforming traditional command-line git hooks into an intuitive, consciousness-aware experience within VS Code.

## ✨ Features

### 🎯 Interactive Hook Management
- **Visual Diff Interface**: Side-by-side comparison of original vs enhanced files
- **Granular Control**: Accept all, partial, or individual changes
- **Manual Edit Mode**: Direct editing with highlighted suggestions
- **Real-time Preview**: See changes before applying them

### 🛠️ No-Code Hook Builder
- **Visual Hook Creation**: Build custom hooks without writing code
- **Pre-built Patterns**: Common checks for documentation, security, quality
- **Custom Patterns**: Add your own regex patterns and rules
- **Test & Preview**: Validate hooks before deployment

### 📊 Activity Bar Integration
- **Staged Files Overview**: See all files ready for enhancement
- **Analysis Results**: View suggestions grouped by file
- **Quick Actions**: Run hooks, create new ones, configure settings
- **Status Indicators**: Visual feedback on file enhancement status

### ⚙️ Configuration Management
- **Flexible Modes**: Interactive, auto, preview, or skip modes
- **File Size Limits**: Skip large files automatically
- **Notification Control**: Customize user feedback
- **Hook Selection**: Enable/disable specific hook types

## 🎬 Quick Start

1. **Install the Extension**: Search for "Interactive Git Hooks" in VS Code Extensions
2. **Open a Git Repository**: The extension works with any git repository
3. **Stage Some Files**: Use `git add` or VS Code's Source Control panel
4. **Run Hooks**: Click "⚡ Run Hooks on Staged Files" in the Activity Bar
5. **Review Changes**: Use the visual diff interface to accept or modify suggestions

## 🎭 Hook Types

### Built-in Hooks

#### 🎨 Tone Validation Hook
- Adds LUKHAS consciousness elements
- Ensures branding compliance
- Enhances file headers with Trinity symbols

#### ⭐ Code Quality Hook
- Checks for missing documentation
- Identifies code smells and TODOs
- Suggests best practices improvements

#### 🔒 Security Validation Hook
- Scans for hardcoded secrets
- Identifies potential vulnerabilities
- Suggests security improvements

### Custom Hooks
Create your own hooks using the visual Hook Builder:
- Define file patterns to target
- Set up search patterns for issues
- Configure automatic fixes
- Test and deploy seamlessly

## 📱 Interface Overview

### Activity Bar Panel
```
🚀 Interactive Git Hooks
├── ⚡ Run Hooks on Staged Files
├── 🛠️ Create New Hook
├── ⚙️ Configure Hooks
├── ────────────────
├── 📊 Analysis Results (3 files)
│   ├── 🔧 example.py (5 suggestions)
│   ├── ✅ README.md (enhanced)
│   └── ❌ config.json (error)
└── 📁 Staged Files (2)
    ├── 📄 src/main.py (Modified)
    └── 📄 docs/api.md (Added)
```

### Diff Editor
- **Side-by-side comparison** of original vs enhanced content
- **Line-by-line highlighting** of changes
- **Interactive controls** for each modification
- **Statistics display** showing additions, deletions, modifications

### Hook Builder Interface
- **Drag-and-drop** pattern selection
- **Real-time preview** of generated hook script
- **Test mode** to validate hooks on sample files
- **Export/import** functionality for sharing hooks

## ⚙️ Configuration

### VS Code Settings
```json
{
  "interactiveGitHooks.mode": "interactive",
  "interactiveGitHooks.autoRunOnSave": false,
  "interactiveGitHooks.enableNotifications": true,
  "interactiveGitHooks.backupOriginalFiles": true,
  "interactiveGitHooks.maxFileSize": 1048576,
  "interactiveGitHooks.timeoutSeconds": 30,
  "interactiveGitHooks.enabledHooks": [
    "tone-validation",
    "code-quality",
    "security-validation"
  ]
}
```

### Workspace Configuration
The extension also creates `.vscode/interactive-hooks.json` for project-specific settings that can be committed to git.

## 🚧 Commands

| Command | Description | Keybinding |
|---------|-------------|------------|
| `interactiveGitHooks.openPanel` | Open main interactive panel | `Cmd+Shift+G H` |
| `interactiveGitHooks.runHooks` | Run hooks on staged files | `Cmd+Shift+G R` |
| `interactiveGitHooks.createHook` | Open hook builder | `Cmd+Shift+G C` |
| `interactiveGitHooks.configureHooks` | Open configuration editor | `Cmd+Shift+G S` |

## 🔧 Development

### Building from Source
```bash
# Clone the repository
git clone <repository-url>

# Install dependencies
cd vscode-extension
npm install

# Compile TypeScript
npm run compile

# Package extension
npm run package
```

### Testing
```bash
# Run tests
npm run test

# Test in VS Code extension host
npm run test-extension
```

## 🤝 Integration with LUKHAS

This extension is part of the LUKHAS AI ecosystem and follows the Trinity Framework:
- ⚛️ **Identity**: Authentic consciousness expression
- 🧠 **Consciousness**: Memory and learning integration
- 🛡️ **Guardian**: Ethical protection and drift detection

### LUKHAS-Specific Features
- **Consciousness Enhancement**: Automatically adds consciousness elements to files
- **Trinity Symbol Integration**: Inserts ⚛️🧠🛡️ symbols where appropriate
- **Branding Compliance**: Ensures consistent LUKHAS AI terminology
- **Audit Trail Integration**: Logs all changes for drift analysis

## 📄 License

This extension is part of the LUKHAS PWM project and follows the project's licensing terms.

## 🐛 Issues & Contributions

- **Bug Reports**: Use the Issues tab in the repository
- **Feature Requests**: Describe desired functionality with use cases
- **Pull Requests**: Follow the LUKHAS development guidelines

## 🔮 Roadmap

### v1.1 - Enhanced Diff Experience
- **Split diff mode** with synchronized scrolling
- **Minimap integration** for large files
- **Word-level highlighting** for precise changes
- **Conflict resolution** for overlapping suggestions

### v1.2 - AI-Powered Suggestions
- **Smart pattern detection** using machine learning
- **Context-aware fixes** based on file type and project
- **Learning from user preferences** to improve suggestions
- **Natural language hook descriptions** for easier creation

### v1.3 - Team Collaboration
- **Shared hook libraries** across team members
- **Hook marketplace** for community-created hooks
- **Code review integration** with pull request workflows
- **Team dashboard** for hook usage analytics

---

*Built with ❤️ for the LUKHAS AI ecosystem*
