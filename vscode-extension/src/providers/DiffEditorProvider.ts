import * as vscode from 'vscode';

export class DiffEditorProvider implements vscode.CustomTextEditorProvider {
    public static register(context: vscode.ExtensionContext): vscode.Disposable {
        const provider = new DiffEditorProvider(context);
        const providerRegistration = vscode.window.registerCustomEditorProvider(
            DiffEditorProvider.viewType,
            provider
        );
        return providerRegistration;
    }

    private static readonly viewType = 'interactiveGitHooks.diffEditor';

    constructor(private readonly context: vscode.ExtensionContext) {}

    public async resolveCustomTextEditor(
        document: vscode.TextDocument,
        webviewPanel: vscode.WebviewPanel,
        _token: vscode.CancellationToken
    ): Promise<void> {
        // Set up webview options
        webviewPanel.webview.options = {
            enableScripts: true,
            localResourceRoots: [this.context.extensionUri]
        };

        // Get the file content and enhancement data
        const uri = document.uri;
        const query = new URLSearchParams(uri.query);
        const enhancementId = query.get('enhancement');
        const isEnhanced = query.get('enhanced') === 'true';

        if (isEnhanced) {
            // Show enhanced version
            webviewPanel.webview.html = await this.getEnhancedFileHtml(webviewPanel.webview, document);
        } else if (enhancementId) {
            // Show diff for specific enhancement
            webviewPanel.webview.html = await this.getDiffHtml(webviewPanel.webview, document, enhancementId);
        } else {
            // Default diff view
            webviewPanel.webview.html = await this.getDefaultDiffHtml(webviewPanel.webview, document);
        }

        // Handle messages from webview
        webviewPanel.webview.onDidReceiveMessage(async (message) => {
            switch (message.command) {
                case 'acceptChange':
                    await this.acceptChange(message.changeId, message.filePath);
                    break;
                case 'declineChange':
                    await this.declineChange(message.changeId, message.filePath);
                    break;
                case 'acceptAll':
                    await this.acceptAllChanges(message.filePath);
                    break;
                case 'declineAll':
                    await this.declineAllChanges(message.filePath);
                    break;
                case 'editManually':
                    await this.openForManualEdit(message.filePath);
                    break;
                case 'showOriginal':
                    await this.showOriginalFile(message.filePath);
                    break;
            }
        });
    }

    private async getDiffHtml(
        webview: vscode.Webview,
        document: vscode.TextDocument,
        enhancementId: string
    ): Promise<string> {
        // This would integrate with GitHookManager to get the enhancement data
        const originalContent = document.getText();
        const enhancedContent = await this.getEnhancedContent(document.uri.fsPath);
        
        return this.generateDiffHtml(webview, originalContent, enhancedContent, document.uri.fsPath);
    }

    private async getEnhancedFileHtml(
        webview: vscode.Webview,
        document: vscode.TextDocument
    ): Promise<string> {
        const enhancedContent = await this.getEnhancedContent(document.uri.fsPath);
        return this.generateEnhancedFileHtml(webview, enhancedContent, document.uri.fsPath);
    }

    private async getDefaultDiffHtml(
        webview: vscode.Webview,
        document: vscode.TextDocument
    ): Promise<string> {
        const originalContent = document.getText();
        const enhancedContent = await this.getEnhancedContent(document.uri.fsPath);
        
        return this.generateDiffHtml(webview, originalContent, enhancedContent, document.uri.fsPath);
    }

