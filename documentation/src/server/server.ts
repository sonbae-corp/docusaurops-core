import express from "express";
import fs from "fs";
import path from "path";

const app = express();
const port = process.env.port || process.env.PORT || 3333;

// Dynamic sitemap: merges the static Docusaurus sitemap with sub-site URLs from ENV_SITE_URLS (comma-separated).
// ENV_SITE_URLS is updated by deploy-site.ps1 via az webapp config appsettings set after each new site deploy.
app.get('/sitemap.xml', (req, res) => {
    const staticSitemap = fs.readFileSync(path.join(__dirname, '/build/sitemap.xml'), 'utf-8');

    const subSiteUrls = process.env.ENV_SITE_URLS
        ? process.env.ENV_SITE_URLS.split(',').map(u => u.trim()).filter(Boolean)
        : [];

    const extraEntries = subSiteUrls
        .map(url => `<url><loc>${url}</loc><changefreq>daily</changefreq><priority>0.7</priority></url>`)
        .join('');

    const merged = staticSitemap.replace('</urlset>', `${extraEntries}</urlset>`);

    res.header('Content-Type', 'application/xml');
    res.send(merged);
});

// A default route should exist (even if not functional) to make application gateway probes working (i.e. HTTP 200) (in the case of the site doesn't have any authentication). 
// With EasyAuth, the probe will hit the authentication endpoint first with a HTTP 401.
app.use('/', express.static(__dirname + '/build'));

// Allow the Easy Auth redirect to work. If not set, it will result to a endless redirect loop
app.use(`/${process.env.ENV_BASE_URL}`, express.static(__dirname + '/build'));

app.listen(port, () => {
  console.log(`Server started on Azure on port ${port}`)
});