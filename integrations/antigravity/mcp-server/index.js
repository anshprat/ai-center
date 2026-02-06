#!/usr/bin/env node
/**
 * Team AI MCP Server for Google Antigravity
 * Provides Team AI tools to Antigravity IDE via MCP protocol
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

import {
  getToolDefinitions,
  handleToolCall,
  autoRegister,
  autoDeregister,
  updateHeartbeat,
  startHeartbeatInterval,
  stopHeartbeatInterval,
} from "../../shared/mcp-tools.js";

const MODEL_NAME = "antigravity";
const CLIENT_NAME = "antigravity";

// Store agent ID for cleanup on exit
let registeredAgentId = null;

// Create server
const server = new Server(
  {
    name: "team-ai",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: getToolDefinitions(CLIENT_NAME),
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const result = handleToolCall(name, args, MODEL_NAME, registeredAgentId);

  // Track agent ID if registration was successful
  if (name === "team-ai-register" && result.agentId) {
    registeredAgentId = result.agentId;
    startHeartbeatInterval(registeredAgentId);
  }

  // Update heartbeat on every tool call (shows agent activity)
  if (registeredAgentId) {
    updateHeartbeat(registeredAgentId);
  }

  return result;
});

// Start server
async function main() {
  // Register cleanup handlers
  process.on("SIGINT", () => {
    stopHeartbeatInterval();
    autoDeregister(registeredAgentId);
    process.exit(0);
  });
  process.on("SIGTERM", () => {
    stopHeartbeatInterval();
    autoDeregister(registeredAgentId);
    process.exit(0);
  });
  process.on("exit", () => {
    stopHeartbeatInterval();
    autoDeregister(registeredAgentId);
  });

  // Auto-register this Antigravity instance
  const { agentId, agentName } = autoRegister(MODEL_NAME, CLIENT_NAME);
  registeredAgentId = agentId;

  // Start periodic heartbeat to indicate this agent is alive
  if (registeredAgentId) {
    startHeartbeatInterval(registeredAgentId);
  }

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Team AI MCP server running (Antigravity)");
}

main().catch(console.error);
