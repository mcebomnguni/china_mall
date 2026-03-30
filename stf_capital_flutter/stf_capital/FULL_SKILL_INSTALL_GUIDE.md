# FULL SKILL INSTALLATION GUIDE — New Device Setup
# Source: https://skills.sh (The Agent Skills Directory)
# Install method: npx skills add <repo> --skill <name>
# Compatible with: Claude Code, Cursor, Windsurf, Cline, Copilot, and more

---

## STEP 1: INSTALL THE META-SKILL FIRST (lets Claude Code find & install skills itself)

```bash
npx skills add https://github.com/vercel-labs/skills --skill find-skills
```
> **find-skills** (753K installs) — If Claude Code hits a problem and needs a skill it doesn't have, it can search the registry and install what it needs from inside the terminal.

---

## STEP 2: ANTHROPIC OFFICIAL SKILLS (all 17 from github.com/anthropics/skills)

### Design & Creative Skills

```bash
npx skills add https://github.com/anthropics/skills --skill frontend-design
```
> **frontend-design** (211K installs) — Bold aesthetic direction, intentional typography, meaningful motion, spatial composition. Never produces generic AI-aesthetic UI. The primary design intelligence skill.

```bash
npx skills add https://github.com/anthropics/skills --skill canvas-design
```
> **canvas-design** (27K installs) — Design skill for creating visual compositions, layouts, and graphic design outputs.

```bash
npx skills add https://github.com/anthropics/skills --skill algorithmic-art
```
> **algorithmic-art** (21K installs) — Generative art creation through algorithmic philosophies. Creates p5.js sketches with emergent behavior, noise fields, particle systems, and computational beauty.

```bash
npx skills add https://github.com/anthropics/skills --skill theme-factory
```
> **theme-factory** (20K installs) — Generates cohesive design themes, color systems, and visual identity packages.

```bash
npx skills add https://github.com/anthropics/skills --skill brand-guidelines
```
> **brand-guidelines** (19K installs) — Access to brand identity and style resources. Covers branding, corporate identity, visual formatting, brand colors, typography.

### Document Skills

```bash
npx skills add https://github.com/anthropics/skills --skill pdf
```
> **pdf** (53K installs) — Comprehensive PDF toolkit: extract text/tables, create new PDFs, merge/split, handle forms, watermarks, encryption/decryption, OCR on scanned docs.

```bash
npx skills add https://github.com/anthropics/skills --skill pptx
```
> **pptx** (49K installs) — Create, edit, and analyze PowerPoint presentations with layouts, templates, charts, speaker notes, and automated slide generation.

```bash
npx skills add https://github.com/anthropics/skills --skill docx
```
> **docx** (42K installs) — Create, edit, and analyze Word documents with tracked changes, comments, formatting preservation, tables of contents, and text extraction.

```bash
npx skills add https://github.com/anthropics/skills --skill xlsx
```
> **xlsx** (38K installs) — Create, edit, and analyze Excel spreadsheets with formulas, formatting, data analysis, charts, and visualization.

```bash
npx skills add https://github.com/anthropics/skills --skill doc-coauthoring
```
> **doc-coauthoring** (20K installs) — Structured collaborative document creation workflow. Three stages: Context Gathering, Refinement & Structure, and Reader Testing with a fresh Claude instance to catch blind spots.

### Communication & Enterprise Skills

```bash
npx skills add https://github.com/anthropics/skills --skill internal-comms
```
> **internal-comms** (17K installs) — Enterprise internal communications skill for company announcements, memos, and organizational messaging.

```bash
npx skills add https://github.com/anthropics/skills --skill slack-gif-creator
```
> **slack-gif-creator** (16K installs) — Creates GIF animations optimized for Slack and team communications.

### Developer & Builder Skills

```bash
npx skills add https://github.com/anthropics/skills --skill skill-creator
```
> **skill-creator** (112K installs) — Meta-skill for creating new custom skills as markdown files in .claude/skills/. Essential for building your own Flutter-specific skills.

```bash
npx skills add https://github.com/anthropics/skills --skill web-artifacts-builder
```
> **web-artifacts-builder** (20K installs) — Self-healing patterns for API routes, retry logic, standardized error responses, graceful failure handling.

