
import { useState } from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import useBaseUrl from '@docusaurus/useBaseUrl';
import ThemedImage from '@theme/ThemedImage';
import Head from '@docusaurus/Head';
import styles from './index.module.css';

const commands = [
  {
    comment: '// Install the plugin',
    cmd: 'copilot plugin install docusaurops@docusaurops-plugins'
  },
  {
    comment: '// Scaffold a new documentation site using the company template',
    cmd: `copilot --agent docusaurops:docusaurops --prompt "Setup documentation for my project 'HR Smart Assistant' with url 'hr-smart-assistant'"`,
    video: 'https://www.youtube.com/embed/rcS7U7C5ufg'
  },
  {
    comment: '// Ask about content across all documentation sites in the DocusaurOps network',
    cmd: `copilot --agent docusaurops:docusaurops --prompt "Did we already implement a project using Azure Application Gateway? If yes, which one and what configuration did we use?"`,
    video: 'https://www.youtube.com/embed/xGUISHrJpyo'
  },
  {
    comment: '// Generate specifications from a document',
    cmd: `copilot --agent docusaurops:docusaurops --prompt "Generate specifications from requirements document https://myorg.sharepoint.com/sites/hr-smart-assistant/Shared Documents/projects_requirements.docx"`,
    video: 'https://www.youtube.com/embed/cUkXb5Wmd3o',
  },
];

const pillars = [
  {
    title: 'GitHub Copilot CLI + VS Code Native',
    description: 'Run the same documentation automation workflow from terminal or editor with consistent behavior.',
    icon: '/img/gh_copilot.svg',
  },
  {
    title: 'Documentation-As-Code Lifecycle',
    description: 'Generate, version, review, and deploy Markdown documentation using the well-known Docusaurus tool',
    icon: '/img/docusaurus.svg',
  },
  {
    title: 'Search-Ready Knowledge Mesh',
    description: 'Expose documentation through Copilot connectors and WorkIQ and create an organizational knowledge mesh network.',
    icon: '/img/knowledge-graph.svg',
  },
];

const cards = [
  {
    title: 'Create docs in minutes',
    description: 'Bootstrap a complete Docusaurus site template, metadata, and deploy pipeline from a single prompt.',
    href: '/docs/getting_started',
  },
  {
    title: "Operate one 'self-service' shared platform",
    description: 'Host and scale multiple team sites on one Azure foundation with reusable IaC and workflow orchestration supporting an on-demand strategy.',
    href: '/docs/getting_started',
  },
  {
    title: 'Access and feed organizational knowledge with WorkIQ',
    description: 'Use the DocusaurOps agent to retrieve architecture, process, and runbook knowledge instantly leveraging WorkIQ tools like Word MCP Server and WorkIQ CLI.',
    href: '/docs/development/getting_started',
  },
];

