---
name: docs-specs
description: 'Generate feature specifications from a Word document and convert them into GitHub issues'
argument-hint: "[requirement_document_path] [target_project]"
---

# Docs Specs Skill

Extract feature requirements from a Word document, generate one specification file per feature, and create matching GitHub issues linked to those specs.

## Use This Skill When

- Requirements are provided in a Word document from stakeholders.
- The team needs implementation-ready feature specs in the documentation site.
- The team wants GitHub issues created from those specs.

## Inputs

- `requirement_document_path`: SharePoint or OneDrive URL to the requirement document.
- `target_project`: Existing GitHub project URL (if available).
- Documentation root folder (default: `/documentation`).

## Required References

- Specification template: `plugins/docusaurops/skills/docs-specs/spec.template.md`
- Output docs location: `/documentation/docs`

## Workflow

1. Read the requirement document.
2. Extract distinct features or requirement groups.
3. Generate one markdown specification file per feature using the template.
4. If requirement details are missing, add comments in the Word document and add matching placeholders in the spec files.
5. Create or reuse a GitHub project and create one issue per generated specification.
6. Link each issue to its full spec in the documentation.

## Detailed Procedure

1. Read source document

- Use the Word MCP tool `workiq_mcpWordServer` server from `.mcp.json` to read the document from `requirement_document_path`.
- Parse all functional requirements, constraints, assumptions, and acceptance criteria.

2. Build feature list

- Group requirements by feature.
- Keep features independent when possible.
- Do not merge unrelated features into a single spec file.

3. Generate specification files

- Follow `spec.template.md` for structure.
- Create one markdown file per feature in `/documentation/docs`.
- File naming rule: use a stable feature-based name, for example `login_spec.md`, or preserve requirement IDs when available.
- Each specification must include at least:
	- Feature overview
	- User stories or use cases
	- Acceptance criteria
	- Constraints, dependencies, and assumptions
	- Open questions (if any)

4. Handle missing information

- If the source document is incomplete, add comments directly in the Word document requesting missing details.
- Each comment must identify the agent as the source.
- Add a corresponding placeholder section in the generated spec file indicating missing information.

5. Create GitHub issues

- Reuse `target_project` if provided.
- Using the `github-mcp-server` MCP server, create one issue per generated spec.
- Issue content should be a condensed implementation summary, not the full spec.
- Include a link to the full specification page in the published DocusaurOps site. To determine the URL, use the environment variables `ENV_DOCUSAUROPS_ROOT_SITE_URL` and `ENV_BASE_URL` from the `.env.docusaurops` file to construct the project URL (ex: `https://{{ENV_DOCUSAUROPS_ROOT_SITE_URL}}/{{ENV_BASE_URL}}/specs/<feature-spec-based-on-file-name>`).

## Output Requirements

- One spec file per feature in `/documentation/docs`.
- One GitHub issue per spec.
- Every issue links to exactly one full spec based on the DocusaurOps documentation site.
- Missing information is tracked in both the Word doc comments and spec placeholders.

## Quality Checklist

- No typos in generated headings and filenames.
- Specs are complete enough for developers to implement.
- Acceptance criteria are explicit and testable.
- Issues are concise and actionable.
- Documentation links are valid.