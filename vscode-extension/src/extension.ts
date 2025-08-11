import * as vscode from 'vscode';
import { InteractiveHooksProvider } from './providers/InteractiveHooksProvider';
import { DiffEditorProvider } from './providers/DiffEditorProvider';
import { HookBuilder } from './builders/HookBuilder';
import { GitHookManager } from './managers/GitHookManager';
import { ConfigurationManager } from './managers/ConfigurationManager';

export function activate(context: vscode.ExtensionContext) {
    console.log('🚀 Interactive Git Hooks extension is now active!');

    // Initialize managers
    const configManager = new ConfigurationManager();
    const gitHookManager = new GitHookManager(configManager);
    const hookBuilder = new HookBuilder();

    // Initialize providers
    const hooksProvider = new InteractiveHooksProvider(gitHookManager, configManager);
    const diffEditorProvider = new DiffEditorProvider();

    // Register views
    const hooksView = vscode.window.createTreeView('interactiveGitHooks', {
        treeDataProvider: hooksProvider,
        showCollapseAll: true,
        canSelectMany: true
    });

    // Register custom editors
    context.subscriptions.push(
        vscode.window.registerCustomEditorProvider(
            'interactiveGitHooks.diffEditor',
            diffEditorProvider,
            {
                webviewOptions: {
                    retainContextWhenHidden: true,
                    enableCommandUris: true
                }
            }
        )
    );

    // Register commands
    context.subscriptions.push(
        // Main panel command
        vscode.commands.registerCommand('interactiveGitHooks.openPanel', async () => {
            await openInteractivePanel(gitHookManager, configManager);
        }),

        // Run hooks command
        vscode.commands.registerCommand('interactiveGitHooks.runHooks', async () => {
            await runInteractiveHooks(gitHookManager, hooksProvider);
        }),

        // Create hook command
        vscode.commands.registerCommand('interactiveGitHooks.createHook', async () => {
            await openHookBuilder(hookBuilder);
        }),

        // Configuration command
        vscode.commands.registerCommand('interactiveGitHooks.configureHooks', async () => {
            await openConfigurationEditor(configManager);
        }),

        // Diff commands
        vscode.commands.registerCommand('interactiveGitHooks.showDiff', async (item) => {
            await showEnhancementDiff(item, diffEditorProvider);
        }),

        vscode.commands.registerCommand('interactiveGitHooks.acceptAll', async (item) => {
            await acceptAllChanges(item, hooksProvider);
        }),

        vscode.commands.registerCommand('interactiveGitHooks.acceptPartial', async (item) => {
            await acceptPartialChanges(item, hooksProvider);
        }),

        vscode.commands.registerCommand('interactiveGitHooks.decline', async (item) => {
            await declineChanges(item, hooksProvider);
        }),

        vscode.commands.registerCommand('interactiveGitHooks.editManually', async (item) => {
            await editManually(item);
        })
    );

    // Watch for git changes
    const gitExtension = vscode.extensions.getExtension('vscode.git');
    if (gitExtension) {
        gitExtension.activate().then(git => {
            const repos = git.exports.getAPI(1).repositories;
            repos.forEach((repo: any) => {
                repo.state.onDidChange(() => {
                    hooksProvider.refresh();
                });
            });
        });
    }

    // Auto-run hooks on commit (if enabled)
    context.subscriptions.push(
        vscode.workspace.onDidSaveTextDocument(async (document) => {
            const config = configManager.getConfiguration();
            if (config.autoRunOnSave) {
                await runHooksForDocument(document, gitHookManager);
            }
        })
    );

    // Status bar
    const statusBarItem = vscode.window.createStatusBarItem(
        vscode.StatusBarAlignment.Left,
        100
    );
    statusBarItem.command = 'interactiveGitHooks.openPanel';
    statusBarItem.text = '$(git-commit) Git Hooks';
    statusBarItem.tooltip = 'Open Interactive Git Hooks';
    statusBarItem.show();
    context.subscriptions.push(statusBarItem);

    console.log('✅ Interactive Git Hooks extension fully initialized');
}

