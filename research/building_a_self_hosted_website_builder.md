# **Architectural Blueprint for 'Grimoire': A Self-Hosted, Astro-Based Website Builder**

## **1. Executive Summary**

The contemporary web development landscape is currently characterized by a dichotomy between monolithic, database-driven Content Management Systems (CMS) and high-performance, developer-centric static site generators. 'Grimoire', the proposed self-hosted website builder, represents a strategic convergence of these paradigms. It is architected to leverage **Astro** as a meta-framework, ensuring the delivery of zero-JavaScript static assets for end-users while utilizing a **React**\-based visual editor for the content creation experience. This hybrid approach addresses the critical market need for a platform that offers the ease of use found in tools like Wix or Squarespace, but with the performance profile and portability of a hand-coded static site.

The core architectural mandate for Grimoire is the seamless integration of a live, interactive preview environment with a programmatic static site generation (SSG) engine. This necessitates a sophisticated decoupling of the "Builder" (the administrative dashboard) from the "Renderer" (the build engine), bridged by a unified component library. By employing a monorepo structure managed by **Turborepo** and **pnpm workspaces**, Grimoire ensures that the UI components used in the drag-and-drop editor are identical to those rendered in the final static build, guaranteeing visual parity.

Identity management is handled via **Zitadel**, selected for its robust support of machine-to-machine (M2M) communication and granular Role-Based Access Control (RBAC), which is essential for a multi-tenant, self-hosted environment. The platform’s infrastructure relies on containerization (Docker) and dynamic routing (Nginx/Traefik) to serve thousands of user-generated sites from a single deployment instance without requiring manual configuration reloads. This report provides an exhaustive technical analysis of the proposed architecture, detailing the data flows, security mechanisms, and build pipelines required to realize Grimoire as a production-grade system.

## **2. Strategic Framework Selection and Analysis**

### **2.1 The Evolution of Web Architectures and the Case for Astro**

To understand the selection of Astro as the foundational technology for Grimoire, one must first analyze the limitations of competing frameworks in the context of a website builder. Traditional Single Page Applications (SPAs) built with React or Next.js rely heavily on client-side hydration. When a user visits a site built with Next.js, the browser must download a substantial JavaScript bundle to "hydrate" the HTML, attaching event listeners and rebuilding the application state in the browser. For a complex SaaS dashboard, this is acceptable; for a static marketing site, portfolio, or blog—the primary output of Grimoire—this constitutes unnecessary overhead that degrades Core Web Vitals, specifically Interaction to Next Paint (INP) and Total Blocking Time (TBT).1

Astro fundamentally diverges from this model through its "Islands Architecture." In an Astro application, the page is rendered as static HTML by default. Interactive components are isolated as "islands" that are only hydrated when necessary. This architecture is particularly advantageous for Grimoire because it allows the platform to act as a compiler. The heavy, interactive React components required for the visual editor (the builder) can be stripped away entirely during the build process, leaving only lightweight HTML and CSS for the final user site. Comparative benchmarks indicate that Astro builds can load approximately 40% faster with 90% less JavaScript than comparable Next.js setups, a critical metric for user-generated sites where SEO performance is often a primary KPI.1

Furthermore, Astro’s framework-agnostic nature prevents vendor lock-in. While Grimoire’s editor is built in React to leverage the mature drag-and-drop ecosystem, the renderer is not strictly bound to the React lifecycle for static output. This flexibility allows for future optimizations where specific, high-performance blocks could potentially be rewritten in lighter frameworks (like Preact or Svelte) without refactoring the entire architecture, provided they adhere to the established data schema.3

### **2.2 Comparative Analysis: Astro vs. Next.js for Website Builders**

The decision to utilize Astro over Next.js is not merely a preference but a strategic alignment with the specific functional requirements of a static site builder. Next.js excels in dynamic, state-heavy applications. If Grimoire were purely a dynamic dashboard, Next.js would be the obvious choice due to its robust server actions and integrated API routes. However, Grimoire is a factory for *other* websites.

