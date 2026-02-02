# **Comprehensive Architectural Analysis of Self-Hosted Git Infrastructure and Identity Federation**

## **1. Executive Summary**

The modern software development lifecycle (SDLC) demands an infrastructure that balances autonomy, security, and interoperability. For the "KyleHub" initiative, the objective is to establish a self-hosted Git service that retains full data sovereignty while integrating seamlessly with an existing centralized identity provider, Zitadel, via OpenID Connect (OIDC). This report provides an exhaustive technical evaluation of the available self-hosted Git solutions—specifically Gitea, Forgejo, GitLab Community Edition (CE), OneDev, and Soft Serve—to determine the optimal platform for this specific architectural context.

The analysis delves beyond superficial feature comparison, rigorously examining the underlying architectures, resource consumption profiles, and OIDC integration mechanics of each candidate. Critical attention is devoted to the configuration of OIDC authentication flows, addressing the specific challenges of claim mapping, Just-In-Time (JIT) user provisioning, and scope management that arise when federating identity with Zitadel. Furthermore, the report evaluates the maturity of the Continuous Integration/Continuous Delivery (CI/CD) ecosystems embedded within these platforms, contrasting the resource-heavy but feature-rich GitLab Runner architecture against the lightweight, GitHub Actions-compatible act\_runner used by Gitea and Forgejo.

Based on the synthesis of technical documentation, performance benchmarks, and community governance models, the analysis identifies distinct trade-offs. While GitLab CE sets the standard for enterprise features, its resource footprint and "Open Core" limitations regarding mirroring and identity management present significant barriers for efficiency-focused self-hosting. Conversely, the Gitea and Forgejo ecosystems offer a compelling efficiency-to-utility ratio, with Forgejo emerging as a robust candidate for those prioritizing strict Free Software principles and long-term stability. The report concludes with a detailed implementation strategy, offering precise configuration directives for integrating the selected platform with Zitadel to ensure a secure, resilient, and scalable "KyleHub."

## **2. Infrastructure Philosophy and Identity Federation**

The transition to a self-hosted Git infrastructure moves the locus of control from third-party SaaS providers to the infrastructure owner. However, this decentralization necessitates a robust centralized authentication strategy to prevent identity sprawl. "KyleHub" leverages Zitadel as this central authority, utilizing the OpenID Connect (OIDC) protocol to federation identity across services.

### **2.1 The Strategic Role of Zitadel in DevOps Infrastructure**

Zitadel operates as a cloud-native Identity and Access Management (IAM) solution, distinct from legacy LDAP systems by utilizing modern standards like OIDC and OAuth 2.0. In the context of "KyleHub," integrating the Git service with Zitadel shifts the responsibility of credential handling, multi-factor authentication (MFA), and session lifecycle management away from the application and onto the IdP.1 This separation of concerns is critical for security; the Git service need not store password hashes or manage reset flows, instead relying on cryptographically signed assertions (tokens) from Zitadel.

Zitadel’s architecture supports project-based multi-tenancy, allowing "KyleHub" to be defined as a specific Project within an Organization.2 This hierarchical structure enables granular role management, where Zitadel "Actions" can be scripted to inject specific claims—such as is\_admin or team\_membership—into the tokens presented to the Git service, theoretically allowing for centralized role-based access control (RBAC).1

### **2.2 OpenID Connect (OIDC) Mechanics and Flow**

Understanding the OIDC flow is prerequisite to debugging integration issues. The integration typically employs the **Authorization Code Flow**, often enhanced with **PKCE (Proof Key for Code Exchange)** for additional security.3

1. **Initiation:** The user attempts to access "KyleHub" and chooses "Sign in with Zitadel." The Git service redirects the user agent to Zitadel's authorization endpoint.  
2. **Authentication:** Zitadel validates the user's credentials. This interaction happens entirely within Zitadel's domain, protecting credentials from the Git service.  
3. **Authorization:** Upon successful authentication, Zitadel issues an Authorization Code to the browser, which redirects back to the Git service's registered redirect\_uri (e.g., https://git.kylehub.io/user/oauth2/zitadel/callback).4  
4. **Token Exchange:** The Git service’s backend makes a direct, back-channel request to Zitadel’s token endpoint, exchanging the Authorization Code (and its client\_secret) for an **ID Token** and an **Access Token**.3  
5. **Claim Inspection & Provisioning:** The Git service decodes the ID Token (a JWT) to extract claims. Critical claims include:  
   * sub (Subject): A unique, immutable identifier for the user.  
   * name / preferred\_username: Used to seed the local username.  
   * email / email\_verified: Used for account linking and notifications.  
   * groups: Optional claim used for organization mapping.5

