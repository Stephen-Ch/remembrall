# Evidence Pack Template

**Source:** Extracted from [protocol/protocol-v7.md § Evidence Pack Requirement](../protocol/protocol-v7.md#evidence-pack-requirement-mandatory) as an example/template only.

**Authority:** [protocol/protocol-v7.md](../protocol/protocol-v7.md#evidence-pack-requirement-mandatory) remains authoritative for all Evidence Pack requirements, mandatory sections, and confidence thresholds.

---

## Template

```
## Evidence Pack — <TICKET-ID>

### Repro Steps
1. <step>
2. <step>

### Environment Fingerprint
- OS: Windows 11 / Server 2022
- .NET: 4.8.x
- IIS: Express / Full
- Date: YYYY-MM-DD HH:MM

### DLL Hashes
| File | SHA256 | Modified |
|------|--------|----------|
| bin/X.dll | abc123... | 2026-02-05 10:30 |

### Connection Targets
- <ConnectionName1>: <server>/<database>
- <ConnectionName2>: <server>/<database>

### Observed Error
<exact message or behavior>

### DB Proof
```sql
SELECT ... -- query
-- result: <summary>
```

### Diff Proof
<git diff output or summary>

### Decision
Evidence proves: <conclusion>
Recommended action: <next step>
```