| Feature | Astro | Next.js | Implication for Grimoire |
| :---- | :---- | :---- | :---- |
| **Default Output** | Static HTML (Zero JS) | React Hydrated Application | Astro ensures user sites are performant by default; Next.js requires manual optimization to remove unused JS. |
| **Hydration Strategy** | Partial (Islands) | Full / Progressive | Astro allows the Editor to be a heavy React app while the Preview remains lightweight. |
| **Data Layer** | Content Collections / agnostic | Opinionated (Fetch/Cache) | Astro’s flexible content layer simplifies injecting JSON configuration from the database into the build process.5 |
| **Edge Rendering** | Adapter-based | Vercel-optimized | Astro’s adapter system is more neutral, supporting self-hosting on Node.js/Docker without Vercel-specific primitives.1 |

The analysis suggests that while Next.js offers a more unified "full-stack" experience, Astro provides the necessary separation of concerns between the *build environment* and the *build artifact*. For a website builder, the artifact's performance is the product; therefore, Astro’s HTML-first philosophy is the superior architectural fit.2

## ---

**3. System Architecture and Component Design**

### **3.1 The Monorepo Strategy**

Grimoire functions as a distributed system composed of distinct services: the Dashboard (UI), the Renderer (Build Engine), the Authentication Service, and the Data Layer. To manage the shared dependencies and ensuring type safety across these boundaries, a monorepo structure managed by **Turborepo** and **pnpm workspaces** is mandated.

The monorepo solves the critical "Dual-Context Component" problem. A visual block, such as a "Pricing Table," must be rendered in two distinct contexts:

1. **The Editor Context:** Inside the React-based visual builder, the component must be wrapped in drag-and-drop handlers, display overlay controls (edit/delete), and react to real-time property changes.  
2. **The Renderer Context:** Inside the final generated site, the same component must render as pure HTML/CSS, stripped of the editor's administrative overhead.

By placing these components in a shared packages/blocks workspace, both the apps/dashboard and apps/renderer can import them. Turborepo’s caching mechanisms ensure that changes to a component library trigger rebuilds only for the affected applications, significantly accelerating the development lifecycle.6

#### **3.1.1 Directory Structure**

The proposed file structure facilitates clear separation of concerns while maximizing code reuse:

/grimoire-monorepo

├── package.json \# Root manifest

├── pnpm-workspace.yaml \# Workspace definitions

├── turbo.json \# Build pipeline configuration

├── apps/

│ ├── dashboard/ \# (Astro \+ React) The SaaS Admin & Visual Editor

│ └── renderer/ \# (Astro) The Headless Build Engine

├── packages/

│ ├── ui/ \# (React) Design System (Buttons, Inputs, Modals)

│ ├── blocks/ \# (React) The "Lego bricks" for user sites

│ ├── database/ \# (Drizzle) Schema definitions and DB client

│ ├── auth/ \# (Zitadel) Auth utilities and middleware

│ └── config/ \# Shared TypeScript and Tailwind configurations

└── docker/ \# Infrastructure definitions (Compose, Nginx)

### **3.2 Application Layer: The Dashboard (The Builder)**

The Dashboard is the user-facing application where users manage their projects, configure domain settings, and access the visual editor. It is built as an Astro application configured for **Server-Side Rendering (SSR)** (output: 'server'). This allows for dynamic routing, session validation via cookies, and API endpoints for saving data.8

The visual editor itself is the most complex component of the Dashboard. It is implemented as a "Client-Only" Astro Island. Astro allows specific components to be hydrated immediately upon load using the client:only="react" directive. This effectively mounts a Single Page Application (SPA) onto the specific route /editor/\[siteId\], providing the rich interactivity required for drag-and-drop operations without burdening the rest of the dashboard with unnecessary JavaScript.9

