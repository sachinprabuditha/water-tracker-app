# Water Tracker DevOps: Zero to Hero

Oct 11, 2026 · @Sachin Prabuditha

You will learn DevOps and cloud by shipping one real product: the Water Tracker app plus a small backend API, built, tested, containerized, deployed to Kubernetes with Argo CD, provisioned with Terraform and monitored. At about 10 hours a week it takes roughly 7 months, and everything except the optional $25 Play Store fee can be done for $0.

## At a glance

&#91;embedded content: learning roadmap · 7 stages, about 28 weeks\]

The weeks assume about 10 hours of study a week. With more time, move faster; never skip a stage, because each one is built on the previous.

## What you will build

&#91;embedded content: final system architecture\]

You push code; GitHub Actions tests it, builds an image and opens a pull request that bumps the image tag in the GitOps repo; Argo CD sees the change and updates the cluster. The same pipeline also builds the Android APK and AAB for GitHub Releases and, optionally, Google Play.

## Before you start

Set up once in week 1, then follow the stages in order: each one builds on the last, and each ends with something you push to GitHub.

**Your computer**

- 8 GB RAM is the minimum for a local Kubernetes cluster; 16 GB is comfortable once monitoring is added.
- On Windows, install WSL2 with Ubuntu and do all DevOps work inside it. On macOS, use the Terminal. On Linux, you are ready.
- Install VS Code, Git, Docker (Docker Desktop on Windows/macOS, Docker Engine on Linux) and Flutter.
- Weak laptop? Use free browser labs ([Killercoda](https://killercoda.com), [Play with Docker](https://labs.play-with-docker.com)) and the Oracle Always Free VM from Stage 5.

**Accounts (all free)**

- GitHub: your code, CI/CD and container images all live here. Make your project repos public, which also keeps Actions free.
- Firebase: already used by the app (Spark plan).
- AWS and Oracle Cloud: wait until Stage 5. Both ask for a debit or credit card to verify your identity.

**How to study**

- Split every week into about 30% theory and 70% building. You learn DevOps by breaking things and fixing them.
- Keep a `LEARNING.md` log in your repo: what you did, what broke, how you fixed it. It becomes blog posts and interview stories later.
- Do not copy commands you do not understand. Run `--help` or read the man page first.
- Stuck for more than an hour? Search the exact error, then ask in the [DevOps subreddit](https://www.reddit.com/r/devops/) or the Kubernetes Slack.

**Rules that keep you at $0**

1. Build and practise everything locally first. The cloud is only for the final deployment.
2. In AWS, create a budget alert of $1 on day one and turn on MFA for the root user.
3. Never commit keys or passwords. Add a `.gitignore` before your first commit.
4. After every cloud lab, run `terraform destroy` and check the billing page.

## Stage 1: Foundations (weeks 1 to 5)

Every DevOps tool runs on Linux, is stored in Git and talks over a network, so these three skills come first. Milestone: the Flutter app is on GitHub with a clean history and a README.

### 1.1 Linux and the shell (weeks 1 to 3)

Learn: files and folders, permissions (`chmod`, `chown`), users and `sudo`, processes (`ps`, `top`, `kill`), package managers (`apt`), environment variables, pipes and redirection, `grep`/`find`/`sed`, `ssh`, `systemd` services, and simple Bash scripts.

- [Linux Journey](https://linuxjourney.com): read Grasshopper and Journeyman.
- [The Linux Command Line](https://linuxcommand.org/tlcl.php) by William Shotts: free book, chapters 1 to 11 and 24 to 30 (scripting).
- [OverTheWire Bandit](https://overthewire.org/wargames/bandit/): a game that drills shell skills. Aim for level 15.

Build:

- [ ] Write `scripts/setup-dev.sh` that checks Git, Docker and Flutter are installed and prints their versions.
- [ ] Write `scripts/backup.sh` that zips the project folder with today's date in the file name.

### 1.2 Git and GitHub (week 4)

Learn: commits, branches, merging, rebasing, resolving conflicts, `.gitignore`, pull requests, and a simple branching strategy (feature branches into `main`).

- [Pro Git](https://git-scm.com/book/en/v2): chapters 1 to 3.
- [Learn Git Branching](https://learngitbranching.js.org): interactive and visual.
- [GitHub Skills](https://skills.github.com): "Introduction to GitHub" and "Review pull requests".

Build:

- [ ] Create a public repo `water-tracker-app` and push the Flutter project.
- [ ] Add a `.gitignore` that excludes `key.properties`, `*.jks` and `google-services.json`.
- [ ] Protect `main`: changes only arrive through pull requests.
- [ ] Make every change from now on on a branch with a pull request, even when you work alone.

### 1.3 Networking basics (week 5)

Learn: IP addresses and CIDR (`10.0.0.0/16`), ports, DNS, HTTP methods and status codes, HTTPS and TLS certificates, load balancers, and what a reverse proxy does. You need these for Kubernetes Services, Ingress and AWS VPCs.

- [Cloudflare Learning Center](https://www.cloudflare.com/learning/): DNS, CDN, TLS and "what is a load balancer".
- [MDN: An overview of HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview).

Build:

- [ ] Use `curl -v`, `dig` and `ping` on a few websites and explain each line of output in `LEARNING.md`.
- [ ] Draw your home network: router, devices, IP addresses, DNS server.

## Stage 2: Build and package (weeks 6 to 9)

A mobile app alone gives Kubernetes nothing to run, so you add a small backend API and then package it as a container. Milestone: `docker compose up` starts the API and its database, and the app shows the daily tip from it.

### 2.1 The Water Tracker API (weeks 6 and 7)

Firebase keeps each user's water log. The new API serves content that is the same for everyone, which makes it a realistic service to deploy, scale and monitor.

| Endpoint | What it does |
| --- | --- |
| `GET /health` | Returns 200 if the process is alive (Kubernetes liveness probe) |
| `GET /ready` | Returns 200 only when the database is reachable (readiness probe) |
| `GET /v1/tips/today` | A hydration tip of the day, shown on the Today screen |
| `GET /v1/config` | Remote settings: minimum app version, reminder message texts |
| `POST /v1/feedback` | Saves feedback sent from the Settings screen |
| `GET /metrics` | Request counts and timings for Prometheus (Stage 6) |

Stack: Python with [FastAPI](https://fastapi.tiangolo.com/tutorial/) and PostgreSQL. Python is also the most useful scripting language in DevOps.

Learn: Python basics (if new), REST APIs, JSON, environment variables for configuration, connecting to PostgreSQL, and unit tests with `pytest`.

- [FastAPI tutorial](https://fastapi.tiangolo.com/tutorial/): "First Steps" through "SQL Databases" and "Testing".
- [Python for Everybody](https://www.py4e.com): free course if Python is new to you.

Build:

- [ ] Create a public repo `water-tracker-api` with the endpoints above and at least 5 `pytest` tests.
- [ ] Read every setting (database URL, port) from environment variables, never from code. This is the [Twelve-Factor App](https://12factor.net) rule.
- [ ] Add a tip card to the Flutter Today screen that calls `/v1/tips/today` and hides itself if the API is offline.

### 2.2 Docker (weeks 8 and 9)

Learn: images versus containers, writing a `Dockerfile`, layers and caching, multi-stage builds, running as a non-root user, volumes, container networking, Docker Compose, and pushing images to a registry.

- [Docker "Get started"](https://docs.docker.com/get-started/): the official walkthrough.
- [TechWorld with Nana: Docker tutorial](https://www.youtube.com/@TechWorldwithNana) (YouTube): a full beginner course.

Build:

- [ ] Write a multi-stage `Dockerfile` for the API that runs as a non-root user. Aim for an image under 200 MB.
- [ ] Write `docker-compose.yml` that starts the API and PostgreSQL with a named volume, so data survives restarts.
- [ ] Push the image to GitHub Container Registry (`ghcr.io/<your-user>/water-tracker-api`).

## Stage 3: Automate with CI/CD (weeks 10 and 11)

Continuous integration means every push is tested and built by a robot, not by you. Milestone: a pull request shows green checks, and merging to `main` publishes a new API image and a signed Android build automatically.

Learn: workflows, jobs, steps, triggers (`push`, `pull_request`, tags), runners, caching, artifacts, secrets, matrix builds, and reusable workflows.

- [GitHub Actions docs: Quickstart and "Understanding GitHub Actions"](https://docs.github.com/en/actions).
- [GitHub Skills: "Hello GitHub Actions" and "Test with Actions"](https://skills.github.com).

Build the API pipeline (`water-tracker-api/.github/workflows/ci.yml`):

1. Lint with `ruff` and run `pytest` on every pull request.
2. Build the Docker image and scan it with [Trivy](https://trivy.dev). Fail on critical vulnerabilities.
3. On merge to `main`, push the image to GHCR tagged with the commit SHA (for example `ghcr.io/you/water-tracker-api:3f2a9c1`). Never deploy `latest`.

Build the app pipeline (`water-tracker-app/.github/workflows/android.yml`):

1. Run `flutter analyze` and `flutter test` on every pull request.
2. On a version tag (`v1.0.1`), build a signed `.aab` and `.apk`. Store the keystore as a base64 GitHub secret and decode it inside the job.
3. Attach both files to a GitHub Release. Anyone can install the APK for free from there.
4. Optional, after you pay the Play Console fee: upload the `.aab` to the internal testing track with [Fastlane](https://docs.fastlane.tools) `supply` or a Play upload action.

Checklist:

- [ ] Both repos show a passing status badge in their README.
- [ ] A deliberately broken test blocks the pull request from merging.
- [ ] Pushing tag `v1.0.1` produces a GitHub Release with an APK, with no manual steps.

## Stage 4: Orchestrate with Kubernetes and GitOps (weeks 12 to 18)

This is the core of the CV, so it gets the most time. You run everything on a free local cluster first. Milestone: merging a pull request in your GitOps repo deploys the new API version to Kubernetes with no `kubectl` commands.

### 4.1 Kubernetes (weeks 12 to 15)

Learn, in this order: cluster architecture (control plane, nodes, kubelet), Pods, Deployments and ReplicaSets, Services (ClusterIP, NodePort), Namespaces, ConfigMaps and Secrets, liveness and readiness probes, resource requests and limits, Ingress with ingress-nginx, StatefulSets and PersistentVolumes (for PostgreSQL), rolling updates and rollbacks, and the Horizontal Pod Autoscaler.

- [Kubernetes Basics tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/) and the [Concepts](https://kubernetes.io/docs/concepts/) pages.
- [Killercoda Kubernetes scenarios](https://killercoda.com): free clusters in the browser.
- [TechWorld with Nana: Kubernetes tutorial for beginners](https://www.youtube.com/@TechWorldwithNana) (YouTube).
- Local cluster: [kind](https://kind.sigs.k8s.io) or [k3d](https://k3d.io). Both run Kubernetes inside Docker at no cost.

Build (folder `k8s/` in a new repo `water-tracker-gitops`):

- [ ] Create a kind cluster with one control-plane node and two workers.
- [ ] Write YAML for the API: Deployment (2 replicas, probes on `/health` and `/ready`, CPU and memory limits), Service, ConfigMap and Secret.
- [ ] Run PostgreSQL as a StatefulSet with a PersistentVolumeClaim.
- [ ] Install ingress-nginx and reach the API at `http://api.localtest.me`.
- [ ] Roll out a new image tag, watch `kubectl rollout status`, then `kubectl rollout undo`.
- [ ] Delete a Pod and explain in `LEARNING.md` why it comes back.
- [ ] Add an HPA that scales the API from 2 to 5 replicas, and trigger it with a load test ([k6](https://k6.io) or `hey`).

### 4.2 Helm (week 16)

Helm turns your YAML into a reusable chart with values, so the same chart can deploy to a `dev` and a `prod` environment.

- [Helm docs: Quickstart and "Chart Template Guide"](https://helm.sh/docs/).

Build:

- [ ] Convert `k8s/` into a chart at `charts/water-tracker-api` with `values.yaml`, `values-dev.yaml` and `values-prod.yaml`.
- [ ] Install PostgreSQL from a public chart instead of your own StatefulSet, and compare the two approaches in `LEARNING.md`.

### 4.3 GitOps with Argo CD (weeks 17 and 18)

GitOps means Git is the single source of truth: Argo CD watches your GitOps repo and makes the cluster match it. Nobody runs `kubectl apply` by hand.

Learn: the pull model versus push-based CI deploys, Argo CD Applications, sync policies (auto-sync, self-heal, prune), the app-of-apps pattern, and how CI hands a new image tag to Git.

- [Argo CD "Getting Started"](https://argo-cd.readthedocs.io/en/stable/getting_started/) and its core concepts page.

Build:

- [ ] Install Argo CD in the kind cluster and open its web UI.
- [ ] Create Applications for `dev` and `prod` pointing at your Helm chart with their values files.
- [ ] Extend the API pipeline from Stage 3: after pushing the image, it opens a pull request in `water-tracker-gitops` that updates the image tag. Merging it deploys.
- [ ] Change a replica count by hand with `kubectl`, then watch Argo CD self-heal it back.
- [ ] Record a 2-minute screen video of one full release: code change, CI, tag bump PR, Argo CD sync.

## Stage 5: Cloud and infrastructure as code (weeks 19 to 24)

You now move the same GitOps setup from your laptop to the real cloud, and every cloud resource is created by Terraform code instead of clicking. Milestone: `terraform apply` builds a cluster, Argo CD deploys the API to it, and `terraform destroy` removes everything.

### 5.1 Cloud and AWS fundamentals (weeks 19 to 21)

Learn: regions and availability zones, IAM (users, roles, policies, least privilege), VPC networking (public and private subnets, route tables, internet gateway, NAT gateway, security groups), EC2, S3, load balancers, CloudWatch, and how AWS billing works.

- [AWS Skill Builder](https://skillbuilder.aws): the free "AWS Cloud Practitioner Essentials" course.
- [AWS Free Tier page](https://aws.amazon.com/free/): read the rules before you sign up.

How the AWS free plan works today: a new account gets $100 in credits and can earn up to $100 more, for up to 6 months. The account closes when the 6 months or the credits run out, and you are not charged unless you upgrade to a paid plan. Start your AWS account only when you reach this stage so the 6 months are not wasted.

Build:

- [ ] Create the account, turn on MFA for root, create an admin IAM user for daily work, and set a $1 budget alert.
- [ ] By hand in the console once: launch an EC2 instance, SSH in, run the API container, then delete everything. You will automate this next.

### 5.2 Terraform (weeks 22 to 24)

Learn: providers, resources, variables and outputs, `plan` versus `apply`, state and why it matters, remote state in S3, modules, workspaces or per-environment folders, and `terraform fmt` and `validate`.

- [HashiCorp Terraform tutorials](https://developer.hashicorp.com/terraform/tutorials): "Get Started - Docker" first (no cloud needed), then "Get Started - AWS".

Build a public repo `water-tracker-infra`:

- [ ] Practise locally with the Docker provider: Terraform starts the API and PostgreSQL containers.
- [ ] Create an S3 bucket for remote state, with versioning and encryption on.
- [ ] Set up GitHub Actions OIDC so pipelines get short-lived AWS credentials. No access keys stored anywhere.
- [ ] Add a pipeline: `terraform plan` runs on every pull request and posts the output; `apply` runs only after merge.

Then pick a deployment target. Doing both is best for the CV.

|  | Path A: Oracle Cloud, always on | Path B: AWS EKS, short sessions |
| --- | --- | --- |
| What you build | One Always Free Arm VM running k3s, plus Argo CD | VPC + EKS cluster from the official Terraform modules, plus Argo CD |
| Cost | $0 permanently, inside Always Free limits | Paid from your AWS credits. EKS alone is $0.10 per cluster-hour, plus nodes and NAT |
| How long it runs | Always, so it gives you a live demo URL | A few hours per session, then `terraform destroy` |
| What it proves | Terraform, Linux, k3s, real DNS and TLS with cert-manager | The AWS and EKS skills most job ads ask for |

Path A notes: Oracle's Always Free Arm allowance is currently 2 OCPUs and 12 GB of memory in total, which runs k3s, the API, PostgreSQL and Argo CD. Oracle may reclaim an instance that stays idle for 7 days, and new VMs sometimes fail with "out of host capacity". Retry later or in another availability domain.

Path B notes: write it so that `terraform apply` and `terraform destroy` each take one command. Run it, take screenshots of Argo CD syncing to EKS, then destroy it the same day. If your free-plan account blocks a service you need, Path A covers the same skills.

## Stage 6: Operate, monitor and secure (weeks 25 to 27)

Running software is only half the job: you must know when it breaks and make it hard to attack. Milestone: a Grafana dashboard shows API traffic, an alert fires when the API goes down, and the pipelines block known vulnerabilities and leaked secrets.

### 6.1 Monitoring and logging (weeks 25 and 26)

Learn: the three pillars (metrics, logs, traces), Prometheus and PromQL, Grafana dashboards, alerting rules, the four golden signals (latency, traffic, errors, saturation), and SLOs.

- [Prometheus "Getting started"](https://prometheus.io/docs/prometheus/latest/getting_started/).
- [Grafana documentation](https://grafana.com/docs/grafana/latest/) and [Grafana Loki](https://grafana.com/docs/loki/latest/).

Build (deployed through Argo CD, like everything else):

- [ ] Install the `kube-prometheus-stack` Helm chart: Prometheus, Grafana and Alertmanager.
- [ ] Add a ServiceMonitor for the API's `/metrics` endpoint.
- [ ] Build a dashboard: requests per second, error rate, p95 latency, Pod CPU and memory.
- [ ] Write two alerts: API down for 2 minutes, error rate above 5%. Send them to a free Discord or Telegram webhook.
- [ ] Collect Pod logs with Loki and search them from Grafana.
- [ ] Add Firebase Crashlytics to the Flutter app so you also see mobile crashes (free).
- [ ] Write `docs/SLO.md`: "99% of `/v1/tips/today` requests succeed within 300 ms over 30 days."

### 6.2 DevSecOps (week 27)

Learn: shift-left security, image scanning, dependency updates, secret scanning, Kubernetes Secrets versus encrypted secrets, least privilege, and network policies.

- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/).
- [Kubernetes security concepts](https://kubernetes.io/docs/concepts/security/).

Build:

- [ ] Turn on Dependabot and secret scanning in all four repos.
- [ ] Keep the Trivy step from Stage 3, and add a Trivy scan of your Terraform and Kubernetes files.
- [ ] Replace plain Kubernetes Secrets in Git with [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), so even the encrypted form is safe to commit.
- [ ] Add a NetworkPolicy so only the API can reach PostgreSQL.
- [ ] Run containers as non-root with a read-only root filesystem, and apply the "restricted" Pod Security Standard to the app namespace.

## Stage 7: Show it on your CV (week 28 onward)

Recruiters spend under a minute on a project, so make the result easy to see and easy to verify. Milestone: one link on your CV leads to a README that explains the whole system in 2 minutes.

### 7.1 Portfolio polish

- [ ] Pin the four repos on your GitHub profile: `water-tracker-app`, `water-tracker-api`, `water-tracker-gitops`, `water-tracker-infra`.
- [ ] Write a main README with the architecture diagram, the tech stack, a "how a release works" section, screenshots of Grafana and Argo CD, and the demo video.
- [ ] Add `docs/decisions/` with short notes on why you chose each tool (for example "Why Argo CD instead of pushing from CI").
- [ ] Turn your `LEARNING.md` into 3 or 4 blog posts on a free platform such as Hashnode, dev.to or Medium, and share each on LinkedIn.
- [ ] Keep the Oracle demo running, or show the EKS session recording if you only did Path B.

### 7.2 CV bullets

Write them only for what you actually built, and keep the numbers real. Example project entry:

**Water Tracker: cloud-native platform for a Flutter mobile app** (GitHub link)

- Built a FastAPI backend for a Flutter and Firebase hydration app, containerized with Docker and deployed to Kubernetes with Helm.
- Implemented GitOps with Argo CD: merged pull requests deploy automatically to dev and prod, with self-healing and one-click rollback.
- Created GitHub Actions pipelines for testing, Trivy image scanning, publishing to GHCR and signed Android release builds.
- Provisioned AWS (VPC, EKS) and Oracle Cloud (k3s) infrastructure with Terraform, using S3 remote state and OIDC credentials instead of stored keys.
- Added monitoring with Prometheus, Grafana, Loki and Alertmanager, including a 99% availability SLO and alerting.

Skills line: Linux, Bash, Git, Python, Docker, Kubernetes, Helm, Argo CD, GitHub Actions, Terraform, AWS, Prometheus, Grafana.

### 7.3 Interview preparation

Be ready to explain, without notes:

1. What happens, step by step, from `git push` to the new Pod serving traffic.
2. Why a Pod can be stuck in `CrashLoopBackOff` or `Pending`, and how you debug it.
3. The difference between liveness and readiness probes, and what breaks if you mix them up.
4. What Terraform state is, why it lives in S3, and what happens if two people apply at once.
5. How you keep secrets out of Git, and why OIDC beats access keys.
6. One real problem you hit in this project and how you solved it. Your `LEARNING.md` is the source.

Practise with [DevOps Exercises](https://github.com/bregman-arie/devops-exercises), a free question bank.

### 7.4 Certifications (optional, later)

The learning material is free, but the exams cost money, so take them once you have a job lead or a discount voucher. Most useful for a junior role: AWS Certified Cloud Practitioner, then Certified Kubernetes Administrator (CKA) or HashiCorp Terraform Associate. A finished project like this often impresses more than a certificate alone.

## What it costs

The whole path costs $0. The Play Store fee is optional, and AWS and Oracle need a card only to verify your identity.

| Tool or service | Used for | Free option | Watch out for |
| --- | --- | --- | --- |
| GitHub repos, Actions, GHCR | Code, CI/CD, container images | Free for public repos and public images | Keep repos public; private repos have monthly limits |
| Docker, kind or k3d, Helm, Argo CD, Terraform, Prometheus, Grafana, Loki | Everything you run | Open source, free | Needs RAM: 8 GB minimum, 16 GB comfortable |
| Killercoda, Play with Docker | Browser labs if your laptop is weak | Free | Sessions are time-limited |
| Firebase (Spark plan) | App data, Crashlytics | Free within daily quotas | Do not upgrade to the Blaze plan |
| Oracle Cloud Always Free | Always-on k3s demo (Path A) | Free permanently within limits | Card check at signup; idle VMs can be reclaimed |
| AWS free plan | AWS and EKS (Path B) | Up to $200 credits for up to 6 months | EKS, NAT gateways and load balancers burn credits by the hour; always destroy |
| AWS Skill Builder, HashiCorp tutorials, official docs | Theory | Free | Exams are paid |
| Google Play Console | Publishing the app | None: one-time $25 fee | Optional: GitHub Releases can host the APK for free |

## Sources

Free-tier and pricing facts checked on 11 October 2026. Re-check them before you sign up, because providers change them often.

- [AWS Free Tier](https://aws.amazon.com/free/): credits, 6-month free plan, account closure rules.
- [Amazon EKS pricing](https://aws.amazon.com/eks/pricing/): $0.10 per cluster per hour (standard support).
- [Oracle Cloud Always Free resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/resourceref.htm): Arm A1 allowance, idle reclamation, capacity errors.
- [roadmap.sh DevOps roadmap](https://roadmap.sh/devops): a wider map of the field if you want to go further after this path.
