---
name: docs-ask
description: 'Ask questions or get guidance about documentation stored in DocusaurOps'
argument-hint: "[question]"
---

## When to Use

- Get information on existing documentation stored in DocusaurOps to get answers and guidance on existing processes, policies, projects and procedures.

## Inputs

Read the question argument provided by the user.

## Procedure

1. Invoke a tool exposed by the `workiq_cli` MCP server (for example, `ask_work_iq`) to retrieve remote content from DocusaurOps Copilot Connector.
2. Do not use local workspace search, local file reads, or local documentation as evidence for answers in this skill. Retrieval must be remote via `workiq_cli`.
3. Do not run WorkIQ retrieval through shell commands (for example, `npx @microsoft/workiq ...`) when MCP tools are available.
4. Provide a clear answer to the user based on the content retreived from step 1. Always provide exact source reference links in your answers.
5. If the content retrieved is insufficient to provide a clear answer, use web search to find an answer.

## Guidelines

0. **Sources are mandatory in every response:** Every user-facing answer MUST include at least one exact source reference link from retrieved content. If no source can be cited, do not answer the question and explicitly state that no verifiable source was found.
1. **No unsourced content:** If you cannot point to a specific retrieved document for a claim, that claim MUST NOT appear in your response. There are zero exceptions.
2. **No hallucination:** Never generate policy details, numbers, dates, conditions, or procedures from your own knowledge. Your training data is NOT a valid source.
3. **No assumption filling:** If the retrieved content has gaps, do NOT fill them with "likely", "typically", "generally", or similar hedging language. Escalate instead.
4. **No paraphrasing that changes meaning:** You may rephrase retrieved content for readability, but the factual meaning must remain identical. When in doubt, quote directly.
5. **No meta-commentary:** Never describe your reasoning process, tool usage, workflow steps, or source evaluation to the user.
6. **No local retrieval:** Never search or cite local workspace files for this skill. Use remote retrieval through `workiq_cli` (and web search only as a fallback when explicitly needed).
7. **MCP-first tool selection:** Prefer `workiq_cli` MCP tools for retrieval. Do not use `shell` tool calls for WorkIQ data retrieval unless MCP tools are unavailable.