### **3.3 The Visual Editor Engine: Puck Integration**

For the core editing experience, Grimoire integrates **Puck**, an open-source visual editor for React. Puck is selected over alternatives like GrapesJS or Craft.js because of its data-centric philosophy. Puck represents the page structure not as a DOM tree, but as a clean JSON object. This separation of content (JSON) from presentation (React components) is crucial for the security and flexibility of a self-hosted builder.10

In the Grimoire architecture, Puck acts as the state manager for the site configuration. When a user drags a component onto the canvas, Puck updates its internal JSON store.

* **Component Mapping:** The packages/blocks library exports a configuration object that maps internal JSON types (e.g., HeroSection) to actual React components.  
* **Field Definitions:** Each block exports a Zod schema defining its editable properties (title, background image, alignment). Puck uses these schemas to automatically generate the settings sidebar, ensuring that the UI is always in sync with the component's data requirements.

### **3.4 The Renderer and Programmatic Generation**

The Renderer is the engine room of Grimoire. It is a separate Astro project (apps/renderer) designed to run in a headless capacity. Unlike the Dashboard, which serves a user interface, the Renderer is invoked programmatically to convert the JSON configuration saved by the editor into deployable static assets.

This programmatic generation is achieved through a Node.js child process orchestration. When a user publishes a site, the Dashboard spawns a new process that executes the Astro build command within the Renderer's context. The Renderer utilizes a dynamic route \[...slug\].astro which acts as a catch-all template. During the build initialization, this route fetches the specific site's configuration from the database (or a passed JSON file) and generates the corresponding HTML pages. This architecture allows a single Astro codebase to generate infinite variations of websites based on the input data, effectively acting as a "Website Compiler".12

## ---

**4. Identity and Access Management (IAM) Strategy**

### **4.1 Zitadel Integration**

Security in a multi-tenant, self-hosted environment is non-trivial. Grimoire delegates identity management to **Zitadel**, an open-source identity provider (IdP) that supports modern standards like OpenID Connect (OIDC) and SAML. Zitadel is particularly well-suited for this architecture because of its first-class support for "Organizations," which maps directly to Grimoire’s tenant model.14

The authentication flow utilizes the **Authorization Code Flow with PKCE** (Proof Key for Code Exchange). This flow is superior to the implicit flow as it prevents the exposure of access tokens in the browser URL.

1. **Initiation:** When a user clicks "Login," the Astro middleware generates a cryptographically random code\_verifier and its transformed code\_challenge.  
2. **Redirection:** The user is redirected to Zitadel with the code\_challenge.  
3. **Verification:** Upon successful authentication, Zitadel redirects back to Grimoire with an authorization code.  
4. **Exchange:** The Grimoire server (Astro backend) exchanges this code and the original code\_verifier for an Access Token and ID Token. This exchange happens over a direct back-channel (server-to-server), ensuring the tokens are never exposed to the client-side JavaScript.

### **4.2 Multi-Tenancy and Authorization**

In a self-hosted builder, multiple users or teams (tenants) may use the same instance. Data isolation is enforced at both the Application and Database layers.

* **Organization-Based Isolation:** Every user in Zitadel belongs to an Organization. This org\_id is embedded in the ID Token.  
* **Database Enforcement:** The Drizzle schema relates every Site to an organization\_id.  
* **Middleware Checks:** Astro middleware intercepts every request to /dashboard/\*. It decodes the session token, extracts the org\_id, and verifies that the requested resource belongs to that organization. This strictly prevents Insecure Direct Object Reference (IDOR) attacks where a user might guess a site ID.15

### **4.3 Machine-to-Machine (M2M) Authentication**

The build system requires privileged access to the API to fetch site configurations during the static generation process. Since the build runs as a background process, there is no interactive user session.