```bash
npx skills add https://github.com/anthropics/skills --skill mcp-builder
```
> **mcp-builder** (28K installs) — For building and integrating MCP (Model Context Protocol) servers and tools.

```bash
npx skills add https://github.com/anthropics/skills --skill webapp-testing
```
> **webapp-testing** (34K installs) — Testing skill for web applications. Covers test strategies, browser testing, integration tests, and quality assurance workflows.

```bash
npx skills add https://github.com/anthropics/skills --skill template-skill
```
> **template-skill** (16K installs) — Starting point template for creating your own custom skills. Includes the proper SKILL.md structure with YAML frontmatter.

```bash
npx skills add https://github.com/anthropics/skills --skill claude-api
```
> **claude-api** — Patterns and best practices for working with the Anthropic/Claude API programmatically.

---

## STEP 3: VERCEL LABS SKILLS (UI Quality & Architecture)

```bash
npx skills add https://github.com/vercel-labs/agent-skills --skill web-design-guidelines
```
> **web-design-guidelines** (206K installs) — Vercel's 100+ UI quality rules. Audits for accessibility, touch targets, focus states, heading hierarchy, reduced-motion support, semantic structure. The quality gate.

```bash
npx skills add https://github.com/vercel-labs/agent-skills --skill vercel-composition-patterns
```
> **vercel-composition-patterns** (104K installs) — Clean component architecture. Compound components, context providers, explicit variants. Prevents boolean prop mess that makes components unmaintainable.

```bash
npx skills add https://github.com/vercel-labs/agent-skills --skill vercel-react-best-practices
```
> **vercel-react-best-practices** (256K installs) — React patterns and best practices from Vercel. Useful for web-based projects alongside Flutter builds.

---

## STEP 4: UI-UX PRO MAX (The Big One for Design Intelligence)

```bash
npx skills add https://github.com/nextlevelbuilder/ui-ux-pro-max-skill --skill ui-ux-pro-max
```
> **ui-ux-pro-max** (86K installs) — 50+ styles, 161 color palettes, 57 font pairings, 99 UX guidelines with explicit Flutter/Dart support. Primary UI intelligence for all screen design decisions.

---

## STEP 5: OBRA SUPERPOWERS (Workflow & Process Skills)

These are the structured workflow skills that make Claude Code operate like a disciplined engineering team.

```bash
npx skills add https://github.com/obra/superpowers --skill brainstorming
```
> **brainstorming** (77K installs) — Structured design dialogue. Explores requirements, proposes 2-3 approaches, validates ideas before any code is written.

```bash
npx skills add https://github.com/obra/superpowers --skill writing-plans
```
> **writing-plans** (41K installs) — Creates structured implementation plans before writing code.

```bash
npx skills add https://github.com/obra/superpowers --skill executing-plans
```
> **executing-plans** (34K installs) — Executes the plan with review checkpoints. Doesn't skip steps.

```bash
npx skills add https://github.com/obra/superpowers --skill dispatching-parallel-agents
```
> **dispatching-parallel-agents** (25K installs) — Runs independent screens or components simultaneously via sub-agents. Build Home Dashboard and Services page in parallel.

```bash
npx skills add https://github.com/obra/superpowers --skill subagent-driven-development
```
> **subagent-driven-development** (29K installs) — Delegates independent sub-tasks to sub-agents within the session.

```bash
npx skills add https://github.com/obra/superpowers --skill test-driven-development
```
> **test-driven-development** (35K installs) — Write failing tests first, then implement to make them pass.

```bash
npx skills add https://github.com/obra/superpowers --skill verification-before-completion
```
> **verification-before-completion** (27K installs) — Run verification commands and confirm output BEFORE claiming anything works. Evidence before assertions.

```bash
npx skills add https://github.com/obra/superpowers --skill systematic-debugging
```
> **systematic-debugging** (42K installs) — Diagnose before fixing. No guessing. Structured debugging methodology.

```bash
npx skills add https://github.com/obra/superpowers --skill requesting-code-review
```
> **requesting-code-review** (34K installs) — Invoke code review before merging or completing.

```bash
npx skills add https://github.com/obra/superpowers --skill receiving-code-review
```
> **receiving-code-review** (27K installs) — How to properly process and act on code review feedback.

```bash
npx skills add https://github.com/obra/superpowers --skill writing-skills
```
> **writing-skills** (26K installs) — Meta-skill for writing new skill definitions.

