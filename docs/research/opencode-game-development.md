# AI game development with OpenCode

Research date: 2026-10-16. Recommendation based on public Summer source and static inspection of Potion Shop; no engine session or gameplay was tested.

## Recommendation

Use OpenCode as the development orchestrator, backed by a real engine and an automated playtest interface. Start with the existing Summer runtime for Potion Shop. Keep our design memory, agent instructions, scenarios, and evidence in the repository so the workflow can later move to stock Godot.

For a new project whose requirement is independence from Summer, use stock Godot with a small editor/runtime testing bridge. Do not build a new renderer, physics engine, or a large multi-agent platform first.

The central product is a closed loop:

**Brief → acceptance criteria → edit → compile → launch → input → observe state and pixels → repair → evidence.**

Agents provide reasoning and coordination. Engine tooling provides the ability to act and observe. Both are necessary.

## What Summer actually provides

Inspected public repository: `SummerEngine/summer`, commit `9fca4b88e1af9a5f4f232a8636190dc3a8eb36d4`; package version in that checkout: `4.3.0`.

| Layer | Findings | OpenCode equivalent |
| --- | --- | --- |
| Agent guidance | Searchable skills, templates, references, project memory | Project instructions, lazy-loaded skills, commands |
| Engine tools | Scene inspection/mutation, script diagnostics, editor scripts, snapshots | Reuse Summer MCP initially; Godot bridge for independence |
| Runtime feedback | Launch, debugger reads, input, frame-stamped state and image probes, replay | Tool-driven QA with retained evidence |
| Asset pipeline | Hosted image, 3D, animation, audio and video operations | Optional provider adapters plus import validation |
| Publishing/services | Exports, store, analytics, matchmaking, hosting | Separate engine/platform integrations |

The public agent integration is MIT-licensed; the editor/runtime is described as closed-source. Hosted services are separate. Copying or adapting public integration code requires preserving applicable license/attribution notices. This investigation does not establish the private implementation of Summer's built-in AI or parity with its whole product.

### Source-level observations

- `src/core/ops/engine.ts` defines a practical engine operation catalog, including scene edits, compilation diagnostics, guarded file writes, and batch scripting.
- `src/core/api-client.ts` sends authenticated requests to a loopback engine API, binds calls to engine/project identity, and handles queued operations. MCP is an adapter over engine capabilities, not the engine itself.
- `src/core/capabilities/agent-playbook.ts` describes the verification ladder and real failure cases: stale editor state, scene changes not persisted, unsupported operations, and captures requiring a desktop bridge.
- `library/skills/agent-playtesting/SKILL.md` describes before/after probes containing state and pixels from the same frame, scripted input, frame stepping, and replay. Tool success alone is explicitly insufficient evidence of correct gameplay.
- `RunVerification` is a fallback probe interface described in the source: disposable game instance, GDScript probe, structured results, and rendered frames. Its engine-side implementation is not in this public integration repository.
- The library is indexed from resource descriptions. Search and load relevant guidance instead of inserting every skill into every prompt.

These are documented/source-visible capabilities, not locally verified capabilities of Potion Shop's installed engine.

## Potion Shop implications

The README says “Starting fresh,” but current source contains substantial gameplay and networking. Treat the code as the actual starting point.

- `project.godot` declares Summer `0.7.2` and feature string `4.7`; these are project metadata, not proof of the installed executable version.
- `client/main.gd` initializes Summer, joins its queue, sends commands, and renders replicated shop state.
- `authority/main.gd` owns shop actions, player seats, movement acceptance, command receipts, and state publication.
- `network/game.gd` contains recipes, station geometry, timing rules, and constructors for Summer networking nodes.
- `summer.build.json` requests hosted execution, iOS/macOS targets, and a two-player queue. This is configuration intent, not evidence that exports or hosting work.

Stock Godot cannot simply replace the executable: `SummerNetworkSpawner`, `SummerNetworkWorld`, `SummerResult`, `Summer.initialize`, and related resources need replacement or adaptation.

The project also uses `Time.get_ticks_msec()`. A seeded RNG and fixed frame rate alone will not make its shop timers or network behavior deterministic. Controlled-clock rule tests and tolerance-based integration tests are appropriate.

