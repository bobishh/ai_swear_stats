## ADDED Requirements

### Requirement: Deterministic lexical classification
The classifier SHALL use a versioned bundled dictionary and explicit morphological rules without regular expressions or LLM calls. It SHALL return a normalized word, family, category, and recognition method. English and Russian forms SHALL be supported, with explicit exclusions for innocent lookalikes.

#### Scenario: Inflections and exceptions
- **WHEN** words include Russian inflections, English derivatives, masked forms, and innocent words such as страхуй, подстрахуй, рубля, and Scunthorpe
- **THEN** supported offensive forms classify consistently and innocent words remain unclassified

### Requirement: Index-only reclassification
The index SHALL retain word frequencies and SHALL reclassify them when classifier version changes without reading source-log content.

#### Scenario: New lexicon version
- **GIVEN** indexed messages
- **WHEN** classifier version changes and source files remain unchanged
- **THEN** metrics reflect the new classifier and zero source bytes are read