A recurring challenge in self-hosted integrations involves **Just-In-Time (JIT) Provisioning**.6 When a new user authenticates via Zitadel, the Git service must decide whether to link this identity to an existing account (by matching email) or create a new local user. Misconfiguration here often leads to duplicate accounts or security vulnerabilities where an attacker could hijack an account by registering a matching email on the IdP.5

## **3. Architectural Evaluation of Git Service Candidates**

The selection of the Git platform defines the resource requirements, maintenance burden, and feature set of "KyleHub." We analyze the primary candidates—GitLab CE, Gitea, Forgejo, OneDev, and Soft Serve—focusing on their architectural suitability for a Zitadel-integrated environment.

### **3.1 GitLab Community Edition (CE): The Enterprise Monolith**

GitLab CE is the open-source version of the GitLab platform. It is an "Open Core" product, meaning significant features are reserved for the paid Enterprise Edition (EE).

**Architecture and Resource Profile:** GitLab is architecturally complex, composed of a Ruby on Rails monolith, Go microservices (Gitaly, GitLab Workhorse), a PostgreSQL database, Redis for caching, and Prometheus for monitoring.7 This complexity translates to high resource demands. The minimum viable configuration requires 4GB of RAM plus swap, but production stability typically demands 8GB+.8 In idle states, GitLab can consume upwards of 2.5GB to 4GB of RAM merely to keep its services resident.9 For "KyleHub," this implies a need for dedicated hardware or a substantial VM allocation.

**OIDC Integration:** GitLab utilizes the omniauth Ruby gem for authentication. While robust, the integration configuration in gitlab.rb is verbose. A critical limitation of the CE version is the lack of **SAML/OIDC Group Sync**.10 While CE allows authentication via OIDC, mapping Zitadel groups to GitLab groups automatically is generally an EE feature, necessitating manual user management after the initial JIT provisioning.

**Mirroring Limitations:** GitLab CE supports **Push Mirroring** (pushing to GitHub) freely, but **Pull Mirroring** (syncing changes from an external repo to GitLab) is strictly a paid feature.11 This is a significant architectural constraint for a self-hosted hub intended to mirror upstream open-source projects.

### **3.2 Gitea: The Efficient Standard**

Gitea is a community-managed fork of Gogs, written in Go. It prioritizes efficiency and ease of deployment.

**Architecture and Resource Profile:** Gitea compiles to a single binary, simplifying updates and deployment. It supports SQLite, MySQL, and PostgreSQL. Its resource footprint is minimal; idle memory usage is often reported between 40MB and 200MB.13 This efficiency makes it ideal for running alongside Zitadel on shared hardware without contention.

**OIDC Integration:** Gitea features native OIDC support that is highly configurable via its app.ini or web interface. It supports auto-discovery, scope customization, and granular control over user provisioning (e.g., matching by email vs. creating new accounts).4 The integration allows for mapping the OIDC preferred\_username claim to the local Gitea username, which is critical for maintaining consistent identities across "KyleHub".5

### **3.3 Forgejo: Sovereignty and Stability**

Forgejo originated as a soft fork of Gitea in October 2022 and transitioned to a hard fork in 2024.15 It was created in response to the commercialization of Gitea, with a mandate to remain strictly non-profit and Free Software.

**Architecture and Resource Profile:** Forgejo shares the Go-based architecture of Gitea and maintains a similar resource profile (\~150MB idle RAM).15 However, the projects are diverging. Forgejo emphasizes supply chain security and "soft" federation features.

**Governance and Licensing:** For a self-hosted "KyleHub" prioritizing independence, Forgejo’s governance model (Codeberg e.V.) offers insurance against future "Open Core" restrictions.16 Unlike Gitea, where feature development might be influenced by commercial interests, Forgejo guarantees that features like Actions and Federation remain free.