// ═══════════════════════════════════════════════════════════════════════════════════
// Command Implementations
// ═══════════════════════════════════════════════════════════════════════════════════

async function openInteractivePanel(
    gitHookManager: GitHookManager,
    configManager: ConfigurationManager
) {
    const panel = vscode.window.createWebviewPanel(
        'interactiveGitHooks',
        '🚀 Interactive Git Hooks',
        vscode.ViewColumn.One,
        {
            enableScripts: true,
            retainContextWhenHidden: true,
            localResourceRoots: [
                vscode.Uri.joinPath(vscode.extensions.getExtension('LukhasAI.interactive-git-hooks')!.extensionUri, 'resources')
            ]
        }
    );

    panel.webview.html = await getMainPanelHtml(panel.webview, gitHookManager);

    panel.webview.onDidReceiveMessage(async (message) => {
        switch (message.command) {
            case 'runHooks':
                await gitHookManager.runHooks(message.files || []);
                break;
            case 'acceptChanges':
                await gitHookManager.acceptChanges(message.fileId, message.changes);
                break;
            case 'declineChanges':
                await gitHookManager.declineChanges(message.fileId);
                break;
            case 'editManually':
                await openFileForEditing(message.filePath);
                break;
            case 'saveConfiguration':
                await configManager.saveConfiguration(message.config);
                break;
        }
    });
}

async function runInteractiveHooks(
    gitHookManager: GitHookManager,
    hooksProvider: InteractiveHooksProvider
) {
    try {
        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: '🔍 Analyzing files...',
            cancellable: true
        }, async (progress, token) => {
            const stagedFiles = await gitHookManager.getStagedFiles();
            
            if (stagedFiles.length === 0) {
                vscode.window.showInformationMessage('No staged files to analyze');
                return;
            }

            progress.report({ increment: 20, message: `Found ${stagedFiles.length} staged files` });

            const results = await gitHookManager.analyzeFiles(stagedFiles, (current, total) => {
                progress.report({ 
                    increment: (current / total) * 60,
                    message: `Analyzing file ${current}/${total}`
                });
            });

            progress.report({ increment: 20, message: 'Opening interactive interface...' });

            if (results.length > 0) {
                await openEnhancementInterface(results);
                hooksProvider.refresh();
            } else {
                vscode.window.showInformationMessage('✅ All files look good! No enhancements needed.');
            }
        });
    } catch (error) {
        vscode.window.showErrorMessage(`Error running hooks: ${error}`);
    }
}

async function openHookBuilder(hookBuilder: HookBuilder) {
    const panel = vscode.window.createWebviewPanel(
        'hookBuilder',
        '🛠️ Hook Builder',
        vscode.ViewColumn.One,
        {
            enableScripts: true,
            retainContextWhenHidden: true
        }
    );

    panel.webview.html = await getHookBuilderHtml(panel.webview, hookBuilder);

    panel.webview.onDidReceiveMessage(async (message) => {
        switch (message.command) {
            case 'previewHook':
                const preview = await hookBuilder.generatePreview(message.config);
                panel.webview.postMessage({ command: 'showPreview', preview });
                break;
            case 'saveHook':
                await hookBuilder.saveHook(message.config);
                vscode.window.showInformationMessage('✅ Hook saved successfully!');
                break;
            case 'testHook':
                const testResult = await hookBuilder.testHook(message.config);
                panel.webview.postMessage({ command: 'testResult', result: testResult });
                break;
        }
    });
}

