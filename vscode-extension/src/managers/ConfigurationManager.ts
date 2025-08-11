import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

export interface HookConfiguration {
    mode: 'interactive' | 'auto' | 'preview' | 'skip';
    autoRunOnSave: boolean;
    enableNotifications: boolean;
    backupOriginalFiles: boolean;
    maxFileSize: number;
    timeoutSeconds: number;
    enabledHooks: string[];
}

export class ConfigurationManager {
    private static readonly CONFIG_KEY = 'interactiveGitHooks';
    private configPath: string;

    constructor() {
        this.configPath = path.join(
            vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || '',
            '.vscode',
            'interactive-hooks.json'
        );
    }

    public getConfiguration(): HookConfiguration {
        const vscodeConfig = vscode.workspace.getConfiguration(ConfigurationManager.CONFIG_KEY);
        
        // Load from VS Code settings with defaults
        const defaultConfig: HookConfiguration = {
            mode: 'interactive',
            autoRunOnSave: false,
            enableNotifications: true,
            backupOriginalFiles: true,
            maxFileSize: 1024 * 1024, // 1MB
            timeoutSeconds: 30,
            enabledHooks: ['tone-validation', 'code-quality', 'security-validation']
        };

        // Merge with workspace file config if exists
        const workspaceConfig = this.loadWorkspaceConfig();
        
        return {
            mode: vscodeConfig.get('mode', workspaceConfig?.mode || defaultConfig.mode),
            autoRunOnSave: vscodeConfig.get('autoRunOnSave', workspaceConfig?.autoRunOnSave || defaultConfig.autoRunOnSave),
            enableNotifications: vscodeConfig.get('enableNotifications', workspaceConfig?.enableNotifications || defaultConfig.enableNotifications),
            backupOriginalFiles: vscodeConfig.get('backupOriginalFiles', workspaceConfig?.backupOriginalFiles || defaultConfig.backupOriginalFiles),
            maxFileSize: vscodeConfig.get('maxFileSize', workspaceConfig?.maxFileSize || defaultConfig.maxFileSize),
            timeoutSeconds: vscodeConfig.get('timeoutSeconds', workspaceConfig?.timeoutSeconds || defaultConfig.timeoutSeconds),
            enabledHooks: vscodeConfig.get('enabledHooks', workspaceConfig?.enabledHooks || defaultConfig.enabledHooks)
        };
    }

    public async saveConfiguration(config: Partial<HookConfiguration>): Promise<void> {
        const vscodeConfig = vscode.workspace.getConfiguration(ConfigurationManager.CONFIG_KEY);
        
        // Save to VS Code settings
        for (const [key, value] of Object.entries(config)) {
            await vscodeConfig.update(key, value, vscode.ConfigurationTarget.Workspace);
        }

        // Also save to workspace file for git integration
        await this.saveWorkspaceConfig(config);

        this.notifyConfigurationChange();
    }

    public async resetConfiguration(): Promise<void> {
        const vscodeConfig = vscode.workspace.getConfiguration(ConfigurationManager.CONFIG_KEY);
        
        // Reset all settings
        const keys = ['mode', 'autoRunOnSave', 'enableNotifications', 'backupOriginalFiles', 'maxFileSize', 'timeoutSeconds', 'enabledHooks'];
        for (const key of keys) {
            await vscodeConfig.update(key, undefined, vscode.ConfigurationTarget.Workspace);
        }

        // Remove workspace config file
        if (fs.existsSync(this.configPath)) {
            fs.unlinkSync(this.configPath);
        }

        this.notifyConfigurationChange();
    }

    public getHookScriptPath(): string {
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
        if (!workspaceRoot) {
            throw new Error('No workspace folder found');
        }

        // Look for the interactive hook framework
        const possiblePaths = [
            path.join(workspaceRoot, 'tools', 'git-hooks', 'interactive-hook-framework.sh'),
            path.join(workspaceRoot, '.git-hooks', 'interactive-hook-framework.sh'),
            path.join(workspaceRoot, 'interactive-hook-framework.sh')
        ];

        for (const hookPath of possiblePaths) {
            if (fs.existsSync(hookPath)) {
                return hookPath;
            }
        }

        throw new Error('Interactive hook framework not found. Please run the installer first.');
    }