```bash
npx skills add https://github.com/obra/superpowers --skill using-superpowers
```
> **using-superpowers** (39K installs) — The orchestrator that teaches Claude Code how to use all the Superpowers skills together.

```bash
npx skills add https://github.com/obra/superpowers --skill using-git-worktrees
```
> **using-git-worktrees** (25K installs) — Git worktree management for parallel development branches.

```bash
npx skills add https://github.com/obra/superpowers --skill finishing-a-development-branch
```
> **finishing-a-development-branch** (23K installs) — Structured process for completing and merging dev branches.

---

## STEP 6: SUPABASE SKILL (Database Best Practices)

```bash
npx skills add https://github.com/supabase/agent-skills --skill supabase-postgres-best-practices
```
> **supabase-postgres-best-practices** (54K installs) — Supabase/Postgres patterns, RLS policies, migrations, and database best practices. Directly relevant to STF Capital, Shape Health, and DriveInn backends.

---

## STEP 7: EXPO SKILLS (For React Native / DriveInn projects)

```bash
npx skills add https://github.com/expo/skills --skill building-native-ui
```
> **building-native-ui** (22K installs) — Native UI patterns for Expo/React Native apps.

```bash
npx skills add https://github.com/expo/skills --skill native-data-fetching
```
> **native-data-fetching** (16K installs) — Data fetching patterns for Expo apps.

```bash
npx skills add https://github.com/expo/skills --skill expo-deployment
```
> **expo-deployment** (13K installs) — Deployment workflows for Expo apps.

---

## STEP 8: CUSTOM SKILLS (Create manually in .claude/skills/)

After running all the above installs, paste this into Claude Code to create the Flutter-specific custom skills that don't exist on skills.sh:

```
Use the skill-creator skill to create 4 custom skills in .claude/skills/.
Each must follow SKILL.md format with YAML frontmatter (name, description)
followed by markdown instructions.

SKILL 1: flutter-animation-premium
Description: Premium Flutter animation patterns for fintech/neobank apps.
Invoke before building any screen that needs motion.
Instructions:
- Splash/loading: AnimationController with Curves.elasticOut, RadialGradient
  glow with animated opacity, staggered text fade-in using SlideTransition
  with 200ms delays
- Page transitions: PageRouteBuilder with combined SlideTransition +
  FadeTransition, never default MaterialPageRoute
- Spring physics: SpringDescription(mass: 1, stiffness: 200, damping: 15)
  for bottom sheets and draggable elements
- Number count-up: TweenAnimationBuilder<double> from 0 to target with
  800ms duration for KPI dashboard cards
- List animations: AnimatedList with SlideTransition + FadeTransition,
  50-100ms stagger interval per item
- Micro-interactions: 0.98 scale on press (100ms, Curves.easeInOut),
  snap back on release
- Checkmark/success: ScaleTransition with Curves.elasticOut
- Loading states: shimmer package with gold gradient on dark surface,
  never plain CircularProgressIndicator
- Bottom sheet wizard: DraggableScrollableSheet with snap: true,
  AnimatedSwitcher for step transitions with horizontal slide
- Hero transitions: Wrap shared elements in Hero widget for seamless
  screen-to-screen animation
- Tab bar: AnimatedContainer for active indicator slide

SKILL 2: flutter-ui-audit
Description: Audits Flutter widget trees for UI quality, accessibility,
and premium design compliance. Invoke after building any screen.
Instructions:
- Touch targets minimum 48x48dp
- Color contrast 4.5:1 minimum
- Semantic widget hierarchy
- Proper focus states
- Reduced-motion support
- Labeled inputs
- Keyboard navigation support
- Proper heading hierarchy
- When invoked, check current screen's widget tree against all rules
  and report violations

SKILL 3: flutter-composition
Description: Enforces clean Flutter widget architecture. Invoke when
building reusable widgets.
Instructions:
- Use compound widgets with shared InheritedWidget/Provider context
  instead of boolean props
- Use explicit variant widgets instead of mode flags
- Decouple state interfaces
- Use composition over inheritance
- When invoked, review current widget for anti-patterns and refactor

SKILL 4: animation-patterns
Description: Reusable premium Flutter animation reference. Invoke on
any screen for physics-based motion.
Instructions:
- Spring physics: SpringSimulation with damping 0.7, stiffness 200
- Staggered reveals: 50-100ms interval per item
- Custom page transitions: SlideTransition + FadeTransition combined
- Micro-interactions: 0.98 scale on press with 100ms duration
- Shimmer loading: gold gradient on dark surface
- Elastic curves: Curves.elasticOut for checkmarks and success states
- When invoked, apply these patterns to the current screen

After creating these, list all files in .claude/skills/ to confirm.
```