    private generateDiffHtml(
        webview: vscode.Webview,
        originalContent: string,
        enhancedContent: string,
        filePath: string
    ): Promise<string> {
        const fileName = filePath.split('/').pop() || 'file';
        
        return Promise.resolve(`
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Interactive Diff - ${fileName}</title>
                <style>
                    body {
                        font-family: var(--vscode-font-family);
                        margin: 0;
                        padding: 0;
                        background: var(--vscode-editor-background);
                        color: var(--vscode-editor-foreground);
                        height: 100vh;
                        overflow: hidden;
                    }
                    
                    .header {
                        background: var(--vscode-titleBar-activeBackground);
                        color: var(--vscode-titleBar-activeForeground);
                        padding: 12px 20px;
                        border-bottom: 1px solid var(--vscode-panel-border);
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                    }
                    
                    .header h2 {
                        margin: 0;
                        font-size: 16px;
                    }
                    
                    .header-actions {
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
                        font-size: 12px;
                    }
                    
                    .btn:hover {
                        background: var(--vscode-button-hoverBackground);
                    }
                    
                    .btn-secondary {
                        background: var(--vscode-button-secondaryBackground);
                        color: var(--vscode-button-secondaryForeground);
                    }
                    
                    .btn-danger {
                        background: var(--vscode-errorForeground);
                        color: white;
                    }
                    
                    .diff-container {
                        display: flex;
                        height: calc(100vh - 60px);
                    }
                    
                    .diff-pane {
                        flex: 1;
                        display: flex;
                        flex-direction: column;
                        border-right: 1px solid var(--vscode-panel-border);
                    }
                    
                    .diff-pane:last-child {
                        border-right: none;
                    }
                    
                    .pane-header {
                        background: var(--vscode-panel-background);
                        padding: 8px 16px;
                        border-bottom: 1px solid var(--vscode-panel-border);
                        font-weight: bold;
                        font-size: 13px;
                    }
                    
                    .pane-content {
                        flex: 1;
                        overflow: auto;
                        font-family: var(--vscode-editor-font-family);
                        font-size: var(--vscode-editor-font-size);
                        line-height: var(--vscode-editor-line-height);
                    }
                    
                    .code-content {
                        padding: 16px;
                        white-space: pre-wrap;
                        background: var(--vscode-textCodeBlock-background);
                        margin: 0;
                        min-height: 100%;
                    }
                    
                    .line-numbers {
                        background: var(--vscode-editorLineNumber-background);
                        color: var(--vscode-editorLineNumber-foreground);
                        padding: 16px 8px;
                        border-right: 1px solid var(--vscode-panel-border);
                        font-family: var(--vscode-editor-font-family);
                        font-size: var(--vscode-editor-font-size);
                        line-height: var(--vscode-editor-line-height);
                        user-select: none;
                        white-space: pre;
                        text-align: right;
                        min-width: 40px;
                    }
                    
                    .diff-line {
                        display: flex;
                        margin: 0;
                        padding: 0;
                    }
                    
                    .line-added {
                        background: rgba(0, 255, 0, 0.1);
                        border-left: 3px solid var(--vscode-gitDecoration-addedResourceForeground);
                    }
                    
                    .line-removed {
                        background: rgba(255, 0, 0, 0.1);
                        border-left: 3px solid var(--vscode-gitDecoration-deletedResourceForeground);
                    }
                    
                    .line-modified {
                        background: rgba(255, 255, 0, 0.1);
                        border-left: 3px solid var(--vscode-gitDecoration-modifiedResourceForeground);
                    }
                    
                    .enhancement-marker {
                        position: absolute;
                        right: 8px;
                        background: var(--vscode-badge-background);
                        color: var(--vscode-badge-foreground);
                        padding: 2px 6px;
                        border-radius: 8px;
                        font-size: 10px;
                        cursor: pointer;
                    }
                    
                    .enhancement-marker:hover {
                        background: var(--vscode-button-hoverBackground);
                    }
                    
                    .change-controls {
                        position: absolute;
                        right: 40px;
                        display: flex;
                        gap: 4px;
                    }
                    
                    .change-btn {
                        background: var(--vscode-button-secondaryBackground);
                        color: var(--vscode-button-secondaryForeground);
                        border: none;
                        padding: 2px 8px;
                        border-radius: 2px;
                        cursor: pointer;
                        font-size: 10px;
                    }
                    
                    .stats {
                        padding: 8px 16px;
                        background: var(--vscode-statusBar-background);
                        color: var(--vscode-statusBar-foreground);
                        border-top: 1px solid var(--vscode-panel-border);
                        font-size: 12px;
                        display: flex;
                        justify-content: space-between;
                    }
                </style>
            </head>
            <body>
                <div class="header">
                    <h2>🔍 Enhanced Diff: ${fileName}</h2>
                    <div class="header-actions">
                        <button class="btn" onclick="acceptAll()">✅ Accept All</button>
                        <button class="btn btn-secondary" onclick="editManually()">✏️ Edit Manually</button>
                        <button class="btn btn-danger" onclick="declineAll()">❌ Decline All</button>
                        <button class="btn btn-secondary" onclick="showOriginal()">👁️ Original</button>
                    </div>
                </div>
                
                <div class="diff-container">
                    <div class="diff-pane">
                        <div class="pane-header">📄 Original</div>
                        <div class="pane-content">
                            <pre class="code-content" id="original-content">${this.escapeHtml(originalContent)}</pre>
                        </div>
                    </div>
                    
                    <div class="diff-pane">
                        <div class="pane-header">✨ Enhanced</div>
                        <div class="pane-content">
                            <pre class="code-content" id="enhanced-content">${this.escapeHtml(enhancedContent)}</pre>
                        </div>
                    </div>
                </div>
                
                <div class="stats">
                    <span id="diff-stats">Analyzing changes...</span>
                    <span>File: ${fileName}</span>
                </div>
                
                <script>
                    const vscode = acquireVsCodeApi();
                    
                    function acceptAll() {
                        vscode.postMessage({
                            command: 'acceptAll',
                            filePath: '${filePath}'
                        });
                    }
                    
                    function declineAll() {
                        vscode.postMessage({
                            command: 'declineAll',
                            filePath: '${filePath}'
                        });
                    }
                    
                    function editManually() {
                        vscode.postMessage({
                            command: 'editManually',
                            filePath: '${filePath}'
                        });
                    }
                    
                    function showOriginal() {
                        vscode.postMessage({
                            command: 'showOriginal',
                            filePath: '${filePath}'
                        });
                    }
                    
                    function acceptChange(changeId) {
                        vscode.postMessage({
                            command: 'acceptChange',
                            changeId: changeId,
                            filePath: '${filePath}'
                        });
                    }
                    
                    function declineChange(changeId) {
                        vscode.postMessage({
                            command: 'declineChange',
                            changeId: changeId,
                            filePath: '${filePath}'
                        });
                    }
                    
                    // Initialize diff analysis
                    window.addEventListener('load', () => {
                        analyzeChanges();
                    });
                    
                    function analyzeChanges() {
                        const originalLines = document.getElementById('original-content').textContent.split('\\n');
                        const enhancedLines = document.getElementById('enhanced-content').textContent.split('\\n');
                        
                        let additions = 0;
                        let deletions = 0;
                        let modifications = 0;
                        
                        // Simple diff analysis
                        const maxLength = Math.max(originalLines.length, enhancedLines.length);
                        for (let i = 0; i < maxLength; i++) {
                            const original = originalLines[i] || '';
                            const enhanced = enhancedLines[i] || '';
                            
                            if (original !== enhanced) {
                                if (!original) additions++;
                                else if (!enhanced) deletions++;
                                else modifications++;
                            }
                        }
                        
                        document.getElementById('diff-stats').textContent = 
                            \`+\${additions} -\${deletions} ~\${modifications} changes\`;
                    }
                </script>
            </body>
            </html>
        `);
    }

