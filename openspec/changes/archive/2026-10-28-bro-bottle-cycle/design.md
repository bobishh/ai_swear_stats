## Ownership

`MascotCycle` owns five phases: settled, buzzing, sleeping, drinking a wake-up stash, and sobering. It owns heat and bottle accounting. `DashboardState` retains it across refreshes and filter changes. Existing live ingestion supplies only new user profanity; archive imports and replays stay excluded upstream. Sound and notifications consume the same live batch independently.

A snapshot advances a copy to its requested time. SwiftUI can render timed transitions without mutating observable state in its body. A received event first advances the authoritative model to its arrival time. The cycle intentionally resets across app restarts.

## Bottle and heat rules

Each positive awake hit is consumed immediately, including coalesced batches. It adds one to total drunk and to decorative empties, records the latest gulp, and raises heat by one up to 24. Sleeping hits add to a full-bottle stash instead. Total received always equals total drunk plus the current stash; decorative empties are a separate presentation inventory.

Awake heat decays by 0.2 per second. Heat at four enables rowdy behavior; heat below four shows sobering. Crossing twelve commits a sleep four seconds later, leaving a readable buildup. Sleep lasts eighteen seconds and cools heat by 0.5 per second. On waking, a nonempty stash is consumed immediately and shown as a three-second drinking scene. New awake hits during that scene are still consumed promptly. Its completion chooses sleep again at heat twelve, buzzing at four, sobering above zero, or settled at zero. Empty waking chooses the same outcome without a drinking scene. Heat at zero clears decorative empties.

The heat cap and cooling guarantee eventual rest after input stops. Timers alone never raise heat or manufacture bottles. Lower profanity frequency delays or prevents another sleep cycle.

## Presentation

Reserve one fixed 90-point stage under the chart in loaded, empty, loading, and every story state. Bro remains inside it. Fresh batches show quick drinking and a motivated empty-bottle throw; only elevated heat enables the custom rowdy bottle routine. Generic pet waving, unmotivated jumping, and constant pacing are absent.

Full bottles queue beside the sleeping character. Empty bottles land on the other side after a bounded projectile arc. Artwork and piles stay within the stage; visual pile counts may be capped without changing model accounting. As heat drops, movement slows and the empty pile fades away. The stage never intercepts chart gestures.

Reduce Motion uses representative stationary poses while timed phases and bottle accounting keep advancing. The ordinary dashboard has no simulation controls or explanatory story prose. Isolated synthetic previews exercise the sequence without adding fabricated user messages to real logs.
