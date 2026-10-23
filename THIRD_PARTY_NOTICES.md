# Third-party notices

## LDNOOBW word-list candidates

The curated German, Spanish, French, Italian, Portuguese, Dutch, and Polish lexicon packs in `Sources/CodexStatsCore/Resources/lexicon.json` derive candidate terms from [LDNOOBW: List of Dirty, Naughty, Obscene, and Otherwise Bad Words](https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words), copyright © 2012–2020 Shutterstock, Inc. The source is pinned to commit `5faf2ba42d7b1c0977169ec3611df25a3c08eb13` and licensed under [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/); a copy is in [`licenses/CC-BY-4.0-LDNOOBW.txt`](licenses/CC-BY-4.0-LDNOOBW.txt). The resource separates 133 exact source candidates from 45 project-added explicit forms.

The project selected and removed candidate entries, normalized spelling, added selected explicit forms, assigned its own family and lexical-category labels, and added conservative exclusions. These choices are project curation, not LDNOOBW classifications or linguistic validation. LDNOOBW itself describes the lists as subjective autocomplete/recommendation exclusions. The packs are finite and may still misclassify words without context.

## Snowball stemming library

The app bundles the Snowball C runtime and UTF-8 English, German, Spanish, French, Italian, Dutch, Polish, Portuguese, and Russian stemmers from [Snowball](https://github.com/snowballstem/snowball), pinned to commit [`6389c79f91cd67ed2de3ebdcf84ec8c2d2d23c11`](https://github.com/snowballstem/snowball/tree/6389c79f91cd67ed2de3ebdcf84ec8c2d2d23c11). Snowball is licensed under the BSD 3-Clause license; see the [upstream license](https://github.com/snowballstem/snowball/blob/6389c79f91cd67ed2de3ebdcf84ec8c2d2d23c11/COPYING) and the bundled copy at [`Sources/CodexStatsCore/Resources/SNOWBALL-COPYING.txt`](Sources/CodexStatsCore/Resources/SNOWBALL-COPYING.txt). Project-added bridge code dispatches to these stemmers; upstream source files are included without modifications. Stem groups affect ranking only, never lexical recognition.