**CI/CD Ecosystem:** Forgejo (and Gitea) utilizes act\_runner, a runner based on nektos/act that is capable of executing GitHub Actions workflows.15 This architectural decision provides massive utility, allowing "KyleHub" to leverage the existing ecosystem of GitHub Actions, whereas GitLab requires rewriting pipelines into its specific syntax.

### **3.4 OneDev: The Integrated Java Platform**

OneDev offers a tightly integrated platform with unique features like code-aware searching and native Kubernetes CI/CD.

**Architecture and Resource Profile:** Built on Java (Wicket framework), OneDev is heavier than the Go-based forges but lighter than GitLab, typically requiring 2GB+ of RAM for the JVM.17 It is particularly strong in environments where Kubernetes is the underlying infrastructure.

**OIDC Challenges:** Integration with OIDC has historically been a friction point for OneDev. Users report 500 Internal Server Errors during the callback phase, often triggered by strict validation of claims or mismatches in the UserInfo response.19 Specifically, issues have arisen when the IdP does not provide a name claim or when username mapping encounters conflicts. While recent versions (11.0+) have addressed some of these 21, the configuration requires precise alignment of claims (e.g., ensuring Zitadel sends preferred\_username and OneDev is configured to expect it).

### **3.5 Soft Serve: The Minimalist Terminal Forge**

Soft Serve represents a radical departure, offering a Git server accessed entirely via the terminal (SSH/TUI).22

**Architecture and Workflow:** It is a single Go binary. Management is performed via ssh commands (e.g., ssh git.kylehub.io repo create). It lacks a web interface, rendering it unsuitable for users who rely on web-based Pull Request reviews or issue tracking.22

**OIDC Utility:** Soft Serve's OIDC integration is primarily for generating HTTP access tokens via the CLI.22 It does not use OIDC for the primary SSH authentication flow, limiting the utility of Zitadel for access control compared to the other platforms.

## **4. Technical Implementation: Zitadel OIDC Integration**

This section provides the specific implementation details for integrating the viable candidates with Zitadel.

### **4.1 Configuring Zitadel for "KyleHub"**

Before configuring the Git service, Zitadel must be prepared.

1. **Project Creation:** Create a project named "KyleHub".  
2. **Application Creation:** Create a new Application.  
   * **Type:** Web Application (Server-side).  
   * **Auth Method:** PKCE (Recommended) or Code (Basic).  
   * **Redirect URIs:** These must be exact.  
     * For Gitea/Forgejo: https://\<git-url\>/user/oauth2/zitadel/callback.4  
     * For GitLab: https://\<gitlab-url\>/users/auth/openid\_connect/callback.23  
     * For OneDev: https://\<onedev-url\>/sso/callback (verify specific version path).  
3. **Token Settings:** Ensure "Auth Token Type" is JWT.  
4. **Action for Claims (Optional but Recommended):** To simplify mapping, a Zitadel Action can be scripted to copy the user's role or group membership into a groups claim in the ID Token.

### **4.2 Gitea / Forgejo Implementation Strategy**

The configuration is identical for both, typically managed in custom/conf/app.ini.

**OAuth2 Client Configuration:**

The \[oauth2\_client\] section controls how OIDC users are handled.

Ini, TOML

\[oauth2\_client\]  
ENABLE\_AUTO\_REGISTRATION \= true  
ACCOUNT\_LINKING \= auto  
USERNAME \= preferred\_username  
OpenIdConnectScopes \= openid, profile, email, groups

* ENABLE\_AUTO\_REGISTRATION \= true: This allows a user authenticated by Zitadel to automatically have a local account created. This is crucial for seamless onboarding.4  
* ACCOUNT\_LINKING \= auto: This links the OIDC identity to an existing account if the email matches. **Warning:** This assumes the OIDC provider (Zitadel) has verified the email. Ensure Zitadel enforces email verification before issuing tokens to prevent account takeover attacks.  
* USERNAME \= preferred\_username: This maps the preferred\_username claim from Zitadel to the local username. If set to nickname or email, the user experience may suffer from awkward generated usernames.4

