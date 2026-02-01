# **Architectural Feasibility and Implementation Strategy: Building 'Grimoire' vs. Self-Hosting Carrd Alternatives**

## **1. Executive Strategic Analysis**

The decision matrix facing a modern developer or technical founder choosing between architecting a bespoke page-building platform—codenamed 'Grimoire'—and deploying an existing self-hosted alternative to Carrd is complex. It involves balancing immediate utility against long-term architectural sovereignty, performance ceilings, and extensibility. This report provides an exhaustive technical analysis of this dichotomy, specifically tailored to a modern JavaScript stack (Next.js/Astro, React, PayloadCMS) and the requirement for a high-performance template system.

The market for "one-page" or "link-in-bio" builders has bifurcated into two distinct categories: rigid, proprietary SaaS platforms like Carrd or Linktree, and open-source alternatives that struggle to match the user experience (UX) and performance of their closed-source counterparts. The user's query posits a fundamental strategic question: Is the effort of building a custom solution using PayloadCMS 3.0 justified by the limitations of existing self-hosted tools like LinkStack or Webstudio?

Our research indicates that for a developer seeking a true "Carrd alternative"—defined as a platform allowing free-form design, complex layouts, and high-performance rendering—the self-hosted market is currently insufficient. Tools like LinkStack are restricted to linear layouts 1, while powerful visual builders like Webstudio impose significant DevOps complexity and restrict key dynamic features in their open-source community editions.3 Consequently, for use cases requiring a "template system" with high performance and modern stack integration, building 'Grimoire' is not only a viable option but the superior architectural choice. This report details the specific implementation strategy for such a build, focusing on PayloadCMS 3.0, the Puck visual editor, and a comparative analysis of Next.js 15 versus Astro 5.0 as the rendering engine.

## ---

**2. Landscape Analysis: The Limits of "Buying" (Self-Hosting)**

To justify the engineering hours required to build 'Grimoire', one must first rigorously evaluate the "Host" path. The open-source ecosystem offers several candidates that promise to replace Carrd, but a deep technical audit reveals significant architectural divergences from the "modern stack" requirement.

### **2.1 LinkStack: The Linear Limitation**

LinkStack (formerly LittleLink) represents the most mature self-hosted alternative for the specific "link-in-bio" use case. Built on a PHP/Laravel foundation, it is designed for efficiency and ease of deployment via Docker.5

#### **2.1.1 Architectural Constraints**

LinkStack operates on a strictly linear content model. Unlike Carrd, which allows for the placement of elements in columns, containers, and complex grids, LinkStack forces content into a single vertical column optimized for mobile viewing.1 While this satisfies the requirement for a basic profile page, it fails the broader "Carrd alternative" test, which often implies the ability to build landing pages, portfolio sites, and small promotional pages with distinct visual hierarchies.

From a technical perspective, LinkStack's reliance on PHP 8.2 5 places it outside the "modern stack" definition provided in the user query (Astro/React). While PHP is robust, it does not offer the component-based modularity of React or the edge-caching capabilities native to Next.js applications. Customizing LinkStack requires knowledge of Blade templates and the Laravel ecosystem, creating a context-switching burden for developers primarily versed in TypeScript and React.

#### **2.1.2 The Theme System vs. True Templating**

LinkStack's approach to customization is theme-based rather than structural. Users can upload themes 2, but these themes primarily control CSS variables and background assets. They do not fundamentally alter the DOM structure or allow for the programmatic injection of new component types (e.g., a newsletter signup form or a WebGL canvas), which are trivial in a React-based environment. This limitation makes LinkStack a "terminal" solution: it works well for its specific purpose but hits a hard ceiling when requirements expand.

### **2.2 Webstudio: The Complexity of Power**

At the other end of the spectrum lies Webstudio, an open-source visual builder that positions itself as a competitor to Webflow rather than Carrd. Built on Remix (React) and utilizing a sophisticated CSS-in-JS engine (tokens, variables, breakpoints), Webstudio offers immense power.7

