/**
 * Team AI MCP Tools - Shared library for MCP server implementations
 * Used by Cursor, VSCode, Antigravity, and other MCP-compatible clients
 */

import { execSync } from "child_process";
import { existsSync, readFileSync, readdirSync, copyFileSync, mkdirSync } from "fs";
import { homedir } from "os";
import { join, basename } from "path";
import { randomUUID } from "crypto";

export const TEAM_AI_DIR = join(homedir(), ".team-ai");
export const ARTIFACTS_DIR = join(TEAM_AI_DIR, "artifacts");

// Heartbeat interval reference (for cleanup)
let heartbeatIntervalId = null;
const DEFAULT_HEARTBEAT_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Helper to run ai-* commands
 */
export function runCommand(command, args = []) {
  try {
    const fullCommand = [command, ...args].join(" ");
    const result = execSync(fullCommand, {
      encoding: "utf-8",
      timeout: 30000,
      env: { ...process.env, PATH: `${TEAM_AI_DIR}/bin:${process.env.PATH}` },
    });
    return { success: true, output: result.trim() };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      output: error.stdout?.toString() || "",
    };
  }
}

/**
 * Get all tool definitions
 * @param {string} clientType - The client type for descriptions (e.g., 'cursor', 'vscode', 'antigravity')
 */