**Service Configuration:**

To enforce Zitadel as the primary auth method, disable local registration:

Ini, TOML

\[service\]  
DISABLE\_REGISTRATION \= true  
ALLOW\_ONLY\_EXTERNAL\_REGISTRATION \= true

This configuration 24 ensures that no user can register directly via the Git form; they *must* come through Zitadel, ensuring the IdP remains the single source of truth.

**Troubleshooting "Disable Registration":** A known issue exists where setting DISABLE\_REGISTRATION \= true can inadvertently block OIDC auto-registration if not paired with ENABLE\_AUTO\_REGISTRATION \= true in the OAuth2 config.25 Administrators must ensure both are set correctly to allow federated users to sign up while blocking local sign-ups.

### **4.3 GitLab CE Implementation Strategy**

GitLab's configuration is managed via the OmniAuth provider settings in /etc/gitlab/gitlab.rb.

**Configuration Block:**

Ruby

gitlab\_rails\['omniauth\_enabled'\] \= true  
gitlab\_rails\['omniauth\_allow\_single\_sign\_on'\] \= \['openid\_connect'\]  
gitlab\_rails\['omniauth\_auto\_link\_user'\] \= \['openid\_connect'\]  
gitlab\_rails\['omniauth\_providers'\] \= \[  
  {  
    'name' \=\> 'openid\_connect',  
    'label' \=\> 'Zitadel',  
    'args' \=\> {  
      'name' \=\> 'openid\_connect',  
      'scope' \=\> \['openid', 'profile', 'email'\],  
      'response\_type' \=\> 'code',  
      'issuer' \=\> 'https://\<zitadel-instance\>',  
      'discovery' \=\> true,  
      'client\_auth\_method' \=\> 'query',  
      'uid\_field' \=\> 'sub',  
      'client\_options' \=\> {  
        'identifier' \=\> '\<CLIENT\_ID\>',  
        'secret' \=\> '\<CLIENT\_SECRET\>',  
        'redirect\_uri' \=\> 'https://\<gitlab-url\>/users/auth/openid\_connect/callback'  
      }  
    }  
  }  
\]

* **Auto Link:** omniauth\_auto\_link\_user is critical. Without it, users with matching emails will be prompted to manually link accounts, or linking may fail depending on security settings.  
* **Discovery:** Setting discovery to true allows GitLab to fetch the endpoint URLs from /.well-known/openid-configuration, simplifying setup.2  
* **UID Field:** Using sub is standard, as it is the immutable identifier from the IdP.

### **4.4 OneDev Implementation & Troubleshooting**

OneDev requires configuration via its web UI (Administration \-\> Authentication Source).

**The "500 Error" Issue:** As noted in research snippets, users frequently encounter HTTP 500 errors during the OIDC callback.19 This is often due to OneDev failing to map a mandatory attribute, specifically the username or email, from the UserInfo response.

* **Fix:** In the OneDev SSO configuration, ensure the "Username Attribute" matches a claim that Zitadel *guarantees* to send (e.g., preferred\_username or sub). If Zitadel sends email but not preferred\_username, and OneDev is configured to look for login, the mapping fails, throwing a RuntimeException.19  
* **Scope:** Ensure the openid, profile, and email scopes are requested.  
* **Debug:** If the error persists, check the OneDev server logs for pydantic\_core or WicketRuntimeException errors 19, which indicate a schema validation failure of the incoming JWT.

## **5. Continuous Integration & Delivery Ecosystems**

For "KyleHub," the CI/CD capability is as important as the code storage. The choice of Git platform dictates the runner architecture.

### **5.1 Forgejo/Gitea: The act\_runner Architecture**

Forgejo and Gitea use act\_runner, a Go-based daemon that connects to the instance via gRPC.27

**GitHub Actions Compatibility:**

The most significant advantage of this ecosystem is its compatibility with GitHub Actions. The act\_runner interprets .github/workflows/\*.yaml files.