## Recommended OpenCode organization

Start with one primary implementer and an independent QA subagent. Add specialist work only when tasks warrant it.

| Role | Responsibility | Work boundary |
| --- | --- | --- |
| `game-director` (primary) | Clarify intent, choose a small playable increment, implement/integrate, track evidence | Owns integration and shared contracts |
| `game-qa` (subagent) | Exercise acceptance scenarios, inspect images/logs/state, return reproducible failures | Does not fix the feature it is judging |
| `game-art` (optional) | Maintain visual direction, prepare/import assets, inspect composition | Assigned asset and presentation paths |
| `game-systems` (optional) | Focused gameplay/network subsystem work | Assigned files/worktree and explicit interface contract |

Avoid permanently running a separate agent for every discipline. Fresh-context agents need a concise brief: goal, relevant files, interface constraints, acceptance criteria, runtime target, and expected evidence.

Parallelize independent asset work or isolated code modules. Serialize changes to a shared scene or live editor. A Git worktree isolates files, but does not automatically isolate an editor, runtime instance, network port, or match session.

Suggested repository layout (proposed, not installed):

```text
AGENTS.md                         # architecture, workflow, explicit delegation policy
.opencode/agents/                 # director, QA, optional specialists
.opencode/skills/                 # game iteration, scene editing, testing, art import
.opencode/commands/               # /game-feature, /game-playtest, /game-review
docs/game/brief.md                # intended experience and scope
docs/game/art-direction.md        # palette, scale, silhouettes, animation rules
docs/game/architecture.md         # authority, client, shared boundaries
docs/game/status.md               # implemented vs verified vs next
tests/scenarios/                  # reusable behavior scenarios
artifacts/playtests/<run-id>/     # results, logs, screenshots, replay
```

Keep large generated artifacts out of normal source history; retain compact result summaries with artifact references. Use one canonical design brief rather than competing OpenCode and Summer memory documents.

OpenCode V2 natively supports project Markdown agents, skills, and commands. No custom OpenCode plugin is needed for the first version. A dedicated GUI or automated session scheduler can come later if ordinary commands become limiting.

## Engine integration

### Immediate path: OpenCode + Summer tools

1. Inspect installed CLI/engine versions and discover actual capabilities.
2. Pin a tested Summer CLI version and explicitly bind the project.
3. Add the local MCP server using OpenCode V2's `mcp.servers` configuration, or use the same operations through the CLI.
4. Load a small relevant skill set: scene editing, GDScript, playtesting, debugging, and this project's networking conventions.
5. Prove that compilation, input, runtime state, screenshots, and two-client testing work before expanding the workflow.

Summer's `.opencode/INSTALL.md` currently shows older syntax (`plugin`, `skills.paths`, and server names directly beneath `mcp`). Use official V2 docs rather than copying those examples. The reviewed package version is not proof of compatibility with the installed editor.

Use engine tools for live scene changes and reload-aware script edits. Use normal repository tools for documentation, search, and version control. Avoid simultaneous disk and live-editor writes to the same scene.

### Independent path: OpenCode + stock Godot

Build or adopt a narrow Godot adapter with these capabilities, checking each against the chosen engine version:

- Project identity, version, and capability discovery.
- Compile/import diagnostics and runtime log capture.
- Scene/resource inspection and persisted scene edits.
- Start/stop named game instances with isolated output directories.
- Inject normal player input and observe runtime state.
- Capture rendered frames, ideally synchronized with state reads.
- Execute repeatable scenarios and return structured results.

Prefer existing Godot CLI facilities and small scripts where sufficient; add an editor plugin/debug-only runtime component where live control is necessary. A headless parse check is not a rendered visual test. Visual scenarios need a working rendering environment.

Proposed adapter vocabulary: `project_info`, `validate`, `scene_inspect`, `scene_edit`, `play`, `stop`, `input`, `probe`, `logs`, `scenario_run`. These are design names, not existing OpenCode or Godot APIs.

For Potion Shop, independently inventory and replace Summer networking, session admission, replication, authority lifecycle, and hosting assumptions. Preserve game rules and presentation where practical. Treat this as a separate migration after a baseline is established.

