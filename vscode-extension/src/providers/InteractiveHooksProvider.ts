import * as vscode from 'vscode';
import { FileAnalysisResult } from '../managers/GitHookManager';

export class InteractiveHooksProvider implements vscode.TreeDataProvider<HookItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<HookItem | undefined | null | void> = new vscode.EventEmitter<HookItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<HookItem | undefined | null | void> = this._onDidChangeTreeData.event;

    private analysisResults: FileAnalysisResult[] = [];

    constructor(
        private gitHookManager: any, // GitHookManager causes circular import for now
        private configManager: any   // ConfigurationManager
    ) {}

    refresh(): void {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element: HookItem): vscode.TreeItem {
        return element;
    }

    async getChildren(element?: HookItem): Promise<HookItem[]> {
        if (!element) {
            // Root level - show analysis results or empty state
            return this.getRootItems();
        }

        if (element.contextValue === 'fileAnalysis') {
            // File level - show suggestions for this file
            return this.getFileSuggestions(element);
        }

        return [];
    }

    private async getRootItems(): Promise<HookItem[]> {
        const items: HookItem[] = [];

        // Add quick actions
        items.push(new HookItem(
            '⚡ Run Hooks on Staged Files',
            'runHooks',
            vscode.TreeItemCollapsibleState.None,
            {
                command: 'interactiveGitHooks.runHooks',
                title: 'Run Hooks',
                arguments: []
            }
        ));

        items.push(new HookItem(
            '🛠️ Create New Hook',
            'createHook',
            vscode.TreeItemCollapsibleState.None,
            {
                command: 'interactiveGitHooks.createHook',
                title: 'Create Hook',
                arguments: []
            }
        ));

        items.push(new HookItem(
            '⚙️ Configure Hooks',
            'configureHooks',
            vscode.TreeItemCollapsibleState.None,
            {
                command: 'interactiveGitHooks.configureHooks',
                title: 'Configure',
                arguments: []
            }
        ));

        // Add separator
        items.push(new HookItem(
            '────────────────',
            'separator',
            vscode.TreeItemCollapsibleState.None
        ));

        // Add analysis results if any
        if (this.analysisResults.length > 0) {
            items.push(new HookItem(
                `📊 Analysis Results (${this.analysisResults.length} files)`,
                'analysisHeader',
                vscode.TreeItemCollapsibleState.Expanded
            ));

            for (const result of this.analysisResults) {
                const icon = this.getFileStatusIcon(result.status);
                const label = `${icon} ${result.fileName}`;
                const description = `${result.suggestions.length} suggestions`;
                
                const fileItem = new HookItem(
                    label,
                    'fileAnalysis',
                    result.suggestions.length > 0 ? vscode.TreeItemCollapsibleState.Collapsed : vscode.TreeItemCollapsibleState.None
                );
                
                fileItem.description = description;
                fileItem.tooltip = `${result.filePath}\n${result.suggestions.length} enhancement suggestions`;
                fileItem.resourceUri = vscode.Uri.file(result.filePath);
                fileItem.analysisResult = result;

                items.push(fileItem);
            }
        } else {
            // Show staged files if no analysis results
            try {
                const stagedFiles = await this.gitHookManager.getStagedFiles();
                if (stagedFiles.length > 0) {
                    items.push(new HookItem(
                        `📁 Staged Files (${stagedFiles.length})`,
                        'stagedHeader',
                        vscode.TreeItemCollapsibleState.Expanded
                    ));

                    for (const file of stagedFiles) {
                        const fileItem = new HookItem(
                            `📄 ${file.path}`,
                            'stagedFile',
                            vscode.TreeItemCollapsibleState.None,
                            {
                                command: 'interactiveGitHooks.runHooks',
                                title: 'Analyze File',
                                arguments: [[file.path]]
                            }
                        );
                        
                        fileItem.description = file.status;
                        fileItem.tooltip = `${file.path}\nStatus: ${file.status}`;
                        
                        items.push(fileItem);
                    }
                } else {
                    items.push(new HookItem(
                        '📭 No staged files',
                        'emptyState',
                        vscode.TreeItemCollapsibleState.None
                    ));
                }
            } catch (error) {
                items.push(new HookItem(
                    '❌ Error loading files',
                    'error',
                    vscode.TreeItemCollapsibleState.None
                ));
            }
        }

        return items;
    }

    private getFileSuggestions(fileElement: HookItem): HookItem[] {
        if (!fileElement.analysisResult) {
            return [];
        }

        const suggestions = fileElement.analysisResult.suggestions;
        const items: HookItem[] = [];

        // Add file actions first
        items.push(new HookItem(
            '✅ Accept All Changes',
            'acceptAll',
            vscode.TreeItemCollapsibleState.None,
            {
                command: 'interactiveGitHooks.acceptAll',
                title: 'Accept All',
                arguments: [fileElement]
            }
        ));

        items.push(new HookItem(
            '🎯 Accept Partial Changes',
            'acceptPartial',
            vscode.TreeItemCollapsibleState.None,
            {
                command: 'interactiveGitHooks.acceptPartial',
                title: 'Accept Partial',
                arguments: [fileElement]
            }
        ));

        items.push(new HookItem(
            '👁️ Show Diff',
            'showDiff',
            vscode.TreeItemCollapsibleState.None,
            {
                command: 'interactiveGitHooks.showDiff',
                title: 'Show Diff',
                arguments: [fileElement]
            }
        ));

        items.push(new HookItem(
            '✏️ Edit Manually',
            'editManually',
            vscode.TreeItemCollapsibleState.None,
            {
                command: 'interactiveGitHooks.editManually',
                title: 'Edit Manually',
                arguments: [fileElement]
            }
        ));

        items.push(new HookItem(
            '❌ Decline Changes',
            'decline',
            vscode.TreeItemCollapsibleState.None,
            {
                command: 'interactiveGitHooks.decline',
                title: 'Decline',
                arguments: [fileElement]
            }
        ));

        // Add separator
        items.push(new HookItem(
            '────────────────',
            'separator',
            vscode.TreeItemCollapsibleState.None
        ));

        // Add individual suggestions
        for (const suggestion of suggestions) {
            const icon = this.getSuggestionIcon(suggestion.type);
            const severityIcon = this.getSeverityIcon(suggestion.severity);
            
            const suggestionItem = new HookItem(
                `${icon} ${suggestion.description}`,
                'suggestion',
                vscode.TreeItemCollapsibleState.None
            );
            
            suggestionItem.description = `${severityIcon} ${suggestion.hookName}`;
            suggestionItem.tooltip = `${suggestion.description}\n\nOriginal: ${suggestion.original}\nEnhanced: ${suggestion.enhanced}`;
            suggestionItem.suggestion = suggestion;

            items.push(suggestionItem);
        }

        return items;
    }

    public updateAnalysisResults(results: FileAnalysisResult[]): void {
        this.analysisResults = results;
        this.refresh();
    }

    public clearAnalysisResults(): void {
        this.analysisResults = [];
        this.refresh();
    }

    private getFileStatusIcon(status: string): string {
        switch (status) {
            case 'needs_enhancement': return '🔧';
            case 'enhanced': return '✅';
            case 'error': return '❌';
            case 'skipped': return '⏭️';
            default: return '📄';
        }
    }

    private getSuggestionIcon(type: string): string {
        switch (type) {
            case 'header': return '📝';
            case 'documentation': return '📚';
            case 'formatting': return '🎨';
            case 'security': return '🔒';
            case 'quality': return '⭐';
            case 'tone': return '🎭';
            default: return '💡';
        }
    }

    private getSeverityIcon(severity: string): string {
        switch (severity) {
            case 'error': return '🔴';
            case 'warning': return '🟡';
            case 'info': return '🔵';
            default: return '⚪';
        }
    }
}

