# Builder + Auditor — Reference Contract Schema

Canonical keyword registry for all 8 platform reference contract files under `lib/platforms/<platform>/reference/contract/`.

**Builder** persona greps these keywords when reading platform reference files.
**Auditor** persona (`arch-check-conventions`) enforces their presence on all platforms.

See `docs/contract/README.md` for heading structure rules, validation, and adding a new platform.

---

## domain.md

| Canonical keyword | Concept |
|---|---|
| `Entities` | Domain entity definitions |
| `Repository` | Repository interface/protocol |
| `Use Cases` | UseCase definitions and patterns |
| `Services` | Domain service definitions (pure business logic spanning multiple entities) |
| `Domain Errors` | Domain-level error type |

---

## data.md

| Canonical keyword | Concept |
|---|---|
| `DTOs` | Data Transfer Objects / response models |
| `Mappers` | DTO → Entity mapping |
| `Data Sources` | DataSource abstraction and implementation |
| `Repository Impl` | Repository implementation (bridges DataSource → Domain) |

---

## presentation.md

| Canonical keyword | Concept |
|---|---|
| `State` | State container (ViewModel, BLoC state, ViewDataState) |
| `Shared Component Paths` | Canonical file paths for reusable UI components on this platform |

---

## navigation.md

| Canonical keyword | Concept | Notes |
|---|---|---|
| `Route Constants` | Named route definitions | Web and Flutter |
| `Navigator` OR `Coordinator` | Navigation pattern entry point | iOS (Coordinator pattern has no route constants) |

At least one of the three keywords must be present.

---

## di.md

| Canonical keyword | Concept |
|---|---|
| `DI Principles` | Core DI rules that apply regardless of framework |

---

## testing.md

| Canonical keyword | Concept |
|---|---|
| `Test Pyramid` | Layer distribution — unit heavy, integration light, e2e minimal |
| `Repository Tests` | How to test repository implementations |
| `Mapper Tests` | How to test DTO → Entity mappers |

---

## error-handling.md

| Canonical keyword | Concept |
|---|---|
| `Error Flow` | Layer-by-layer error propagation diagram |
| `Error Types` | Platform error type definitions (DomainError, BaseErrorModel, Failure) |
| `Error Mapping` | How errors are converted between layers |
| `Error UI` | How errors are surfaced to users in the UI layer |

---

## utilities.md

| Canonical keyword | Concept |
|---|---|
| `StorageService` | Key-value storage abstraction |
| `DateService` | Date formatting and parsing |
| `Logger` | Structured logging |
| `Null Safety` | Null/optional fallback utilities |
