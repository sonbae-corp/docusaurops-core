
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import useBaseUrl from '@docusaurus/useBaseUrl';
import ThemedImage from '@theme/ThemedImage';
import Head from '@docusaurus/Head';
import styles from './index.module.css';

const commands = [
  'copilot plugin install docusaurops@docusaurops-plugins',
  'copilot --agent docusaurops:docusaurops --prompt "Setup documentation for my project"',

];

const pillars = [
  {
    title: 'CLI + VS Code Native',
    description: 'Run the same documentation automation workflow from terminal or editor with consistent behavior.',
  },
  {
    title: 'Docs-As-Code Lifecycle',
    description: 'Generate, version, review, and deploy Markdown documentation through reusable GitHub workflows.',
  },
  {
    title: 'Search-Ready Knowledge Mesh',
    description: 'Expose organization knowledge through Copilot connectors and WorkIQ.',
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
    href: '/docs/deployment',
  },
  {
    title: 'Query documentation with Copilot',
    description: 'Use the DocusaurOps agent to retrieve architecture, process, and runbook knowledge instantly.',
    href: '/docs/development/intro',
  },
];

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  const logoLight = useBaseUrl('/img/logo-light.svg');
  const logoDark = useBaseUrl('/img/logo-dark.svg');

  return (
    <Layout title={siteConfig.title} description="Engineering knowledge platform powered by DocusaurOps and Copilot">
      <Head>
        <meta property="DocusaurOpsPageType" name="DocusaurOpsPageType" content="site_home" />
      </Head>

      <main className={styles.page}>
        <section className={styles.hero}>
          <div className={styles.heroGlow} />
          <div className={styles.heroInner}>
            <p className={styles.heroKicker}>The ultimate documentation platform based on AI</p>
            <div className={styles.heroTitleRow}>
              <h1 className={styles.heroTitle}>Transform Your Organizational Knowledge Into a Strategic Asset</h1>
              <a
                href="https://info.microsoft.com/Agents-League-Hackathon-Registration.html"
                target="_blank"
                rel="noopener noreferrer"
                className={styles.hackathonBadge}
              >
                Made with ❤️ for the 🏆 Agents League Hackathon &mdash; Creative Apps category
              </a>
            </div>
            <p className={styles.heroLead}>
              DocusaurOps combines infrastructure automation, docs-as-code templates, and Copilot-powered retrieval so teams can ship documentation like they ship software.
            </p>
            <div className={styles.heroActions}>
              <a href="/docs/getting_started" className={styles.primaryButton}>Get Started with the plugin</a>
              <a href="/docs/deployment" className={styles.ghostButton}>Deploy it your org!</a>
            </div>

            <div className={styles.terminalFrame}>
              <div className={styles.terminalTopBar}>
                <span />
                <span />
                <span />
                <p>copilot-cli</p>
              </div>
              <div className={styles.terminalBody}>
                {commands.map((line) => (
                  <p key={line}>
                    <span>$</span> {line}
                  </p>
                ))}
              </div>
            </div>
          </div>

          <div className={styles.heroBrandMark}>
            <ThemedImage
              alt="DocusaurOps Logo"
              className={styles.heroLogo}
              sources={{ light: logoLight, dark: logoDark }}
            />
          </div>
        </section>

        <section className={styles.pillarSection}>
          <div className={styles.pillarGrid}>
            {pillars.map(({ title, description }) => (
              <article key={title} className={styles.pillarCard}>
                <h2>{title}</h2>
                <p>{description}</p>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.cardSection}>
          <div className={styles.sectionHeader}>
            <h2>From template to searchable platform</h2>
            <p>Everything needed to run a modern documentation program for engineering teams.</p>
          </div>
          <div className={styles.cardGrid}>
            {cards.map(({ title, description, href }) => (
              <article key={title} className={styles.valueCard}>
                <h3>{title}</h3>
                <p>{description}</p>
                <a href={href}>Open guide</a>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.ctaSection}>
          <div className={styles.ctaPanel}>
            <h2>Ready to launch your first DocusaurOps site?</h2>
            <p>
              Start with the setup flow, provision the Azure core infrastructure, then onboard repositories with the plugin.
            </p>
            <div className={styles.heroActions}>
              <a href="/docs/getting_started" className={styles.primaryButton}>Setup Documentation</a>
              <a href="https://github.com/FranckyC/agents-league-docusaurops/releases" className={styles.ghostButton}>View Agent Releases</a>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}