## The iteration contract

For every gameplay change:

1. Define player-visible success and an observable failure condition.
2. Record baseline state/screenshots and identify relevant architecture constraints.
3. Implement the smallest complete change.
4. Check changed scripts and resource imports.
5. Launch the relevant configuration and wait for observed readiness.
6. Drive normal input; capture before/after state, frames, and diagnostics.
7. Assert the intended behavior. Direct state mutation can set up a fixture, but cannot prove the player can reach it.
8. Repair specific failures and rerun affected scenarios. Bound attempts; report unresolved blockers with evidence.
9. Record what was verified, what was not, and artifact locations.

QA should use criteria defined before implementation, including failure paths. An LLM looking at a screenshot is useful for layout and readability, but is not a reliable substitute for state assertions or human judgment of fun.

For generated assets, use an asset manifest recording source, usage rights, dimensions, pivot, animation layout, import settings, and intended scale. Consistent art direction and correct imports matter more than generating many files.

## First experiment: Potion Shop golden path

The first deliverable should be a repeatable test of existing gameplay, not a new feature.

Run one authority and two clients, using the engine's supported local multiplayer orchestration. Confirm support rather than assuming a single-player probe launches that topology.

Acceptance scenarios:

1. Both clients join with distinct seats and visible characters.
2. Movement/input affects the correct player and remains within legal bounds.
3. A player gathers and prepares ingredients, brews, bottles, and serves a matching order.
4. Coins, held items, and the customer queue converge on both clients.
5. Two players competing for the same item cannot duplicate it.
6. Wrong-station/out-of-range commands are refused without changing shop state.
7. Late join or reconnect obtains the expected authoritative state.
8. HUD and interaction prompts remain readable at selected target aspect ratios.

Record each run's code revision/dirty diff, engine and adapter versions, scenario inputs, instance IDs, timing assumptions, assertions, logs, and screenshots. Separate functional correctness from human playfeel feedback.

Compare the workflow on a small representative task set: a gameplay rule change, a visual change, and a two-player bug. Track verified task completion, human interventions, elapsed time, model/tool costs, and regressions. Repeat comparable tasks before claiming productivity or quality parity with Summer's built-in AI.

## Implementation order

1. Establish a capability inventory and baseline playtest.
2. Add the primary agent, QA agent, focused skills, commands, and canonical project memory.
3. Automate the golden path with saved evidence.
4. Run a bounded feature/bugfix benchmark and improve the weakest feedback step.
5. Add art-provider integration and specialists only as needed.
6. If independence is required, port the adapter and runtime dependencies to stock Godot against the same acceptance suite.

Success means a fresh OpenCode session can understand the game, make a scoped change, run it, demonstrate its behavior, and leave enough evidence for the next session to continue.

## Sources

- [Summer public integration and architecture](https://github.com/SummerEngine/summer/tree/9fca4b88e1af9a5f4f232a8636190dc3a8eb36d4)
- [Engine operation catalog](https://github.com/SummerEngine/summer/blob/9fca4b88e1af9a5f4f232a8636190dc3a8eb36d4/src/core/ops/engine.ts)
- [Local API client](https://github.com/SummerEngine/summer/blob/9fca4b88e1af9a5f4f232a8636190dc3a8eb36d4/src/core/api-client.ts)
- [Verification and engine playbook](https://github.com/SummerEngine/summer/blob/9fca4b88e1af9a5f4f232a8636190dc3a8eb36d4/src/core/capabilities/agent-playbook.ts)
- [Agent playtesting](https://github.com/SummerEngine/summer/blob/9fca4b88e1af9a5f4f232a8636190dc3a8eb36d4/library/skills/agent-playtesting/SKILL.md)
- [Summer OpenCode integration guide reviewed](https://github.com/SummerEngine/summer/blob/9fca4b88e1af9a5f4f232a8636190dc3a8eb36d4/.opencode/INSTALL.md)
- OpenCode V2: [agents](https://opencode.ai/v2/docs/agents/), [skills](https://opencode.ai/v2/docs/skills/), [commands](https://opencode.ai/v2/docs/commands/), [MCP](https://opencode.ai/v2/docs/mcp-servers/)