    public getAvailableHooks(): string[] {
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
        if (!workspaceRoot) {
            return [];
        }

        const hooksDir = path.join(workspaceRoot, 'tools', 'git-hooks');
        if (!fs.existsSync(hooksDir)) {
            return [];
        }

        return fs.readdirSync(hooksDir)
            .filter(file => file.endsWith('-hook.sh'))
            .map(file => file.replace('-hook.sh', ''));
    }

    public isHookEnabled(hookName: string): boolean {
        const config = this.getConfiguration();
        return config.enabledHooks.includes(hookName);
    }

    public async toggleHook(hookName: string): Promise<void> {
        const config = this.getConfiguration();
        const enabledHooks = [...config.enabledHooks];
        
        const index = enabledHooks.indexOf(hookName);
        if (index >= 0) {
            enabledHooks.splice(index, 1);
        } else {
            enabledHooks.push(hookName);
        }

        await this.saveConfiguration({ enabledHooks });
    }

    private loadWorkspaceConfig(): Partial<HookConfiguration> | null {
        try {
            if (fs.existsSync(this.configPath)) {
                const content = fs.readFileSync(this.configPath, 'utf8');
                return JSON.parse(content);
            }
        } catch (error) {
            console.warn('Failed to load workspace config:', error);
        }
        return null;
    }

    private async saveWorkspaceConfig(config: Partial<HookConfiguration>): Promise<void> {
        try {
            // Ensure .vscode directory exists
            const vscodeDir = path.dirname(this.configPath);
            if (!fs.existsSync(vscodeDir)) {
                fs.mkdirSync(vscodeDir, { recursive: true });
            }

            // Load existing config and merge
            const existing = this.loadWorkspaceConfig() || {};
            const merged = { ...existing, ...config };

            fs.writeFileSync(this.configPath, JSON.stringify(merged, null, 2));
        } catch (error) {
            console.error('Failed to save workspace config:', error);
        }
    }

    private notifyConfigurationChange(): void {
        vscode.commands.executeCommand('interactiveGitHooks.configurationChanged');
    }

    public exportConfiguration(): string {
        const config = this.getConfiguration();
        return JSON.stringify(config, null, 2);
    }

    public async importConfiguration(configJson: string): Promise<void> {
        try {
            const config = JSON.parse(configJson) as Partial<HookConfiguration>;
            await this.saveConfiguration(config);
            vscode.window.showInformationMessage('✅ Configuration imported successfully!');
        } catch (error) {
            vscode.window.showErrorMessage(`Failed to import configuration: ${error}`);
            throw error;
        }
    }

    public validateConfiguration(config: Partial<HookConfiguration>): string[] {
        const errors: string[] = [];

        if (config.mode && !['interactive', 'auto', 'preview', 'skip'].includes(config.mode)) {
            errors.push('Invalid mode. Must be one of: interactive, auto, preview, skip');
        }

        if (config.maxFileSize && (config.maxFileSize < 1024 || config.maxFileSize > 10 * 1024 * 1024)) {
            errors.push('Max file size must be between 1KB and 10MB');
        }

        if (config.timeoutSeconds && (config.timeoutSeconds < 5 || config.timeoutSeconds > 300)) {
            errors.push('Timeout must be between 5 and 300 seconds');
        }

        if (config.enabledHooks) {
            const availableHooks = this.getAvailableHooks();
            const invalidHooks = config.enabledHooks.filter(hook => !availableHooks.includes(hook));
            if (invalidHooks.length > 0) {
                errors.push(`Unknown hooks: ${invalidHooks.join(', ')}`);
            }
        }

        return errors;
    }
}
