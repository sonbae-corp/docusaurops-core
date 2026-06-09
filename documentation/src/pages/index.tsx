
import { useRef, useCallback } from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import { wrapWc } from 'wc-react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import ThemedImage from '@theme/ThemedImage';
import Head from '@docusaurus/Head';
import BrowserOnly from '@docusaurus/BrowserOnly';

// ── Inline SVG icons ──────────────────────────────────────────────────────────

function IconInfo() {
  return (
    <svg className="w-8 h-8" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z" />
    </svg>
  );
}

function IconCode() {
  return (
    <svg className="w-8 h-8" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" d="M17.25 6.75L22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3l-4.5 16.5" />
    </svg>
  );
}

function IconSparkles() {
  return (
    <svg className="w-8 h-8" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456z" />
    </svg>
  );
}

function IconShare() {
  return (
    <svg className="w-8 h-8" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" d="M7.217 10.907a2.25 2.25 0 100 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186l9.566-5.314m-9.566 7.5l9.566 5.314m0 0a2.25 2.25 0 103.935 2.186 2.25 2.25 0 00-3.935-2.186zm0-12.814a2.25 2.25 0 103.933-2.185 2.25 2.25 0 00-3.933 2.185z" />
    </svg>
  );
}

function IconPerson() {
  return (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
    </svg>
  );
}

// ── Static data ───────────────────────────────────────────────────────────────

const infoCards = [
  {
    Icon: IconCode,
    title: 'Documentation as Code',
    description:
      'Build beautiful sites using Markdown and Docusaurus. Install the Copilot plugin, say "Setup documentation", and DocusaurOps creates the site, handles CI pipelines, and deploys everything for you.',
    href: '/docs/intro#what-DocusaurOps-offers',
  },
  {
    Icon: IconSparkles,
    title: 'DocusaurOps GitHub Copilot Agent',
    description:
      'Ask the DocusaurOps agent "Where is the documentation for project X?" and get precise answers from every indexed site on the platform — directly inside VS Code or the Copilot CLI.',
    href: 'https://github.com/FranckyC/agents-league-docusaurops/releases',
  },
  {
    Icon: IconShare,
    title: 'Knowledge Sharing & Best Practices',
    description:
      'Discover curated best practices, shared tools, and proven patterns from teams across the organization — so every team can deliver better work, faster, without reinventing the wheel.',
    href: '/docs/intro#what-benefits',
  },
];

const featureCards = [
  {
    imgSrc: '/img/app.png',
    title: 'Centralized Portal',
    description:
      'One centralized website aggregating content from every documentation site. One URL for shared organizational knowledge.',
    linkLabel: 'Explore the portal',
    href: '/docs/intro',
  },
  {
    imgSrc: '/img/github_copilot.png',
    title: 'GitHub Copilot Agent',
    description:
      'Your "do it all" agent for engineering teams. Get technical best practices, access internal content, and run DocusaurOps tools without leaving Visual Studio Code or the GitHub Copilot CLI.',
    linkLabel: 'Meet the agent',
    href: 'https://github.com/FranckyC/agents-league-docusaurops/releases',
  },
  {
    imgSrc: '/img/copilot.svg',
    title: 'AI-Powered Discovery',
    description:
      'The DocusaurOps GitHub Copilot Copilot agent indexes all integrated sites thanks to a dedicated Copilot connector. Ask in natural language and get relevant answers with direct links back to the source documentation.',
    linkLabel: 'Meet the agent',
    href: '/docs/intro#what-DocusaurOps-offers',
  },
];

const limitationCards = [
  {
    title: 'No Permissions Management',
    description:
      'DocusaurOps does not manage access control. Content published on the platform is assumed suitable for organization-wide consumption.',
  },
  {
    title: 'No Content Ownership',
    description:
      'You are responsible for your own content. Ensure nothing published discloses private or confidential information.',
  },
  {
    title: 'No Application Hosting',
    description:
      'DocusaurOps is a documentation platform, not a free hosting service. Only documentation sites are supported — not custom applications.',
  },
];

// ── Page component ────────────────────────────────────────────────────────────

