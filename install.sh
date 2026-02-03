#!/bin/bash
# AI Center Installation Script
# Creates the ~/.ai-center/ directory structure, installs scripts,
# and configures integrations for detected AI tools

set -e

AI_CENTER_DIR="${HOME}/.ai-center"
AI_CENTER_BIN="${AI_CENTER_DIR}/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_BIN="${SCRIPT_DIR}/bin"
INTEGRATIONS_DIR="${SCRIPT_DIR}/integrations"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  AI Center Installation${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_header
echo "Installing AI Center multi-agent communication system..."

# =============================================================================
# Core Installation
# =============================================================================
print_section "Installing core components"

# Create main directory structure
mkdir -p "${AI_CENTER_DIR}/agents"
mkdir -p "${AI_CENTER_DIR}/artifacts"
mkdir -p "${AI_CENTER_BIN}"
print_success "Created directory structure at ${AI_CENTER_DIR}"
print_success "Created artifacts directory at ${AI_CENTER_DIR}/artifacts"

# Initialize registry.json if it doesn't exist
if [ ! -f "${AI_CENTER_DIR}/registry.json" ]; then
    echo '{"agents": {}}' > "${AI_CENTER_DIR}/registry.json"
    print_success "Created registry.json"
else
    print_info "registry.json already exists"
fi

# Copy scripts from source to ~/.ai-center/bin
if [ -d "${SOURCE_BIN}" ]; then
    for script in "${SOURCE_BIN}"/ai-*; do
        if [ -f "${script}" ]; then
            script_name=$(basename "${script}")
            cp "${script}" "${AI_CENTER_BIN}/${script_name}"
            chmod +x "${AI_CENTER_BIN}/${script_name}"
        fi
    done
    print_success "Installed ai-* commands to ${AI_CENTER_BIN}"
else
    print_error "Source bin directory not found at ${SOURCE_BIN}"
    print_warning "Scripts will need to be installed manually"
fi

# =============================================================================
# PATH Configuration
# =============================================================================
print_section "Configuring PATH"

# Determine shell config file
SHELL_CONFIG=""
if [ -n "${ZSH_VERSION}" ] || [ "${SHELL}" = "/bin/zsh" ]; then
    SHELL_CONFIG="${HOME}/.zshrc"
elif [ -n "${BASH_VERSION}" ] || [ "${SHELL}" = "/bin/bash" ]; then
    if [ -f "${HOME}/.bash_profile" ]; then
        SHELL_CONFIG="${HOME}/.bash_profile"
    else
        SHELL_CONFIG="${HOME}/.bashrc"
    fi
fi

PATH_EXPORT="export PATH=\"\${HOME}/.ai-center/bin:\${PATH}\""
if [ -n "${SHELL_CONFIG}" ]; then
    if ! grep -q "\.ai-center/bin" "${SHELL_CONFIG}" 2>/dev/null; then
        echo "" >> "${SHELL_CONFIG}"
        echo "# AI Center - Multi-Agent Communication System" >> "${SHELL_CONFIG}"
        echo "${PATH_EXPORT}" >> "${SHELL_CONFIG}"
        print_success "Added PATH to ${SHELL_CONFIG}"
    else
        print_info "PATH already configured in ${SHELL_CONFIG}"
    fi
else
    print_warning "Could not determine shell config file"
    print_info "Add this to your shell configuration: ${PATH_EXPORT}"
fi

# =============================================================================
# Tool Detection and Integration
# =============================================================================
print_section "Detecting AI tools"

CLAUDE_CODE_DETECTED=false
CURSOR_DETECTED=false
VSCODE_DETECTED=false
CONTINUE_DETECTED=false
COPILOT_DETECTED=false
ANTIGRAVITY_DETECTED=false
CLAUDE_DESKTOP_DETECTED=false
PERPLEXITY_DETECTED=false

# Detect Claude Code
if [ -d "${HOME}/.claude" ]; then
    CLAUDE_CODE_DETECTED=true
    print_success "Claude Code detected (~/.claude/)"
fi

# Detect Cursor
if [ -d "${HOME}/.cursor" ]; then
    CURSOR_DETECTED=true
    print_success "Cursor IDE detected (~/.cursor/)"
fi

# Detect VSCode
if [ -d "${HOME}/.vscode" ] || [ -d "${HOME}/Library/Application Support/Code" ]; then
    VSCODE_DETECTED=true
    print_success "Visual Studio Code detected"
fi

# Detect Continue
if [ -d "${HOME}/.continue" ]; then
    CONTINUE_DETECTED=true
    print_success "Continue IDE detected (~/.continue/)"
fi

# Detect GitHub Copilot
if [ -d "${HOME}/.copilot" ]; then
    COPILOT_DETECTED=true
    print_success "GitHub Copilot detected (~/.copilot/)"
fi

# Detect Google Antigravity (check for config directory or if installed)
if [ -d "${HOME}/.antigravity" ] || [ -d "${HOME}/Library/Application Support/Antigravity" ]; then
    ANTIGRAVITY_DETECTED=true
    print_success "Google Antigravity detected"
fi

# Detect Claude Desktop (macOS app)
if [ -d "${HOME}/Library/Application Support/Claude" ]; then
    CLAUDE_DESKTOP_DETECTED=true
    print_success "Claude Desktop detected"
fi

# Detect Perplexity (macOS app)
if [ -d "${HOME}/Library/Application Support/Perplexity" ]; then
    PERPLEXITY_DETECTED=true
    print_success "Perplexity detected"
fi

if [ "${CLAUDE_CODE_DETECTED}" = false ] && [ "${CURSOR_DETECTED}" = false ] && \
   [ "${VSCODE_DETECTED}" = false ] && [ "${CONTINUE_DETECTED}" = false ] && \
   [ "${COPILOT_DETECTED}" = false ] && [ "${ANTIGRAVITY_DETECTED}" = false ] && \
   [ "${CLAUDE_DESKTOP_DETECTED}" = false ] && [ "${PERPLEXITY_DETECTED}" = false ]; then
    print_warning "No AI tools detected. Core installation complete."
fi

# =============================================================================
# Shared MCP Library Installation
# =============================================================================
if [ "${CURSOR_DETECTED}" = true ] || [ "${VSCODE_DETECTED}" = true ] || [ "${ANTIGRAVITY_DETECTED}" = true ] || [ "${CLAUDE_DESKTOP_DETECTED}" = true ] || [ "${PERPLEXITY_DETECTED}" = true ]; then
    print_section "Installing shared MCP library"

    SHARED_AI_CENTER="${AI_CENTER_DIR}/integrations/shared"
    mkdir -p "${SHARED_AI_CENTER}"

    if [ -d "${INTEGRATIONS_DIR}/shared" ]; then
        cp "${INTEGRATIONS_DIR}/shared"/*.js "${SHARED_AI_CENTER}/" 2>/dev/null || true
        cp "${INTEGRATIONS_DIR}/shared/package.json" "${SHARED_AI_CENTER}/" 2>/dev/null || true
        print_success "Installed shared MCP library to ${SHARED_AI_CENTER}"
    fi
fi

# =============================================================================
# Claude Code Integration
# =============================================================================
if [ "${CLAUDE_CODE_DETECTED}" = true ] && [ -d "${INTEGRATIONS_DIR}/claude-code" ]; then
    print_section "Installing Claude Code integration"

    # Install slash commands to ~/.claude/commands/
    CLAUDE_COMMANDS_DIR="${HOME}/.claude/commands"
    mkdir -p "${CLAUDE_COMMANDS_DIR}"

    if [ -d "${INTEGRATIONS_DIR}/claude-code/commands" ]; then
        for cmd in "${INTEGRATIONS_DIR}/claude-code/commands"/*.md; do
            if [ -f "${cmd}" ]; then
                cp "${cmd}" "${CLAUDE_COMMANDS_DIR}/"
            fi
        done
        print_success "Installed slash commands to ${CLAUDE_COMMANDS_DIR}"
        print_info "Commands: /ai-register, /ai-list, /ai-send, /ai-check"
    fi

    # Install helper scripts to ~/.ai-center/scripts/
    SCRIPTS_DIR="${AI_CENTER_DIR}/scripts"
    mkdir -p "${SCRIPTS_DIR}"

    if [ -d "${INTEGRATIONS_DIR}/claude-code/scripts" ]; then
        cp "${INTEGRATIONS_DIR}/claude-code/scripts"/*.sh "${SCRIPTS_DIR}/" 2>/dev/null || true
        chmod +x "${SCRIPTS_DIR}"/*.sh 2>/dev/null || true
        print_success "Installed helper scripts to ${SCRIPTS_DIR}"
    fi

    # Configure SessionStart and Stop hooks in ~/.claude/settings.json
    CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
    if [ -f "${CLAUDE_SETTINGS}" ]; then
        # Use python to intelligently merge hooks into existing settings
        if command -v python3 &> /dev/null; then
            HOOK_RESULT=$(python3 << 'PYTHON'
import json
import os

settings_path = os.path.expanduser("~/.claude/settings.json")
scripts_dir = os.path.expanduser("~/.ai-center/scripts")

with open(settings_path, 'r') as f:
    settings = json.load(f)

if 'hooks' not in settings:
    settings['hooks'] = {}

hooks = settings['hooks']
added = []

if 'SessionStart' not in hooks:
    hooks['SessionStart'] = [{"hooks": [{"type": "command", "command": f"bash {scripts_dir}/session-start.sh"}]}]
    added.append("SessionStart")

if 'Stop' not in hooks:
    hooks['Stop'] = [{"hooks": [{"type": "command", "command": "bash -c 'if [ -n \"$AI_CENTER_AGENT_ID\" ]; then ~/.ai-center/bin/ai-deregister \"$AI_CENTER_AGENT_ID\" 2>/dev/null; fi'"}]}]
    added.append("Stop")

if 'UserPromptSubmit' not in hooks:
    hooks['UserPromptSubmit'] = [{"hooks": [{"type": "command", "command": "bash -c 'if [ -n \"$AI_CENTER_AGENT_ID\" ]; then ~/.ai-center/bin/ai-heartbeat \"$AI_CENTER_AGENT_ID\" 2>/dev/null; fi'"}]}]
    added.append("UserPromptSubmit")

if 'PostToolUse' not in hooks:
    hooks['PostToolUse'] = [{"hooks": [{"type": "command", "command": "bash -c 'if [ -n \"$AI_CENTER_AGENT_ID\" ]; then ~/.ai-center/bin/ai-heartbeat \"$AI_CENTER_AGENT_ID\" 2>/dev/null; fi'"}]}]
    added.append("PostToolUse")

if added:
    with open(settings_path, 'w') as f:
        json.dump(settings, f, indent=2)
    print(",".join(added))
else:
    print("NONE")
PYTHON
)
            if [ "${HOOK_RESULT}" = "NONE" ]; then
                print_info "All AI Center hooks already configured"
            else
                if echo "${HOOK_RESULT}" | grep -q "SessionStart"; then
                    print_success "Configured SessionStart hook (auto-register on session start)"
                fi
                if echo "${HOOK_RESULT}" | grep -q "Stop"; then
                    print_success "Configured Stop hook (auto-deregister on session end)"
                fi
                if echo "${HOOK_RESULT}" | grep -q "UserPromptSubmit"; then
                    print_success "Configured UserPromptSubmit hook (heartbeat on each prompt)"
                fi
                if echo "${HOOK_RESULT}" | grep -q "PostToolUse"; then
                    print_success "Configured PostToolUse hook (heartbeat on each tool call)"
                fi
            fi
        else
            print_warning "Python3 not found - hooks not configured automatically"
            print_info "Add hooks manually to ${CLAUDE_SETTINGS}"
        fi
    else
        print_warning "Claude settings.json not found at ${CLAUDE_SETTINGS}"
    fi
fi

# =============================================================================
# Update ~/.claude/CLAUDE.md
# =============================================================================
if [ "${CLAUDE_CODE_DETECTED}" = true ]; then
    print_section "Updating Claude Code instructions"

    CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
    AI_CENTER_SECTION="## AI Center Integration"

    # Check if AI Center section already exists
    if [ -f "${CLAUDE_MD}" ] && grep -q "${AI_CENTER_SECTION}" "${CLAUDE_MD}" 2>/dev/null; then
        print_info "AI Center section already exists in CLAUDE.md"
    else
        # Append AI Center section
        cat >> "${CLAUDE_MD}" << 'AICENTERSECTION'

## AI Center Integration

You have access to the AI Center multi-agent communication system. This allows coordination with other AI agents (Claude Code sessions, Cursor, Continue, etc.).

### Quick Commands

- `/ai-list` - List all registered agents
- `/ai-register` - Register this session as an agent
- `/ai-send` - Send a message to another agent
- `/ai-check` - Check for incoming messages

### Shell Commands

```bash
ai-list              # List all active agents
ai-register --name "name" --command "task"  # Register
ai-send TARGET --subject "subj" --body "msg"  # Send message
ai-check AGENT_ID    # Check messages
```

### When to Use AI Center

- **Before major changes**: Check if other agents are working on related files
- **For coordination**: Send messages to notify other agents about breaking changes
- **For questions**: Query other agents for information about their work areas
- **After completing work**: Notify relevant agents about completed changes

### Heartbeat System

AI Center uses heartbeats to track agent liveness. Your Claude Code session automatically sends heartbeats:

- **On session start**: Heartbeat is set when you register
- **On each prompt**: Heartbeat is updated whenever you send a message
- **On each tool call**: Heartbeat is updated after every tool use (keeps agent alive during long tasks)
- **Stale detection**: Agents without heartbeats for >1 hour are marked stale

```bash
ai-heartbeat AGENT_ID    # Manually update heartbeat
ai-cleanup               # Remove stale agents (>1 hour without heartbeat)
ai-cleanup -t 1800       # Remove agents stale for >30 minutes
```

AICENTERSECTION
        print_success "Added AI Center section to CLAUDE.md"
    fi
fi

# =============================================================================
# Cursor Integration
# =============================================================================
if [ "${CURSOR_DETECTED}" = true ] && [ -d "${INTEGRATIONS_DIR}/cursor" ]; then
    print_section "Installing Cursor integration"

    CURSOR_AI_CENTER="${AI_CENTER_DIR}/integrations/cursor"
    mkdir -p "${CURSOR_AI_CENTER}"

    # Copy MCP server
    if [ -d "${INTEGRATIONS_DIR}/cursor/mcp-server" ]; then
        cp -r "${INTEGRATIONS_DIR}/cursor/mcp-server" "${CURSOR_AI_CENTER}/"
        print_success "Installed MCP server to ${CURSOR_AI_CENTER}/mcp-server"
    fi

    # Copy .cursorrules template
    if [ -f "${INTEGRATIONS_DIR}/cursor/.cursorrules" ]; then
        cp "${INTEGRATIONS_DIR}/cursor/.cursorrules" "${CURSOR_AI_CENTER}/"
        print_success "Installed .cursorrules template"
    fi

    echo ""
    print_info "To enable the MCP server in Cursor, add to your mcp.json:"
    echo ""
    echo -e "    ${BLUE}{${NC}"
    echo -e "    ${BLUE}  \"mcpServers\": {${NC}"
    echo -e "    ${BLUE}    \"ai-center\": {${NC}"
    echo -e "    ${BLUE}      \"command\": \"node\",${NC}"
    echo -e "    ${BLUE}      \"args\": [\"${CURSOR_AI_CENTER}/mcp-server/index.js\"]${NC}"
    echo -e "    ${BLUE}    }${NC}"
    echo -e "    ${BLUE}  }${NC}"
    echo -e "    ${BLUE}}${NC}"
    echo ""
    print_info "Run 'npm install' in ${CURSOR_AI_CENTER}/mcp-server to install dependencies"
fi

# =============================================================================
# VSCode Integration (Copilot, Codex, etc.)
# =============================================================================
if [ "${VSCODE_DETECTED}" = true ] && [ -d "${INTEGRATIONS_DIR}/vscode" ]; then
    print_section "Installing VSCode integration"

    VSCODE_AI_CENTER="${AI_CENTER_DIR}/integrations/vscode"
    mkdir -p "${VSCODE_AI_CENTER}"

    # Copy MCP server
    if [ -d "${INTEGRATIONS_DIR}/vscode/mcp-server" ]; then
        cp -r "${INTEGRATIONS_DIR}/vscode/mcp-server" "${VSCODE_AI_CENTER}/"
        print_success "Installed MCP server to ${VSCODE_AI_CENTER}/mcp-server"
    fi

    # Configure VSCode mcp.json (user-level)
    VSCODE_MCP_JSON="${HOME}/Library/Application Support/Code/User/mcp.json"
    if [ -f "${VSCODE_MCP_JSON}" ]; then
        # Check if ai-center is already configured
        if ! grep -q "ai-center" "${VSCODE_MCP_JSON}" 2>/dev/null; then
            if command -v python3 &> /dev/null; then
                python3 << PYTHON
import json

mcp_path = "${VSCODE_MCP_JSON}"
with open(mcp_path, 'r') as f:
    config = json.load(f)

if 'servers' not in config:
    config['servers'] = {}

config['servers']['ai-center'] = {
    "type": "stdio",
    "command": "node",
    "args": ["${VSCODE_AI_CENTER}/mcp-server/index.js"]
}

with open(mcp_path, 'w') as f:
    json.dump(config, f, indent='\t')
PYTHON
                print_success "Added AI Center to VSCode mcp.json"
            else
                print_warning "Python3 not found - manual config required"
            fi
        else
            print_info "AI Center already configured in VSCode mcp.json"
        fi
    else
        # Create new mcp.json
        cat > "${VSCODE_MCP_JSON}" << MCPJSON
{
	"servers": {
		"ai-center": {
			"type": "stdio",
			"command": "node",
			"args": ["${VSCODE_AI_CENTER}/mcp-server/index.js"]
		}
	},
	"inputs": []
}
MCPJSON
        print_success "Created VSCode mcp.json with AI Center"
    fi

    echo ""
    print_info "VSCode MCP configured at: ${VSCODE_MCP_JSON}"
    print_info "Reload VSCode to activate (Cmd+Shift+P → 'Developer: Reload Window')"
    print_info "Run 'npm install' in ${VSCODE_AI_CENTER}/mcp-server to install dependencies"
fi

# =============================================================================
# Continue Integration
# =============================================================================
if [ "${CONTINUE_DETECTED}" = true ] && [ -d "${INTEGRATIONS_DIR}/continue" ]; then
    print_section "Installing Continue integration"

    CONTINUE_AI_CENTER="${AI_CENTER_DIR}/integrations/continue"
    mkdir -p "${CONTINUE_AI_CENTER}"

    # Copy context provider
    if [ -f "${INTEGRATIONS_DIR}/continue/ai-center-context.ts" ]; then
        cp "${INTEGRATIONS_DIR}/continue/ai-center-context.ts" "${CONTINUE_AI_CENTER}/"
        print_success "Installed context provider template"
    fi

    echo ""
    print_info "To enable the context provider in Continue:"
    print_info "1. Copy ${CONTINUE_AI_CENTER}/ai-center-context.ts to your Continue config"
    print_info "2. Add to your config.json:"
    echo ""
    echo -e "    ${BLUE}{${NC}"
    echo -e "    ${BLUE}  \"contextProviders\": [${NC}"
    echo -e "    ${BLUE}    { \"name\": \"ai-center\" }${NC}"
    echo -e "    ${BLUE}  ]${NC}"
    echo -e "    ${BLUE}}${NC}"
fi

# =============================================================================
# Google Antigravity Integration
# =============================================================================
if [ "${ANTIGRAVITY_DETECTED}" = true ] || [ -d "${INTEGRATIONS_DIR}/antigravity" ]; then
    print_section "Installing Google Antigravity integration"

    # Install MCP server to ~/.ai-center/integrations/antigravity (standard location)
    ANTIGRAVITY_AI_CENTER="${AI_CENTER_DIR}/integrations/antigravity"
    mkdir -p "${ANTIGRAVITY_AI_CENTER}"

    if [ -d "${INTEGRATIONS_DIR}/antigravity/mcp-server" ]; then
        cp -r "${INTEGRATIONS_DIR}/antigravity/mcp-server" "${ANTIGRAVITY_AI_CENTER}/"
        print_success "Installed MCP server to ${ANTIGRAVITY_AI_CENTER}/mcp-server"
    fi

    # Antigravity expects MCP config at ~/.gemini/antigravity/mcp_config.json
    ANTIGRAVITY_GEMINI_DIR="${HOME}/.gemini/antigravity"
    ANTIGRAVITY_MCP_CONFIG="${ANTIGRAVITY_GEMINI_DIR}/mcp_config.json"
    mkdir -p "${ANTIGRAVITY_GEMINI_DIR}"

    # Smart update: merge ai-center into existing config or create new
    if command -v python3 &> /dev/null; then
        python3 << PYTHON
import json
import os

config_path = "${ANTIGRAVITY_MCP_CONFIG}"
mcp_server_path = "${ANTIGRAVITY_AI_CENTER}/mcp-server/index.js"

# Load existing config or start fresh
if os.path.exists(config_path):
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
    except (json.JSONDecodeError, IOError):
        config = {}
else:
    config = {}

# Ensure mcpServers exists
if 'mcpServers' not in config:
    config['mcpServers'] = {}

# Add/update ai-center entry with absolute path
config['mcpServers']['ai-center'] = {
    "command": "node",
    "args": [mcp_server_path]
}

# Write back
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
PYTHON
        if [ -f "${ANTIGRAVITY_MCP_CONFIG}" ]; then
            print_success "Updated mcp_config.json with ai-center entry"
        fi
    else
        # Fallback: create new config if python3 not available
        if [ ! -f "${ANTIGRAVITY_MCP_CONFIG}" ]; then
            cat > "${ANTIGRAVITY_MCP_CONFIG}" << MCPCONFIG
{
  "mcpServers": {
    "ai-center": {
      "command": "node",
      "args": [
        "${ANTIGRAVITY_AI_CENTER}/mcp-server/index.js"
      ]
    }
  }
}
MCPCONFIG
            print_success "Created mcp_config.json"
        else
            print_warning "Python3 not found - manual config update required"
            print_info "Add ai-center to ${ANTIGRAVITY_MCP_CONFIG}"
        fi
    fi

    echo ""
    print_info "Antigravity MCP configured at: ${ANTIGRAVITY_MCP_CONFIG}"
    print_info "Run 'npm install' in ${ANTIGRAVITY_AI_CENTER}/mcp-server to install dependencies"
fi

# =============================================================================
# Claude Desktop Integration (macOS)
# =============================================================================
if [ "${CLAUDE_DESKTOP_DETECTED}" = true ]; then
    print_section "Installing Claude Desktop integration"

    # Claude Desktop uses the VSCode MCP server
    VSCODE_AI_CENTER="${AI_CENTER_DIR}/integrations/vscode"

    # Ensure MCP server is installed (may have been done by VSCode section)
    if [ ! -d "${VSCODE_AI_CENTER}/mcp-server" ] && [ -d "${INTEGRATIONS_DIR}/vscode/mcp-server" ]; then
        mkdir -p "${VSCODE_AI_CENTER}"
        cp -r "${INTEGRATIONS_DIR}/vscode/mcp-server" "${VSCODE_AI_CENTER}/"
        print_success "Installed MCP server to ${VSCODE_AI_CENTER}/mcp-server"
    fi

    # Configure Claude Desktop config
    CLAUDE_DESKTOP_CONFIG="${HOME}/Library/Application Support/Claude/claude_desktop_config.json"

    if [ -f "${CLAUDE_DESKTOP_CONFIG}" ]; then
        # Check if ai-center is already configured
        if ! grep -q "ai-center" "${CLAUDE_DESKTOP_CONFIG}" 2>/dev/null; then
            if command -v python3 &> /dev/null; then
                python3 << PYTHON
import json

config_path = "${CLAUDE_DESKTOP_CONFIG}"
mcp_server_path = "${VSCODE_AI_CENTER}/mcp-server/index.js"

with open(config_path, 'r') as f:
    config = json.load(f)

# Ensure mcpServers exists
if 'mcpServers' not in config:
    config['mcpServers'] = {}

# Add ai-center entry
config['mcpServers']['ai-center'] = {
    "command": "node",
    "args": [mcp_server_path]
}

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
PYTHON
                print_success "Added AI Center to Claude Desktop config"
            else
                print_warning "Python3 not found - manual config required"
            fi
        else
            print_info "AI Center already configured in Claude Desktop"
        fi
    else
        # Create new config
        if command -v python3 &> /dev/null; then
            python3 << PYTHON
import json
import os

config_path = "${CLAUDE_DESKTOP_CONFIG}"
mcp_server_path = "${VSCODE_AI_CENTER}/mcp-server/index.js"

config = {
    "mcpServers": {
        "ai-center": {
            "command": "node",
            "args": [mcp_server_path]
        }
    }
}

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
PYTHON
            print_success "Created Claude Desktop config with AI Center"
        else
            print_warning "Python3 not found - manual config required"
        fi
    fi

    echo ""
    print_info "Claude Desktop config: ${CLAUDE_DESKTOP_CONFIG}"
    print_info "Restart Claude Desktop to activate the MCP server"
fi

# =============================================================================
# Perplexity Integration (macOS)
# =============================================================================
if [ "${PERPLEXITY_DETECTED}" = true ]; then
    print_section "Installing Perplexity integration"

    # Install Perplexity-specific MCP server
    PERPLEXITY_AI_CENTER="${AI_CENTER_DIR}/integrations/perplexity"
    mkdir -p "${PERPLEXITY_AI_CENTER}"

    if [ -d "${INTEGRATIONS_DIR}/perplexity/mcp-server" ]; then
        cp -r "${INTEGRATIONS_DIR}/perplexity/mcp-server" "${PERPLEXITY_AI_CENTER}/"
        print_success "Installed MCP server to ${PERPLEXITY_AI_CENTER}/mcp-server"
    fi

    # Perplexity MCP is configured via UI settings (no config file)
    echo ""
    print_info "Perplexity MCP is configured via the app's UI settings."
    print_info "To enable AI Center in Perplexity:"
    echo ""
    echo -e "    ${BLUE}1. Open Perplexity Settings${NC}"
    echo -e "    ${BLUE}2. Navigate to MCP settings${NC}"
    echo -e "    ${BLUE}3. Add a new local MCP server:${NC}"
    echo -e "       ${BLUE}Command: node${NC}"
    echo -e "       ${BLUE}Args: ${PERPLEXITY_AI_CENTER}/mcp-server/index.js${NC}"
    echo ""
    print_info "Documentation: https://www.perplexity.ai/help-center/en/articles/11502712-local-and-remote-mcps-for-perplexity"
    print_info "Run 'npm install' in ${PERPLEXITY_AI_CENTER}/mcp-server to install dependencies"
fi

# =============================================================================
# GitHub Copilot (Limited Support)
# =============================================================================
if [ "${COPILOT_DETECTED}" = true ]; then
    print_section "GitHub Copilot"
    print_info "Copilot has limited integration support (instructions only)"
    print_info "The shell commands (ai-list, ai-register, etc.) are available"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Directory structure: ${AI_CENTER_DIR}"
echo ""
echo "Installed integrations:"
[ "${CLAUDE_CODE_DETECTED}" = true ] && echo "  • Claude Code (full plugin support)"
[ "${CLAUDE_DESKTOP_DETECTED}" = true ] && echo "  • Claude Desktop (MCP server)"
[ "${CURSOR_DETECTED}" = true ] && echo "  • Cursor (MCP server)"
[ "${VSCODE_DETECTED}" = true ] && echo "  • VSCode (MCP server for Copilot/Codex)"
[ "${ANTIGRAVITY_DETECTED}" = true ] && echo "  • Google Antigravity (MCP server)"
[ "${PERPLEXITY_DETECTED}" = true ] && echo "  • Perplexity (MCP server)"
[ "${CONTINUE_DETECTED}" = true ] && echo "  • Continue (context provider)"
[ "${COPILOT_DETECTED}" = true ] && echo "  • GitHub Copilot (shell commands only)"
echo ""
echo "To start using AI Center, either:"
echo "  1. Open a new terminal, or"
echo "  2. Run: source ${SHELL_CONFIG}"
echo ""
echo "Quick start:"
echo "  ai-register --name \"my-agent\" --command \"my task\""
echo "  ai-list"
echo "  ai-check AGENT_ID"
echo ""
