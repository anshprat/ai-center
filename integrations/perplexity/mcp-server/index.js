#!/usr/bin/env node
/**
 * AI Center MCP Server for Perplexity
 * Provides AI Center tools to Perplexity desktop app via MCP protocol
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

const MODEL_NAME = "perplexity";
const CLIENT_NAME = "perplexity";

// Store agent ID for cleanup on exit
let registeredAgentId = null;

// Create server
const server = new Server(
  {
    name: "ai-center",
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
  if (name === "ai-center-register" && result.agentId) {
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

  // Auto-register this Perplexity instance
  const { agentId, agentName } = autoRegister(MODEL_NAME, CLIENT_NAME);
  registeredAgentId = agentId;

  // Start periodic heartbeat to indicate this agent is alive
  if (registeredAgentId) {
    startHeartbeatInterval(registeredAgentId);
  }

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("AI Center MCP server running (Perplexity)");
}

main().catch(console.error);