* **Mechanism:** It pulls a Docker image (e.g., node:16-bullseye) to execute the steps defined in the workflow.  
* **Limitations:** While mostly compatible, specific features like Matrix builds have historically had differences in behavior compared to GitHub.28 Furthermore, actions that rely on hardcoded GitHub URLs or specific GitHub APIs may fail unless mapped correctly.  
* **Resource Usage:** The runner process itself uses minimal RAM (\~20-50MB).14 However, the *workload* (the Docker containers spawned) determines the actual consumption. Since it spawns ephemeral containers for each job, it ensures clean environments but requires the host to have sufficient capacity for Docker execution.

### **5.2 GitLab Runner: The Heavy Duty Option**

GitLab Runner is a mature, enterprise-grade CI executor.

**Architecture:**

It is a standalone Go binary that polls the GitLab API for pending jobs.

* **Executors:** It supports multiple executors.29  
  * **Shell:** Runs jobs directly on the host. Fast, but insecure and not isolated.  
  * **Docker:** Runs jobs in containers. The standard for modern CI.  
  * **Docker Machine:** Used for auto-scaling runners on cloud providers.  
* **Resource Benchmarks:**  
  * The Runner binary is lightweight.  
  * The GitLab *Server* bears the load of orchestrating the pipeline state. Processing logs for a massive job (e.g., 1 million lines) can cause the GitLab server's memory usage to spike significantly (e.g., 4.5GB RAM usage for log processing).30 This "log parsing overhead" is a known bottleneck in resource-constrained GitLab instances.

**Comparison Table: CI/CD Resources**

| Feature | act\_runner (Gitea/Forgejo) | gitlab-runner (GitLab) |
| :---- | :---- | :---- |
| **Configuration** | .github/workflows (YAML) | .gitlab-ci.yml (YAML) |
| **Runner Idle RAM** | \~20-50 MB | \~30-60 MB |
| **Server Overhead** | Low (gRPC connection) | High (Log processing, State management) |
| **Isolation** | Docker (Default) | Docker (Configurable) |
| **Ecosystem** | GitHub Actions Marketplace | GitLab CI Templates |

### **5.3 Benchmarking & Performance**

In a self-hosted context like "KyleHub," every megabyte counts.

* **Gitea/Forgejo:** A full stack (Web \+ DB \+ Runner) can run comfortably on **1GB RAM**. The web service typically idles at 150MB.8  
* **GitLab CE:** A functional stack requires **4GB+ RAM**. The bundle (Rails) processes and sidekiq (background jobs) are memory hungry. Idle usage rarely drops below 2.5GB.7  
* **OneDev:** Requires **2GB+ RAM**. The JVM pre-allocates memory, making it less flexible on constrained hardware.17

## **6. Automated Provisioning and API Strategy**

To manage "KyleHub" efficiently, especially if integrating with other Infrastructure-as-Code (IaC) tools, API interaction is required.

### **6.1 Creating Repositories on Behalf of Users (Sudo Mode)**

A common requirement is to programmatically create repositories for users managed by Zitadel.

* **Gitea/Forgejo API:** The API supports a Sudo mechanism. An admin can execute actions as another user.  
  * **Header:** Sudo: \<username\>  
  * **Query Param:** ?sudo=\<username\>.31  
  * **Endpoint:** POST /api/v1/admin/users/{username}/repos allows creating a repo directly under a specific user's namespace.33  
* **GitLab API:** Requires an Impersonation Token or using the Sudo header with an Admin Personal Access Token.

### **6.2 Generating from Templates**

Standardizing project structures is a best practice. Gitea/Forgejo allows generating new repositories from template repositories via the API.

* **Endpoint:** POST /repos/{template\_owner}/{template\_repo}/generate.34  
* **Payload:** Can include parameters to enable/disable Git hooks, avatars, and labels.  
* **Integration:** A script could listen for a "New User" webhook from Zitadel and automatically trigger this endpoint to provision a "Welcome" repository for the new user on "KyleHub."

**Forgejo Template Limitations:** When generating from a template, certain variables in files (like REPO\_NAME) can be auto-expanded if configured in .gitea/template.35 This allows for dynamic initialization of READMEs and config files.

## **7. Repository Mirroring and Synchronization**

Data redundancy is a core tenet of self-hosting.

### **7.1 Push Mirroring (Backup)**

