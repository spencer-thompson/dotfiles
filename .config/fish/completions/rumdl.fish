# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_rumdl_global_optspecs
	string join \n color= c/config= no-config isolated h/help V/version
end

function __fish_rumdl_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_rumdl_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_rumdl_using_subcommand
	set -l cmd (__fish_rumdl_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c rumdl -n "__fish_rumdl_needs_command" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_needs_command" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_needs_command" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_needs_command" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_needs_command" -s V -l version -d 'Print version'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "check" -d 'Lint Markdown files and print warnings/errors'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "fmt" -d 'Format Markdown files and apply fixes with formatter-style exit codes'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "init" -d 'Initialize a new configuration file'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "rule" -d 'Show information about a rule or list all rules'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "explain" -d 'Explain a rule with detailed information and examples'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "config" -d 'Show configuration or query a specific key'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "server" -d 'Start the Language Server Protocol server'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "schema" -d 'Generate or check JSON schema for rumdl.toml'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "code-block-tools-docs" -d 'Generate or check the built-in code-block-tools docs table'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "import" -d 'Import and convert markdownlint configuration files'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "vscode" -d 'Install the rumdl VS Code extension'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "completions" -d 'Generate shell completion scripts'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "clean" -d 'Clear the cache'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "version" -d 'Show version information'
complete -c rumdl -n "__fish_rumdl_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s d -l disable -d 'Disable specific rules (comma-separated)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s e -l enable -l rules -d 'Enable only specific rules (comma-separated)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l extend-enable -d 'Extend the list of enabled rules (additive with config)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l extend-disable -d 'Extend the list of disabled rules (additive with config)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l fixable -d 'Only allow these rules to be fixed (comma-separated)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l unfixable -d 'Prevent these rules from being fixed (comma-separated)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l exclude -d 'Exclude specific files or directories (comma-separated glob patterns)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l include -d 'Include only specific files or directories (comma-separated glob patterns)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l respect-gitignore -d 'Respect .gitignore files when scanning directories (does not apply to explicitly provided paths)' -r -f -a "true\t''
false\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l stdin-filename -d 'Filename to use when reading from stdin (e.g., README.md)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l cache-dir -d 'Directory to store cache files (default: .rumdl_cache, or $RUMDL_CACHE_DIR, or cache-dir in config)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s o -l output -d 'Legacy alias for --output-format: text (default) or json' -r -f -a "text\t''
json\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l output-format -d 'Output format for diagnostics (default: text)' -r -f -a "text\t'One-line-per-warning with file, line, column, rule, and message (default)'
full\t'Show source lines with caret underlines highlighting the violation'
concise\t'Minimal: file:line:col rule message'
grouped\t'Warnings grouped by file with a header per file'
json\t'JSON array of all warnings (collected across files)'
json-lines\t'One JSON object per warning (streaming)'
github\t'GitHub Actions annotation format (::warning/::error)'
gitlab\t'GitLab Code Quality report (JSON)'
pylint\t'Pylint-compatible format'
azure\t'Azure Pipelines logging commands'
sarif\t'SARIF 2.1.0 for static analysis tools'
junit\t'JUnit XML for CI test reporters'"
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l flavor -d 'Markdown flavor to use: standard (also accepts gfm/github/commonmark), mkdocs, mdx, pandoc, quarto, obsidian, kramdown, azure_devops (also accepts azure/ado), or myst (also accepts mystmd)' -r -f -a "standard\t''
mkdocs\t''
mdx\t''
pandoc\t''
quarto\t''
obsidian\t''
kramdown\t''
azure_devops\t''
myst\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l fail-on -d 'Exit code behavior: \'any\' (default) exits 1 on any violation, \'warning\' on warning+error, \'error\' only on errors, \'never\' always exits 0' -r -f -a "any\t'Exit 1 on any violation (info, warning, or error)'
warning\t'Exit 1 on warning or error severity violations'
error\t'Exit 1 only on error-severity violations'
never\t'Always exit 0'"
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s f -l fix -d 'Fix issues automatically where possible'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l diff -d 'Show diff of what would be fixed instead of fixing files'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l check -d 'Exit with code 1 if any formatting changes would be made (for CI)'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s l -l list-rules -d 'Deprecated and hidden: rule listing moved to `rumdl rule`. When passed, `run_check` prints guidance to the canonical commands and exits'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l no-exclude -d 'Disable all exclude patterns'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s q -l quiet -d 'Print diagnostics, but suppress summary lines'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l show-full-path -d 'Show absolute file paths in output instead of relative paths'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l stderr -d 'Output diagnostics to stderr instead of stdout'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l no-cache -d 'Disable caching (re-check all files)'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s v -l verbose -d 'Show detailed output'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l profile -d 'Show profiling information'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l statistics -d 'Show statistics summary of rule violations'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l stdin -d 'Read from stdin instead of files'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s s -l silent -d 'Suppress diagnostics and summaries'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s w -l watch -d 'Run in watch mode by re-running whenever files change'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l force-exclude -d 'Deprecated and hidden: exclude patterns are always respected, including for explicitly provided paths (since v0.0.156), so this flag has no effect. Accepted for backward compatibility; passing it prints a deprecation notice. Use `--no-exclude` to disable exclusions instead'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand check" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s d -l disable -d 'Disable specific rules (comma-separated)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s e -l enable -l rules -d 'Enable only specific rules (comma-separated)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l extend-enable -d 'Extend the list of enabled rules (additive with config)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l extend-disable -d 'Extend the list of disabled rules (additive with config)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l fixable -d 'Only allow these rules to be fixed (comma-separated)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l unfixable -d 'Prevent these rules from being fixed (comma-separated)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l exclude -d 'Exclude specific files or directories (comma-separated glob patterns)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l include -d 'Include only specific files or directories (comma-separated glob patterns)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l respect-gitignore -d 'Respect .gitignore files when scanning directories (does not apply to explicitly provided paths)' -r -f -a "true\t''
false\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l stdin-filename -d 'Filename to use when reading from stdin (e.g., README.md)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l cache-dir -d 'Directory to store cache files (default: .rumdl_cache, or $RUMDL_CACHE_DIR, or cache-dir in config)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s o -l output -d 'Hidden legacy alias for --output-format' -r -f -a "text\t''
json\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l output-format -d 'Output format for remaining diagnostics (default: text)' -r -f -a "text\t'One-line-per-warning with file, line, column, rule, and message (default)'
full\t'Show source lines with caret underlines highlighting the violation'
concise\t'Minimal: file:line:col rule message'
grouped\t'Warnings grouped by file with a header per file'
json\t'JSON array of all warnings (collected across files)'
json-lines\t'One JSON object per warning (streaming)'
github\t'GitHub Actions annotation format (::warning/::error)'
gitlab\t'GitLab Code Quality report (JSON)'
pylint\t'Pylint-compatible format'
azure\t'Azure Pipelines logging commands'
sarif\t'SARIF 2.1.0 for static analysis tools'
junit\t'JUnit XML for CI test reporters'"
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l flavor -d 'Markdown flavor to use while formatting: standard (also accepts gfm/github/commonmark), mkdocs, mdx, pandoc, quarto, obsidian, kramdown, or azure_devops (also accepts azure/ado)' -r -f -a "standard\t''
mkdocs\t''
mdx\t''
pandoc\t''
quarto\t''
obsidian\t''
kramdown\t''
azure_devops\t''
myst\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l fail-on -d 'Hidden compatibility flag; fmt always exits with formatter-style semantics' -r -f -a "any\t'Exit 1 on any violation (info, warning, or error)'
warning\t'Exit 1 on warning or error severity violations'
error\t'Exit 1 only on error-severity violations'
never\t'Always exit 0'"
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l diff -d 'Show diff of what would be formatted instead of rewriting files'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l check -d 'Exit with code 1 if any formatting changes would be made (for CI)'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s l -l list-rules -d 'Deprecated and hidden compatibility flag from check; routed to the same guidance path as `check --list-rules`'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l no-exclude -d 'Disable all exclude patterns'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s q -l quiet -d 'Print diagnostics, but suppress summary lines'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l show-full-path -d 'Show absolute file paths in output instead of relative paths'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l stderr -d 'Output diagnostics to stderr instead of stdout'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l no-cache -d 'Disable caching (re-check all files)'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s v -l verbose -d 'Show detailed formatter output'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l profile -d 'Hidden compatibility flag from check'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l statistics -d 'Hidden compatibility flag from check'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l stdin -d 'Read Markdown from stdin instead of files'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s s -l silent -d 'Suppress diagnostics and summaries; only formatted content is emitted in stdin/stdout mode'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s w -l watch -d 'Re-run formatting whenever files change'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l force-exclude -d 'Hidden deprecated compatibility flag from check'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand fmt" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand init" -l preset -d 'Use a style preset (default, google, relaxed)' -r -f -a "default\t'Default rumdl configuration'
google\t'Google developer documentation style'
relaxed\t'Relaxed rules for existing projects'"
complete -c rumdl -n "__fish_rumdl_using_subcommand init" -s o -l output -d 'Output file path (default: .rumdl.toml)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand init" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand init" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand init" -l pyproject -d 'Generate configuration for pyproject.toml instead of .rumdl.toml'
complete -c rumdl -n "__fish_rumdl_using_subcommand init" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand init" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand init" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -s o -l output-format -d 'Output format' -r -f -a "text\t''
json\t''
json-lines\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -l category -d 'Filter by category (use --list-categories to see options)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -s f -l fixable -d 'Filter to only fixable rules'
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -l explain -d 'Include full documentation in output (for json/json-lines)'
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -l list-categories -d 'List available categories and exit'
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand rule" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand explain" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand explain" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand explain" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand explain" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand explain" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -l output -d 'Output format (e.g. toml, json)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -l defaults -d 'Show only the default configuration values'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -l no-defaults -d 'Show only non-default configuration values (exclude defaults)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -f -a "get" -d 'Query a specific config key (e.g. global.exclude or MD013.line_length)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -f -a "file" -d 'Show the absolute path of the configuration file that was loaded'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and not __fish_seen_subcommand_from get file help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from get" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from get" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from get" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from get" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from get" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from file" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from file" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from file" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from file" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from file" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from help" -f -a "get" -d 'Query a specific config key (e.g. global.exclude or MD013.line_length)'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from help" -f -a "file" -d 'Show the absolute path of the configuration file that was loaded'
complete -c rumdl -n "__fish_rumdl_using_subcommand config; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rumdl -n "__fish_rumdl_using_subcommand server" -l port -d 'TCP port to listen on (for debugging)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand server" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand server" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand server" -l stdio -d 'Compatibility flag; stdio is the default when --port is not set'
complete -c rumdl -n "__fish_rumdl_using_subcommand server" -s v -l verbose -d 'Enable verbose logging'
complete -c rumdl -n "__fish_rumdl_using_subcommand server" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand server" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand server" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -f -a "generate" -d 'Generate/update the JSON schema file'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -f -a "check" -d 'Check if the schema is up-to-date'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -f -a "print" -d 'Print the schema to stdout'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and not __fish_seen_subcommand_from generate check print help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from generate" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from generate" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from generate" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from generate" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from generate" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from check" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from check" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from check" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from check" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from check" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from print" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from print" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from print" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from print" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from print" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from help" -f -a "generate" -d 'Generate/update the JSON schema file'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from help" -f -a "check" -d 'Check if the schema is up-to-date'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from help" -f -a "print" -d 'Print the schema to stdout'
complete -c rumdl -n "__fish_rumdl_using_subcommand schema; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -f -a "generate" -d 'Generate/update the built-in tools table in docs/code-block-tools.md'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -f -a "check" -d 'Check if the built-in tools docs are up-to-date'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -f -a "print" -d 'Print the generated table to stdout'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and not __fish_seen_subcommand_from generate check print help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from generate" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from generate" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from generate" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from generate" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from generate" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from check" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from check" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from check" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from check" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from check" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from print" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from print" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from print" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from print" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from print" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from help" -f -a "generate" -d 'Generate/update the built-in tools table in docs/code-block-tools.md'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from help" -f -a "check" -d 'Check if the built-in tools docs are up-to-date'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from help" -f -a "print" -d 'Print the generated table to stdout'
complete -c rumdl -n "__fish_rumdl_using_subcommand code-block-tools-docs; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rumdl -n "__fish_rumdl_using_subcommand import" -s o -l output -d 'Output file path (default: .rumdl.toml)' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand import" -l format -d 'Output format' -r -f -a "toml\t''
json\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand import" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand import" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand import" -l dry-run -d 'Show converted config without writing to file'
complete -c rumdl -n "__fish_rumdl_using_subcommand import" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand import" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand import" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand vscode" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand vscode" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand vscode" -l force -d 'Force reinstall the current version even if already installed'
complete -c rumdl -n "__fish_rumdl_using_subcommand vscode" -l update -d 'Update to the latest version (only if newer version available)'
complete -c rumdl -n "__fish_rumdl_using_subcommand vscode" -l status -d 'Show installation status without installing'
complete -c rumdl -n "__fish_rumdl_using_subcommand vscode" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand vscode" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand vscode" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand completions" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand completions" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand completions" -s l -l list -d 'List available shells'
complete -c rumdl -n "__fish_rumdl_using_subcommand completions" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand completions" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand completions" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand clean" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand clean" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand clean" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand clean" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand clean" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand version" -l color -d 'Control colored output' -r -f -a "auto\t''
always\t''
never\t''"
complete -c rumdl -n "__fish_rumdl_using_subcommand version" -s c -l config -d 'Path to a configuration file, or an inline TOML override (e.g. `MD013.reflow=true`). Can be passed multiple times.' -r
complete -c rumdl -n "__fish_rumdl_using_subcommand version" -l no-config -d 'Ignore all configuration files and use built-in defaults (--isolated is also accepted)'
complete -c rumdl -n "__fish_rumdl_using_subcommand version" -l isolated -d 'Ignore all configuration files (alias for --no-config)'
complete -c rumdl -n "__fish_rumdl_using_subcommand version" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "check" -d 'Lint Markdown files and print warnings/errors'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "fmt" -d 'Format Markdown files and apply fixes with formatter-style exit codes'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "init" -d 'Initialize a new configuration file'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "rule" -d 'Show information about a rule or list all rules'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "explain" -d 'Explain a rule with detailed information and examples'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "config" -d 'Show configuration or query a specific key'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "server" -d 'Start the Language Server Protocol server'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "schema" -d 'Generate or check JSON schema for rumdl.toml'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "code-block-tools-docs" -d 'Generate or check the built-in code-block-tools docs table'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "import" -d 'Import and convert markdownlint configuration files'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "vscode" -d 'Install the rumdl VS Code extension'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "completions" -d 'Generate shell completion scripts'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "clean" -d 'Clear the cache'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "version" -d 'Show version information'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and not __fish_seen_subcommand_from check fmt init rule explain config server schema code-block-tools-docs import vscode completions clean version help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and __fish_seen_subcommand_from config" -f -a "get" -d 'Query a specific config key (e.g. global.exclude or MD013.line_length)'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and __fish_seen_subcommand_from config" -f -a "file" -d 'Show the absolute path of the configuration file that was loaded'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and __fish_seen_subcommand_from schema" -f -a "generate" -d 'Generate/update the JSON schema file'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and __fish_seen_subcommand_from schema" -f -a "check" -d 'Check if the schema is up-to-date'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and __fish_seen_subcommand_from schema" -f -a "print" -d 'Print the schema to stdout'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and __fish_seen_subcommand_from code-block-tools-docs" -f -a "generate" -d 'Generate/update the built-in tools table in docs/code-block-tools.md'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and __fish_seen_subcommand_from code-block-tools-docs" -f -a "check" -d 'Check if the built-in tools docs are up-to-date'
complete -c rumdl -n "__fish_rumdl_using_subcommand help; and __fish_seen_subcommand_from code-block-tools-docs" -f -a "print" -d 'Print the generated table to stdout'
