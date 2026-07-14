# SSH Extension

SSH mode for pi.

Routes pi's built-in file and shell tools to a remote host selected from `~/.ssh/config`. Use `/ssh` to pick a host interactively, or pass an alias directly with an optional remote path.

## Commands

- `/ssh` - Open the SSH host picker
- `/ssh <alias>` - Enable SSH mode for a host alias
- `/ssh <alias>:/remote/path` - Enable SSH mode and pin the remote working directory
- `/ssh status` - Show the active SSH target
- `/ssh off` - Disable SSH mode

## Behavior

When SSH mode is active, these tools run on the remote host:

- `read`
- `write`
- `edit`
- `bash`
- `find`
- `ls`
- `grep`

The extension also:

- shows the active SSH target in the status line
- persists SSH state in the session
- updates the agent prompt so pi knows it is operating remotely
- maps local workspace-relative paths into the configured remote workspace

## Usage Examples

Enable SSH mode with the remote login shell's default directory:

```text
/ssh my-server
```

Enable SSH mode with an explicit remote project root:

```text
/ssh my-server:/srv/my-app
```

Disable SSH mode:

```text
/ssh off
```

## Requirements

- a configured `~/.ssh/config` with direct `Host` aliases
- SSH access that works non-interactively
- remote shell utilities such as `cat`, `test`, `ls`, and `grep`
- `rg` and `fd` are used when available, with fallbacks for search/list operations

## Development

Install local type dependencies and run type-checking:

```bash
cd ~/.pi/agent/extensions/ssh
npm install
npm run check
```

## How SSH Mode Works

When SSH mode is enabled, the extension uses this flow:

1. Resolve the SSH target from `/ssh <alias>` or `/ssh <alias>:/remote/path`
2. Determine the remote working directory:
   - explicit path from the command, or
   - remote `pwd` when no path is provided
3. Wrap pi's built-in tools with remote operations executed through `ssh`
4. Translate local workspace-relative paths into the remote workspace root
5. Update pi's status line, session state, and agent prompt to reflect remote execution

Tool execution behavior:

- `read`, `write`, `edit`, `find`, `ls`, and `grep` are redirected to the remote host
- `bash` and user `!` shell commands run remotely when SSH mode is active
- `rg` is preferred for grep/search when available, with `grep` fallback
- `fd` is preferred for file discovery when available, with `find` fallback

Session behavior:

- the active SSH target is stored in session state
- on session restore, the extension re-validates the saved target before re-enabling SSH mode
- the agent prompt is rewritten so the model sees the remote cwd instead of the local one

## File Structure

```text
ssh/
├── index.ts       # Extension entrypoint
├── package.json   # Pi package manifest and dev dependencies
├── tsconfig.json  # Local TypeScript config for type-checking
├── .gitignore
└── README.md
```