#### **2.2.1 The DevOps Burden**

Self-hosting Webstudio is non-trivial. Unlike a simple Next.js app that can be deployed to Vercel or a single Docker container, Webstudio's architecture is composed of multiple microservices, requiring a complex orchestration of a builder instance, a database (Postgres), a Redis cache for real-time collaboration, and an image optimization pipeline (IPX).3

Crucially, the "Open Source" version of Webstudio comes with significant feature gates. The research highlights that multi-tenancy (team workspaces) is planned as an enterprise feature, not part of the open-source core.4 Furthermore, essential features like email sending for forms are "cloud-only," forcing self-hosting users to implement their own backend solutions using tools like n8n or Make.com.3 This negates the "all-in-one" convenience that makes Carrd attractive.

#### **2.2.2 The "Designer" vs. "User" Gap**

Webstudio exposes the raw primitives of the web platform—padding, margins, flexbox properties, and grid coordinates.7 While this empowers designers, it overwhelms the typical user looking for a "template filler." If 'Grimoire' is intended to allow users to quickly clone and edit a template, Webstudio's interface is likely too granular and complex. It requires the user to understand the box model, whereas a template system should abstract these details away.

### **2.3 The "Starter Kit" Ecosystem: LibreLinks, Biohub, and Beyond**

Between LinkStack and Webstudio exists a fragmented landscape of "Starter Kits"—repositories like LibreLinks 9 and Biohub.fyi.10 These projects are often built on the exact stack requested: Next.js, Tailwind CSS, and a database like MongoDB or Supabase.

#### **2.3.1 Maintenance and Viability Risks**

While these projects align technologically, they often suffer from the "maintainer abandonment" common in open-source portfolio projects. For example, LibreLinks utilizes Next.js 13 and the pages directory (in older versions), requiring significant refactoring to bring it up to Next.js 15 standards.9 Biohub.fyi is a more recent entrant, boasting Next.js 15 and Tailwind v4 10, but it is primarily a single-developer project rather than a platform with a governance model.

Using one of these starters is not "buying" a solution; it is "forking" a codebase. This is a valid strategy, but it does not provide the robust content management features of a dedicated CMS. The data models are often hardcoded into the application logic, making it difficult to introduce new block types or features without rewriting the core application. This reinforces the argument for building 'Grimoire' on top of a dedicated Headless CMS like Payload, which handles the data management layer professionally.

### **2.4 Comparative Summary**

The following table synthesizes the capabilities of existing self-hosted options against the requirements for 'Grimoire'.

| Feature | LinkStack | Webstudio (Self-Hosted) | Biohub.fyi / LibreLinks | 'Grimoire' (Target State) |
| :---- | :---- | :---- | :---- | :---- |
| **Core Technology** | PHP / Laravel | React / Remix | Next.js / Tailwind | PayloadCMS / Next.js 15 |
| **Layout Flexibility** | Low (Linear only) | Maximum (Webflow-like) | Moderate (Code-dependent) | High (Block-based) |
| **Templating** | Theme-based | CSS/Token-based | Hardcoded Components | Database-Driven Objects |
| **Performance** | Server-side Rendered | High (Edge/Static) | Varies (Vercel-optimized) | Elite (ISR/PPR) |
| **Multi-Tenancy** | Native | Enterprise/Roadmap | Manual Implementation | Custom (Middleware) |
| **Ease of Self-Host** | High (Docker) | Low (Complex Stack) | Moderate (Vercel/Docker) | Moderate (Docker/Coolify) |

**Conclusion on the "Host" Path**: Existing solutions force a compromise between simplicity (LinkStack) and maintainability (Webstudio). There is a clear market gap for a **Next.js-native, block-based page builder** that balances the ease of Carrd with the power of a headless CMS. This validates the decision to build 'Grimoire'.

## ---

**3. Architectural Vision: The 'Grimoire' Stack**