export class HookItem extends vscode.TreeItem {
    public analysisResult?: FileAnalysisResult;
    public suggestion?: any; // EnhancementSuggestion

    constructor(
        public readonly label: string,
        public readonly contextValue: string,
        public readonly collapsibleState: vscode.TreeItemCollapsibleState,
        public readonly command?: vscode.Command
    ) {
        super(label, collapsibleState);
        this.contextValue = contextValue;
    }

    // Methods for GitHookManager integration
    public async applyAllChanges(): Promise<void> {
        if (this.analysisResult && this.analysisResult.suggestions.length > 0) {
            // This would integrate with GitHookManager.acceptChanges
            vscode.commands.executeCommand('interactiveGitHooks.acceptChanges', {
                fileId: this.analysisResult.filePath,
                changes: this.analysisResult.suggestions
            });
        }
    }

    public async applyPartialChanges(selectedSuggestions: any[]): Promise<void> {
        if (this.analysisResult) {
            vscode.commands.executeCommand('interactiveGitHooks.acceptChanges', {
                fileId: this.analysisResult.filePath,
                changes: selectedSuggestions
            });
        }
    }

    public async decline(): Promise<void> {
        if (this.analysisResult) {
            vscode.commands.executeCommand('interactiveGitHooks.declineChanges', {
                fileId: this.analysisResult.filePath
            });
        }
    }

    public getSelectableChanges(): any[] {
        if (!this.analysisResult) {
            return [];
        }

        return this.analysisResult.suggestions.map(suggestion => ({
            label: suggestion.description,
            description: `${suggestion.hookName} - Line ${suggestion.range.start.line + 1}`,
            detail: `${suggestion.original} → ${suggestion.enhanced}`,
            suggestion: suggestion
        }));
    }

    public getChangeRanges(): vscode.Range[] {
        if (!this.analysisResult) {
            return [];
        }

        return this.analysisResult.suggestions.map(s => s.range);
    }

    public getSuggestions(): any[] {
        if (!this.analysisResult) {
            return [];
        }

        return this.analysisResult.suggestions.map(suggestion => ({
            title: suggestion.description,
            description: `${suggestion.hookName} suggestion`,
            preview: `${suggestion.original} → ${suggestion.enhanced}`,
            range: suggestion.range,
            newText: suggestion.enhanced,
            suggestion: suggestion
        }));
    }
}