---

## VERIFICATION

After all installs, run this in your terminal to confirm everything landed:

```bash
ls -la .claude/skills/
```

You should see all the installed skills plus the 4 custom ones.

---

## QUICK REFERENCE — FULL SKILL STACK (39 total)

| # | Skill | Source Repo | Type |
|---|-------|-------------|------|
| 1 | find-skills | vercel-labs/skills | Meta |
| **ANTHROPIC OFFICIAL (17)** | | | |
| 2 | frontend-design | anthropics/skills | UI/Design |
| 3 | canvas-design | anthropics/skills | UI/Design |
| 4 | algorithmic-art | anthropics/skills | Creative |
| 5 | theme-factory | anthropics/skills | UI/Design |
| 6 | brand-guidelines | anthropics/skills | Branding |
| 7 | pdf | anthropics/skills | Documents |
| 8 | pptx | anthropics/skills | Documents |
| 9 | docx | anthropics/skills | Documents |
| 10 | xlsx | anthropics/skills | Documents |
| 11 | doc-coauthoring | anthropics/skills | Documents |
| 12 | internal-comms | anthropics/skills | Enterprise |
| 13 | slack-gif-creator | anthropics/skills | Creative |
| 14 | skill-creator | anthropics/skills | Meta |
| 15 | web-artifacts-builder | anthropics/skills | Architecture |
| 16 | mcp-builder | anthropics/skills | Integration |
| 17 | webapp-testing | anthropics/skills | Testing |
| 18 | template-skill | anthropics/skills | Meta |
| 19 | claude-api | anthropics/skills | Developer |
| **VERCEL LABS (3)** | | | |
| 20 | web-design-guidelines | vercel-labs/agent-skills | UI/Audit |
| 21 | vercel-composition-patterns | vercel-labs/agent-skills | Architecture |
| 22 | vercel-react-best-practices | vercel-labs/agent-skills | Architecture |
| **UI-UX PRO MAX (1)** | | | |
| 23 | ui-ux-pro-max | nextlevelbuilder/ui-ux-pro-max-skill | UI/Design |
| **OBRA SUPERPOWERS (14)** | | | |
| 24 | brainstorming | obra/superpowers | Workflow |
| 25 | writing-plans | obra/superpowers | Workflow |
| 26 | executing-plans | obra/superpowers | Workflow |
| 27 | dispatching-parallel-agents | obra/superpowers | Workflow |
| 28 | subagent-driven-development | obra/superpowers | Workflow |
| 29 | test-driven-development | obra/superpowers | Testing |
| 30 | verification-before-completion | obra/superpowers | Testing |
| 31 | systematic-debugging | obra/superpowers | Debugging |
| 32 | requesting-code-review | obra/superpowers | Quality |
| 33 | receiving-code-review | obra/superpowers | Quality |
| 34 | writing-skills | obra/superpowers | Meta |
| 35 | using-superpowers | obra/superpowers | Orchestrator |
| 36 | using-git-worktrees | obra/superpowers | Git |
| 37 | finishing-a-development-branch | obra/superpowers | Git |
| **SUPABASE (1)** | | | |
| 38 | supabase-postgres-best-practices | supabase/agent-skills | Database |
| **EXPO (3)** | | | |
| 39 | building-native-ui | expo/skills | Mobile |
| 40 | native-data-fetching | expo/skills | Mobile |
| 41 | expo-deployment | expo/skills | Mobile |
| **CUSTOM FLUTTER SKILLS (4)** | | | |
| +1 | flutter-animation-premium | Custom (.claude/skills/) | Flutter |
| +2 | flutter-ui-audit | Custom (.claude/skills/) | Flutter |
| +3 | flutter-composition | Custom (.claude/skills/) | Flutter |
| +4 | animation-patterns | Custom (.claude/skills/) | Flutter |

**Total: 41 from skills.sh + 4 custom = 45 skills**
