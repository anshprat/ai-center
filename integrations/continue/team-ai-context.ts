/**
 * Team AI Context Provider for Continue IDE
 *
 * This context provider adds Team AI awareness to Continue,
 * allowing it to see other registered agents and pending messages.
 *
 * Installation:
 * 1. Copy this file to your Continue config directory
 * 2. Add to your config.json:
 *    {
 *      "contextProviders": [
 *        {
 *          "name": "team-ai",
 *          "params": {}
 *        }
 *      ]
 *    }
 */

import {
  ContextItem,
  ContextProviderDescription,
  ContextProviderExtras,
  IContextProvider,
  LoadSubmenuItemsArgs,
} from "@continuedev/core";
import { execSync } from "child_process";
import { existsSync, readFileSync, readdirSync } from "fs";
import { homedir } from "os";
import { join } from "path";

const TEAM_AI_DIR = join(homedir(), ".team-ai");
const AGENTS_DIR = join(TEAM_AI_DIR, "agents");

interface AgentMetadata {
  id: string;
  name: string;
  state: string;
  current_task: string;
  working_directory: string;
  last_heartbeat: string;
}

class AICenterContextProvider implements IContextProvider {
  get description(): ContextProviderDescription {
    return {
      title: "team-ai",
      displayTitle: "Team AI",
      description: "Multi-agent awareness and communication",
      type: "submenu",
    };
  }

  private getAgents(): AgentMetadata[] {
    const agents: AgentMetadata[] = [];

    if (!existsSync(AGENTS_DIR)) {
      return agents;
    }

    for (const agentId of readdirSync(AGENTS_DIR)) {
      const metadataPath = join(AGENTS_DIR, agentId, "metadata.json");
      if (existsSync(metadataPath)) {
        try {
          const metadata = JSON.parse(readFileSync(metadataPath, "utf-8"));
          agents.push(metadata);
        } catch {
          // Skip invalid metadata
        }
      }
    }

    return agents;
  }

  private getPendingMessages(agentId: string): string[] {
    const todoDir = join(AGENTS_DIR, agentId, "incoming", "todo");
    if (!existsSync(todoDir)) {
      return [];
    }

    return readdirSync(todoDir).filter((f) => f.endsWith(".md"));
  }

  private readMessage(agentId: string, filename: string): string {
    const messagePath = join(AGENTS_DIR, agentId, "incoming", "todo", filename);
    if (existsSync(messagePath)) {
      return readFileSync(messagePath, "utf-8");
    }
    return "";
  }

  async loadSubmenuItems(
    args: LoadSubmenuItemsArgs
  ): Promise<ContextItem[]> {
    const items: ContextItem[] = [];

    // Add overview item
    items.push({
      id: "team-ai-overview",
      name: "Overview",
      description: "Team AI system overview",
    });

    // Add each agent as a submenu item
    const agents = this.getAgents();
    for (const agent of agents) {
      const pendingCount = this.getPendingMessages(agent.id).length;
      items.push({
        id: `agent-${agent.id}`,
        name: agent.name,
        description: `${agent.state} - ${pendingCount} pending messages`,
      });
    }

    return items;
  }

  async getContextItems(
    query: string,
    extras: ContextProviderExtras
  ): Promise<ContextItem[]> {
    const items: ContextItem[] = [];

    if (query === "team-ai-overview" || query === "") {
      // Return overview
      const agents = this.getAgents();
      let content = `# Team AI Overview\n\n`;
      content += `**Registered Agents:** ${agents.length}\n\n`;

      if (agents.length > 0) {
        content += `## Active Agents\n\n`;
        content += `| Name | State | Current Task | Directory |\n`;
        content += `|------|-------|--------------|-----------||\n`;

        for (const agent of agents) {
          const task = agent.current_task?.substring(0, 30) || "-";
          const dir = agent.working_directory?.split("/").pop() || "-";
          content += `| ${agent.name} | ${agent.state} | ${task} | ${dir} |\n`;
        }
      }

      content += `\n## Available Commands\n\n`;
      content += `- \`ai-list\`: List all agents\n`;
      content += `- \`ai-register --name "name" --command "task"\`: Register this session\n`;
      content += `- \`ai-send TARGET --subject "subj" --body "msg"\`: Send message\n`;
      content += `- \`ai-check AGENT_ID\`: Check messages\n`;

      items.push({
        name: "Team AI Overview",
        description: "Multi-agent system status",
        content,
      });
    } else if (query.startsWith("agent-")) {
      // Return specific agent details
      const agentId = query.replace("agent-", "");
      const metadataPath = join(AGENTS_DIR, agentId, "metadata.json");

      if (existsSync(metadataPath)) {
        const metadata = JSON.parse(readFileSync(metadataPath, "utf-8"));
        const messages = this.getPendingMessages(agentId);

        let content = `# Agent: ${metadata.name}\n\n`;
        content += `- **ID:** ${metadata.id}\n`;
        content += `- **State:** ${metadata.state}\n`;
        content += `- **Task:** ${metadata.current_task}\n`;
        content += `- **Directory:** ${metadata.working_directory}\n`;
        content += `- **Last Heartbeat:** ${metadata.last_heartbeat}\n\n`;

        if (messages.length > 0) {
          content += `## Pending Messages (${messages.length})\n\n`;
          for (const msg of messages) {
            const msgContent = this.readMessage(agentId, msg);
            const subjectMatch = msgContent.match(/^# Subject: (.+)$/m);
            const subject = subjectMatch ? subjectMatch[1] : "(no subject)";
            content += `- ${msg}: ${subject}\n`;
          }
        }

        items.push({
          name: `Agent: ${metadata.name}`,
          description: `${metadata.state} - ${metadata.current_task}`,
          content,
        });
      }
    }

    return items;
  }
}

export default AICenterContextProvider;