Building 'Grimoire' requires a rigorous selection of technologies that function cohesively to deliver a "factory" for high-performance websites. The core requirement is to decouple the *management* of content (CMS) from the *rendering* of content (Framework), while bridging the gap with a visual interface (Editor).

### **3.1 The Backend Engine: PayloadCMS 3.0**

The selection of PayloadCMS 3.0 is critical. Unlike its predecessors, Payload 3.0 is **Next.js Native**.11 This means it does not require a separate Node.js / Express server process. Instead, it installs directly into the Next.js App Router as a set of Server Components and API routes.

#### **3.1.1 Why Payload 3.0 for a Builder?**

1. **Single Monorepo Architecture**: You can house the marketing site, the builder dashboard, the admin panel, and the user's published sites all within a single Next.js application. This drastically simplifies the "Self-Hosting" requirement—a single Docker container can run the entire platform.13  
2. **The Local API**: Payload exposes a strictly typed Local API (payload.find, payload.create) that runs directly on the server.15 This is essential for the "Template System" (discussed in Section 4), as it allows for the programmatic duplication of complex document trees without the latency of HTTP requests.  
3. **Schema as Code**: The entire database structure is defined in TypeScript configuration files. This allows for rapid iteration of the "Block" definitions that make up the user's pages.

#### **3.1.2 Database Strategy**

For a multi-tenant system, **PostgreSQL** is the recommended database backend over MongoDB, despite Payload's history with Mongo. Payload 3.0 supports Postgres natively via Drizzle ORM.

* **Relational Integrity**: As the system grows, you will need to enforce strict relationships between Users, Sites, Domains, and Templates. SQL is superior for maintaining these constraints.  
* **JSONB Columns**: Payload uses JSONB columns in Postgres to store the flexible layout array (the blocks). This gives you the best of both worlds: the structure of SQL for user management and the flexibility of NoSQL for page layouts.

### **3.2 The Visual Interface: Integrating Puck**

A standard Headless CMS uses a form-based interface: fields on the left, preview on the right. This is insufficient for a Carrd competitor. Users expect direct manipulation—dragging a button from a sidebar and dropping it onto the canvas.

To achieve this without building a drag-and-drop engine from scratch, 'Grimoire' should integrate **Puck**, an open-source visual editor for React.16

#### **3.2.1 The "Puckload" Integration Pattern**

Research identifies a proof-of-concept integration known as "Puckload".18 The strategy involves replacing the standard Payload "Edit View" for the Pages collection with a custom React component that renders the Puck editor.

