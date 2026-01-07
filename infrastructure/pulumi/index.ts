import * as pulumi from "@pulumi/pulumi";
import * as cloudflare from "@pulumi/cloudflare";

// Configuration
const config = new pulumi.Config();
const zoneId = config.require("zoneId");
const domain = config.get("domain") || "randoeats.com";
const accountId = config.require("accountId");

// Cloudflare Pages Project for Flutter Web
const pagesProject = new cloudflare.PagesProject("randoeats-web", {
  accountId: accountId,
  name: "randoeats",
  productionBranch: "main",
  buildConfig: {
    buildCommand: "",
    destinationDir: "",
  },
  deploymentConfigs: {
    production: {
      compatibilityDate: "2024-01-01",
    },
    preview: {
      compatibilityDate: "2024-01-01",
    },
  },
});

// Custom domain for Pages (www.randoeats.com)
const wwwDomain = new cloudflare.PagesDomain("www-domain", {
  accountId: accountId,
  projectName: pagesProject.name,
  name: `www.${domain}`,
});

// DNS record for www pointing to Pages
const wwwDnsRecord = new cloudflare.DnsRecord("www-dns-record", {
  zoneId: zoneId,
  name: "www",
  type: "CNAME",
  content: "randoeats.pages.dev",
  proxied: true,
  ttl: 1, // 1 = automatic
  comment: "Managed by Pulumi - Flutter Web on Cloudflare Pages",
});

// Apex domain redirect (randoeats.com → www.randoeats.com)
const apexRedirect = new cloudflare.Ruleset("apex-redirect", {
  zoneId: zoneId,
  name: "Apex to www redirect",
  kind: "zone",
  phase: "http_request_dynamic_redirect",
  rules: [
    {
      action: "redirect",
      actionParameters: {
        fromValue: {
          statusCode: 301,
          targetUrl: {
            expression: `concat("https://www.${domain}", http.request.uri.path)`,
          },
          preserveQueryString: true,
        },
      },
      expression: `(http.host eq "${domain}")`,
      description: "Redirect apex to www",
      enabled: true,
    },
  ],
});

// Exports
export const pagesProjectName = pagesProject.name;
export const pagesProjectId = pagesProject.id;
export const productionUrl = pulumi.interpolate`https://www.${domain}`;
export const pagesDevUrl = pulumi.interpolate`https://${pagesProject.name}.pages.dev`;