const primaryBtn = 'no-underline rounded-[10px] font-bold py-[0.78rem] px-[1.2rem] transition-[transform,box-shadow,border-color] duration-200 ease-in-out text-[#04111c] bg-[linear-gradient(120deg,#72dfbf,#20c997)] shadow-[0_16px_28px_rgba(32,201,151,0.27)] hover:-translate-y-px hover:shadow-[0_20px_32px_rgba(32,201,151,0.35)]';
const ghostBtn = 'no-underline rounded-[10px] font-bold py-[0.78rem] px-[1.2rem] transition-[transform,box-shadow,border-color] duration-200 ease-in-out text-[#dce7ff] border border-[rgba(195,208,238,0.6)] bg-[rgba(5,12,30,0.5)] hover:-translate-y-px hover:border-[#f7fbff]';

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  const logoLight = useBaseUrl('/img/logo-light.svg');
  const githubLogo = useBaseUrl('/img/gh_logo.svg');
  const lifecycleImg = useBaseUrl('/img/docusaurops_lifecycle.png');
  const [videoUrl, setVideoUrl] = useState<string | null>(null);

  return (
    <Layout title={siteConfig.title} description="Engineering knowledge platform powered by DocusaurOps and Copilot">
      <Head>
        <meta property="DocusaurOpsPageType" name="DocusaurOpsPageType" content="site_home" />
      </Head>

      <main className="flex flex-col gap-10 pb-12">
        {videoUrl && (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm"
            onClick={() => setVideoUrl(null)}
          >
            <div
              className="relative w-full max-w-3xl mx-4 rounded-2xl overflow-hidden shadow-2xl border border-[rgba(183,241,221,0.25)]"
              onClick={(e) => e.stopPropagation()}
            >
              <button
                onClick={() => setVideoUrl(null)}
                className="absolute top-3 right-3 z-10 flex items-center justify-center w-8 h-8 rounded-full bg-[rgba(2,8,22,0.8)] text-[#dce7ff] hover:bg-[rgba(32,201,151,0.3)] transition-colors cursor-pointer border-0"
                aria-label="Close"
              >
                ✕
              </button>
              <div className="aspect-video">
                <iframe
                  src={`${videoUrl}?autoplay=1`}
                  className="w-full h-full"
                  allow="autoplay; encrypted-media"
                  allowFullScreen
                />
              </div>
            </div>
          </div>
        )}
        <section className="relative overflow-hidden px-[clamp(1rem,4vw,3rem)] pt-[clamp(2rem,4vw,3.6rem)] pb-[clamp(3rem,7vw,5.8rem)]">
          <div className={styles.heroGlow} />
          <div className="max-w-[1220px] mx-auto grid grid-cols-1 gap-5">
            <a
              href="https://info.microsoft.com/Agents-League-Hackathon-Registration.html"
              target="_blank"
              rel="noopener noreferrer"
              className="w-[70%] inline-flex items-center gap-[0.4rem] bg-[linear-gradient(90deg,#7c3aed22,#2563eb22)] border border-[#7c3aed66] text-[#a78bfa] text-[0.78rem] font-semibold tracking-[0.04em] uppercase py-[0.35rem] px-[0.85rem] rounded-full mb-5 no-underline transition-[background,border-color] duration-200 hover:bg-[linear-gradient(90deg,#7c3aed44,#2563eb44)] hover:border-[#7c3aedaa] hover:no-underline"
            >
              Made with ❤️ and ☕ for the 🏆 Agents League Hackathon &mdash; Creative Apps category // June 2026 By Franck Cornu
            </a>
            <div className="flex items-start gap-4 flex-wrap">
              <h1 className="m-0 max-w-[18ch] text-[#f7fbff] font-['Space_Grotesk',sans-serif] text-[clamp(2rem,4.2vw,4.3rem)] leading-[1.02] tracking-[-0.03em] flex-1 min-w-0">
                Transform Your Organizational Knowledge Into a Strategic Asset
              </h1>
              <div>
              <div className="flex justify-end">
              <ThemedImage
                alt="DocusaurOps Logo"
                className="w-[80%]  opacity-90"
                sources={{ light: logoLight, dark: logoLight }}
              />
            </div>
            <a
              href="https://github.com/FranckyC/agents-league-docusaurops.git"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-3 inline-flex items-center gap-2 text-[#c4d0ea] hover:text-[#f7fbff] no-underline transition-colors"
              aria-label="Open repository clone URL on GitHub"
            >
              <img src={githubLogo} alt="GitHub" className="w-4 h-4" />
              <span className="text-[0.78rem] font-semibold tracking-[0.03em]">Clone URL</span>
              <span className="font-['JetBrains_Mono',monospace] text-[0.72rem] text-[#8da3cf]">
                https://github.com/FranckyC/agents-league-docusaurops.git
              </span>
            </a>
              </div>
            </div>

            <img
              src={lifecycleImg}
              alt="DocusaurOps Lifecycle"
              className="w-full h-auto block"
            />
            <p className="m-0 max-w-[66ch] text-[#c4d0ea] text-[clamp(1rem,1.4vw,1.2rem)] leading-[1.72] mt-4">
              DocusaurOps unifies infrastructure automation, docs‑as‑code templates, and Microsoft WorkIQ intelligence to eliminate the hassle of documentation setup, allowing your teams to produce reliable, high‑quality content throughout the entire project lifecycle.
            </p>
            <div className="flex flex-wrap gap-[0.85rem]">
              <a href="/docs/getting_started" className={primaryBtn}>Get Started with the plugin</a>
              <a href="/docs/deployment" className={ghostBtn}>Deploy it to your org!</a>
            </div>
            <div className="max-w-[850px] mt-2 rounded-2xl border border-[rgba(183,241,221,0.35)] bg-[rgba(2,8,22,0.76)] shadow-[0_24px_42px_rgba(2,8,24,0.48)] overflow-hidden backdrop-blur-[8px]">
              <div className="border-b border-[rgba(195,208,238,0.2)] py-[0.7rem] px-[0.85rem] flex items-center gap-[0.4rem]">
                <span className="w-[0.62rem] h-[0.62rem] rounded-full bg-[#ff5f56]" />
                <span className="w-[0.62rem] h-[0.62rem] rounded-full bg-[#ffbd2e]" />
                <span className="w-[0.62rem] h-[0.62rem] rounded-full bg-[#27c93f]" />
                <p className="m-0 ml-auto text-[#8da3cf] text-[0.78rem] lowercase tracking-[0.08em]">copilot-cli</p>
              </div>
              <div className="py-[0.9rem] px-4">
                {commands.map(({ comment, cmd, video }, i) => (
                  <div
                    key={cmd}
                    onClick={video ? () => setVideoUrl(video) : undefined}
                    className={`py-2 font-['JetBrains_Mono',monospace] text-[0.81rem] leading-[1.68]${
                      i < commands.length - 1 ? ' border-b border-[rgba(195,208,238,0.14)]' : ''
                    }${video ? ' cursor-pointer group' : ''}`}
                  >
                    <p className="m-0 text-[#64799f] italic">{comment}</p>
                    <p className="m-0 text-[#eef5ff]">
                      <span className="text-[#72dfbf] mr-[0.4rem]">$</span>{cmd}
                      {video && (
                        <span className="ml-3 inline-flex items-center gap-2 rounded-full border border-[#72dfbf] bg-[rgba(114,223,191,0.14)] px-3 py-1 text-[0.82rem] font-bold tracking-[0.02em] text-[#b9ffe8] opacity-95 group-hover:bg-[rgba(114,223,191,0.24)] group-hover:text-[#eafff8] transition-colors">
                          <span className="text-[0.95rem]" aria-hidden="true">🎞️</span>
                          watch demo
                        </span>
                      )}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        <section className="px-[clamp(1rem,4vw,3rem)]">
          <div className="max-w-[1220px] mx-auto grid gap-4 grid-cols-1 lg:grid-cols-3">
            {pillars.map(({ title, description, icon }) => (
              <article key={title} className={styles.pillarCard}>
                <div className="flex items-center gap-[0.6rem]">
                  {icon && <img src={icon} alt="" aria-hidden="true" className="w-6 h-6 shrink-0" />}
                  <h2 className="m-0 font-['Space_Grotesk',sans-serif] text-[1.16rem]">{title}</h2>
                </div>
                <p className="mt-[0.72rem] mb-0 text-[var(--ifm-font-color-secondary)] leading-[1.66]">{description}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="px-[clamp(1rem,4vw,3rem)]">
          <div className="max-w-[1220px] mx-auto">
            <div className="flex flex-col lg:flex-row lg:justify-between lg:items-end items-start gap-4 mb-4">
              <h2 className="m-0 font-['Space_Grotesk',sans-serif] text-[clamp(1.45rem,2.2vw,2rem)]">From template to searchable and collaborative documentation platform</h2>      
            </div>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
              {cards.map(({ title, description, href }) => (
                <article key={title} className="border border-[var(--ifm-table-border-color)] rounded-[14px] p-[1.3rem] bg-[var(--ifm-background-surface-color)] transition-[transform,border-color] duration-200 ease-in-out hover:-translate-y-0.5 hover:border-[rgba(32,201,151,0.55)]">
                  <h3 className="m-0 text-[1.1rem] font-['Space_Grotesk',sans-serif]">{title}</h3>
                  <p className="mt-[0.72rem] mb-0 text-[var(--ifm-font-color-secondary)] leading-[1.66]">{description}</p>
                  <a href={href} className="mt-4 inline-block no-underline text-[var(--ifm-color-primary-darkest)] font-bold">Open guide</a>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="px-[clamp(1rem,4vw,3rem)]">
          <div className={`max-w-[1220px] mx-auto ${styles.ctaPanel}`}>
            <h2 className="m-0 font-['Space_Grotesk',sans-serif]">Ready to use DocusaurOps in your organization?</h2>
            <p className="mt-[0.8rem] mb-0 mx-auto text-[var(--ifm-font-color-secondary)] leading-[1.7] max-w-[70ch]">
              Start with the setup flow, provision the Azure core infrastructure, then onboard repositories with the plugin. We detailed the entire recipe.
            </p>
            <div className="flex flex-wrap gap-[0.85rem] justify-center mt-5">
              <a href="/docs/deployment" className={primaryBtn}>Setup Documentation</a>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}


