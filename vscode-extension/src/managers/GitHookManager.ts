import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { spawn } from 'child_process';
import { ConfigurationManager } from './ConfigurationManager';

export interface FileAnalysisResult {
    filePath: string;
    fileName: string;
    status: 'needs_enhancement' | 'enhanced' | 'error' | 'skipped';
    suggestions: EnhancementSuggestion[];
    originalContent: string;
    enhancedContent?: string;
    hookResults: HookResult[];
}

export interface EnhancementSuggestion {
    id: string;
    type: 'header' | 'documentation' | 'formatting' | 'security' | 'quality' | 'tone';
    description: string;
    original: string;
    enhanced: string;
    range: vscode.Range;
    severity: 'info' | 'warning' | 'error';
    hookName: string;
}

export interface HookResult {
    hookName: string;
    status: 'success' | 'error' | 'skipped';
    message: string;
    suggestions: EnhancementSuggestion[];
    executionTime: number;
}

export interface StagedFile {
    path: string;
    status: string;
    size: number;
}

export class GitHookManager {
    private configManager: ConfigurationManager;

    constructor(configManager: ConfigurationManager) {
        this.configManager = configManager;
    }

    public async getStagedFiles(): Promise<StagedFile[]> {
        return new Promise((resolve, reject) => {
            const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
            if (!workspaceRoot) {
                resolve([]);
                return;
            }

            const gitProcess = spawn('git', ['diff', '--cached', '--name-status'], {
                cwd: workspaceRoot,
                stdio: ['pipe', 'pipe', 'pipe']
            });

            let output = '';
            let errorOutput = '';

            gitProcess.stdout.on('data', (data) => {
                output += data.toString();
            });

            gitProcess.stderr.on('data', (data) => {
                errorOutput += data.toString();
            });

            gitProcess.on('close', (code) => {
                if (code !== 0) {
                    if (errorOutput.includes('not a git repository')) {
                        resolve([]);
                    } else {
                        reject(new Error(`Git command failed: ${errorOutput}`));
                    }
                    return;
                }

                const files: StagedFile[] = [];
                const lines = output.split('\n').filter(line => line.trim());

                for (const line of lines) {
                    const [status, filePath] = line.split('\t');
                    if (filePath) {
                        const fullPath = path.join(workspaceRoot, filePath);
                        let size = 0;
                        try {
                            size = fs.existsSync(fullPath) ? fs.statSync(fullPath).size : 0;
                        } catch {
                            // File might be deleted
                        }

                        files.push({
                            path: filePath,
                            status: this.getStatusDescription(status),
                            size
                        });
                    }
                }

                resolve(files);
            });
        });
    }

    public async analyzeFiles(
        filePaths: string[], 
        progressCallback?: (current: number, total: number) => void
    ): Promise<FileAnalysisResult[]> {
        const config = this.configManager.getConfiguration();
        const results: FileAnalysisResult[] = [];
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;

        if (!workspaceRoot) {
            throw new Error('No workspace folder found');
        }

        for (let i = 0; i < filePaths.length; i++) {
            progressCallback?.(i + 1, filePaths.length);

            const filePath = path.isAbsolute(filePaths[i]) 
                ? filePaths[i] 
                : path.join(workspaceRoot, filePaths[i]);

            try {
                // Check file size
                const stats = fs.statSync(filePath);
                if (stats.size > config.maxFileSize) {
                    results.push({
                        filePath,
                        fileName: path.basename(filePath),
                        status: 'skipped',
                        suggestions: [],
                        originalContent: '',
                        hookResults: [{
                            hookName: 'system',
                            status: 'skipped',
                            message: `File too large (${this.formatFileSize(stats.size)})`,
                            suggestions: [],
                            executionTime: 0
                        }]
                    });
                    continue;
                }

                const originalContent = fs.readFileSync(filePath, 'utf8');
                const result = await this.analyzeFile(filePath, originalContent);
                results.push(result);

            } catch (error) {
                results.push({
                    filePath,
                    fileName: path.basename(filePath),
                    status: 'error',
                    suggestions: [],
                    originalContent: '',
                    hookResults: [{
                        hookName: 'system',
                        status: 'error',
                        message: `Error analyzing file: ${error}`,
                        suggestions: [],
                        executionTime: 0
                    }]
                });
            }
        }

        return results;
    }