"KyleHub" should ideally push code to a secondary location (like GitHub) for safekeeping.

* **GitLab CE:** Supports Push Mirroring natively in the free tier.11 You configure the remote URL and authentication (username/token), and GitLab pushes changes automatically.  
* **Gitea/Forgejo:** Also supports Push Mirroring natively. Configuration is per-repository in the "Settings" \-\> "Mirror Settings" menu.

### **7.2 Pull Mirroring (Upstream Sync)**

This is where the platforms diverge significantly.

* **GitLab CE:** **Does NOT support Pull Mirroring** in the free version.12 To sync a repo from GitHub *to* GitLab automatically, you must pay for Premium or write custom cron scripts (using git fetch / git push).  
* **Gitea/Forgejo:** Supports **Pull Mirroring** natively and for free.36 You can set an interval (e.g., every 8 hours) for "KyleHub" to fetch updates from an upstream GitHub repository. This is vital for maintaining local copies of dependencies or mirroring open-source projects.

## **8. Governance, Licensing, and Long-Term Viability**

The choice between Gitea and Forgejo is heavily influenced by governance.

* **Gitea:** Transferred domain and trademark to a for-profit entity. While currently open source (MIT), the structural incentives align with an "Open Core" model where advanced features might be gated in the future.15  
* **Forgejo:** Governed by a non-profit (Codeberg e.V.). It has committed to keeping all features (including federation and actions) free. The "Hard Fork" status means their codebases are drifting apart.15  
* **GitLab:** Publicly traded company. The "Open Core" model is aggressive; useful features (like Pull Mirroring) are deliberately excluded from CE to drive upsells.

**Strategic Insight:** For a self-hosted environment intended to last years ("KyleHub"), Forgejo offers the highest degree of alignment with user interests, minimizing the risk of "rug pulls" or feature paywalls.

## **9. Recommendation and Implementation Plan**

Based on the requirement for **Zitadel OIDC integration**, **resource efficiency**, and **full feature availability** (including mirroring and CI/CD), **Forgejo** is the optimal choice for "KyleHub."

### **9.1 Recommended Architecture**

* **Identity:** Zitadel (OIDC Provider)  
* **Git Service:** Forgejo (Docker Container)  
* **CI/CD:** act\_runner (Docker Container)  
* **Database:** PostgreSQL (Shared between Zitadel and Forgejo, distinct databases)

### **9.2 Implementation Checklist**

1. **Zitadel Setup:**  
   * Create Web App "Forgejo".  
   * Set Redirect URI: https://git.kylehub.io/user/oauth2/zitadel/callback.  
   * Note ClientID and ClientSecret.  
2. **Forgejo Configuration (app.ini):**  
   Ini, TOML  
   \[server\]  
   ROOT\_URL \= https://git.kylehub.io/

   \[service\]  
   DISABLE\_REGISTRATION \= true  
   ALLOW\_ONLY\_EXTERNAL\_REGISTRATION \= true

   \[oauth2\_client\]  
   ENABLE\_AUTO\_REGISTRATION \= true  
   ACCOUNT\_LINKING \= auto  
   USERNAME \= preferred\_username

3. **Runner Deployment:**  
   * Deploy act\_runner connecting to Forgejo.  
   * Ensure the runner has access to the docker socket (or use rootless docker) to spawn job containers.  
4. **Verification:**  
   * Log out of Forgejo local admin.  
   * Click "Sign in with Zitadel."  
   * Verify redirection, authentication, and return.  
   * Confirm a new user is created in Forgejo with the username from Zitadel.

By selecting Forgejo, "KyleHub" secures a lightweight, feature-complete platform that respects the user's sovereignty while integrating robustly with Zitadel's modern identity management capabilities. This architecture avoids the resource overhead of GitLab and the stability risks of OneDev, providing a stable foundation for years of development.

#### **Referenzen**

