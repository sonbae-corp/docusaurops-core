---
name: docs-setup
description: 'Set up or upgrade a solution with the latest DocusaurOps documentation template by downloading, merging, configuring, running, and cleaning up the documentation project.'
argument-hint: "[site_title] [site_slug] [site_tagline] [repository_url] [contact_email] [project_technologies]"
---

# DocusaurOps Setup

Set up or upgrade a solution with the latest DocusaurOps documentation template.

## When to Use

- Initialize a new documentation site from the DocusaurOps template
- Upgrade an existing documentation site to the latest DocusaurOps template version

## Inputs

Read provided skill arguments first and use them as defaults. Confirm the target documentation root folder (default: `/documentation`).

Argument-to-variable mapping:

| Argument | Variable |
|---|---|
| `site_title` | `ENV_SITE_TITLE` |
| `site_slug` | `ENV_BASE_URL` |
| `site_tagline` | `ENV_SITE_TAGLINE` |
| `repository_url` | `ENV_REPOSITORY_URL` |
| `contact_email` | `ENV_PROJECT_CONTACT` |
| `project_technologies` | `ENV_PROJECT_TECHNOLOGIES` |

## Procedure

1. Download the latest template archive from:
   `https://api.github.com/repos/sonbae-corp/docusaurops-template/zipball/main`

   Use header with the current user token retrieved via `gh auth token`: `Authorization: Bearer <user token>`

2. Extract the archive into a temporary local folder.

3. Confirm the target root folder with the user (default: `/documentation`).

4. Copy and merge extracted files into the confirmed target root, preserving relative paths. Read specific template instructions from the extracted file `INSTRUCTIONS.md`. The file gives indications on how to install or update from this specific version. Compare the current template version from the existing `VERSION.md` file. If this version is prior to the new one from the template, follow the instructions from the `INSTRUCTIONS.md` file from the new template version. If merge is required, you should always ask the user to review and confirm before continuing.

5. Resolve configuration values from skill arguments (see mapping above). Ask the user only for missing values:
   - `ENV_SITE_TITLE` (required): Site display title (e.g. `My Project Docs`).
   - `ENV_BASE_URL` (required): URL slug for Azure Application Gateway path routing (e.g. `my-project-docs`). Generate from site title if missing. It should be lowercase, without spaces and without slash '/'.
     - Example transformation: `My Project Docs` → `my-project-docs`
   - `ENV_SITE_TAGLINE` (optional): Site tagline (e.g. `Documentation for My Project`).
   - `ENV_REPOSITORY_URL` (optional): GitHub repository URL (e.g. `https://github.com/username/repository`). If missing, infer from current git repository.
   - `ENV_PROJECT_DESCRIPTION` (optional): Short project description (e.g. `This project is a sample documentation site.`). Infer from solution or use a placeholder.
   - `ENV_PROJECT_CONTACT` (optional): Contact email (e.g. `contact@example.com`). Infer from current logged-in user if missing.
   - `ENV_PROJECT_TECHNOLOGIES` (optional): Comma-separated technologies (max 4) (e.g. `JavaScript, Node.js, React`). Infer from solution if missing.
   - `ENV_PROJECT_DOCUSAUROPS_ROOT_SITE_URL` (optional): Absolute URL of the documentation site (e.g. `https://docs.example.com/my-project-docs`) for that project. Use the value `{{ENV_DOCUSAUROPS_ROOT_SITE_URL}}` as host name.

6. Write values to `/documentation/.env.docusaurops`.
   If `.env.docusaurops` already exists, merge with existing values and ask the user to confirm before saving.

7. Replace placeholders in `/.github/workflows/deploy-docs.yml`:
   - `[[ENV_SITE_TITLE]]` → value of `ENV_SITE_TITLE`
   - `[[ENV_BASE_URL]]` → value of `ENV_BASE_URL`
   - `[[ENV_DOC_PATH]]` → documentation folder name chosen by the user (default: `documentation`, no leading/trailing slashes)
   - `[[ENV_DOCUSAUROPS_HOST_REPO]]` → Repository hosting DocusaurOps (default: `sonbae-corp/docusaurops-core`).
   - `[[ENV_ENABLE_AUTH]]` → `true` or `false` (default) based on user choice regarding the authentication for the documentation site. User has to explicity choose to enable authentication if required.

8. Run in `/documentation` (or folder name set by the user):
   ```
   npm i
   ```

9. Optional `DEMO` mode (only when explicitly requested by the user):
   - After the documentation structure is in place, generate fake sample documentation content derivbed from the provided `[[ENV_SITE_TITLE]]` and `[[ENV_PROJECT_TECHNOLOGIES]]` values. The content should be realistic but fictional, and should showcase the capabilities of the documentation site template.
   - Create 3 to 4 pages in `docs/` (or equivalent project docs folder), for example:
     - `architecture`
     - `api-overview`
     - `deployment`  
   - Use appealing, polished markdown structure with realistic but fictional content (headings, tables, code snippets, diagrams, and callouts).
   - Ensure links/sidebar navigation are updated so demo pages are easy to browse.
   - Do not overwrite existing user-authored docs without explicit confirmation.

10. After dependencies install successfully, ask the user whether to start the local server. If yes, run in `/documentation` (or folder name set by the user):
   ```
   npm run start
   ```

11. When the local server starts, open `http://localhost:3000/`.

12. Clean up temporary artifacts (downloaded archive and extraction folder).

## Rules

- Do not perform destructive actions.
- Do not overwrite existing files without merge and user confirmation.
- After the archive is downloaded, use only local file operations for extraction and copy/merge.
- Never create commits on behalf of the user without explicit permission.
- Before running any `git commit`, ask the user for approval first.