    public async runHooks(filePaths?: string[]): Promise<FileAnalysisResult[]> {
        const targetFiles = filePaths || (await this.getStagedFiles()).map(f => f.path);
        return this.analyzeFiles(targetFiles);
    }

    public async acceptChanges(fileId: string, changes: EnhancementSuggestion[]): Promise<void> {
        try {
            const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
            if (!workspaceRoot) {
                throw new Error('No workspace folder');
            }

            const filePath = path.isAbsolute(fileId) ? fileId : path.join(workspaceRoot, fileId);
            let content = fs.readFileSync(filePath, 'utf8');

            // Apply changes in reverse order to maintain correct positions
            const sortedChanges = changes.sort((a, b) => b.range.start.line - a.range.start.line);

            for (const change of sortedChanges) {
                const lines = content.split('\n');
                const startLine = change.range.start.line;
                const endLine = change.range.end.line;

                // Replace the content
                lines.splice(startLine, endLine - startLine + 1, change.enhanced);
                content = lines.join('\n');
            }

            // Backup original file
            const config = this.configManager.getConfiguration();
            if (config.backupOriginalFiles) {
                const backupPath = filePath + '.backup-' + Date.now();
                fs.copyFileSync(filePath, backupPath);
            }

            // Write enhanced content
            fs.writeFileSync(filePath, content);

            if (config.enableNotifications) {
                vscode.window.showInformationMessage(
                    `✅ Applied ${changes.length} enhancement(s) to ${path.basename(filePath)}`
                );
            }

        } catch (error) {
            vscode.window.showErrorMessage(`Failed to accept changes: ${error}`);
            throw error;
        }
    }

    public async declineChanges(fileId: string): Promise<void> {
        const config = this.configManager.getConfiguration();
        if (config.enableNotifications) {
            vscode.window.showInformationMessage(`❌ Declined enhancements for ${path.basename(fileId)}`);
        }
    }

    private async analyzeFile(filePath: string, content: string): Promise<FileAnalysisResult> {
        const config = this.configManager.getConfiguration();
        const fileName = path.basename(filePath);
        const hookResults: HookResult[] = [];
        const allSuggestions: EnhancementSuggestion[] = [];

        // Run each enabled hook
        for (const hookName of config.enabledHooks) {
            try {
                const startTime = Date.now();
                const result = await this.runSingleHook(hookName, filePath, content);
                const executionTime = Date.now() - startTime;

                hookResults.push({
                    hookName,
                    status: 'success',
                    message: `Found ${result.suggestions.length} suggestions`,
                    suggestions: result.suggestions,
                    executionTime
                });

                allSuggestions.push(...result.suggestions);

            } catch (error) {
                hookResults.push({
                    hookName,
                    status: 'error',
                    message: `Hook failed: ${error}`,
                    suggestions: [],
                    executionTime: 0
                });
            }
        }

        // Generate enhanced content if we have suggestions
        let enhancedContent: string | undefined;
        if (allSuggestions.length > 0) {
            enhancedContent = this.applyAllSuggestions(content, allSuggestions);
        }

        return {
            filePath,
            fileName,
            status: allSuggestions.length > 0 ? 'needs_enhancement' : 'enhanced',
            suggestions: allSuggestions,
            originalContent: content,
            enhancedContent,
            hookResults
        };
    }

