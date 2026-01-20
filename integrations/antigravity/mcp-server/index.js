#!/usr/bin/env node
/**
 * AI Center MCP Server for Google Antigravity
 * Provides AI Center tools to Antigravity IDE via MCP protocol
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
} from "../../shared/mcp-tools.js";

const MODEL_NAME = "antigravity";
const CLIENT_NAME = "antigravity";

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
  }

  return result;
});

// Start server
async function main() {
  // Register cleanup handlers
  process.on("SIGINT", () => {
    autoDeregister(registeredAgentId);
    process.exit(0);
  });
  process.on("SIGTERM", () => {
    autoDeregister(registeredAgentId);
    process.exit(0);
  });
  process.on("exit", () => autoDeregister(registeredAgentId));

  // Auto-register this Antigravity instance
  const { agentId, agentName } = autoRegister(MODEL_NAME, CLIENT_NAME);
  registeredAgentId = agentId;

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("AI Center MCP server running (Antigravity)");
}

main().catch(console.error);
