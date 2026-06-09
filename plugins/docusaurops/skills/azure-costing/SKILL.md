---
name: azure-costing
description: >
  Determine the infrastructure and operational costs based on a set of Bicep
  templates describing a solution architecture. Produces a Markdown cost estimate
  file with real-time CAD pricing sourced from the Azure Retail Prices API.
---

# Gather Usage Assumptions

Parse the user-provided assumptions from `$ARGUMENTS`.

Assumptions describe the **workload** on the solution (number of users, messages,
tokens, etc.) — they are usage-related, not technical. If no assumptions are
provided or are incomplete to determine a full cost picture, **ask the user**
before proceeding.

## Output file

If the user has not provided a **file name** and **folder path** for the output
Markdown file, **ask the user** before proceeding. For example:

> Where should I save the cost estimate? Please provide a folder path and file
> name (e.g. `documentation/docs/cost-estimate.md`).

**Example assumptions:**

- Daily active users: 1,382
- Messages per user per day: ~5
- Messages per user per month: ~150
- Total messages per month: ~207,300
- Average input tokens per message: ~17,000 (system prompt + tools output)
- Average cached input tokens per message: ~7,500
- Average output tokens per message: ~700

# Inventory All Azure Resources

If the user provides a templates folder path (e.g. `/azure-costing "assumptions..." infrastructure/templates/app`),
read **every** `.bicep` file in that folder recursively. Otherwise, scan the
entire project for all `*.bicep` files and catalog every deployed resource.

- Include **ALL** resources with no exceptions: compute, storage, networking,
  AI services, private endpoints, diagnostics, etc.
- Extract from each resource: **location**, **SKU/tier**, **capacity**, and
  any conditional logic.
- If templates have conditional environment branches (e.g. `tenant.isProduction`),
  **always use the production path**.

# Fetch Real-Time CAD Pricing

Use the Azure Retail Prices API to retrieve current prices for every resource.

- **Base URL:** `https://prices.azure.com/api/retail/prices`
- **OpenAPI spec:** [`azure-retail-prices-openapi.yaml`](./azure-retail-prices-openapi.yaml)
- **Docs:** [Azure Retail Prices REST API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices)
- **Auth:** None required (public API)
- **Pagination:** Max 100 items/page — follow `NextPageLink` for all results
- **Currency:** Always pass `currencyCode=CAD`

## Filter best practices

- `armRegionName eq '<region>'` — use the region from the Bicep templates.
- `priceType eq 'Consumption'` — exclude reservation pricing.
- `isPrimaryMeterRegion eq true` — avoid duplicate meter entries.
- Omit the region filter for global services (e.g. Bot Service).

## Currency conversion

All final prices in the cost estimate must be in **CAD**. When a price is only
available in USD (or another currency), convert it to CAD using the Azure
billing exchange rate. Derive this rate by comparing a well-known resource's
USD and CAD prices returned by the Retail Prices API (e.g. query the same SKU
once with `currencyCode=USD` and once with `currencyCode=CAD`, then compute
the ratio). State the exchange rate used in the **Notes** section of the
output.

## Price lookup fallback chain

Follow this order when looking up a price for any resource or service:

1. **Azure Retail Prices API** — query with `currencyCode=CAD` first. If a
   CAD price is not available, query with `currencyCode=USD` and convert.