    private async runSingleHook(hookName: string, filePath: string, content: string): Promise<{ suggestions: EnhancementSuggestion[] }> {
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
        if (!workspaceRoot) {
            throw new Error('No workspace folder');
        }

        const hookScriptPath = path.join(workspaceRoot, 'tools', 'git-hooks', `${hookName}-hook.sh`);
        
        if (!fs.existsSync(hookScriptPath)) {
            throw new Error(`Hook script not found: ${hookScriptPath}`);
        }

        return new Promise((resolve, reject) => {
            const hookProcess = spawn('bash', [hookScriptPath, filePath], {
                cwd: workspaceRoot,
                stdio: ['pipe', 'pipe', 'pipe'],
                env: {
                    ...process.env,
                    INTERACTIVE_MODE: 'false',
                    VSCODE_INTEGRATION: 'true'
                }
            });

            let output = '';
            let errorOutput = '';

            hookProcess.stdout.on('data', (data) => {
                output += data.toString();
            });

            hookProcess.stderr.on('data', (data) => {
                errorOutput += data.toString();
            });

            hookProcess.on('close', (code) => {
                if (code !== 0) {
                    reject(new Error(`Hook failed with code ${code}: ${errorOutput}`));
                    return;
                }

                try {
                    const suggestions = this.parseHookOutput(output, content, hookName);
                    resolve({ suggestions });
                } catch (error) {
                    reject(new Error(`Failed to parse hook output: ${error}`));
                }
            });
        });
    }

    private parseHookOutput(output: string, originalContent: string, hookName: string): EnhancementSuggestion[] {
        const suggestions: EnhancementSuggestion[] = [];
        const lines = originalContent.split('\n');

        // Parse hook output for suggestions
        // Expected format: SUGGESTION:type:line:description:original:enhanced
        const suggestionLines = output.split('\n').filter(line => line.startsWith('SUGGESTION:'));

        for (const suggestionLine of suggestionLines) {
            try {
                const parts = suggestionLine.split(':');
                if (parts.length >= 6) {
                    const [, type, lineStr, description, original, enhanced] = parts;
                    const lineNumber = parseInt(lineStr, 10);

                    if (lineNumber >= 0 && lineNumber < lines.length) {
                        suggestions.push({
                            id: `${hookName}-${lineNumber}-${Date.now()}`,
                            type: type as any,
                            description,
                            original,
                            enhanced,
                            range: new vscode.Range(lineNumber, 0, lineNumber, lines[lineNumber].length),
                            severity: this.getSeverityFromType(type),
                            hookName
                        });
                    }
                }
            } catch (error) {
                console.warn('Failed to parse suggestion line:', suggestionLine, error);
            }
        }

        return suggestions;
    }

    private applyAllSuggestions(content: string, suggestions: EnhancementSuggestion[]): string {
        let enhancedContent = content;
        const lines = enhancedContent.split('\n');

        // Sort suggestions by line number in reverse order
        const sortedSuggestions = suggestions.sort((a, b) => b.range.start.line - a.range.start.line);

        for (const suggestion of sortedSuggestions) {
            const lineIndex = suggestion.range.start.line;
            if (lineIndex >= 0 && lineIndex < lines.length) {
                lines[lineIndex] = suggestion.enhanced;
            }
        }

        return lines.join('\n');
    }

    private getSeverityFromType(type: string): 'info' | 'warning' | 'error' {
        switch (type) {
            case 'security':
                return 'error';
            case 'quality':
            case 'documentation':
                return 'warning';
            default:
                return 'info';
        }
    }

    private getStatusDescription(status: string): string {
        switch (status) {
            case 'A': return 'Added';
            case 'M': return 'Modified';
            case 'D': return 'Deleted';
            case 'R': return 'Renamed';
            case 'C': return 'Copied';
            case 'U': return 'Unmerged';
            default: return status;
        }
    }

    private formatFileSize(bytes: number): string {
        const sizes = ['B', 'KB', 'MB', 'GB'];
        if (bytes === 0) return '0 B';
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
    }
}
