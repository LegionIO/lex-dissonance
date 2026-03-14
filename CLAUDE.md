# lex-dissonance

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Cognitive dissonance modeling for the LegionIO cognitive architecture. Tracks beliefs by domain, detects contradictions between beliefs in the same domain, generates dissonance events with computed magnitude, and manages psychological stress accumulation. Supports three resolution strategies: belief_revision, rationalization, and avoidance.

## Gem Info

- **Gem name**: `lex-dissonance`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Dissonance`
- **Location**: `extensions-agentic/lex-dissonance/`

## File Structure

```
lib/legion/extensions/dissonance/
  dissonance.rb                 # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # DISSONANCE_THRESHOLD, IMPORTANCE_WEIGHTS, RESOLUTION_STRATEGIES
    belief.rb                   # Belief value object
    dissonance_event.rb         # DissonanceEvent value object
    dissonance_model.rb         # Model: belief store, contradiction detection, stress tracking
  runners/
    dissonance.rb               # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `DISSONANCE_THRESHOLD` | 0.4 | Magnitude above which dissonance is flagged |
| `MAX_BELIEFS` | 200 | Belief store cap |
| `MAX_DISSONANCE_EVENTS` | 100 | Event log cap |
| `DECAY_RATE` | 0.03 | Stress increment per unresolved event per tick |
| `RESOLUTION_RELIEF` | 0.3 | Stress reduction per resolved event |
| `RATIONALIZATION_FACTOR` | 0.5 | Rationalization provides only 50% of normal relief |
| `IMPORTANCE_WEIGHTS` | `{core: 1.0, significant: 0.7, moderate: 0.5, peripheral: 0.25}` | Belief importance weights |
| `RESOLUTION_STRATEGIES` | `[:belief_revision, :rationalization, :avoidance]` | Valid resolution strategies |
| `CONTRADICTION_TYPES` | `[:direct, :inverse, :conditional, :temporal]` | Types (currently always `:direct`) |

## Runners

All methods in `Legion::Extensions::Dissonance::Runners::Dissonance`.

| Method | Key Args | Returns |
|---|---|---|
| `add_belief` | `domain:, content:, confidence: 0.7, importance: :moderate` | `{ success:, belief_id:, new_dissonance_events:, dissonance_triggered: }` |
| `update_dissonance` | — | `{ success:, stress:, unresolved_count:, above_threshold: }` |
| `resolve_dissonance` | `event_id:, strategy: :belief_revision` | `{ success:, resolved:, strategy:, event: }` |
| `dissonance_status` | — | `{ success:, stress:, total_beliefs:, total_events:, unresolved_count: }` |
| `domain_dissonance` | `domain:` | `{ success:, domain:, stress:, unresolved_count:, events: }` |
| `beliefs_for` | `domain:` | `{ success:, domain:, count:, beliefs: }` |
| `unresolved` | — | `{ success:, count:, events: }` |
| `dissonance_stats` | — | Full stats including resolution breakdown by strategy |

## Helpers

### `Belief`
Value object. Attributes: `id`, `domain`, `content`, `confidence`, `importance`, `created_at`. `contradicts?(other)` returns true when same domain but different content (simple string comparison). Does not detect semantic contradiction.

### `DissonanceEvent`
Value object. Attributes: `id`, `belief_a_id`, `belief_b_id`, `domain`, `magnitude`, `contradiction_type`, `resolved`, `resolution_strategy`, `timestamp`. `resolve!(strategy)` sets resolved flag.

### `DissonanceModel`
Central state: `@beliefs` (hash by id), `@events` (hash by id), `@stress` (float). Key methods:
- `add_belief(...)`: creates Belief, runs `detect_contradictions_for(belief)`, updates events
- `detect_contradictions`: full pairwise scan of all beliefs
- `resolve(event_id, strategy:)`: resolves event, reduces stress by `compute_relief(strategy)`
- `decay`: increments stress by `DECAY_RATE * unresolved_events.size` per tick
- `domain_stress(domain)`: sum of unresolved event magnitudes / MAX_DISSONANCE_EVENTS

## Integration Points

- `update_dissonance` maps to lex-tick's periodic update cycle
- `dissonance_status[:stress]` feeds into lex-emotion as a negative valence contribution
- `domain_dissonance` provides domain-specific stress for lex-prediction confidence modulation
- Resolved beliefs feed into lex-memory as updated semantic traces

## Development Notes

- Contradiction detection is simple: same domain + different content string (not semantic)
- `add_belief` auto-detects contradictions on insert — no need to call `detect_contradictions` manually
- Stress accumulates only when there are unresolved events; decays otherwise
- Rationalization provides less relief (`RESOLUTION_RELIEF * RATIONALIZATION_FACTOR = 0.15`)