2. **Official Microsoft pricing pages** — if the API does not return a result
   (common for AI model token pricing, preview services, etc.), fetch the
   price from the relevant Microsoft pricing pages, for instance:
   - [Azure OpenAI pricing](https://azure.microsoft.com/en-us/pricing/details/azure-openai/)
   - [Azure Private Link pricing](https://azure.microsoft.com/en-ca/pricing/details/private-link/)
   - [Azure pricing overview](https://azure.microsoft.com/en-ca/pricing/)
   Convert any USD prices to CAD using the exchange rate derived above.
3. **Ask the user** — if a price cannot be found through either source above,
   **ask the user** before proceeding. List the specific resource(s) and the
   price unit you need. For example:

   > I could not find pricing for the following resource(s). Please provide
   > the unit prices so I can complete the estimate:
   >
   > | Resource | Price unit needed |
   > |----------|-------------------|
   > | Cohere Command R+ | per 1M input tokens (USD or CAD) |
   > | ... | ... |

# Generate the Cost Estimate File

Produce a **Markdown** (`.md`) file at the path provided by the user, following
the structure below. Instructions between `(( ))` are directives — do not
include them in the output. Replace every `$XX` placeholder with real
calculated values.

````markdown
## Production Deployment Details

The following details are derived from the Bicep templates in `infrastructure/templates/app/`.

| Parameter | Value |
|-----------|-------|
| **Region** | **((region name))** (`((region code))`) |
| **App Service** | ((runtime)), SKU `((sku))`, ((worker count)) worker(s) |
| **AI Foundry** | `Microsoft.CognitiveServices/accounts`, Kind `((kind))`, SKU `((sku))` |
| ... | ((one row per resource from Bicep)) |

---

## Usage Assumptions

(( Format the user-provided assumptions into a table. ))

| Parameter | Value |
|-----------|-------|
| Daily active users | **XX** |
| Messages per user per day | **~XX** |
| Messages per user per month | **~XX** |
| Total messages per month | **~XX** |
| ... | ... |

---

## Infrastructure Costs (Fixed Monthly)

These costs are incurred regardless of usage — the baseline for running the production environment.

### Compute, Data & Platform Services

| Resource | SKU / Tier | Unit Price (CAD) | Calculation | Monthly Cost (CAD) |
|----------|-----------|------------------|-------------|-------------------|
| **App Service Plan** | ((sku)) | $XX/hr | $XX × 730 hrs | **$XX** |
| **Bot Service** | ((tier)) | $XX/1K messages | XX K × $XX/1K | **$XX** |
| ... | ... | ... | ... | ... |

### Private Endpoints (Networking)

(( Only include this section if the Bicep templates deploy private endpoints. ))

Production uses VNet integration with private endpoints for service isolation. Each endpoint is billed at **$XX CAD/hr** (~$XX CAD/month).

| Private Endpoint | Target Service | Monthly Cost (CAD) |
|------------------|---------------|-------------------|
| **App Service** | `Microsoft.Web/sites` | **$XX** |
| **AI Foundry** | `Microsoft.CognitiveServices/accounts` | **$XX** |
| ... | ... | ... |

### Infrastructure Subtotal

| Component | Monthly Cost (CAD) |
|-----------|-------------------|
| Compute, Data & Platform | ~$XX |
| Private Endpoints (XX×) | ~$XX |
| **Subtotal (Infrastructure)** | **~$XX** |

---

## AI Model Costs (Usage-Based Monthly)

(( Only include this section if the solution uses AI models. ))

These costs scale with the number of messages processed. AI model prices are published in USD and converted to CAD at the Azure billing rate (1 USD ≈ XX CAD).

### ((Model Name)) (((deployment type, capacity)))

Prices per **1M tokens**:

| Token Type | Price (USD) | Price (CAD) | Monthly Tokens | Monthly Cost (CAD) |
|------------|------------|------------|----------------|-------------------|
| **Non-cached input** | $XX/1M | $XX/1M | XX × XX = **XX** | **$XX** |
| **Cached input** | $XX/1M | $XX/1M | XX × XX = **XX** | **$XX** |
| **Output** | $XX/1M | $XX/1M | XX × XX = **XX** | **$XX** |

**((Model Name)) subtotal: $XX CAD/month**

(( Repeat for each additional model used in the solution. ))

**AI Models subtotal: $XX CAD/month**

---

## Total Monthly Estimate

| Category | Monthly Cost (CAD) |
|----------|-------------------|
| Compute, Data & Platform Services | ~$XX |
| Private Endpoints (XX×) | ~$XX |
| AI Models | ~$XX |
| **Total** | **~$XX CAD** |

> **⚠️ Cost driver**
>
> (( Identify the single largest cost component and explain what levers can reduce it. ))

---

## Cost Optimization Opportunities

(( List realistic strategies to reduce costs. ))

| Strategy | Potential Savings | Description |
|----------|-------------------|-------------|
| **((strategy))** | ((estimate)) | ((explanation)) |
| ... | ... | ... |

---

## Notes

(( Include sourcing notes and disclaimers. ))

- **Currency:** All costs are presented in **CAD**.
- **Exchange rate:** Prices originally in USD were converted at **1 USD ≈ XX CAD**, derived from Azure Retail Prices API rate comparisons.
- **All infrastructure prices** are sourced from the Azure Retail Prices API with `currencyCode=CAD` and `armRegionName=((region))`.
- **AI model prices** are sourced from official Microsoft pricing pages in USD and converted to CAD using the rate above.
- **Private endpoint pricing** is $XX USD/hr per endpoint (~$XX CAD/hr) as published on the [Azure Private Link pricing page](https://azure.microsoft.com/en-ca/pricing/details/private-link/).
- **User-provided prices:** ((List any prices that were provided directly by the user, or remove this bullet if none.))
- ...
````