async function openConfigurationEditor(configManager: ConfigurationManager) {
    const document = await vscode.workspace.openTextDocument({
        content: JSON.stringify(configManager.getConfiguration(), null, 2),
        language: 'json'
    });
    
    const editor = await vscode.window.showTextDocument(document);
    
    // Add save listener for this document
    const disposable = vscode.workspace.onDidSaveTextDocument(async (savedDoc) => {
        if (savedDoc === document) {
            try {
                const config = JSON.parse(savedDoc.getText());
                await configManager.saveConfiguration(config);
                vscode.window.showInformationMessage('✅ Configuration saved!');
                disposable.dispose();
            } catch (error) {
                vscode.window.showErrorMessage(`Invalid JSON: ${error}`);
            }
        }
    });
}

async function showEnhancementDiff(item: any, diffEditorProvider: DiffEditorProvider) {
    const uri = vscode.Uri.parse(`interactive-git-hooks:${item.filePath}?enhancement=${item.id}`);
    await vscode.commands.executeCommand('vscode.openWith', uri, 'interactiveGitHooks.diffEditor');
}

async function acceptAllChanges(item: any, hooksProvider: InteractiveHooksProvider) {
    const result = await vscode.window.showInformationMessage(
        `Accept all enhancements for ${item.label}?`,
        { modal: true },
        'Accept All',
        'Cancel'
    );

    if (result === 'Accept All') {
        // Apply all changes
        await item.applyAllChanges();
        vscode.window.showInformationMessage(`✅ Applied all enhancements to ${item.label}`);
        hooksProvider.refresh();
    }
}

async function acceptPartialChanges(item: any, hooksProvider: InteractiveHooksProvider) {
    const changes = item.getSelectableChanges();
    const selected = await vscode.window.showQuickPick(changes, {
        canPickMany: true,
        placeHolder: 'Select changes to apply'
    });

    if (selected && selected.length > 0) {
        await item.applyPartialChanges(selected);
        vscode.window.showInformationMessage(`✅ Applied ${selected.length} enhancement(s) to ${item.label}`);
        hooksProvider.refresh();
    }
}

async function declineChanges(item: any, hooksProvider: InteractiveHooksProvider) {
    const result = await vscode.window.showWarningMessage(
        `Decline all enhancements for ${item.label}?`,
        { modal: true },
        'Decline',
        'Cancel'
    );

    if (result === 'Decline') {
        await item.decline();
        vscode.window.showInformationMessage(`❌ Declined enhancements for ${item.label}`);
        hooksProvider.refresh();
    }
}

async function editManually(item: any) {
    const document = await vscode.workspace.openTextDocument(item.filePath);
    const editor = await vscode.window.showTextDocument(document, vscode.ViewColumn.Beside);
    
    // Highlight suggested changes
    const decorationType = vscode.window.createTextEditorDecorationType({
        backgroundColor: 'rgba(255, 255, 0, 0.2)',
        border: '1px solid yellow'
    });

    const ranges = item.getChangeRanges();
    editor.setDecorations(decorationType, ranges);

    // Show information message
    vscode.window.showInformationMessage(
        'Manual edit mode: Highlighted areas show suggested changes',
        'Show Suggestions',
        'Done'
    ).then(selection => {
        if (selection === 'Show Suggestions') {
            // Show suggestions in hover or quick pick
            showManualEditSuggestions(item, editor);
        } else if (selection === 'Done') {
            decorationType.dispose();
        }
    });
}

async function openEnhancementInterface(results: any[]) {
    // Open each file in diff view
    for (const result of results) {
        const originalUri = vscode.Uri.file(result.filePath);
        const enhancedUri = vscode.Uri.parse(`interactive-git-hooks:${result.filePath}?enhanced=true`);
        
        await vscode.commands.executeCommand(
            'vscode.diff',
            originalUri,
            enhancedUri,
            `${result.fileName} (Enhanced)`,
            { preview: true }
        );
    }
}

async function openFileForEditing(filePath: string) {
    const document = await vscode.workspace.openTextDocument(filePath);
    await vscode.window.showTextDocument(document);
}

