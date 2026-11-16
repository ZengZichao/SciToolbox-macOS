# Roadmap

SciToolbox is a personal research tool released under GPL-3.0. Directions below are indicative and may change based on feedback.

## Completed (1.0.0)

- **Offline bioinformatics toolkit**: reverse complement, GC content, translation (standard + bacterial), pairwise alignment (Needleman-Wunsch + Smith-Waterman), protein physicochemical properties (MW / pI / extinction coefficient).
- **File parsing**: FASTA / FASTQ / GenBank / GFF3 import with structured detail view.
- **Local full-text search**: SQLite FTS5 index over favorites / collections / result sets.
- **Result sets**: save search results as named sets with set operations (union / intersect / diff / dedup).
- **Result statistics**: Swift Charts visualizations for source distribution and year distribution.
- **System integration**: `scitoolbox://` URL scheme, Core Spotlight indexing, file type associations, NSServices menu, clipboard monitor, Dock menu.
- **Data backup & restore**: one-click JSON backup of all local data (favorites / collections / result sets / imported files / history).
- **Onboarding**: three-step intro cards (data sources / local tools / system integration).
- **Home workspace**: quick actions (local tools / import files / smart identify) + sample data loader.
- **Comprehensive test suite**: 71 tests covering parsers, local tools, alignment, file import, set ops, URL routing, and offline detail serialization.

## Near term

- Additional providers (e.g., ENA, Reactome, DisProt).
- Improved cross-database entity resolution — the current router is regex-based with confidence scoring.
- Better empty/error-state guidance per data source.
- Multiple sequence alignment (MSA) viewer.
- Sequence motif search and annotation.

## Mid term

- Saved searches / lightweight alerting.
- Plugin-style provider registration so contributors can add sources without modifying core.
- Phylogenetic tree viewer.
- Genome browser integration.

## Exploratory (no commitment)

- A reusable Swift package extracting the `Provider` + `APIClient` layer for other academic tools.
- Broader platform reach beyond macOS (currently SwiftUI / macOS 15+ only).
- BLAST integration (local or remote).

Feedback and priorities are welcome via the issue tracker.
