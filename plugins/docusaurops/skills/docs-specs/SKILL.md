---
name: docs-specs
description: 'Generate requirement specifications from a Word document and translate them into proper GitHub workable issues'
argument-hint: "[requirement_document_path] [target_project]"
---

# DocusaurOps Setup

Generate requirement specifications from a Word document and translate them into proper GitHub workable issues.

## When to Use

- Understanding and extracting key requirement specifications from a Word document produced by analysis or stakeholders and translating them into proper GitHub workable issues for developers or architects.
- Create issues in an existing project or create a new one for the generated issues.

## Inputs

- Input in the document to read from and where to extract the requirements specifications. Confirm the target documentation root folder (default: `/documentation`).
- Existing GitHub project URL if already exists. The user should have access to the project.

## Procedure

1. Using the `workiq_mcpWordServer` MCP server from `.mcp.json`, read the document from the URL passed as parameter.

2. From the content, generate a specification following instructions in the `spec.template.md` file. Each specification should be generated as a separate issue with its own acceptance criteria, description, etc. Output specifications in markdown format and integrated in hte `/documentation/docs` folder respecting the existing style and structure.

3. If there ae not enough details in the document to generate a complete specification, add comments directly in the Word document requesting for the missing information. For each comment added, also add a placeholder in the generated specification indicating that there is missing information that needs to be filled in. Make sure you identify yourself when adding comments in the document so stakeholders know an agent processed the document.

4. On the current repository, use an exsting GitHUb proejct to create issues form the generated specs. The issue should be a condesned version of the specification in the documentation site with a link to the full specification in the documentation. If no project exists, create a new one and use it to create the issues.