async function runHooksForDocument(document: vscode.TextDocument, gitHookManager: GitHookManager) {
    if (document.uri.scheme === 'file') {
        const results = await gitHookManager.analyzeFiles([document.fileName]);
        if (results.length > 0) {
            vscode.window.showInformationMessage(
                `Found ${results.length} potential enhancement(s)`,
                'Review',
                'Ignore'
            ).then(selection => {
                if (selection === 'Review') {
                    openEnhancementInterface(results);
                }
            });
        }
    }
}

async function showManualEditSuggestions(item: any, editor: vscode.TextEditor) {
    const suggestions = item.getSuggestions();
    const quickPick = vscode.window.createQuickPick();
    quickPick.items = suggestions.map((suggestion: any) => ({
        label: suggestion.title,
        description: suggestion.description,
        detail: suggestion.preview,
        suggestion: suggestion
    }));
    quickPick.placeholder = 'Select a suggestion to apply';
    quickPick.onDidChangeSelection(([item]) => {
        if (item) {
            // Apply suggestion to editor
            const edit = new vscode.WorkspaceEdit();
            edit.replace(editor.document.uri, item.suggestion.range, item.suggestion.newText);
            vscode.workspace.applyEdit(edit);
        }
    });
    quickPick.onDidHide(() => quickPick.dispose());
    quickPick.show();
}

// ═══════════════════════════════════════════════════════════════════════════════════
// HTML Generation Functions
// ═══════════════════════════════════════════════════════════════════════════════════

async function getMainPanelHtml(webview: vscode.Webview, gitHookManager: GitHookManager): Promise<string> {
    const stagedFiles = await gitHookManager.getStagedFiles();
    
    return `
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Interactive Git Hooks</title>
            <style>
                body {
                    font-family: var(--vscode-font-family);
                    padding: 20px;
                    color: var(--vscode-foreground);
                    background-color: var(--vscode-editor-background);
                }
                .header {
                    display: flex;
                    align-items: center;
                    margin-bottom: 20px;
                }
                .header h1 {
                    margin: 0 0 0 10px;
                    color: var(--vscode-textLink-foreground);
                }
                .file-list {
                    border: 1px solid var(--vscode-panel-border);
                    border-radius: 4px;
                    margin: 10px 0;
                }
                .file-item {
                    padding: 12px;
                    border-bottom: 1px solid var(--vscode-panel-border);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                .file-item:last-child {
                    border-bottom: none;
                }
                .file-info {
                    display: flex;
                    flex-direction: column;
                }
                .file-path {
                    font-weight: bold;
                    margin-bottom: 4px;
                }
                .file-status {
                    font-size: 0.9em;
                    color: var(--vscode-descriptionForeground);
                }
                .actions {
                    display: flex;
                    gap: 8px;
                }
                .btn {
                    background: var(--vscode-button-background);
                    color: var(--vscode-button-foreground);
                    border: none;
                    padding: 6px 12px;
                    border-radius: 2px;
                    cursor: pointer;
                    font-size: 13px;
                }
                .btn:hover {
                    background: var(--vscode-button-hoverBackground);
                }
                .btn-secondary {
                    background: var(--vscode-button-secondaryBackground);
                    color: var(--vscode-button-secondaryForeground);
                }
                .btn-secondary:hover {
                    background: var(--vscode-button-secondaryHoverBackground);
                }
                .empty-state {
                    text-align: center;
                    padding: 40px;
                    color: var(--vscode-descriptionForeground);
                }
                .main-actions {
                    display: flex;
                    gap: 12px;
                    margin-bottom: 20px;
                }
                .status-indicator {
                    width: 8px;
                    height: 8px;
                    border-radius: 50%;
                    margin-right: 8px;
                }
                .status-staged { background: var(--vscode-gitDecoration-addedResourceForeground); }
                .status-modified { background: var(--vscode-gitDecoration-modifiedResourceForeground); }
                .status-untracked { background: var(--vscode-gitDecoration-untrackedResourceForeground); }
            </style>
        </head>
        <body>
            <div class="header">
                <span style="font-size: 24px;">🚀</span>
                <h1>Interactive Git Hooks</h1>
            </div>
            
            <div class="main-actions">
                <button class="btn" onclick="runHooks()">
                    <span style="margin-right: 6px;">▶️</span>
                    Run Hooks on Staged Files
                </button>
                <button class="btn btn-secondary" onclick="createHook()">
                    <span style="margin-right: 6px;">➕</span>
                    Create New Hook
                </button>
                <button class="btn btn-secondary" onclick="configure()">
                    <span style="margin-right: 6px;">⚙️</span>
                    Configure
                </button>
            </div>

            ${stagedFiles.length > 0 ? `
                <h3>Staged Files (${stagedFiles.length})</h3>
                <div class="file-list">
                    ${stagedFiles.map(file => `
                        <div class="file-item">
                            <div class="file-info">
                                <div class="file-path">
                                    <span class="status-indicator status-staged"></span>
                                    ${file.path}
                                </div>
                                <div class="file-status">${file.status}</div>
                            </div>
                            <div class="actions">
                                <button class="btn btn-secondary" onclick="previewFile('${file.path}')">
                                    👁️ Preview
                                </button>
                                <button class="btn" onclick="runHooksForFile('${file.path}')">
                                    ⚡ Enhance
                                </button>
                            </div>
                        </div>
                    `).join('')}
                </div>
            ` : `
                <div class="empty-state">
                    <h3>No staged files</h3>
                    <p>Stage some files to see enhancement options here.</p>
                </div>
            `}

            <script>
                const vscode = acquireVsCodeApi();

                function runHooks() {
                    vscode.postMessage({ command: 'runHooks' });
                }

                function createHook() {
                    vscode.postMessage({ command: 'createHook' });
                }

                function configure() {
                    vscode.postMessage({ command: 'configure' });
                }

                function previewFile(filePath) {
                    vscode.postMessage({ command: 'previewFile', filePath });
                }

                function runHooksForFile(filePath) {
                    vscode.postMessage({ command: 'runHooks', files: [filePath] });
                }
            </script>
        </body>
        </html>
    `;
}