export default function Home() {

  const { siteConfig } = useDocusaurusContext();

  // Hoist useBaseUrl calls to top level — never inside BrowserOnly callbacks
  const logoLight = useBaseUrl('/img/logo-light.svg');
  const logoDark  = useBaseUrl('/img/logo-dark.svg');

  // ── CSS scroll-snap carousel ──
  const viewportRef = useRef<HTMLDivElement>(null);

  const scrollPrev = useCallback(() => {
    viewportRef.current?.scrollBy({ left: -viewportRef.current.clientWidth, behavior: 'smooth' });
  }, []);
  const scrollNext = useCallback(() => {
    viewportRef.current?.scrollBy({ left: viewportRef.current.clientWidth, behavior: 'smooth' });
  }, []);

  return (
    <Layout title={siteConfig.title} description="Engineering Knowledge Platform">
      <Head>
        <meta property="DocusaurOpsPageType" name="DocusaurOpsPageType" content="site_home" />
      </Head>

      <main>

        {/* ── Hero ─────────────────────────────────────────────────────────── */}
        <section className="bg-[#fdf4ef] dark:bg-slate-900 py-16 px-4">
          <div className="max-w-4xl mx-auto flex flex-col md:flex-row items-center gap-8 md:gap-12">
            <ThemedImage
              alt="DocusaurOps Logo"
              className="w-36 md:w-44 flex-none"
              sources={{ light: logoLight, dark: logoDark }}
            />
            <div className="text-center md:text-left">
              <h1 className="text-4xl md:text-5xl font-bold text-slate-900 dark:text-white tracking-tight m-0 mb-3">
                DocusaurOps
              </h1>
              <p className="text-xl text-slate-700 dark:text-slate-200 font-medium m-0 mb-2">
                Welcome to DocusaurOps — your development AI companion
              </p>
              <p className="text-base text-slate-500 dark:text-slate-400 m-0">
                The single reference point for technical content across your organization.
              </p>
            </div>
          </div>
        </section>

        {/* ── Info cards ───────────────────────────────────────────────────── */}
        <section className="py-12 px-4">
          <div className="max-w-6xl mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {infoCards.map(({ Icon, title, description, href }) => (
              <a
                key={title}
                href={href}
                className="flex gap-4 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-6 hover:shadow-md transition-shadow no-underline group"
              >
                <div className="flex-none text-slate-400 dark:text-slate-500 group-hover:text-[#D04A02] transition-colors mt-0.5">
                  <Icon />
                </div>
                <div>
                  <h3 className="text-[#D04A02] font-semibold text-base m-0 mb-1 leading-snug">
                    {title}
                  </h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400 m-0 leading-relaxed">
                    {description}
                  </p>
                </div>
              </a>
            ))}
          </div>
        </section>

        {/* ── Feature cards ────────────────────────────────────────────────── */}
        <section className="bg-slate-50 dark:bg-slate-800 py-12 px-4">
          <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-6">
            {featureCards.map(({ imgSrc, title, description, linkLabel, href }) => (
              <div
                key={title}
                className="bg-white dark:bg-slate-700 rounded-xl shadow-sm hover:shadow-md transition-shadow overflow-hidden flex flex-col"
              >
                <div className="flex items-center justify-center bg-slate-100 dark:bg-slate-600 h-40 p-6">
                  <img src={imgSrc} alt={title} className="max-h-full max-w-full object-contain" />
                </div>
                <div className="p-6 flex flex-col flex-1">
                  <h3 className="font-bold text-slate-900 dark:text-white text-lg m-0 mb-2">
                    {title}
                  </h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400 m-0 leading-relaxed flex-1">
                    {description}
                  </p>
                  <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-600">
                    <a
                      href={href}
                      className="inline-flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400 hover:text-[#D04A02] dark:hover:text-[#D04A02] transition-colors no-underline"
                    >
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                      </svg>
                      {linkLabel}
                    </a>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* ── Projects carousel ────────────────────────────────────────────── */}
        <section className="py-14 px-4">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-2xl font-bold text-center mb-2 text-slate-900 dark:text-white">
              Projects integrated with DocusaurOps
            </h2>
            <p className="text-center text-slate-500 dark:text-slate-400 text-sm mb-10">
              Explore the projects already publishing their documentation through DocusaurOps.
            </p>

            <div className="relative">
              {/* Prev / Next buttons */}
              <button
                onClick={scrollPrev}
                aria-label="Scroll left"
                className="absolute -left-4 top-1/2 -translate-y-1/2 z-10 w-9 h-9 rounded-full bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 shadow-md flex items-center justify-center text-slate-500 hover:text-[#D04A02] transition-colors"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" /></svg>
              </button>
              <button
                onClick={scrollNext}
                aria-label="Scroll right"
                className="absolute -right-4 top-1/2 -translate-y-1/2 z-10 w-9 h-9 rounded-full bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 shadow-md flex items-center justify-center text-slate-500 hover:text-[#D04A02] transition-colors"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" /></svg>
              </button>

            </div>
          </div>
        </section>

        {/* ── Limitations ──────────────────────────────────────────────────── */}
        <section className="bg-slate-50 dark:bg-slate-800 py-12 px-4">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-2xl font-bold text-center mb-1 text-slate-900 dark:text-white">
              What DocusaurOps doesn&apos;t include
            </h2>
            <p className="text-center text-slate-500 dark:text-slate-400 text-sm mb-8">
              Set the right expectations before you get started.
            </p>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {limitationCards.map(({ title, description }) => (
                <div
                  key={title}
                  className="bg-white dark:bg-slate-700 rounded-xl p-6 border border-slate-200 dark:border-slate-600"
                >
                  <div className="text-xl mb-3">❌</div>
                  <h3 className="font-semibold text-slate-800 dark:text-white text-sm m-0 mb-2">
                    {title}
                  </h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400 m-0 leading-relaxed">
                    {description}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── Support CTA ──────────────────────────────────────────────────── */}
        <section className="py-12 px-4">
          <div className="max-w-6xl mx-auto">
            <div className="bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 p-6 flex flex-col md:flex-row items-center gap-6">
              <div className="flex-none bg-[#D04A02] rounded-xl w-12 h-12 flex items-center justify-center text-white">
                <IconPerson />
              </div>
              <div className="flex-1 text-center md:text-left">
                <h3 className="font-bold text-slate-900 dark:text-white m-0 mb-1">
                  Need Support?
                </h3>
                <p className="text-sm text-slate-500 dark:text-slate-400 m-0">
                  For incidents, feature requests, suggestions, or escalations — reach out to the DocusaurOps team.
                </p>
              </div>
              <div className="flex flex-wrap gap-3 justify-center">
                <a
                  href="/docs/intro"
                  className="px-4 py-2 border border-slate-200 dark:border-slate-600 text-slate-600 dark:text-slate-300 rounded-md text-sm font-medium hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors no-underline flex items-center gap-1.5"
                >
                  <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244" />
                  </svg>
                  DocusaurOps Integration Channel
                </a>
              </div>
            </div>
          </div>
        </section>

      </main>
    </Layout>
  );
}


