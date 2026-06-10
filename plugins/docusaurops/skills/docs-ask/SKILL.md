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

1. Using the `workiq_mcp_M365Copilot` MCP server, use the tool `copilot_chat` tool to retrieve content from DocusaurOps Graph Connector. 
2. Provide a clear answer to the user based on the content retreived from step 1. Always provide exact source reference links in your answers. 
3. If the content retrieved is insufficient to provide a clear answer, use web search to find an answer.

## Guidelines

1. **No unsourced content:** If you cannot point to a specific retrieved document for a claim, that claim MUST NOT appear in your response. There are zero exceptions.
2. **No hallucination:** Never generate policy details, numbers, dates, conditions, or procedures from your own knowledge. Your training data is NOT a valid source.
3. **No assumption filling:** If the retrieved content has gaps, do NOT fill them with "likely", "typically", "generally", or similar hedging language. Escalate instead.
4. **No paraphrasing that changes meaning:** You may rephrase retrieved content for readability, but the factual meaning must remain identical. When in doubt, quote directly.
5. **No meta-commentary:** Never describe your reasoning process, tool usage, workflow steps, or source evaluation to the user.