async function getHookBuilderHtml(webview: vscode.Webview, hookBuilder: HookBuilder): Promise<string> {
    return `
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Hook Builder</title>
            <style>
                body {
                    font-family: var(--vscode-font-family);
                    padding: 20px;
                    color: var(--vscode-foreground);
                    background-color: var(--vscode-editor-background);
                }
                .builder-container {
                    max-width: 800px;
                    margin: 0 auto;
                }
                .section {
                    margin-bottom: 30px;
                    padding: 20px;
                    border: 1px solid var(--vscode-panel-border);
                    border-radius: 4px;
                }
                .section h3 {
                    margin-top: 0;
                    color: var(--vscode-textLink-foreground);
                }
                .form-group {
                    margin-bottom: 15px;
                }
                .form-group label {
                    display: block;
                    margin-bottom: 5px;
                    font-weight: bold;
                }
                .form-control {
                    width: 100%;
                    padding: 8px;
                    border: 1px solid var(--vscode-input-border);
                    background: var(--vscode-input-background);
                    color: var(--vscode-input-foreground);
                    border-radius: 2px;
                }
                .form-control:focus {
                    outline: 1px solid var(--vscode-focusBorder);
                }
                select.form-control {
                    height: 32px;
                }
                textarea.form-control {
                    min-height: 100px;
                    resize: vertical;
                }
                .btn {
                    background: var(--vscode-button-background);
                    color: var(--vscode-button-foreground);
                    border: none;
                    padding: 8px 16px;
                    border-radius: 2px;
                    cursor: pointer;
                    margin-right: 8px;
                }
                .btn:hover {
                    background: var(--vscode-button-hoverBackground);
                }
                .btn-secondary {
                    background: var(--vscode-button-secondaryBackground);
                    color: var(--vscode-button-secondaryForeground);
                }
                .preview-area {
                    background: var(--vscode-textCodeBlock-background);
                    border: 1px solid var(--vscode-panel-border);
                    border-radius: 4px;
                    padding: 15px;
                    font-family: var(--vscode-editor-font-family);
                    font-size: var(--vscode-editor-font-size);
                    white-space: pre-wrap;
                    max-height: 400px;
                    overflow-y: auto;
                }
                .pattern-list {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 8px;
                    margin-top: 8px;
                }
                .pattern-tag {
                    background: var(--vscode-badge-background);
                    color: var(--vscode-badge-foreground);
                    padding: 4px 8px;
                    border-radius: 12px;
                    font-size: 12px;
                    cursor: pointer;
                }
                .pattern-tag:hover {
                    opacity: 0.8;
                }
                .pattern-tag.selected {
                    background: var(--vscode-button-background);
                }
            </style>
        </head>
        <body>
            <div class="builder-container">
                <h1>🛠️ Hook Builder</h1>
                <p>Create a custom git hook without any coding experience!</p>

                <div class="section">
                    <h3>📋 Basic Information</h3>
                    <div class="form-group">
                        <label for="hookName">Hook Name</label>
                        <input type="text" id="hookName" class="form-control" placeholder="My Custom Hook">
                    </div>
                    <div class="form-group">
                        <label for="hookDescription">Description</label>
                        <textarea id="hookDescription" class="form-control" placeholder="What does this hook do?"></textarea>
                    </div>
                    <div class="form-group">
                        <label for="hookEmoji">Icon (Emoji)</label>
                        <input type="text" id="hookEmoji" class="form-control" placeholder="🎯" maxlength="2">
                    </div>
                </div>

                <div class="section">
                    <h3>📁 File Targeting</h3>
                    <div class="form-group">
                        <label for="filePatterns">File Patterns (one per line)</label>
                        <textarea id="filePatterns" class="form-control" placeholder="*.py&#10;*.js&#10;*.md"></textarea>
                        <small>Use glob patterns like *.py, src/**/*.js, etc.</small>
                    </div>
                </div>

                <div class="section">
                    <h3>🔍 What to Look For</h3>
                    <div class="form-group">
                        <label>Common Patterns</label>
                        <div class="pattern-list">
                            <span class="pattern-tag" onclick="togglePattern(this, 'missing-docstring')">Missing Docstrings</span>
                            <span class="pattern-tag" onclick="togglePattern(this, 'hardcoded-values')">Hardcoded Values</span>
                            <span class="pattern-tag" onclick="togglePattern(this, 'long-lines')">Long Lines</span>
                            <span class="pattern-tag" onclick="togglePattern(this, 'missing-tests')">Missing Tests</span>
                            <span class="pattern-tag" onclick="togglePattern(this, 'security-issues')">Security Issues</span>
                            <span class="pattern-tag" onclick="togglePattern(this, 'code-smells')">Code Smells</span>
                            <span class="pattern-tag" onclick="togglePattern(this, 'missing-headers')">Missing Headers</span>
                            <span class="pattern-tag" onclick="togglePattern(this, 'inconsistent-formatting')">Inconsistent Formatting</span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="customPatterns">Custom Search Patterns</label>
                        <textarea id="customPatterns" class="form-control" placeholder="TODO|FIXME|XXX"></textarea>
                        <small>Use regex patterns to find specific issues</small>
                    </div>
                </div>

                <div class="section">
                    <h3>✨ What to Fix</h3>
                    <div class="form-group">
                        <label for="fixActions">Fix Actions</label>
                        <textarea id="fixActions" class="form-control" placeholder="Add header comment&#10;Replace TODO with implementation&#10;Format code"></textarea>
                        <small>Describe what should be fixed (one action per line)</small>
                    </div>
                    <div class="form-group">
                        <label for="replacements">Text Replacements (find|replace)</label>
                        <textarea id="replacements" class="form-control" placeholder="TODO|IMPLEMENTED&#10;fixme|fixed"></textarea>
                        <small>Simple find and replace patterns (find|replace, one per line)</small>
                    </div>
                </div>

                <div class="section">
                    <h3>⚙️ Behavior</h3>
                    <div class="form-group">
                        <label for="defaultAction">Default Action</label>
                        <select id="defaultAction" class="form-control">
                            <option value="ask">Ask user for each file</option>
                            <option value="preview">Show preview by default</option>
                            <option value="auto">Auto-apply fixes</option>
                            <option value="skip">Skip by default</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="severity">Severity Level</label>
                        <select id="severity" class="form-control">
                            <option value="info">Info (Blue)</option>
                            <option value="warning">Warning (Yellow)</option>
                            <option value="error">Error (Red)</option>
                        </select>
                    </div>
                </div>

                <div class="section">
                    <h3>👀 Preview</h3>
                    <button class="btn" onclick="generatePreview()">Generate Preview</button>
                    <button class="btn btn-secondary" onclick="testHook()">Test Hook</button>
                    <div id="previewArea" class="preview-area" style="display: none; margin-top: 15px;"></div>
                </div>

                <div class="section">
                    <button class="btn" onclick="saveHook()">💾 Save Hook</button>
                    <button class="btn btn-secondary" onclick="exportHook()">📤 Export</button>
                </div>
            </div>

            <script>
                const vscode = acquireVsCodeApi();
                let selectedPatterns = [];

                function togglePattern(element, pattern) {
                    if (selectedPatterns.includes(pattern)) {
                        selectedPatterns = selectedPatterns.filter(p => p !== pattern);
                        element.classList.remove('selected');
                    } else {
                        selectedPatterns.push(pattern);
                        element.classList.add('selected');
                    }
                }

                function generatePreview() {
                    const config = gatherConfiguration();
                    vscode.postMessage({ command: 'previewHook', config });
                }

                function testHook() {
                    const config = gatherConfiguration();
                    vscode.postMessage({ command: 'testHook', config });
                }

                function saveHook() {
                    const config = gatherConfiguration();
                    vscode.postMessage({ command: 'saveHook', config });
                }

                function exportHook() {
                    const config = gatherConfiguration();
                    const blob = new Blob([JSON.stringify(config, null, 2)], { type: 'application/json' });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = (config.name || 'custom-hook').toLowerCase().replace(/\\s+/g, '-') + '.json';
                    a.click();
                }

                function gatherConfiguration() {
                    return {
                        name: document.getElementById('hookName').value,
                        description: document.getElementById('hookDescription').value,
                        emoji: document.getElementById('hookEmoji').value,
                        filePatterns: document.getElementById('filePatterns').value.split('\\n').filter(p => p.trim()),
                        selectedPatterns: selectedPatterns,
                        customPatterns: document.getElementById('customPatterns').value,
                        fixActions: document.getElementById('fixActions').value.split('\\n').filter(a => a.trim()),
                        replacements: document.getElementById('replacements').value.split('\\n').filter(r => r.trim() && r.includes('|')),
                        defaultAction: document.getElementById('defaultAction').value,
                        severity: document.getElementById('severity').value
                    };
                }

                window.addEventListener('message', event => {
                    const message = event.data;
                    switch (message.command) {
                        case 'showPreview':
                            const previewArea = document.getElementById('previewArea');
                            previewArea.textContent = message.preview;
                            previewArea.style.display = 'block';
                            break;
                        case 'testResult':
                            alert('Test Result: ' + JSON.stringify(message.result, null, 2));
                            break;
                    }
                });
            </script>
        </body>
        </html>
    `;
}

export function deactivate() {
    console.log('👋 Interactive Git Hooks extension deactivated');
}