export function getToolDefinitions(clientType = "client") {
  return [
    // Core tools (existing)
    {
      name: "team-ai-list",
      description:
        "List all registered AI agents in the Team AI. Shows agent IDs, names, states, and current tasks.",
      inputSchema: {
        type: "object",
        properties: {
          all: {
            type: "boolean",
            description: "Include completed agents",
            default: false,
          },
          verbose: {
            type: "boolean",
            description: "Show detailed information",
            default: false,
          },
        },
      },
    },
    {
      name: "team-ai-register",
      description:
        "Register this session as an agent in the Team AI for multi-agent coordination.",
      inputSchema: {
        type: "object",
        properties: {
          name: {
            type: "string",
            description: `Agent name (e.g., '${clientType}-frontend')`,
          },
          command: {
            type: "string",
            description: "Current task description",
          },
          tags: {
            type: "string",
            description: "Comma-separated tags (e.g., 'frontend,react')",
          },
          capabilities: {
            type: "string",
            description:
              "Comma-separated capabilities (e.g., 'typescript,css')",
          },
        },
        required: ["name", "command"],
      },
    },
    {
      name: "team-ai-send",
      description: "Send a message to another AI agent's inbox.",
      inputSchema: {
        type: "object",
        properties: {
          target: {
            type: "string",
            description: "Target agent ID or name",
          },
          subject: {
            type: "string",
            description: "Message subject",
          },
          body: {
            type: "string",
            description: "Message body",
          },
          type: {
            type: "string",
            enum: ["request", "info", "query"],
            description: "Message type",
            default: "request",
          },
          priority: {
            type: "string",
            enum: ["low", "normal", "high"],
            description: "Message priority",
            default: "normal",
          },
          artifact: {
            type: "string",
            description: "Path to artifact file to attach (screenshot, plan, etc.)",
          },
        },
        required: ["target", "subject", "body"],
      },
    },
    {
      name: "team-ai-check",
      description: "Check for incoming messages in an agent's inbox.",
      inputSchema: {
        type: "object",
        properties: {
          agentId: {
            type: "string",
            description: "Agent ID to check messages for",
          },
          all: {
            type: "boolean",
            description: "Include completed messages",
            default: false,
          },
        },
        required: ["agentId"],
      },
    },
    {
      name: "team-ai-status",
      description: "Get the current status of Team AI installation.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
    // New tools
    {
      name: "team-ai-agents-by-capability",
      description: "Find agents with specific capabilities (e.g., 'typescript', 'python', 'frontend').",
      inputSchema: {
        type: "object",
        properties: {
          capability: {
            type: "string",
            description: "The capability to search for",
          },
        },
        required: ["capability"],
      },
    },
    {
      name: "team-ai-broadcast",
      description: "Send a message to multiple agents at once (all active agents or filtered by tags/capabilities).",
      inputSchema: {
        type: "object",
        properties: {
          subject: {
            type: "string",
            description: "Message subject",
          },
          body: {
            type: "string",
            description: "Message body",
          },
          type: {
            type: "string",
            enum: ["request", "info", "query"],
            description: "Message type",
            default: "info",
          },
          priority: {
            type: "string",
            enum: ["low", "normal", "high"],
            description: "Message priority",
            default: "normal",
          },
          filterTag: {
            type: "string",
            description: "Only send to agents with this tag",
          },
          filterCapability: {
            type: "string",
            description: "Only send to agents with this capability",
          },
          excludeSelf: {
            type: "boolean",
            description: "Exclude the sending agent from broadcast",
            default: true,
          },
        },
        required: ["subject", "body"],
      },
    },
    {
      name: "team-ai-watch-start",
      description: "Start watching for incoming messages in background. Returns immediately.",
      inputSchema: {
        type: "object",
        properties: {
          agentId: {
            type: "string",
            description: "Agent ID to watch messages for",
          },
          interval: {
            type: "number",
            description: "Poll interval in seconds (default: 5)",
            default: 5,
          },
        },
        required: ["agentId"],
      },
    },
  ];
}

/**
 * Handle tool calls
 * @param {string} name - Tool name
 * @param {object} args - Tool arguments
 * @param {string} modelName - Model identifier (cursor, vscode, antigravity)
 * @param {string|null} registeredAgentId - Currently registered agent ID
 */
export function handleToolCall(name, args, modelName, registeredAgentId = null) {
  try {
    switch (name) {
      case "team-ai-list": {
        const cmdArgs = [];
        if (args?.all) cmdArgs.push("--all");
        if (args?.verbose) cmdArgs.push("--verbose");

        const result = runCommand("ai-list", cmdArgs);
        return {
          content: [
            {
              type: "text",
              text: result.success
                ? result.output
                : `Error: ${result.error}\n${result.output}`,
            },
          ],
        };
      }

      case "team-ai-register": {
        const cmdArgs = [
          "--name",
          `"${args.name}"`,
          "--command",
          `"${args.command}"`,
          "--model",
          `"${modelName}"`,
        ];
        if (args.tags) cmdArgs.push("--tags", `"${args.tags}"`);
        if (args.capabilities)
          cmdArgs.push("--capabilities", `"${args.capabilities}"`);

        const result = runCommand("ai-register", cmdArgs);
        if (result.success) {
          const agentId = result.output.trim();
          return {
            content: [
              {
                type: "text",
                text: `Successfully registered as agent: ${agentId}\n\nUse this ID to check messages: team-ai-check with agentId="${agentId}"`,
              },
            ],
            agentId: agentId, // Return for tracking
          };
        }
        return {
          content: [
            {
              type: "text",
              text: `Registration failed: ${result.error}\n${result.output}`,
            },
          ],
        };
      }

      case "team-ai-send": {
        const cmdArgs = [
          args.target,
          "--subject",
          `"${args.subject}"`,
          "--body",
          `"${args.body}"`,
        ];
        if (args.type) cmdArgs.push("--type", args.type);
        if (args.priority) cmdArgs.push("--priority", args.priority);
        if (args.artifact) cmdArgs.push("--artifact", `"${args.artifact}"`);

        const result = runCommand("ai-send", cmdArgs);
        return {
          content: [
            {
              type: "text",
              text: result.success
                ? result.output
                : `Send failed: ${result.error}\n${result.output}`,
            },
          ],
        };
      }

      case "team-ai-check": {
        const cmdArgs = [args.agentId];
        if (args?.all) cmdArgs.push("--all");

        const result = runCommand("ai-check", cmdArgs);
        return {
          content: [
            {
              type: "text",
              text: result.success
                ? result.output
                : `Check failed: ${result.error}\n${result.output}`,
            },
          ],
        };
      }

      case "team-ai-status": {
        const installed = existsSync(TEAM_AI_DIR);
        const binExists = existsSync(join(TEAM_AI_DIR, "bin"));
        const artifactsExists = existsSync(ARTIFACTS_DIR);

        let agentCount = 0;
        const agentsDir = join(TEAM_AI_DIR, "agents");
        if (existsSync(agentsDir)) {
          agentCount = readdirSync(agentsDir).filter((f) =>
            existsSync(join(agentsDir, f, "metadata.json"))
          ).length;
        }

        return {
          content: [
            {
              type: "text",
              text: `Team AI Status:
- Installed: ${installed ? "Yes" : "No"}
- Bin directory: ${binExists ? "Yes" : "No"}
- Artifacts directory: ${artifactsExists ? "Yes" : "No"}
- Directory: ${TEAM_AI_DIR}
- Registered agents: ${agentCount}`,
            },
          ],
        };
      }

      case "team-ai-agents-by-capability": {
        const capability = args.capability.toLowerCase();
        const agentsDir = join(TEAM_AI_DIR, "agents");
        const matchingAgents = [];

        if (existsSync(agentsDir)) {
          const agentDirs = readdirSync(agentsDir);
          for (const agentId of agentDirs) {
            const metadataPath = join(agentsDir, agentId, "metadata.json");
            if (existsSync(metadataPath)) {
              try {
                const metadata = JSON.parse(readFileSync(metadataPath, "utf-8"));
                const capabilities = (metadata.capabilities || "").toLowerCase().split(",").map(c => c.trim());
                if (capabilities.includes(capability)) {
                  matchingAgents.push({
                    id: agentId,
                    name: metadata.name,
                    capabilities: metadata.capabilities,
                    state: metadata.state,
                    task: metadata.command,
                  });
                }
              } catch (e) {
                // Skip invalid metadata
              }
            }
          }
        }

        if (matchingAgents.length === 0) {
          return {
            content: [
              {
                type: "text",
                text: `No agents found with capability: ${capability}`,
              },
            ],
          };
        }

        const output = matchingAgents
          .map((a) => `- ${a.name} (${a.id.substring(0, 8)}): ${a.task} [${a.state}]`)
          .join("\n");

        return {
          content: [
            {
              type: "text",
              text: `Agents with capability "${capability}":\n${output}`,
            },
          ],
        };
      }

      case "team-ai-broadcast": {
        const agentsDir = join(TEAM_AI_DIR, "agents");
        const targetAgents = [];

        if (existsSync(agentsDir)) {
          const agentDirs = readdirSync(agentsDir);
          for (const agentId of agentDirs) {
            // Optionally exclude self
            if (args.excludeSelf !== false && agentId === registeredAgentId) {
              continue;
            }

            const metadataPath = join(agentsDir, agentId, "metadata.json");
            if (existsSync(metadataPath)) {
              try {
                const metadata = JSON.parse(readFileSync(metadataPath, "utf-8"));

                // Filter by state (only active agents)
                if (metadata.state === "completed") continue;

                // Filter by tag if specified
                if (args.filterTag) {
                  const tags = (metadata.tags || "").toLowerCase().split(",").map(t => t.trim());
                  if (!tags.includes(args.filterTag.toLowerCase())) continue;
                }

                // Filter by capability if specified
                if (args.filterCapability) {
                  const capabilities = (metadata.capabilities || "").toLowerCase().split(",").map(c => c.trim());
                  if (!capabilities.includes(args.filterCapability.toLowerCase())) continue;
                }

                targetAgents.push({ id: agentId, name: metadata.name });
              } catch (e) {
                // Skip invalid metadata
              }
            }
          }
        }

        if (targetAgents.length === 0) {
          return {
            content: [
              {
                type: "text",
                text: "No agents found matching broadcast criteria",
              },
            ],
          };
        }

        // Send message to each agent
        const results = [];
        for (const agent of targetAgents) {
          const cmdArgs = [
            agent.id,
            "--subject",
            `"${args.subject}"`,
            "--body",
            `"${args.body}"`,
          ];
          if (args.type) cmdArgs.push("--type", args.type);
          if (args.priority) cmdArgs.push("--priority", args.priority);

          const result = runCommand("ai-send", cmdArgs);
          results.push({
            agent: agent.name,
            success: result.success,
          });
        }

        const successCount = results.filter((r) => r.success).length;
        return {
          content: [
            {
              type: "text",
              text: `Broadcast sent to ${successCount}/${targetAgents.length} agents:\n${results
                .map((r) => `- ${r.agent}: ${r.success ? "sent" : "failed"}`)
                .join("\n")}`,
            },
          ],
        };
      }

      case "team-ai-watch-start": {
        const cmdArgs = [args.agentId, "--daemon"];
        if (args.interval) cmdArgs.push("--interval", String(args.interval));

        const result = runCommand("ai-watch", cmdArgs);
        return {
          content: [
            {
              type: "text",
              text: result.success
                ? `Started watching for messages (agent: ${args.agentId})`
                : `Watch failed: ${result.error}\n${result.output}`,
            },
          ],
        };
      }

      default:
        return {
          content: [
            {
              type: "text",
              text: `Unknown tool: ${name}`,
            },
          ],
          isError: true,
        };
    }
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error executing ${name}: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
}

/**
 * Auto-register the client as an agent
 * @param {string} modelName - Model identifier
 * @param {string} clientName - Client prefix (e.g., 'cursor', 'vscode', 'antigravity')
 * @returns {{ agentId: string|null, agentName: string }}
 */
export function autoRegister(modelName, clientName) {
  try {
    const cwd = process.cwd();
    const dirName = cwd.split("/").pop() || clientName;
    const agentName = `${clientName}-${dirName}`;

    const result = runCommand("ai-register", [
      "--name",
      `"${agentName}"`,
      "--command",
      `"${clientName.charAt(0).toUpperCase() + clientName.slice(1)} IDE session in ${cwd}"`,
      "--model",
      `"${modelName}"`,
    ]);

    if (result.success) {
      const agentId = result.output.trim();
      console.error(`Team AI: Registered as ${agentName} (${agentId})`);
      return { agentId, agentName };
    }
    return { agentId: null, agentName };
  } catch (error) {
    console.error("Team AI: Auto-registration failed:", error.message);
    return { agentId: null, agentName: "" };
  }
}

/**
 * Deregister an agent
 * @param {string} agentId - Agent ID to deregister
 */
export function autoDeregister(agentId) {
  if (agentId) {
    try {
      stopHeartbeatInterval(); // Stop heartbeat before deregistering
      runCommand("ai-deregister", [agentId]);
      console.error(`Team AI: Deregistered ${agentId}`);
    } catch (error) {
      // Ignore errors on cleanup
    }
  }
}

/**
 * Update heartbeat for an agent
 * @param {string} agentId - Agent ID to update heartbeat for
 * @returns {boolean} - True if heartbeat was updated successfully
 */
export function updateHeartbeat(agentId) {
  if (!agentId) return false;

  try {
    const result = runCommand("ai-heartbeat", [agentId]);
    return result.success;
  } catch (error) {
    console.error("Team AI: Heartbeat update failed:", error.message);
    return false;
  }
}

/**
 * Start periodic heartbeat updates for an agent
 * @param {string} agentId - Agent ID to send heartbeats for
 * @param {number} intervalMs - Interval in milliseconds (default: 5 minutes)
 * @returns {boolean} - True if heartbeat interval was started
 */
export function startHeartbeatInterval(agentId, intervalMs = DEFAULT_HEARTBEAT_INTERVAL_MS) {
  if (!agentId) return false;

  // Stop any existing heartbeat interval
  stopHeartbeatInterval();

  // Send initial heartbeat
  updateHeartbeat(agentId);

  // Start periodic heartbeat
  heartbeatIntervalId = setInterval(() => {
    updateHeartbeat(agentId);
  }, intervalMs);

  console.error(`Team AI: Started heartbeat (every ${intervalMs / 1000}s)`);
  return true;
}

/**
 * Stop periodic heartbeat updates
 */
export function stopHeartbeatInterval() {
  if (heartbeatIntervalId) {
    clearInterval(heartbeatIntervalId);
    heartbeatIntervalId = null;
  }
}
