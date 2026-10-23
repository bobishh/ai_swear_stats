## ADDED Requirements

### Requirement: Deterministic lexical classification
The classifier SHALL use a versioned bundled dictionary and explicit forms and morphological rules without regular expressions, runtime downloads, or LLM calls. It SHALL return a normalized word, legacy family label, category, recognition method, and language when unambiguous. English and Russian morphology SHALL remain supported. The bundled exact-token packs SHALL cover German, Spanish, French, Italian, Portuguese, Dutch, and Polish. The packs SHALL use explicit project-reviewed category labels and source/version attribution; they SHALL NOT import all upstream candidate words as profanity. Ranking SHALL offer Snowball stem groups calculated only for already-classified words using the bundled, pinned Snowball 3.2.0 implementation. Group identity SHALL include stem, unambiguous language, and lexical category; words with no unambiguous language SHALL remain exact-word groups. Stems SHALL NOT expand recognition. The UI SHALL name this ranking Families and display observed whole-word representatives. Documentation SHALL explain the underlying algorithmic grouping and its over- or under-grouping limitations without claiming a semantic taxonomy.

#### Scenario: Inflections and exceptions
- **WHEN** words include Russian inflections, English derivatives, masked forms, and innocent words such as страхуй, подстрахуй, рубля, and Scunthorpe
- **THEN** supported offensive forms classify consistently and innocent words remain unclassified

#### Scenario: Curated multilingual coverage
- **GIVEN** exact terms and explicitly accepted forms in every advertised language pack
- **WHEN** the classifier processes complete tokens
- **THEN** each term returns its curated family, category, and language, while neutral identity/anatomy terms and substring-only lookalikes remain unclassified

#### Scenario: Language collision
- **GIVEN** a spelling has different family or category labels in multiple language packs
- **WHEN** no language is supplied
- **THEN** the classifier leaves that spelling unclassified
- **WHEN** a matching language is supplied
- **THEN** the classifier returns that pack's reviewed label

#### Scenario: Pack integrity and attribution
- **GIVEN** the bundled lexicon
- **WHEN** the classifier loads it
- **THEN** it validates source revision/license metadata, rejects duplicate or excluded forms, and exposes only finite supported language coverage

### Requirement: Index-only reclassification
The index SHALL retain word frequencies and SHALL reclassify them when classifier version changes without reading source-log content.

#### Scenario: New lexicon version
- **GIVEN** indexed messages
- **WHEN** classifier version changes and source files remain unchanged
- **THEN** metrics reflect the new classifier and zero source bytes are read
