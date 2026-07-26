# Agent dev guide — hadron-ios

This is the native iOS application for the Hadron platform (SwiftUI, iOS 17+).

## Use of Hadron

Hadron is this project's institutional memory — assume it covers things that aren't
obvious from code alone (past incidents, decisions whose rationale isn't in the code,
conventions baked into several places). Relevant memories:

- `hrn:mem:hadronmemory.com:hadron-ios` — memory for the Hadron iOS app
- `hrn:mem:hadronmemory.com:hadron-macapp` — the macOS app (shares HadronKit)
- `hrn:mem:hadronmemory.com:dev` — findings, conventions, ops, tasks (the routing index)
- `hrn:mem:hadronmemory.com:specs` — product specs (loc-as-citation; `hadron spec …`)
- `hrn:mem:hadronmemory.com:hadron-server` — Hadron's server/backend

(1) **Query Hadron before reading project code.** For the topics, entities, and decision
areas in a request, run `hadron_find_nodes` first, then `hadron_get_node` on promising hits.
Cite node `loc` values when you reference what you found.

(2) Call `hadron_get_node` with `urn: "hrn:node:hadronmemory.com:dev:instructions"` to load
the project introduction (what Hadron is, URN grammar, the platform-specs corpus, core
architecture). Read it once per session.

(3) At the start of **every change** — before drafting a plan — call `hadron_get_node` with
`urn: "hrn:node:hadronmemory.com:dev:preflight"`. It's a symptom-to-pattern routing
index into the findings, conventions, and ops branches.

(4) When a non-obvious finding emerges — a convention you discovered, a gotcha you hit, a
node that turned out to be wrong — capture, fix, or delete it immediately via
`hadron_create_node` / `hadron_update_node` (don't batch to end-of-session; context decays).

## Build & run

```bash
xcodegen generate      # project.yml → HadronIOS.xcodeproj (gitignored)
xcodebuild -project HadronIOS.xcodeproj -scheme Hadron \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Things to know

- **HadronKit** (`HadronKit/`) holds the shared client stack (OAuth, Keychain,
  GraphQL). hadron-macapp consumes it via a `../hadron-ios/HadronKit` path
  dependency — a change here must keep the macapp building
  (`cd ../hadron-macapp && swift build`).
- **Swift 5 language mode** on purpose (matches hadron-macapp): UI-driven,
  single-actor design; migrate both apps + kit to Swift 6 mode together.
- **OAuth contract** (spec `cor:aut:030:01`): `resource=<base>/mcp` is REQUIRED
  on both `/oauth/authorize` and `/oauth/token`; the DCR client id is cached in
  the Keychain and must survive sign-out (10/min rate limit); the issued
  `hdr_user_*` key never expires — a GraphQL 401 means revoked → sign out.
- **findNodes keyword mode parses a boolean grammar** — free-form input goes
  through `HadronClient.literalSafeQuery` (quoted-phrase fallback), never raw.
- **Optional GraphQL variables must be OMITTED, not null** — `HadronClient.run`
  strips nil/NSNull variables; don't bypass it.