* **Service Users:** Grimoire utilizes Zitadel’s "Service User" functionality. A dedicated Service User is created for the Builder Service.  
* **JWT Profile:** The builder authenticates using a private key (JWT Profile) to obtain an access token. This allows the build script to securely query the database for the site configuration without impersonating a human user, maintaining a clean audit trail.17

## ---

**5. Detailed Component Architecture: The "Islands" of Grimoire**

### **5.1 The Visual Editor Implementation**

The implementation of the visual editor leverages Astro's ability to selectively hydrate React components. The file apps/dashboard/src/pages/editor/\[siteId\].astro serves as the container.

Code-Snippet

\---  
// apps/dashboard/src/pages/editor/\[siteId\].astro  
import Layout from '../../layouts/Layout.astro';  
import { Editor } from '../../components/Editor'; // React Component  
import { getSiteById } from '@grimoire/database';

const { siteId } \= Astro.params;  
// Server-side data fetching (protected by middleware)  
const siteData \= await getSiteById(siteId, Astro.locals.user.orgId);

if (\!siteData) return Astro.redirect('/404');  
\---

\<Layout title={\`Editing: ${siteData.name}\`}\>  
  \<Editor   
    client:only="react"   
    initialData={siteData.content}   
    siteId={siteId}   
  /\>  
\</Layout\>

This snippet demonstrates the power of the architecture. The shell of the page (headers, metadata) is static HTML served by Astro. The heavy editor application is loaded asynchronously. If the JavaScript fails or is blocked, the user still sees the branded shell, rather than a white screen of death common in full SPAs.

### **5.2 The Live Preview Mechanism**

A website builder is only as good as its preview. Users expect "What You See Is What You Get" (WYSIWYG). However, rendering a React component in the editor does not guarantee it will look identical to the static HTML generated by Astro, due to potential differences in CSS scoping and global styles.

Grimoire solves this via a **Server-Side Rendered Preview Pipeline**.

1. **State Transmission:** As the user edits, the Puck editor debounces the changes and sends the JSON configuration to a Preview API endpoint (/api/preview).  
2. **On-Demand Rendering:** The /api/preview endpoint is an Astro SSR route. It receives the JSON payload, dynamically imports the necessary Astro components (mapped from the packages/blocks library), and renders them to an HTML string.  
3. **Iframe Injection:** The editor displays an \<iframe\> pointing to this preview route. This ensures that the user is seeing the *actual* Astro output, complete with all global CSS, typography, and layout resets that will be present in the final build. This eliminates the "drift" often seen in builders where the editor looks slightly different from the published site.18

## ---

**6. Programmatic Site Generation: The Build Engine**

### **6.1 The "Renderer" as a Build Target**

The apps/renderer directory is a minimal Astro project. It contains no content of its own. Instead, it relies on a "Catch-All" route to generate pages based on external data.

**File:** apps/renderer/src/pages/\[...slug\].astro

TypeScript

import type { GetStaticPaths } from "astro";  
import { getSiteConfig } from "@grimoire/database";  
import { BlockRenderer } from "@grimoire/blocks";

export const getStaticPaths \= (async () \=\> {  
  // The Build Script injects the SITE\_ID as an environment variable  
  const targetSiteId \= import.meta.env.SITE\_ID;  
    
  // Fetch the configuration for this specific site  
  const siteConfig \= await getSiteConfig(targetSiteId);

  // Map each page in the config to a static path  
  return siteConfig.pages.map((page) \=\> ({  
    params: { slug: page.slug },  
    props: {   
      blocks: page.blocks,  
      theme: siteConfig.theme   
    },  
  }));  
}) satisfies GetStaticPaths;

const { blocks, theme } \= Astro.props;  
\---  
\<html lang\="en" data-theme\={theme}\>  
  \<head\>  
    \<title\>{Astro.props.title}\</title\>  
    \</head\>  
  \<body\>  
    {blocks.map((block) \=\> (  
      \<BlockRenderer block\={block} /\>  
    ))}  
  \</body\>  
\</html\>

### **6.2 Orchestrating the Build**

To trigger this build process, the Dashboard uses Node.js's child\_process module. This provides isolation; if a build crashes, it does not take down the main dashboard.

**The Build Manager Service:**

The build manager performs the following operations:

1. **Environment Preparation:** Creates a temporary directory for the build artifacts.  
2. **Process Execution:** Spawns astro build with the SITE\_ID environment variable set.  
3. **Artifact Handling:** Upon success (exit code 0), it locates the dist/ folder.  
4. **Post-Processing:** It executes node-archiver to create a ZIP file of the website for the user to download. Simultaneously, it moves the files to the Nginx web root for live hosting.20

### **6.3 Handling Asset Paths and Bases**

A common challenge in programmatic generation is handling relative paths. If a user deploys their site to a subdirectory (e.g., grimoire.app/users/steve), all CSS and Image links must include this prefix. Astro provides the base configuration option. The build script dynamically generates a astro.config.mjs (or passes flags) to set the base URL correctly for the specific deployment target, ensuring assets load correctly regardless of the hosting path.22

## ---

**7. Data Layer and Schema Design**

### **7.1 Database Schema (Drizzle ORM)**

The database schema serves as the contract between the Editor and the Renderer. We utilize **PostgreSQL** with **Drizzle ORM**.

**Core Tables:**

* **organizations**: Linked to Zitadel Org IDs.  
* **sites**: Stores site-level settings (favicon, global SEO, custom CSS).  
  * Columns: id, org\_id, subdomain, custom\_domain, deployment\_status.  
* **pages**: Represents individual routes.  
  * Columns: id, site\_id, slug (e.g., "/about"), title, meta\_description.  
  * **content**: This is a jsonb column that stores the Puck editor state. Using jsonb allows for efficient querying and updates without complex join tables for every single block.24

### **7.2 JSON Content Structure**

The integrity of the builder depends on a strict JSON schema.

JSON

{  
  "root": {  
    "props": { "title": "My Landing Page" }  
  },  
  "content": }  
    }  
  \]  
}

This structure is "flat" enough to be easily parsed by the Astro renderer's map function, yet flexible enough to support complex nested layouts via the zones concept in Puck.25

## ---

**8. Infrastructure & Self-Hosted Deployment**

### **8.1 Docker Composition**

Grimoire is delivered as a multi-container Docker application.

* **dashboard**: The Node.js container running the Astro Admin.  
* **builder**: A worker container (Node.js) that listens for build jobs (via a queue like BullMQ or simple database polling) to keep CPU-intensive builds off the web server.  
* **postgres**: Persistent data storage.  
* **zitadel**: The identity provider (unless using an external instance).  
* **proxy**: Nginx or Traefik acting as the ingress controller.

### **8.2 Dynamic Subdomain Routing (Nginx)**

A key requirement for a website builder is giving each user their own subdomain (e.g., alice.grimoire.app) or custom domain. Reconfiguring Nginx for every new user is inefficient. We utilize **Map Directives** and **Regular Expressions** to handle this dynamically.

**Nginx Configuration:**

Nginx

map $host $site\_slug {  
    \# Extract subdomain: alice.grimoire.app \-\> alice  
    "\~^(?\<subdomain\>\[a-z0-9-\]+)\.grimoire\.app$"  $subdomain;  
    default "dashboard"; \# Fallback to the main app  
}

server {  
    listen 80;  
    server\_name \*.grimoire.app;

    \# Dynamic Root Mapping  
    \# Sites are stored in /var/www/sites/\[slug\]  
    root /var/www/sites/$site\_slug;  
      
    index index.html;

    location / {  
        \# Check if the file exists, if not, check for.html extension (clean URLs)  
        try\_files $uri $uri/ $uri.html \=404;  
    }  
}

This configuration allows for instant site availability. As soon as the Builder process writes files to /var/www/sites/alice, the site alice.grimoire.app is live, with zero Nginx downtime.26

### **8.3 Custom Domain Management with Traefik**

For users bringing their own domains (e.g., www.my-store.com), we employ **Traefik**. Traefik can watch a dynamic configuration file (or a Redis store). When a user adds a custom domain in the Dashboard, the application updates Traefik's configuration to route that domain to the correct static folder. Traefik also handles automatic SSL certificate generation via Let's Encrypt for these custom domains, a critical feature for modern web security.28

## ---

**9. Security Posture and Risk Mitigation**

### **9.1 Cross-Site Scripting (XSS) in User Content**

Allowing users to build sites creates a risk of Stored XSS. If a user can inject \<script\>alert(1)\</script\> into a text block, they could potentially attack visitors to their site.

* **Sanitization:** The Builder service must sanitize all user input before generating the HTML. We utilize isomorphic-dompurify in the build process.  
* **SVG Uploads:** Users often upload SVGs for logos. SVGs can contain executable JavaScript. Grimoire must strip \<script\> tags and on\* attributes from all uploaded SVGs before storage.30

### **9.2 Subdomain Isolation and Cookie Security**

Hosting user sites on subdomains provides a security boundary.

* **Cookie Scope:** Session cookies for the Dashboard must be set with SameSite=Lax and Domain=grimoire.app (not .grimoire.app). This prevents the dashboard session from being sent to user.grimoire.app.  
* **Content Security Policy (CSP):** The Nginx configuration for user sites should enforce a strict CSP that disallows inline scripts (unless required by the user) and restricts object sources, mitigating the impact of any potential XSS vulnerabilities.32

## ---

**10. Future Scalability and Extensibility**

The architecture of Grimoire is designed for growth. The decoupling of the Builder and Renderer allows them to scale independently.

* **Horizontal Scaling:** The Dashboard can be replicated across multiple nodes behind a load balancer. The Builder service can be scaled to handle concurrent builds by increasing the number of worker containers.  
* **Edge Deployment:** As the platform matures, the static output can be pushed directly to an S3-compatible object store and served via a CDN (Cloudflare/AWS CloudFront), moving the traffic load entirely off the Grimoire infrastructure.  
* **AI Page Generation:** The structured JSON nature of the site configuration makes Grimoire an ideal candidate for AI integration. An LLM agent (like Claude) can be tasked to "Generate a landing page for a coffee shop," and the output would be a valid JSON configuration that Grimoire can instantly render and publish.34

This architectural blueprint provides a comprehensive path to building Grimoire. It addresses the functional requirements of live preview, secure auth, and programmatic generation while adhering to the non-functional requirements of performance, security, and maintainability.

#### **Referenzen**

1. Astro vs Next.js Comparison for Modern Web Apps \- Tailkits, Zugriff am Januar 31, 2026, [https://tailkits.com/blog/astro-vs-nextjs/](https://tailkits.com/blog/astro-vs-nextjs/)  
2. JavaScript Efficiency War: Astro.js vs Next.js \- DEV Community, Zugriff am Januar 31, 2026, [https://dev.to/kairatorozobekov/javascript-efficiency-war-astrojs-vs-nextjs-22pm](https://dev.to/kairatorozobekov/javascript-efficiency-war-astrojs-vs-nextjs-22pm)  
3. Astro vs Next.js performance difference after a full website rebuild shocked us \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/Frontend/comments/1pjosu0/astro\_vs\_nextjs\_performance\_difference\_after\_a/](https://www.reddit.com/r/Frontend/comments/1pjosu0/astro_vs_nextjs_performance_difference_after_a/)  
4. Astro.build, Zugriff am Januar 31, 2026, [https://astro.build/](https://astro.build/)  
5. Content collections \- Astro Docs, Zugriff am Januar 31, 2026, [https://docs.astro.build/en/guides/content-collections/](https://docs.astro.build/en/guides/content-collections/)  
6. Turborepo Guide: Manage Multiple Frontends Faster \- Strapi, Zugriff am Januar 31, 2026, [https://strapi.io/blog/turborepo-guide](https://strapi.io/blog/turborepo-guide)  
7. Structuring a repository \- Turborepo, Zugriff am Januar 31, 2026, [https://turborepo.dev/docs/crafting-your-repository/structuring-a-repository](https://turborepo.dev/docs/crafting-your-repository/structuring-a-repository)  
8. astrojs/node \- Astro Docs, Zugriff am Januar 31, 2026, [https://docs.astro.build/en/guides/integrations-guide/node/](https://docs.astro.build/en/guides/integrations-guide/node/)  
9. Building Your First Island-based Project with Astro | by Fernando Doglio \- Bits and Pieces, Zugriff am Januar 31, 2026, [https://blog.bitsrc.io/building-your-first-island-based-project-with-astro-8f6aaa2fcddb](https://blog.bitsrc.io/building-your-first-island-based-project-with-astro-8f6aaa2fcddb)  
10. Puck \- Create your own AI page builder, Zugriff am Januar 31, 2026, [https://puckeditor.com/](https://puckeditor.com/)  
11. r/reactjs \- Puck \- Open-source visual editor for React. Alternative to Builder.io / WordPress., Zugriff am Januar 31, 2026, [https://www.reddit.com/r/reactjs/comments/18mwsc3/puck\_opensource\_visual\_editor\_for\_react/](https://www.reddit.com/r/reactjs/comments/18mwsc3/puck_opensource_visual_editor_for_react/)  
12. Building a Static Website from JSON Data with Astro \- /dev/solita, Zugriff am Januar 31, 2026, [https://dev.solita.fi/2024/12/02/building-static-websites-with-astro.html](https://dev.solita.fi/2024/12/02/building-static-websites-with-astro.html)  
13. Dynamic Routes in Astro (+load parameters from JSON) | by Florian Zeba \- Medium, Zugriff am Januar 31, 2026, [https://medium.com/@flnzba/dynamic-routes-in-astro-load-parameters-from-json-be766a7a2a17](https://medium.com/@flnzba/dynamic-routes-in-astro-load-parameters-from-json-be766a7a2a17)  
14. Astro | ZITADEL Docs, Zugriff am Januar 31, 2026, [https://zitadel.com/docs/sdk-examples/astro](https://zitadel.com/docs/sdk-examples/astro)  
15. Build as many tenants as needed | Multi-tenancy with Payload, Zugriff am Januar 31, 2026, [https://payloadcms.com/multi-tenancy](https://payloadcms.com/multi-tenancy)  
16. How To Build A Multi-Tenant App With Payload, Zugriff am Januar 31, 2026, [https://payloadcms.com/posts/blog/how-to-build-a-multi-tenant-app-with-payload](https://payloadcms.com/posts/blog/how-to-build-a-multi-tenant-app-with-payload)  
17. Node.js Client | ZITADEL Docs, Zugriff am Januar 31, 2026, [https://zitadel.com/docs/sdk-examples/client-libraries/node](https://zitadel.com/docs/sdk-examples/client-libraries/node)  
18. Astro output: static, Server Actions, and Node adapter : r/astrojs \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/astrojs/comments/1jbzxmj/astro\_output\_static\_server\_actions\_and\_node/](https://www.reddit.com/r/astrojs/comments/1jbzxmj/astro_output_static_server_actions_and_node/)  
19. Content editor preview for static websites \- kjac.dev, Zugriff am Januar 31, 2026, [https://kjac.dev/posts/content-editor-preview-for-static-websites/](https://kjac.dev/posts/content-editor-preview-for-static-websites/)  
20. archiverjs/node-archiver: a streaming interface for archive generation \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/archiverjs/node-archiver](https://github.com/archiverjs/node-archiver)  
21. Node.js Archiving Essentials: Zip and Unzip Demystified | by Vishesh Singh \- Medium, Zugriff am Januar 31, 2026, [https://visheshism.medium.com/node-js-archiving-essentials-zip-and-unzip-demystified-76d5471e59c1](https://visheshism.medium.com/node-js-archiving-essentials-zip-and-unzip-demystified-76d5471e59c1)  
22. Configuration overview \- Astro Docs, Zugriff am Januar 31, 2026, [https://docs.astro.build/en/guides/configuring-astro/](https://docs.astro.build/en/guides/configuring-astro/)  
23. Astro \- Automatically minify the JS files in the public folder during build? \- Stack Overflow, Zugriff am Januar 31, 2026, [https://stackoverflow.com/questions/79358966/astro-automatically-minify-the-js-files-in-the-public-folder-during-build](https://stackoverflow.com/questions/79358966/astro-automatically-minify-the-js-files-in-the-public-folder-during-build)  
24. Astro DB | Docs, Zugriff am Januar 31, 2026, [https://docs.astro.build/en/guides/astro-db/](https://docs.astro.build/en/guides/astro-db/)  
25. Data \- Puck, Zugriff am Januar 31, 2026, [https://puckeditor.com/docs/api-reference/data-model/data](https://puckeditor.com/docs/api-reference/data-model/data)  
26. Serve Static Content | NGINX Documentation, Zugriff am Januar 31, 2026, [https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/](https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/)  
27. Resolving subdomains dynamically via Nginx \- CodeX Team, Zugriff am Januar 31, 2026, [https://codex.so/resolving-subdomains-dynamically-via-nginx](https://codex.so/resolving-subdomains-dynamically-via-nginx)  
28. Traefik Configuration Documentation, Zugriff am Januar 31, 2026, [https://doc.traefik.io/traefik/getting-started/configuration-overview/](https://doc.traefik.io/traefik/getting-started/configuration-overview/)  
29. Understand File Provider in Traefik 2 \- Red Tomato's Blog, Zugriff am Januar 31, 2026, [https://tech.aufomm.com/understand-file-provider-in-traefik-2/](https://tech.aufomm.com/understand-file-provider-in-traefik-2/)  
30. A lesser-known vector for XSS attacks: SVG files | by Vinicius Brasil \- Medium, Zugriff am Januar 31, 2026, [https://vnbrs.medium.com/a-lesser-known-vector-for-xss-attacks-svg-files-d700345fff1d](https://vnbrs.medium.com/a-lesser-known-vector-for-xss-attacks-svg-files-d700345fff1d)  
31. Cross Site Scripting Prevention \- OWASP Cheat Sheet Series, Zugriff am Januar 31, 2026, [https://cheatsheetseries.owasp.org/cheatsheets/Cross\_Site\_Scripting\_Prevention\_Cheat\_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)  
32. Defending yourself against cross-site scripting attacks with Content-Security-Policy, Zugriff am Januar 31, 2026, [https://localghost.dev/blog/defending-yourself-against-cross-site-scripting-attacks-with-content-security-policy/](https://localghost.dev/blog/defending-yourself-against-cross-site-scripting-attacks-with-content-security-policy/)  
33. Securely hosting user data in modern web applications | Articles \- web.dev, Zugriff am Januar 31, 2026, [https://web.dev/articles/securely-hosting-user-data](https://web.dev/articles/securely-hosting-user-data)  
34. \[20 minutes\] Video on Claude.ai/Claude Code for an Astro website, CloudFlare, GitHub Actions workflows : r/ClaudeAI \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/ClaudeAI/comments/1m8wbmu/20\_minutes\_video\_on\_claudeaiclaude\_code\_for\_an/](https://www.reddit.com/r/ClaudeAI/comments/1m8wbmu/20_minutes_video_on_claudeaiclaude_code_for_an/)