1. Authenticate users with OpenID Connect (OIDC) \- ZITADEL, Zugriff am Januar 31, 2026, [https://zitadel.com/docs/guides/integrate/login/oidc](https://zitadel.com/docs/guides/integrate/login/oidc)  
2. Log in with ZITADEL on Gitlab OmniAuth Provider, Zugriff am Januar 31, 2026, [https://zitadel.com/docs/guides/integrate/services/gitlab-self-hosted](https://zitadel.com/docs/guides/integrate/services/gitlab-self-hosted)  
3. How OpenID Connect Works \- OpenID Foundation, Zugriff am Januar 31, 2026, [https://openid.net/developers/how-connect-works/](https://openid.net/developers/how-connect-works/)  
4. Configuration Cheat Sheet | Gitea Documentation, Zugriff am Januar 31, 2026, [https://docs.gitea.com/administration/config-cheat-sheet](https://docs.gitea.com/administration/config-cheat-sheet)  
5. Configuration Cheat Sheet | Gitea Documentation, Zugriff am Januar 31, 2026, [https://docs.gitea.com/1.19/administration/config-cheat-sheet](https://docs.gitea.com/1.19/administration/config-cheat-sheet)  
6. JIT Provisioning using OpenID Connect \- Xurrent Developer Documentation, Zugriff am Januar 31, 2026, [https://developer.xurrent.com/v1/jit\_provisioning/openid\_connect/](https://developer.xurrent.com/v1/jit_provisioning/openid_connect/)  
7. Running GitLab in a memory-constrained environment, Zugriff am Januar 31, 2026, [https://docs.gitlab.com/omnibus/settings/memory\_constrained\_envs/](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs/)  
8. Gitea vs GitLab: A Comprehensive Comparison in 2025 \- Ruby-Doc.org, Zugriff am Januar 31, 2026, [https://ruby-doc.org/blog/gitea-vs-gitlab-a-comprehensive-comparison-in-2025/](https://ruby-doc.org/blog/gitea-vs-gitlab-a-comprehensive-comparison-in-2025/)  
9. Gitlab vs Gitea : r/selfhosted \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/selfhosted/comments/1htb7y1/gitlab\_vs\_gitea/](https://www.reddit.com/r/selfhosted/comments/1htb7y1/gitlab_vs_gitea/)  
10. Log in with ZITADEL on Gitlab through SAML 2.0, Zugriff am Januar 31, 2026, [https://zitadel.com/docs/guides/integrate/services/gitlab-saml](https://zitadel.com/docs/guides/integrate/services/gitlab-saml)  
11. Push mirroring \- GitLab Docs, Zugriff am Januar 31, 2026, [https://docs.gitlab.com/user/project/repository/mirror/push/](https://docs.gitlab.com/user/project/repository/mirror/push/)  
12. Repository mirroring \- GitLab Docs, Zugriff am Januar 31, 2026, [https://docs.gitlab.com/user/project/repository/mirror/](https://docs.gitlab.com/user/project/repository/mirror/)  
13. Self-Hosted Git and CI/CD for fun (and profit?) \- Yaakov's Blog, Zugriff am Januar 31, 2026, [https://blog.yaakov.online/self-hosted-git-and-ci-cd-for-fun-and-profit/](https://blog.yaakov.online/self-hosted-git-and-ci-cd-for-fun-and-profit/)  
14. GitHub Alternatives: Gitea vs GitLab? : r/selfhosted \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/selfhosted/comments/1il8yue/github\_alternatives\_gitea\_vs\_gitlab/](https://www.reddit.com/r/selfhosted/comments/1il8yue/github_alternatives_gitea_vs_gitlab/)  
15. Comparison with Gitea | Forgejo – Beyond coding. We forge., Zugriff am Januar 31, 2026, [https://forgejo.org/compare-to-gitea/](https://forgejo.org/compare-to-gitea/)  
16. Comparison with other Forges | Forgejo – Beyond coding. We forge., Zugriff am Januar 31, 2026, [https://forgejo.org/compare/](https://forgejo.org/compare/)  
17. GitHub \- theonedev/onedev: Super Easy All-In-One DevOps Platform \- Show HN: OneDev – A Lightweight GitLab Alternative : r/programming \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/programming/comments/eqy6q8/github\_theonedevonedev\_super\_easy\_allinone\_devops/](https://www.reddit.com/r/programming/comments/eqy6q8/github_theonedevonedev_super_easy_allinone_devops/)  
18. System Requirement \- OneDev Documentation, Zugriff am Januar 31, 2026, [https://docs.onedev.io/installation-guide/system-requirement](https://docs.onedev.io/installation-guide/system-requirement)  
19. OIDC : Can't configure with LemonLDAP::NG (OD-970) \- OneDev, Zugriff am Januar 31, 2026, [https://code.onedev.io/sierra/onedev-server/\~issues/970](https://code.onedev.io/sierra/onedev-server/~issues/970)  
20. gitea/CHANGELOG.md at main · go-gitea/gitea \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/go-gitea/gitea/blob/main/CHANGELOG.md](https://github.com/go-gitea/gitea/blob/main/CHANGELOG.md)  
21. Releases · theonedev/onedev \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/theonedev/onedev/releases](https://github.com/theonedev/onedev/releases)  
22. charmbracelet/soft-serve: The mighty, self-hostable Git server for the command line \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/charmbracelet/soft-serve](https://github.com/charmbracelet/soft-serve)  
23. Configure GitLab as an Identity Provider in ZITADEL, Zugriff am Januar 31, 2026, [https://zitadel.com/docs/guides/integrate/identity-providers/gitlab](https://zitadel.com/docs/guides/integrate/identity-providers/gitlab)  
24. Gitea | OpenID Connect 1.0 | Integration \- Authelia, Zugriff am Januar 31, 2026, [https://www.authelia.com/integration/openid-connect/clients/gitea/](https://www.authelia.com/integration/openid-connect/clients/gitea/)  
25. Guide- Keycloak and Gitea \- Install/Maintain/Configure, Zugriff am Januar 31, 2026, [https://forum.gitea.com/t/guide-keycloak-and-gitea/9457](https://forum.gitea.com/t/guide-keycloak-and-gitea/9457)  
26. Authentik OpenID Failing (OD-607) \- onedev/server, Zugriff am Januar 31, 2026, [https://code.onedev.io/onedev/server/\~issues/607](https://code.onedev.io/onedev/server/~issues/607)  
27. Act Runner | Gitea Documentation, Zugriff am Januar 31, 2026, [https://docs.gitea.com/usage/actions/act-runner](https://docs.gitea.com/usage/actions/act-runner)  
28. Github actions replacement: gitea vs forgejo vs gitlab vs others : r/selfhosted \- Reddit, Zugriff am Januar 31, 2026, [https://www.reddit.com/r/selfhosted/comments/1pp4kn0/github\_actions\_replacement\_gitea\_vs\_forgejo\_vs/](https://www.reddit.com/r/selfhosted/comments/1pp4kn0/github_actions_replacement_gitea_vs_forgejo_vs/)  
29. Executors \- GitLab Docs, Zugriff am Januar 31, 2026, [https://docs.gitlab.com/runner/executors/](https://docs.gitlab.com/runner/executors/)  
30. Abnormal memory usage when reading large workflow log files · Issue \#35925 \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/go-gitea/gitea/issues/35925](https://github.com/go-gitea/gitea/issues/35925)  
31. API Usage | Forgejo – Beyond coding. We forge., Zugriff am Januar 31, 2026, [https://forgejo.org/docs/next/user/api-usage/](https://forgejo.org/docs/next/user/api-usage/)  
32. API Usage | Gitea Documentation, Zugriff am Januar 31, 2026, [https://docs.gitea.com/development/api-usage](https://docs.gitea.com/development/api-usage)  
33. Gitea API., Zugriff am Januar 31, 2026, [https://docs.gitea.com/api/1.19/](https://docs.gitea.com/api/1.19/)  
34. A python client for the gitea api \- GitHub, Zugriff am Januar 31, 2026, [https://github.com/awalker125/gitea-api](https://github.com/awalker125/gitea-api)  
35. Template Repositories \- Gitea Documentation, Zugriff am Januar 31, 2026, [https://docs.gitea.com/usage/template-repositories](https://docs.gitea.com/usage/template-repositories)  
36. Repository Mirror | Gitea Documentation, Zugriff am Januar 31, 2026, [https://docs.gitea.com/1.23/usage/repo-mirror](https://docs.gitea.com/1.23/usage/repo-mirror)