    private generateEnhancedFileHtml(
        webview: vscode.Webview,
        content: string,
        filePath: string
    ): Promise<string> {
        const fileName = filePath.split('/').pop() || 'file';
        
        return Promise.resolve(`
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Enhanced File - ${fileName}</title>
                <style>
                    body {
                        font-family: var(--vscode-font-family);
                        margin: 0;
                        padding: 20px;
                        background: var(--vscode-editor-background);
                        color: var(--vscode-editor-foreground);
                    }
                    
                    .header {
                        margin-bottom: 20px;
                        padding-bottom: 10px;
                        border-bottom: 1px solid var(--vscode-panel-border);
                    }
                    
                    .content {
                        font-family: var(--vscode-editor-font-family);
                        font-size: var(--vscode-editor-font-size);
                        line-height: var(--vscode-editor-line-height);
                        background: var(--vscode-textCodeBlock-background);
                        padding: 16px;
                        border-radius: 4px;
                        white-space: pre-wrap;
                        overflow: auto;
                    }
                </style>
            </head>
            <body>
                <div class="header">
                    <h2>✨ Enhanced Version: ${fileName}</h2>
                    <p>This is the enhanced version with all improvements applied.</p>
                </div>
                
                <div class="content">${this.escapeHtml(content)}</div>
            </body>
            </html>
        `);
    }

    private async getEnhancedContent(filePath: string): Promise<string> {
        // This would integrate with GitHookManager to get enhanced content
        // For now, return a placeholder
        return "Enhanced content would be loaded here...";
    }

    private async acceptChange(changeId: string, filePath: string): Promise<void> {
        vscode.commands.executeCommand('interactiveGitHooks.acceptChange', changeId, filePath);
    }

    private async declineChange(changeId: string, filePath: string): Promise<void> {
        vscode.commands.executeCommand('interactiveGitHooks.declineChange', changeId, filePath);
    }

    private async acceptAllChanges(filePath: string): Promise<void> {
        vscode.commands.executeCommand('interactiveGitHooks.acceptAll', { filePath });
    }

    private async declineAllChanges(filePath: string): Promise<void> {
        vscode.commands.executeCommand('interactiveGitHooks.decline', { filePath });
    }

    private async openForManualEdit(filePath: string): Promise<void> {
        const document = await vscode.workspace.openTextDocument(filePath);
        await vscode.window.showTextDocument(document, vscode.ViewColumn.Beside);
    }

    private async showOriginalFile(filePath: string): Promise<void> {
        const document = await vscode.workspace.openTextDocument(filePath);
        await vscode.window.showTextDocument(document);
    }

    private escapeHtml(text: string): string {
        const element = document.createElement('div');
        element.innerText = text;
        return element.innerHTML;
    }
}