* **Data Transformation**: Payload stores data as an array of blocks (e.g., \`\`). Puck expects a specific JSON tree structure (Zones and Components). You must write a **Transformation Layer** (a React Hook) that:  
  1. Fetches the Payload document via the Local API.  
  2. Maps Payload Blocks to Puck Components.  
  3. On "Save," maps the Puck JSON back to the Payload Block structure and submits it via a Server Action or API call.19  
* **Custom Field Type**: Alternatively, you can create a custom Field Component in Payload that launches Puck in a full-screen modal.18 This keeps the native Payload admin UI for metadata (SEO settings, slug, publishing dates) while delegating the layout editing to Puck.

### **3.3 The Frontend: Next.js 15 vs. Astro 5.0**

The user explicitly asks to compare Astro and React (Next.js) for high performance. Both are capable, but they serve different architectural masters.

#### **3.3.1 The Case for Astro**

Astro 5.0 is a "content-first" framework. Its "Islands Architecture" allows you to ship zero JavaScript to the client for static components (Text, Images) and only hydrate interactive ones (Forms, Carousels).20

* **Pros**: Out-of-the-box performance is mathematically superior for static sites. The "Content Layer" can fetch data from Payload easily.  
* **Cons**: Astro is primarily a *static site generator* (SSG). While it supports SSR, building a dynamic *application* (the builder dashboard itself) is more cumbersome than in Next.js. Integrating the Puck editor (which is a React application) into Astro requires wrapping it in a React Island, which can lead to state synchronization issues.

#### **3.3.2 The Case for Next.js 15**

Next.js 15 introduces **Partial Prerendering (PPR)** and refined **Server Actions**.

* **Pros**: Payload 3.0 is native to Next.js. You share types, authentication session context, and database connections. The "Live Preview" feature in Payload relies on iframe communication postMessage, which is pre-configured for Next.js.12  
* **Performance Mitigation**: Historically, Next.js shipped a large hydration bundle. However, with **React Server Components (RSC)**, components rendered on the server (like the Hero section text) do not add to the client-side JavaScript bundle. This narrows the performance gap with Astro significantly.

#### **3.3.3 Recommendation**

For 'Grimoire', **Next.js 15 is the superior choice**. The architectural synergy of having the CMS, the Editor, and the Renderer in one monorepo outweighs the marginal performance gain of Astro for this specific "SaaS" use case. If the goal was purely to generate static HTML files for export, Astro would win. But for a hosted platform with a dynamic editor, Next.js reduces complexity.

## ---

**4. Engineering the Template System**

A "Template System" is more than just a collection of pretty pages. It is a programmatic engine that allows for the instantiation, inheritance, and divergence of content. This section details how to build this engine using the Payload Local API.

### **4.1 Conceptual Data Model**

We must define three distinct entities in the database:

1. **The Blueprint (Template)**: A document in the templates collection. It contains the layout data but is read-only for standard users.  
2. **The Instance (Page)**: A document in the pages collection. It starts as a clone of a Blueprint but is owned by a specific User.  
3. **The Theme (Style Definition)**: A global setting or config object that defines the *tokens* (colors, fonts, spacing) used by the blocks. This separates "Structure" (Blocks) from "Style" (Theme).

### **4.2 The Cloning Algorithm (The "Factory")**

When a user selects "Use this Template," the system must perform a **Deep Copy**. A shallow copy is insufficient because Blocks often contain nested relationships or unique IDs that must be regenerated to avoid React key conflicts.

#### **4.2.1 Step-by-Step Logic**

Using Payload's Local API, we can write a specialized Server Action or API Route:

1. **Fetch the Source**:  
   Retrieve the Template document using payload.findByID. Use a depth of 0 or 1 depending on whether you want to clone referenced documents.  
   TypeScript  
   // Pseudocode logic for the expert developer  
   const template \= await payload.findByID({  
     collection: 'templates',  
     id: sourceTemplateId,  
   });

2. **Sanitize and Regenerate**:  
   The system must traverse the layout array (the blocks). For every block:  
   * **Strip Metadata**: Remove id, createdAt, updatedAt, and \_status.  
   * **Regenerate Block IDs**: Payload assigns a unique id to every block instance. If you simply copy the array, the new page will have the same block IDs as the template. If a user edits "Block A" on the new page, and the frontend relies on these IDs for state (e.g., in the Puck editor), it could cause collisions. You must generate new UUIDs for every block.  
   * **Handle Relationships**: If the template includes a relationship to a generic "Placeholder Image" (Media ID: 123), you can keep this reference. However, if the template has a "Contact Form" block that relates to a Form document, you must decide: do you link to the original form (bad) or clone the form definition as well? For a robust system, you must **recursively clone specific related documents** (like Forms) so the user has their own independent instance.  
3. **Create the Instance**:  
   Insert the sanitized object into the pages collection, assigning the owner field to the current user.  
   TypeScript  
   const newPage \= await payload.create({  
     collection: 'pages',  
     data: {  
      ...sanitizedTemplateData,  
       slug: \`site-${generateRandomString()}\`,  
       owners: \[currentUser.id\],  
       templateOrigin: template.id, // Track lineage for future analytics  
     },  
   });

### **4.3 Seeding and Distribution**

To launch 'Grimoire', you need an initial set of templates. You cannot rely on manual entry in the production database.

* **Seeding Script**: Use Payload's onInit or a standalone seed script 22 to programmatic insert templates.  
* **JSON Definition**: Store your master templates as JSON files in the repo (e.g., src/seed/templates/portfolio-minimal.json). The seed script reads these files and "upserts" them into the DB on deployment. This ensures that your "Code" (the repo) is the source of truth for your "Data" (the templates).

## ---

**5. Performance Optimization Strategy**

The user requirement for "high performance" is paramount. A self-hosted builder often fails because it lacks the massive infrastructure of Wix or Squarespace. However, by using "Modern Stack" primitives, 'Grimoire' can achieve sub-second load times.

### **5.1 Incremental Static Regeneration (ISR)**

Dynamic rendering (SSR) is often too slow for a published site. Static Generation (SSG) is too slow for the *builder* (waiting 2 minutes for a build to finish after clicking save).

**ISR** is the middle ground.

* **Configuration**: In the Next.js page.tsx for the user's site:  
  TypeScript  
  export const revalidate \= 60; // Revalidate at most every 60 seconds  
  export const dynamicParams \= true;

* **On-Demand Revalidation**: When the user clicks "Publish" in the Grimoire dashboard, trigger a revalidatePath call.12 This purges the Vercel/Next.js cache instantly. This gives the user the *feeling* of a dynamic app with the *performance* of a static file.

### **5.2 Tailwind CSS v4 Integration**

Tailwind v4 offers a significant performance boost in build times and a smaller CSS bundle size.24

* **The Conflict**: Payload 3.0's Admin Panel uses its own styling. If you import tailwindcss globally in the root layout, the "preflight" (reset) styles might break the Admin Panel's UI.  
* **The Fix**: Use CSS Layers or Scoping.  
  * Configure Tailwind to apply only to the frontend routes (e.g., (app)/(frontend) group).  
  * Exclude the (app)/(payload)/admin routes from the global Tailwind directive.  
  * Alternatively, wrap the user's site in a robust CSS reset that is scoped to a root div, ensuring the Admin Panel remains unaffected.

### **5.3 Image Optimization Pipeline**

The biggest bottleneck for Carrd-style sites is images.

* **Next.js Image Component**: Use \<Image /\> strictly. This automatically serves WebP/AVIF formats.  
* **Sharp**: If self-hosting via Docker, ensure the sharp library is installed in the container.3 This allows the Next.js server to resize images on the fly.  
* **External Storage**: Do not store images in the Docker container's filesystem. Use an S3-compatible provider (AWS S3, Cloudflare R2, MinIO). Payload's plugin-cloud-storage handles this transparently. Offloading images to R2 (which has zero egress fees) is a critical cost-saving strategy for a high-traffic builder.

## ---

**6. Multi-Tenancy and Hosting Architecture**

To allow users to have user.grimoire.com or custom-domain.com, the infrastructure must route requests dynamically.

### **6.1 The Middleware Router**

Next.js Middleware is the traffic cop.

* **Logic**:  
  1. Inspect the Host header.  
  2. If it matches the main domain (grimoire.com), pass through to the landing page.  
  3. If it is a subdomain (user.grimoire.com), rewrite the URL to /sites/\[subdomain\].  
  4. If it is a custom domain (myportfolio.com), lookup the domain in the DB to find the associated siteId, then rewrite to /sites/\[siteId\].  
* **Reference Implementation**: The **Vercel Platforms Starter Kit** 26 provides the exact code patterns for this.

### **6.2 The Self-Hosting Setup (Docker)**

While Vercel is the easiest deployment target, the "Self-Hosted" requirement often implies running on a VPS (like Hetzner or DigitalOcean) to save costs.

#### **6.2.1 Dockerfile Optimization**

The Dockerfile for 'Grimoire' must use **Next.js Standalone Mode** to reduce image size.

* **Build Stage**: npm run build. This generates a .next/standalone folder containing only the necessary files for production.  
* **Production Stage**: Copy .next/standalone and public folder to a lightweight Alpine Node image.  
* **Environment Variables**: Crucially, you must pass NEXT\_PUBLIC\_SERVER\_URL and database credentials at runtime.

#### **6.2.2 Reverse Proxy for Custom Domains**

If self-hosting, handling SSL for thousands of user domains is the hardest part.

* **Caddy Server**: Use Caddy as the reverse proxy in front of the Next.js container. Caddy's **On-Demand TLS** feature automatically issues Let's Encrypt certificates for any domain that points to your server, provided you configure a verification endpoint. This replicates the Vercel Custom Domains feature without the platform lock-in.

## ---

**7. Comparative Summary of "Build vs. Buy"**

The following table summarizes the trade-offs between utilizing a self-hosted "buy" option versus the proposed "build" architecture.

| Feature Dimension | Webstudio (Self-Hosted) | LinkStack (Self-Hosted) | 'Grimoire' (Custom Build) |
| :---- | :---- | :---- | :---- |
| **Primary Use Case** | Visual Design / Webflow Alternative | Link Aggregation / Bio Page | Template-Based Page Building |
| **Tech Stack** | Remix / React / Redis / Postgres | PHP / Laravel / SQLite or MySQL | Next.js 15 / Payload 3.0 / Postgres |
| **Visual Editing** | High Complexity (CSS properties) | Low Complexity (Theme settings) | Configurable (Blocks/Puck Editor) |
| **Template System** | Manual Copy / Token-based | Theme Uploads | **Programmatic Deep Cloning** |
| **Performance** | High (Static Export available) | Moderate (Server-side PHP) | **Elite (RSC \+ ISR \+ Edge)** |
| **Multi-Tenancy** | Enterprise Feature (Cloud) | Built-in | **Custom Middleware Implementation** |
| **Customizability** | Restricted by Core Logic | Restricted by Blade Templates | **Unlimited (Full Code Control)** |
| **Self-Hosting Difficulty** | High (Microservices orchestration) | Low (Single Docker Image) | **Moderate (Next.js Standalone)** |

## **8. Conclusion and Recommendation**

The analysis leads to a definitive conclusion based on the user's implicit needs for **performance**, **modern stack**, and **templating capabilities**.

1. **Do Not Use LinkStack**: It is too limited for a "Carrd alternative" that presumably needs layouts beyond a single column.  
2. **Use Webstudio Only If**: You want a *design tool* for yourself and are willing to tolerate the DevOps complexity of hosting it. It is not suitable as a "Template System" for end-users due to its complexity and feature gating.  
3. **Build 'Grimoire'**: This is the correct path for a developer who wants to create a platform. By combining **PayloadCMS 3.0** (for data structure), **Next.js 15** (for performance and rendering), and **Puck** (for the visual interface), you can build a system that surpasses the capabilities of self-hosted alternatives.

**Final Architectural Prescription**:

* **Stack**: PayloadCMS 3.0 \+ Next.js 15 \+ Postgres \+ Tailwind v4.  
* **Editor**: Integrate **Puck** via a custom Payload Field.  
* **Templating**: Implement a **Local API-based cloning service** that deep-copies Block arrays and regenerates IDs.  
* **Deployment**: Deploy via Docker with Caddy for SSL management, or Vercel for immediate MVP validation using the Platforms Starter Kit patterns.

This approach transforms the "Build" from a daunting from-scratch endeavor into a manageable integration of three powerful, modern tools, delivering a product that is sovereign, performant, and highly scalable.

### **References**

1

#### **Referenzen**

1. LinkStack documentation: Overview of LinkStack, Zugriff am Januar 31, 2026, [https://docs.linkstack.org/](https://docs.linkstack.org/)  
2. LinkStack \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/linkstackorg](https://github.com/linkstackorg)  
3. FAQ \- Webstudio, Zugriff am Januar 31, 2026, [https://webstudio.is/faq](https://webstudio.is/faq)  
4. Frequently asked questions \- Webstudio, Zugriff am Januar 31, 2026, [https://webstudio.is/faq/permissions](https://webstudio.is/faq/permissions)  
5. LinkStack \- the ultimate solution for creating a personalized & professional profile page. Showcase all your important links in one place, forget the limitation of one link on social media. Set up your personal site on your own server with just a few clicks. \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/LinkStackOrg/LinkStack](https://github.com/LinkStackOrg/LinkStack)  
6. Self-Hosted Link Tree Alternative | LinkStack Linode Setup Guide \- YouTube, Zugriff am Januar 31, 2026, [https://www.youtube.com/watch?v=VJpZMZOBeB0](https://www.youtube.com/watch?v=VJpZMZOBeB0)  
7. Webstudio — Advanced Open Source Website Builder, Zugriff am Januar 31, 2026, [https://webstudio.is/](https://webstudio.is/)  
8. Frequently asked questions \- Webstudio, Zugriff am Januar 31, 2026, [https://webstudio.is/faq/deployment](https://webstudio.is/faq/deployment)  
9. urdadx/librelinks: An opensource link in bio tool for everyone \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/urdadx/librelinks](https://github.com/urdadx/librelinks)  
10. Building a Modern Link-in-Bio Platform with Next.js 15 \- Indie Hackers, Zugriff am Januar 31, 2026, [https://www.indiehackers.com/post/building-a-modern-link-in-bio-platform-with-next-js-15-b4a8325c3e](https://www.indiehackers.com/post/building-a-modern-link-in-bio-platform-with-next-js-15-b4a8325c3e)  
11. Payload 3.0: The first CMS that installs directly into any Next.js app, Zugriff am Januar 31, 2026, [https://payloadcms.com/posts/blog/payload-30-the-first-cms-that-installs-directly-into-any-nextjs-app](https://payloadcms.com/posts/blog/payload-30-the-first-cms-that-installs-directly-into-any-nextjs-app)  
12. Learn advanced Next.js with Payload's website template: Part 1, Zugriff am Januar 31, 2026, [https://payloadcms.com/posts/guides/learn-advanced-nextjs-with-payloads-website-template](https://payloadcms.com/posts/guides/learn-advanced-nextjs-with-payloads-website-template)  
13. Learn advanced Next.js with Payload's website template \- Part 1 \- YouTube, Zugriff am Januar 31, 2026, [https://www.youtube.com/watch?v=ngm786aqnuo](https://www.youtube.com/watch?v=ngm786aqnuo)  
14. You don't need Vercel. Hosting Next.js 15 with Docker and SQLite : r/nextjs \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/nextjs/comments/1qdcxf8/you\_dont\_need\_vercel\_hosting\_nextjs\_15\_with/](https://www.reddit.com/r/nextjs/comments/1qdcxf8/you_dont_need_vercel_hosting_nextjs_15_with/)  
15. Local API | Documentation \- Payload CMS, Zugriff am Januar 31, 2026, [https://payloadcms.com/docs/local-api/overview](https://payloadcms.com/docs/local-api/overview)  
16. Puck 0.18, the visual editor for React, adds drag-and-drop across CSS grid and flexbox (MIT) : r/nextjs \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/nextjs/comments/1i79k6y/puck\_018\_the\_visual\_editor\_for\_react\_adds/](https://www.reddit.com/r/nextjs/comments/1i79k6y/puck_018_the_visual_editor_for_react_adds/)  
17. Show HN: Puck – Open-source visual editor for React \- Hacker News, Zugriff am Januar 31, 2026, [https://news.ycombinator.com/item?id=44115590](https://news.ycombinator.com/item?id=44115590)  
18. Copystrike/puckload-poc: Proof of concept: Payloadcms \+ ... \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/Copystrike/puckload-poc](https://github.com/Copystrike/puckload-poc)  
19. External Data Sources | Puck, Zugriff am Januar 31, 2026, [https://puckeditor.com/docs/integrating-puck/external-data-sources](https://puckeditor.com/docs/integrating-puck/external-data-sources)  
20. Astro vs. Next.js | CloudCannon, Zugriff am Januar 31, 2026, [https://cloudcannon.com/blog/astro-vs-next-js/](https://cloudcannon.com/blog/astro-vs-next-js/)  
21. Next.js vs Astro: Choosing the Right Framework for Your Project | Cosmic, Zugriff am Januar 31, 2026, [https://www.cosmicjs.com/blog/nextjs-vs-astro-choosing-the-right-framework-for-your-project](https://www.cosmicjs.com/blog/nextjs-vs-astro-choosing-the-right-framework-for-your-project)  
22. Building Your Own Plugin | Documentation \- Payload CMS, Zugriff am Januar 31, 2026, [https://payloadcms.com/docs/plugins/build-your-own](https://payloadcms.com/docs/plugins/build-your-own)  
23. Easy Database Seeding in Payload CMS. My First 100 Video Series (Episode 11 of 100), Zugriff am Januar 31, 2026, [https://www.youtube.com/watch?v=z0jiyp5s9-g](https://www.youtube.com/watch?v=z0jiyp5s9-g)  
24. How to customize the Payload admin panel with Tailwind CSS 4, Zugriff am Januar 31, 2026, [https://payloadcms.com/posts/guides/how-to-theme-the-payload-admin-panel-with-tailwind-css-4](https://payloadcms.com/posts/guides/how-to-theme-the-payload-admin-panel-with-tailwind-css-4)  
25. How to setup Tailwind CSS and shadcn/ui in Payload, Zugriff am Januar 31, 2026, [https://payloadcms.com/posts/guides/how-to-setup-tailwindcss-and-shadcn-ui-in-payload](https://payloadcms.com/posts/guides/how-to-setup-tailwindcss-and-shadcn-ui-in-payload)  
26. Next.js Starter Templates & Themes \- Vercel, Zugriff am Januar 31, 2026, [https://vercel.com/templates/nextjs](https://vercel.com/templates/nextjs)  
27. Platforms Starter Kit \- Next.js Multi-Tenant Example \- Vercel, Zugriff am Januar 31, 2026, [https://vercel.com/templates/next.js/platforms-starter-kit](https://vercel.com/templates/next.js/platforms-starter-kit)  
28. Self-Hosting \- Webstudio Documentation, Zugriff am Januar 31, 2026, [https://docs.webstudio.is/university/self-hosting](https://docs.webstudio.is/university/self-hosting)  
29. Top 10 Open Source Alternatives to Carrd in 2025: A Comprehensive Comparison, Zugriff am Januar 31, 2026, [https://www.femaleswitch.com/directories/tpost/z3oio78vl1-top-10-open-source-alternatives-to-carrd](https://www.femaleswitch.com/directories/tpost/z3oio78vl1-top-10-open-source-alternatives-to-carrd)  
30. Are there any self-hosted Linktree-like "about page" type things? : r/selfhosted \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/selfhosted/comments/1crr0tw/are\_there\_any\_selfhosted\_linktreelike\_about\_page/](https://www.reddit.com/r/selfhosted/comments/1crr0tw/are_there_any_selfhosted_linktreelike_about_page/)  
31. LinkStack \- OpenBestof \- Self-Hosted, Zugriff am Januar 31, 2026, [https://sh.openbestof.com/tools/linkstack/](https://sh.openbestof.com/tools/linkstack/)  
32. The Payload Config | Documentation, Zugriff am Januar 31, 2026, [https://payloadcms.com/docs/configuration/overview](https://payloadcms.com/docs/configuration/overview)  
33. Self-host your supastarter for Next.js 14 app with Docker, Zugriff am Januar 31, 2026, [https://supastarter.dev/blog/self-host-nextjs-app-with-docker](https://supastarter.dev/blog/self-host-nextjs-app-with-docker)