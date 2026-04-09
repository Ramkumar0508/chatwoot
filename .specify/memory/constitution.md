<!--
Sync Impact Report
==================
Version change: N/A → 1.0.0 (Initial ratification)

Added sections:
- Principle I: Code Quality & Consistency
- Principle II: Testing Standards
- Principle III: User Experience Consistency
- Principle IV: Performance Requirements
- Development Workflow section
- Quality Gates section
- Governance rules

Templates requiring updates:
✅ plan-template.md - Compatible (Constitution Check section exists)
✅ spec-template.md - Compatible (Success Criteria aligns with principles)
✅ tasks-template.md - Compatible (Phase structure supports quality gates)

Follow-up TODOs: None
-->

# Chatwoot Constitution

## Core Principles

### I. Code Quality & Consistency

All code contributions MUST adhere to established style guides and patterns:

- **Ruby**: Follow RuboCop rules with 150 character maximum line length; use compact `module/class` definitions
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended); components use PascalCase, events use camelCase
- **Vue Components**: MUST use Composition API with `<script setup>` at the top
- **Styling**: Use Tailwind utility classes exclusively—no custom CSS, scoped CSS, or inline styles
- **I18n**: No bare strings in templates; backend uses `en.yml`, frontend uses `en.json`
- **Simplicity**: Prefer minimal, readable code over elaborate abstractions; clarity beats cleverness
- **Dead Code**: Remove unused/unreachable code; do not maintain multiple versions of the same logic

**Rationale**: Consistent code reduces cognitive load during reviews, enables faster onboarding, and minimizes integration conflicts across the OSS and Enterprise codebases.

### II. Testing Standards

Testing MUST validate functionality without over-engineering:

- **Ruby Tests**: Use RSpec (`bundle exec rspec spec/path/to/file_spec.rb`)
- **JS/Vue Tests**: Use pnpm (`pnpm test` or `pnpm test:watch`)
- **Spec Isolation**: Tests MUST be independently runnable; use `with_modified_env` over stubbing `ENV` directly
- **Error Assertions**: In parallel/reloading environments, compare `error.class.name` over constant class equality
- **Happy Path First**: Ship the happy path; add guards/fallbacks only when production has proven them necessary
- **Test Writing**: Avoid writing specs unless explicitly requested; focus on actionable, production-necessary coverage

**Rationale**: Tests exist to catch regressions and validate contracts, not to achieve arbitrary coverage metrics. Pragmatic testing accelerates delivery while maintaining confidence.

### III. User Experience Consistency

User-facing changes MUST maintain coherent experience across the product:

- **Component Library**: Use `components-next/` for message bubbles and new UI elements (legacy components are being deprecated)
- **Design System**: Reference `tailwind.config.js` for color definitions; maintain visual consistency
- **Branding**: Apply `replaceInstallationName` from `shared/composables/useBranding` for strings that should adapt to branded/self-hosted installs
- **Translations**: Only update `en.yml` (backend) and `en.json` (frontend); other languages are community-maintained
- **Error Handling**: Use custom exceptions from `lib/custom_exceptions/`; provide clear, actionable error messages
- **Accessibility**: New UI components MUST be keyboard-navigable and screen-reader compatible

**Rationale**: Chatwoot serves diverse deployment scenarios from SaaS to self-hosted. Consistent UX and proper white-labeling support create a professional experience across all contexts.

### IV. Performance Requirements

Features MUST meet performance expectations before merge:

- **Database**: Add proper indexes for new queries; validate query performance with `EXPLAIN ANALYZE`
- **N+1 Prevention**: Use eager loading (`includes`, `preload`) for association access in collections
- **API Response**: Endpoints MUST respond within acceptable latency bounds under normal load
- **Frontend**: Avoid unnecessary re-renders; use computed properties and memoization appropriately
- **Background Jobs**: Long-running operations MUST be delegated to background workers (Sidekiq)
- **Resource Limits**: Memory-intensive operations MUST include safeguards against unbounded growth

**Rationale**: Chatwoot handles real-time communication at scale. Performance regressions directly impact user experience and operational costs.

## Development Workflow

Development follows an MVP-focused, iterative approach:

- **Minimal Changes**: Implement the least code change that satisfies requirements
- **Iterative Delivery**: Break complex tasks into small, testable units; commit after each logical group
- **Enterprise Compatibility**: Check `enterprise/` for corresponding files when modifying core functionality
- **Extension Points**: For Enterprise-only behavior, use `prepend_mod_with`/`include_mod_with` instead of editing OSS files
- **Feature Flags**: Avoid hardcoding instance- or plan-specific behavior in OSS; use configuration or feature flags
- **Commit Messages**: Use Conventional Commits format (`type(scope): subject`)—do not reference AI tools

## Quality Gates

All changes MUST pass these gates before merge:

| Gate | Validation | Tool |
|------|------------|------|
| Ruby Lint | No RuboCop violations | `bundle exec rubocop -a` |
| JS/Vue Lint | No ESLint violations | `pnpm eslint` / `pnpm eslint:fix` |
| Ruby Tests | All specs pass | `bundle exec rspec` |
| JS Tests | All tests pass | `pnpm test` |
| I18n Check | No bare strings in templates | Manual review |
| Enterprise Compat | No breaks to `enterprise/` overlay | Search both trees before editing |

## Governance

This constitution supersedes ad-hoc practices and establishes binding standards for all contributions:

- **Compliance**: All PRs and reviews MUST verify adherence to these principles
- **Amendments**: Changes to this constitution require documentation of rationale, impact assessment, and version increment
- **Version Semantics**:
  - MAJOR: Principle removal or backward-incompatible redefinition
  - MINOR: New principle added or materially expanded guidance
  - PATCH: Clarifications, wording fixes, non-semantic refinements
- **Runtime Guidance**: Use `CLAUDE.md`/`AGENTS.md` for development workflow details; this constitution establishes principles

**Version**: 1.0.0 | **Ratified**: 2026-03-14 | **Last Amended**: 2026-03-14
