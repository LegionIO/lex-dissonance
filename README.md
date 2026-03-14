# lex-dissonance

Cognitive dissonance modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Tracks the agent's beliefs by domain and detects when two beliefs in the same domain contradict each other. Contradictions generate dissonance events with a computed magnitude based on belief importance and confidence. Unresolved dissonance accumulates as psychological stress. The agent can resolve events using one of three strategies.

## Usage

```ruby
client = Legion::Extensions::Dissonance::Client.new

# Add beliefs (contradiction auto-detected on insert)
client.add_belief(domain: :architecture, content: 'stateless services scale better',
                  confidence: 0.9, importance: :core)
client.add_belief(domain: :architecture, content: 'stateful services are more reliable',
                  confidence: 0.7, importance: :significant)
# => { success: true, belief_id: "...", new_dissonance_events: [...], dissonance_triggered: true }

# Check stress
client.dissonance_status
# => { stress: 0.245, total_beliefs: 2, unresolved_count: 1, ... }

# Resolve with a strategy
client.resolve_dissonance(event_id: '...', strategy: :belief_revision)
# => { success: true, resolved: true, strategy: :belief_revision }

# Domain-level view
client.domain_dissonance(domain: :architecture)
# => { stress: 0.0, unresolved_count: 0, events: [] }

# Tick: decays or accumulates stress, runs contradiction scan
client.update_dissonance
```

## Resolution Strategies

| Strategy | Relief | Description |
|---|---|---|
| `:belief_revision` | Full | Update belief to remove contradiction |
| `:rationalization` | 50% | Justify the contradiction without resolving it |
| `:avoidance` | Full | Suppress awareness of the contradiction |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
