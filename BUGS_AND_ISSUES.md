# ESS RAP Phase 1 — Bugs & Issues Log

**Purpose:** Track all bugs, issues, and lessons learned during Phase 1 implementation  
**Last Updated:** 2026-08-31  
**Maintainer:** Development Team

---

## Milestone Status

- ✅ **Stage 1 — DDIC:** 5 domains, 5 data elements, 13 tables (156 fields) — activated, confirmed live. Issues #001–#004.
- ✅ **Stage 2 — Service Layer:** 6 interfaces, 7 classes — activated, confirmed live. Issues #005–#008.
- 🔄 **Stage 3 — RAP Business Object:** Round A pushed (5 CDS interface views, 5 projection views, 2 behavior definitions, empty behavior class — CRUD + associations only). Not yet activated. Round B (actions/determinations/validations) follows once confirmed. Issue #009.
- ⏭️ **Stage 4 — Fiori UI:** not started.

---

## Issue #001: [Template]

- **Date Found:** YYYY-MM-DD
- **Component:** (DDIC / Utility Class / RAP BO / Fiori UI / Integration)
- **Severity:** (Critical / High / Medium / Low)
- **Status:** (Open / In Progress / Resolved / Closed)

### Description
What went wrong? What was the symptom observed?

### Root Cause
Why did it happen? What was the underlying issue?

### Resolution
How was it fixed? What code/config changes were made?

### Test Case / Reproduction
Steps to reproduce the issue and verify the fix:
1. Step 1
2. Step 2
3. Expected vs. Actual result

### Related Code
Files & line numbers affected:
- `src/path/file.abap:line`
- `ui/path/view.xml:line`

### Lesson Learned
What should we avoid or do differently next time?

---

## Issue #001: ABAPGit "Cannot find .abapgit.xml - Is this an abapGit repository?"

- **Date Found:** 2026-08-31
- **Component:** Git / ABAPGit integration
- **Severity:** Critical (blocked all pulls)
- **Status:** Resolved

### Description
After pushing the initial documentation set to GitHub and linking the repo
in ABAPGit (Repository → assign to package `ZHR_ESS_V1`), the repository
view showed a red banner: *"Cannot find .abapgit.xml - Is this an abapGit
repository?"* No ABAP objects appeared as pullable — only a self-generated
`DEVC` / `src/package.devc.xml` proposal.

### Root Cause
The repository manifest was created as a file named **`.abapgit`** containing
**JSON**. ABAPGit does not recognize this at all — it requires a file named
**`.abapgit.xml`** in the repository root, containing a specific ABAP-style
XML payload (`<asx:abap>` wrapper with `MASTER_LANGUAGE`, `STARTING_FOLDER`,
`FOLDER_LOGIC`). The JSON `.abapgit` file was a fabricated format that
happened to *look* like a plausible config file but has no meaning to the
actual tool.

### Resolution
1. Deleted `.abapgit` (JSON).
2. Created `.abapgit.xml` with the verified real format:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
    <asx:values>
     <DATA>
      <MASTER_LANGUAGE>E</MASTER_LANGUAGE>
      <STARTING_FOLDER>/src/</STARTING_FOLDER>
      <FOLDER_LOGIC>PREFIX</FOLDER_LOGIC>
     </DATA>
    </asx:values>
   </asx:abap>
   ```
3. Added `src/package.devc.xml` (DEVC serializer XML) — note this file only
   carries a descriptive text (`CTEXT`); the actual target package is
   whatever package you link the repo to in ABAPGit's UI, not something
   read from this file.
4. Cross-verified the exact shape (encoding, indentation, BOM) against a
   second, independently-working ABAPGit repository
   (`VernasoftTechie/RAP_Migration_Tool`) rather than guessing — confirmed
   byte-for-byte structural match for `.abapgit.xml`, `package.devc.xml`,
   `.doma.xml` (domain), `.dtel.xml` (data element), and `.tabl.xml` (table).

### Test Case / Reproduction
1. Link a GitHub repo in ABAPGit to a package.
2. If the repo root has no `.abapgit.xml` (or has a wrongly-named/shaped
   substitute), ABAPGit shows the "Cannot find .abapgit.xml" banner and
   will not list any real objects to pull.
3. After adding a correct `.abapgit.xml`, **Refresh** — the banner clears
   and staged objects under `/src/` become visible.

### Related Code
- [`.abapgit.xml`](../.abapgit.xml) (repo root)
- [`src/package.devc.xml`](../src/package.devc.xml)

### Lesson Learned
Never hand-invent an ABAPGit manifest format from assumption — the file
name (`.abapgit.xml`, not `.abapgit`) and internal schema are exact and
tool-enforced. When in doubt, diff against a known-good repository rather
than guessing the shape. This same lesson applies to every DDIC object
type below (`.doma.xml`, `.dtel.xml`, `.tabl.xml`) — each was built by
copying the verified structure from a real working repo, not from memory.

---

## Issue #002: Scope Decisions Made While Generating DDIC XML (Read Before Activating)

- **Date Found:** 2026-08-31
- **Component:** DDIC (all 13 `.tabl.xml` files)
- **Severity:** Medium (not bugs, but deviations from the original SE11 guide worth knowing before you activate)
- **Status:** Documented, action optional

### Description
The 13 tables were generated as ready-to-pull ABAPGit XML instead of
requiring manual SE11 entry. To keep every field's XML shape provable
against the one verified reference repo (rather than guessing formats
with no working example), a few deliberate simplifications were made
relative to `DDIC/02_SE11_CREATION_GUIDE.md`:

1. **Secondary indexes are NOT included in the generated XML.**
   The reference repo's `TABL` serializer output never included a
   `DD12V`/secondary-index block (all its example tables only relied on
   the primary key), so there was no verified pattern to copy. All 13
   tables activate correctly with **primary keys only**. The `Idx_01`,
   `Idx_02`, etc. listed in `DDIC/01_DDIC_COMPLETE_SPECIFICATION.md` and
   `DDIC/DDIC_CREATION_CHECKLIST.md` still describe the intended
   secondary indexes — add them manually in SE11 (Indexes tab) after
   pulling, or ask to have them generated once a verified index XML
   shape is confirmed against your system.

2. **`LEVEL`, `ATTEMPT` (in `ZHR_ESS_APPR_STEP`) and `SEQUENCE` (in
   `ZHR_ESS_CHANGE_LOG`) are typed `INT4`, not `NUMC`**, even though
   they're key fields. `INT4` as a key field is technically legal in
   ABAP DDIC and was the only numeric field pattern already confirmed
   against a real working table (`READINESS_BLOCKER_COUNT` in the
   reference repo). A hand-written `NUMC` field block would have been
   an unverified guess. If you prefer `NUMC` (more conventional for key
   fields), convert them in SE11 after pulling — low effort, one field
   at a time.

3. **No `MANDT` field / `CLIDEP` set to space (client-independent).**
   Every table's business key starts with our own `CLIENT_ID` (CHAR 3),
   which is the intentional multi-tenant scheme from
   `DDIC/01_DDIC_COMPLETE_SPECIFICATION.md` — a different concept from
   SAP's technical client (`MANDT`). Tables are therefore modeled as
   client-independent so `CLIENT_ID` isn't confused with `MANDT`.

4. **Domain-bound fields use a data element with the *same name* as the
   domain** (e.g., domain `ZHR_ESS_REQ_STATUS` + data element
   `ZHR_ESS_REQ_STATUS`). This is legal in the ABAP Dictionary (SAP
   itself does this, e.g. `WAERS`, `SPRAS`) and keeps naming simple —
   flagging it here only because it looks unusual at first glance.

5. **Buffering is off (`BUFALLOW=N`) on all tables**, including the
   smaller config tables (`ZHR_ESS_CLIENT`, `ZHR_ESS_SERVICE`, etc.)
   that the original SE11 guide marked "Buffering: Allowed". Safer
   default for a first activation; enable buffering later in SE11 if
   you want the performance benefit on read-heavy config tables.

### Resolution
No fix needed — these are conscious, documented trade-offs, not defects.
Everything above is safe to leave as-is for Phase 1 testing. Revisit
only if a specific limitation (e.g. missing secondary index) actually
affects a query you're testing.

### Lesson Learned
When generating DDIC XML from scratch for ABAPGit, only reproduce
sub-structures (like secondary indexes) that have been seen working in
a real pulled/activated repo. Guessing an unverified XML shape for a
"nice to have" (like an index) risks breaking activation of the whole
table — better to ship without it and add it by hand in SE11 once.

---

## Issue #003: Three Real Activation Errors on First Pull (with fixes)

- **Date Found:** 2026-08-31
- **Component:** DDIC (domains, data elements, tables)
- **Severity:** Critical (8 of 13 tables failed to import; 2 data elements failed to activate)
- **Status:** Resolved

### Description
First actual ABAPGit "Pull" + activation against a real SAP system
surfaced three distinct, unrelated errors:

**(a) 8 of 13 tables failed with "Select a shorter name for
`<TABNAME>`" / "Import of object `<TABNAME>` failed":**
```
ZHR_ESS_APPR_STEP, ZHR_ESS_CHANGE_LOG, ZHR_ESS_CUST_FIELD,
ZHR_ESS_LOAN_PARAM, ZHR_ESS_LOAN_PERSONAL,
ZHR_ESS_LOAN_PERSONAL_CUSTOM, ZHR_ESS_VALIDATION_MSG, ZHR_ESS_WF_CONFIG
```

**(b) Two data elements failed to activate:**
```
Data Element ZHR_ESS_FIELD_TYPE could not be activated
Data Element ZHR_ESS_MSG_TYPE could not be activated
```
alongside warnings: `Output length (10) is greater than the calculated
output length (1)`, `Output length (15)...`, `Output length (5)...`, and
`Medium key word in language EN: length 17 > maximum length 15`,
`Long key word in language EN: length 23 > maximum length 20`.

### Root Cause
**(a) Table name length.** Classic ABAP Dictionary transparent tables
are capped at **16 characters** for the physical table name. Every
table that failed was 17–28 characters long; every table ≤16 characters
(`ZHR_ESS_CLIENT`, `ZHR_ESS_SERVICE`, `ZHR_ESS_REQ_HEAD`,
`ZHR_ESS_REQ_ITEM`, `ZHR_ESS_INT_RATE`) activated without issue. This
16-char limit does **not** apply to domains or data elements (up to 30
chars), which is why none of those failed for this reason.

**(b) Domain `OUTPUTLEN` too large.** All 5 domains are `CHAR(1)` with
no conversion exit. For a plain character field like that, the DDIC
will not allow a declared display `OUTPUTLEN` greater than the field's
own `LENG` (1) — there's nothing to pad or convert into a wider display.
The domains had been given arbitrary `OUTPUTLEN` values (5/10/15) for
nicer-looking list columns, which is invalid without a conversion
routine. The data elements built on top of the two most visibly-affected
domains (`ZHR_ESS_FIELD_TYPE`, `ZHR_ESS_MSG_TYPE`) failed to activate as
a downstream consequence.

**(c) Data element label text longer than its declared display width.**
Independently of (b), two data elements had `SCRTEXT_M` (medium column
header) or `SCRTEXT_L` (long column header) text longer than the
`SCRLEN2`/`SCRLEN3` width declared for it:
- `ZHR_ESS_FIELD_TYPE`: medium text `"Custom field type"` = 17 chars,
  but `SCRLEN2` was only 15.
- `ZHR_ESS_MSG_TYPE`: long text `"Validation message type"` = 23 chars,
  but `SCRLEN3` was only 20.

### Resolution
**(a) Renamed all 8 over-length tables** to ≤16 characters:

| Old name (too long) | New name | Chars |
|---|---|---|
| `ZHR_ESS_APPR_STEP` (17) | **`ZHR_ESS_APPRSTEP`** | 16 |
| `ZHR_ESS_CHANGE_LOG` (18) | **`ZHR_ESS_CHGLOG`** | 14 |
| `ZHR_ESS_CUST_FIELD` (18) | **`ZHR_ESS_CUSTFLD`** | 15 |
| `ZHR_ESS_LOAN_PARAM` (18) | **`ZHR_ESS_LOANPRM`** | 15 |
| `ZHR_ESS_LOAN_PERSONAL` (21) | **`ZHR_ESS_LOANDTL`** | 15 |
| `ZHR_ESS_LOAN_PERSONAL_CUSTOM` (28) | **`ZHR_ESS_CUSTVAL`** | 15 |
| `ZHR_ESS_VALIDATION_MSG` (22) | **`ZHR_ESS_VALMSG`** | 14 |
| `ZHR_ESS_WF_CONFIG` (17) | **`ZHR_ESS_WFCONFIG`** | 16 |

Domain and data element names (`ZHR_ESS_REQ_STATUS`,
`ZHR_ESS_APPR_STATUS`, `ZHR_ESS_FIELD_TYPE`, `ZHR_ESS_MSG_TYPE`,
`ZHR_ESS_LOAN_PURPOSE`) were **not** renamed — they're under the 30-char
limit that applies to those object types and were not part of the error.

**(b)** Set every domain's `OUTPUTLEN` to `000001` (equal to `LENG`),
matching what a plain CHAR(1)-without-conversion-exit field is actually
allowed to declare.

**(c)** Widened every data element's label fields uniformly:
`SCRLEN1=10, SCRLEN2=20, SCRLEN3=40, HEADLEN=40` — comfortably fits the
longest text used across all 5 (23 characters) with margin for future
label edits, instead of hand-tuning two individually.

All 13 `.tabl.xml`, 5 `.doma.xml`, and 5 `.dtel.xml` files were
regenerated from the corrected generator script and re-pushed.

### Test Case / Reproduction
1. Pull the repo in ABAPGit into package `ZHR_ESS_V1`.
2. Activate. Expect: all 5 domains, 5 data elements, and 13 tables
   activate with **no errors** (warnings about buffering/index absence,
   per Issue #002, are expected and fine).
3. If a table still fails with "Select a shorter name", check its
   `TABNAME` length in the corresponding `.tabl.xml` — must be ≤16.

### Related Code
- All files under [`src/*.tabl.xml`](../src/) (8 renamed)
- All files under [`src/*.doma.xml`](../src/) (`OUTPUTLEN` fix)
- All files under [`src/*.dtel.xml`](../src/) (`SCRLEN`/`HEADLEN` fix)
- `DDIC/01_DDIC_COMPLETE_SPECIFICATION.md` and
  `DDIC/DDIC_CREATION_CHECKLIST.md` — table names updated to match

### Lesson Learned
Two of these three errors (name length, output length) are **not**
guessable from documentation alone — they only surface at real
activation time against a real SAP system, because they depend on
DDIC-internal validation rules (16-char physical table name cap,
output-length-vs-conversion-exit check) that aren't obvious from the
XML schema itself. Treat every first real `Pull` + activate as a
verification step, not a formality — expect to iterate once against
real error output before a from-scratch DDIC generation is trustworthy.
Naming: keep future custom table names to **16 characters or fewer**
from the start (domains/data elements/classes get up to 30).

---

## Issue #004: Reserved-Word Field Names (`LEVEL`, `COMMENT`)

- **Date Found:** 2026-08-31
- **Component:** DDIC (`ZHR_ESS_APPRSTEP`, `ZHR_ESS_WFCONFIG`)
- **Severity:** Critical (blocked activation of 2 tables)
- **Status:** Resolved

### Description
After fixing Issue #003, re-pulling and activating produced two new
errors:
```
LEVEL is a reserved word (choose another field name)
COMMENT is a reserved word (choose another field name)
Table ZHR_ESS_APPRSTEP could not be activated
Table ZHR_ESS_WFCONFIG could not be activated
```

### Root Cause
`LEVEL` and `COMMENT`, used as bare field names, collide with ABAP/SQL
reserved keywords. `ZHR_ESS_APPRSTEP` had both (`LEVEL` as a key field,
`COMMENT` as a text field); `ZHR_ESS_WFCONFIG` had `LEVEL` only (also a
key field). This is an **exact-name** collision, not a substring one —
compound names sharing the same root, like `CURRENT_LEVEL`,
`PARALLEL_LEVEL`, `ITEM_TYPE`, `FIELD_VALUE`, `OLD_VALUE`, and the bare
words `STATUS` and `SEQUENCE` used elsewhere in the same tables, all
activated without complaint. Only the two exact matches were rejected.

### Resolution
Renamed both fields, in both tables (and in every table's own PK where
`LEVEL` was a key component):
- `LEVEL` → **`APPR_LEVEL`**
- `COMMENT` → **`APPR_COMMENT`**

Regenerated `zhr_ess_apprstep.tabl.xml` and `zhr_ess_wfconfig.tabl.xml`,
and updated every documentation reference to these two tables' field
lists and primary-key tuples (`DDIC/01_DDIC_COMPLETE_SPECIFICATION.md`,
`DDIC/02_SE11_CREATION_GUIDE.md`, `DDIC/DDIC_CREATION_CHECKLIST.md`,
`GITHUB_README.md`) to match — narrowly, line-by-line, since "level"
and "comment" also appear frequently in unrelated prose (e.g.
"3-level chain", "approval level") that must not be touched.

Proactively audited every other field name across all 13 tables for
bare (non-compound) reserved-word risk before regenerating — none
found; every other occurrence of a risky word is a compound name
(`ITEM_TYPE`, `LOAN_TYPE`, `FIELD_VALUE`, etc.), which is safe.

### Test Case / Reproduction
1. Pull the repo in ABAPGit, Activate.
2. Expect all 5 domains, 5 data elements, and 13 tables to activate
   cleanly. If a table fails with "`<WORD>` is a reserved word", the
   fastest fix is renaming just that field (prefix with something
   table-specific, e.g. `APPR_`) rather than guessing a wholesale
   rename — the error names the exact field.

### Related Code
- [`src/zhr_ess_apprstep.tabl.xml`](../src/zhr_ess_apprstep.tabl.xml)
- [`src/zhr_ess_wfconfig.tabl.xml`](../src/zhr_ess_wfconfig.tabl.xml)

### Lesson Learned
Reserved-word collisions in ABAP DDIC are field-name-exact, not
prefix/suffix-aware — a field named `LEVEL` fails where `CURRENT_LEVEL`
succeeds. When choosing field names during initial design, avoid bare
common English nouns that double as SQL/ABAP keywords (`LEVEL`,
`COMMENT`, `TYPE`, `VALUE`, `KEY`, `TIME`, `DATE`, `NAME`, `CLASS`,
`TABLE`) — qualify them (`APPR_LEVEL`, `APPR_COMMENT`) from the start
rather than discovering the collision at activation time.

---

## Issue #005: Service Layer (Interfaces + Classes) — Correction & Verification Status

- **Date Found:** 2026-08-31
- **Component:** Service Layer (`ZIF_ESS_*`, `ZCL_ESS_*`)
- **Severity:** Medium (one factual correction; rest is a transparency note)
- **Status:** Documented — **not yet activated against a real system**

### Part A — Correction: email source is IT0105, not IT0006

The originally uploaded architecture document (`FINAL_CONCLUSIONS.md`,
section 1, and `DDIC_Tables_Final_Spec.md` header) both state:

> Try to read IT0006 (Email, Phone master data). If not found → fallback
> to PA0006.

This is **factually incorrect** about standard SAP HR: infotype **0006**
is "Addresses" — it has no standard email field. Infotype **0105**
("Communication") is the standard SAP infotype for email, mobile,
system-user-ID, etc. `PA0006` and `IT0006` also refer to the exact same
underlying table (infotype 0006's physical table is literally named
`PA0006`) — so the original "try IT0006, fall back to PA0006" reads as
if it names two different sources when phrased that way, which added
to the confusion.

**What `ZCL_ESS_EMPLOYEE_PROVIDER_HCM.get_employee_contact_info()`
actually implements**, correcting for this:
- **Email — primary:** `PA0105`, subtype configured for e-mail
  (`gc_subty_email`, defaulted to `'0010'` — adjust to your system's
  T591A configuration).
- **Phone — primary:** `PA0105`, subtype configured for phone
  (`gc_subty_phone`, defaulted to `'0020'`).
- **Phone — fallback:** `PA0006-TELNR`, which *is* a genuine standard
  field on the Addresses infotype (unlike email).
- **Email — fallback:** left as a documented no-op; standard `PA0006`
  has no email field to fall back to. If your system extended `PA0006`
  with a custom email field, add that read in the `ELSE` branch.

The **dual-source-with-fallback pattern** — the actual architectural
decision that mattered — is preserved exactly as designed; only the
specific infotype/table names were corrected to match real SAP HR.

**Action for you:** if your target system stores email somewhere else
(a Z-infotype, IT0002 extension, etc.), tell me and I'll adjust
`get_employee_contact_info()` accordingly — this was implemented
against generic standard-SAP HR, not your specific system's config.

### Part B — Proactive fix: two class names exceeded the 30-char limit

Learned from Issue #003 (DDIC 16-char table name limit) that SAP
enforces hard length caps per object type. Classes/interfaces allow up
to **30 characters** (not 16), and two names from the original plan
exceeded even that:

| Old name (too long) | Chars | New name | Chars |
|---|---|---|---|
| `ZCL_ESS_LOAN_VALIDATOR_PERSONAL` | 31 | **`ZCL_ESS_PERSLOAN_VALIDATOR`** | 26 |
| `ZCL_ESS_NOTIFICATION_HANDLER_SMTP` | 33 | **`ZCL_ESS_NOTIF_HANDLER_SMTP`** | 26 |

Caught and fixed **before** writing any code this time, rather than
after a failed activation — the DDIC round-trips paid for themselves.

### Part C — Transparency: what's verified vs. not

Unlike the 13 DDIC tables (each field-by-field verified against a real
working ABAPGit repository before being written), the **method bodies**
in these 7 classes are standard ABAP written from HR/ABAP knowledge,
not cross-checked against a matching real example — the reference
repo's only class file is an empty RAP-behavior stub with no method
logic to compare against. The *wrapper XML* format (`.clas.xml`,
`.intf.xml`) **is** the verified-working minimal pattern from that
repo. Specific risk areas to watch on first Pull + Activate:
- `ZCL_ESS_EMPLOYEE_PROVIDER_HCM.is_suspended()` reads table `PA0101`
  ("Disciplinary") **dynamically** (by name, not hard-coded in the
  `FROM` clause) specifically because that infotype is not universal
  standard SAP — if it doesn't exist on your system, this fails safe
  (returns "not suspended") at runtime instead of blocking the whole
  class's activation. If you *do* have `PA0101`, double-check the field
  semantics match "suspended."
- `is_on_probation()` assumes the probation end date lives in infotype
  0041's `DAT01` slot — adjust if your T548Y config uses a different
  slot.
- `ZCL_ESS_WORKFLOW_ENGINE.get_approver_by_relationship()` only
  resolves relationship `A002` via a simplified single-hop Person→
  Person `HRP1001` read — real org models more often route
  Person→Position→Position→Person. Every other relationship ID
  (`A006`, `HR`, `Finance`, custom codes) currently falls straight
  through to `fallback_pernr`, which is exactly why that field is
  mandatory in `ZHR_ESS_WFCONFIG`. Extend as more relationships are
  needed.

### Test Case / Reproduction
1. Pull the repo in ABAPGit, Activate.
2. Interfaces (pure signatures, no logic) should activate cleanly —
   same low risk as DDIC domains.
3. Classes may need one iteration for something environment-specific
   (an infotype absent on your system, a field-name mismatch on a
   non-standard table) — paste whatever the activation log shows and
   it'll be fixed the same way as Issues #001-#004.

### Lesson Learned
For DDIC objects, the risk was an *undocumented internal format* (only
fixable by matching a verified working example). For class/interface
*logic*, the risk shifts to *domain-knowledge correctness* (right
infotype, right field, right subtype) — a different kind of thing to
verify, and one where cross-checking the user's own source documents
against actual standard-SAP behavior (as done here for IT0006 vs 0105)
matters as much as cross-checking a reference repo.

---

## Issue #006: Interface/Class Import Failed — "Invalid parameter OBJECT/OBJECTCLASS"

- **Date Found:** 2026-08-31
- **Component:** Service Layer (all 6 `.intf.xml`, all 7 `.clas.xml`)
- **Severity:** Critical (blocked import of all 13 objects)
- **Status:** Fixed, **not yet re-verified** by a real Pull (see below)

### Description
First Pull + Import of the Service Layer failed completely:
```
Invalid parameter OBJECT/OBJECTCLASS
Import of object ZIF_ESS_EMPLOYEE_PROVIDER failed
... (repeated for all 6 interfaces)
Invalid parameter OBJECT/OBJECTCLASS
Import of object ZCL_ESS_EMPLOYEE_PROVIDER_HCM failed
... (repeated for all 7 classes)
```
followed by, on retry:
```
Error reading report ZIF_ESS_EMPLOYEE_PROVIDER=====IU
Import of object ZIF_ESS_EMPLOYEE_PROVIDER failed
Error reading report ZCL_ESS_EMPLOYEE_PROVIDER_HCM=====CU
Import of object ZCL_ESS_EMPLOYEE_PROVIDER_HCM failed
... (same pattern for every interface/class)
```

### Root Cause
The `.intf.xml` / `.clas.xml` wrapper files were copied from the
**one** class example in the reference repo
(`VernasoftTechie/RAP_Migration_Tool`), which was a near-empty XML —
just `<asx:abap version="1.0" .../>` with no metadata block at all.
That example activated fine, but per that repo's own README, it was
captured by **serializing an already-existing class** (created by hand
in ADT, then synced via abapGit) — not verified for **creating a new
class from scratch** via Pull, which is what this repo needs. A
from-scratch class/interface import needs the object's catalog
metadata (`VSEOCLASS` for classes, `VSEOINTERF` for interfaces —
name, description, exposure, state) so SAP can register the object at
all before writing its source code into the class-pool includes.
Without it, the low-level creation call fails validating a blank/
missing object type, which is what "Invalid parameter
OBJECT/OBJECTCLASS" and the subsequent "Error reading report
`<name>`=====IU/CU" (abapGit falling back to reading a class-pool
include that was never created) both point to.

### Resolution
Added the metadata block to every `.intf.xml` and `.clas.xml`:
```xml
<!-- Interface -->
<VSEOINTERF>
  <CLSNAME>ZIF_...</CLSNAME>
  <LANGU>E</LANGU>
  <DESCRIPT>...</DESCRIPT>
  <EXPOSURE>2</EXPOSURE>
  <STATE>1</STATE>
  <UNICODE>X</UNICODE>
</VSEOINTERF>

<!-- Class -->
<VSEOCLASS>
  <CLSNAME>ZCL_...</CLSNAME>
  <LANGU>E</LANGU>
  <DESCRIPT>...</DESCRIPT>
  <STATE>1</STATE>
  <FIXPT>X</FIXPT>
  <UNICODE>X</UNICODE>
  <EXPOSURE>2</EXPOSURE>
</VSEOCLASS>
```
`EXPOSURE = 2` (public), `STATE = 1` (implemented, not just declared),
`FIXPT = X` (fixed-point arithmetic — needed since several methods do
decimal math, e.g. EMI calculation). Every object now also has a real
description instead of none.

### ⚠️ Verification Status (be aware before pulling again)
Unlike the DDIC fixes (#001–#004), **this fix is not cross-checked
against a matching real working example** — no `VSEOCLASS`/
`VSEOINTERF`-bearing `.clas.xml`/`.intf.xml` exists in the one
reference repo available this session. This shape is written from
well-established, standard SAP OO Repository catalog knowledge
(`SEOCLASS`/`SEOCLASST` structure, stable since ABAP OO's introduction)
rather than a diffed example. It is the best next attempt, not a
guaranteed fix — if it still fails, the exact error text will narrow
down which field is missing or wrong, the same way Issues #001–#004
got resolved.

### Test Case / Reproduction
1. Pull the repo in ABAPGit, Import.
2. Expect all 6 interfaces and 7 classes to import successfully this
   time. If "Invalid parameter OBJECT/OBJECTCLASS" or a similar
   metadata error recurs, paste the log — one of the `VSEOCLASS`/
   `VSEOINTERF` field values is likely still off, not the source code.

### Lesson Learned
A serialized example captured from an **already-existing** object is
not automatically proof that the same (possibly minimal/degenerate)
shape works for **creating** that kind of object from nothing — export
and import are two different code paths in abapGit, and a "successful
real repo" only proves the export side unless you know the object was
actually created via that exact Pull flow. Ask (or check the source
repo's own commit history / README) whether an object was pulled-in
or hand-created-then-synced before trusting its shape as a from-scratch
template.

---

## Issue #007: "CLAS, error while scanning source. Subrc = 0" (ZCL_ESS_EMPLOYEE_PROVIDER_HCM only)

- **Date Found:** 2026-08-31
- **Component:** `ZCL_ESS_EMPLOYEE_PROVIDER_HCM`
- **Severity:** Medium (blocked 1 of 13 objects; the other 12 imported successfully after Issue #006's fix)
- **Status:** ✅ **Resolved, confirmed** — the class now imports and opens in SE24/Class Builder (see Issue #008 for the next, unrelated error found once inside)

### Description
After fixing Issue #006, re-pulling imported all 6 interfaces and 6 of
7 classes successfully. One class failed differently from anything
seen so far:
```
CLAS, error while scanning source. Subrc = 0
Import of object ZCL_ESS_EMPLOYEE_PROVIDER_HCM failed
```
Unlike Issues #001-#006, this is not a naming, length, or metadata
problem — the error is about abapGit's own *parsing* of the source text
into class-pool structure, not a DDIC/catalog validation.

### Root Cause — Honest Assessment
**Not confirmed.** `ZCL_ESS_EMPLOYEE_PROVIDER_HCM` was the only one of
7 classes using `TRY. ... CATCH cx_sy_dynamic_osql_semantics
cx_sy_dynamic_osql_syntax. ... ENDTRY.` around a **dynamic** `SELECT
... FROM (variable)`. That is the single most unusual ABAP construct
in the entire Service Layer — every other class uses only plain,
static `SELECT ... FROM <table>`. No encoding issue was found (file is
plain ASCII, structurally balanced METHOD/ENDMETHOD pairs, same as the
working classes) — the leading hypothesis is that this TRY/CATCH +
dynamic-FROM combination is what abapGit's source scanner tripped on,
but this has **not been proven** by isolating and testing it alone.

### Mitigation Applied
Removed the `TRY/CATCH` and dynamic `SELECT ... FROM (gc_it0101_tabname)`
entirely from `is_suspended()`, replacing it with a plain static
`SELECT SINGLE pernr FROM pa0101 ...`. This trades away the "fails
safe (not suspended) if PA0101 doesn't exist on your system" behavior
— **if table `PA0101` doesn't exist in your system, this method will
now fail class ACTIVATION with a clear, ordinary "table/view PA0101
not defined in the ABAP Dictionary" error**, rather than the opaque
scanning error, and rather than silently defaulting to "not suspended"
at runtime. That trade-off is intentional: a normal, diagnosable
compile error is strictly easier to act on than either the vague
scanning error we just hit or a silent runtime fallback that could
mask a real config problem.

### Update — First Mitigation Failed, Ruled Out
Re-pulling after removing TRY/CATCH produced **the exact same error**:
```
CLAS, error while scanning source. Subrc = 0
Import of object ZCL_ESS_EMPLOYEE_PROVIDER_HCM failed
```
This **rules out** TRY/CATCH and dynamic SQL as the cause — the file
no longer contains either, and the error is unchanged.

**Second, more systematic pass:** diffed this file's *class definition
part* specifically (not implementation) against all 6 classes that
imported successfully. Two remaining differences stood out, both
unique to this one file:
1. A `CONSTANTS:` chain declaration (3 subtype codes) in the
   `PRIVATE SECTION` — **no other class in the Service Layer declares
   any `CONSTANTS` at all.**
2. Two private methods (`read_pa0000`, `read_pa0001`) using
   `EXPORTING`-only signatures with no `RETURNING` — **every other
   method in all 13 objects uses `RETURNING`.**

Both were removed in the same pass (rather than testing one at a time
again, having already burned one single-factor guess):
- The 3 subtype literals (`'1000'`, `'0010'`, `'0020'`) are now inlined
  directly into their respective `SELECT ... WHERE subty = '...'`
  clauses instead of named constants.
- `read_pa0000`/`read_pa0001` now `RETURNING` a small local result
  structure each (`ty_pa0000_result`, `ty_pa0001_result`, declared via
  `TYPES: BEGIN OF ... END OF` — a chain construct already proven safe,
  since interfaces like `ZIF_ESS_EMPLOYEE_PROVIDER` use it successfully)
  instead of populating `EXPORTING` parameters.

### If This Still Doesn't Fix It
If the exact same error recurs a third time, both of these hypotheses
are wrong too, and the cause is something not yet identified — at that
point the most useful next step is pulling a byte-for-byte diff of this
file against `ZCL_ESS_WORKFLOW_ENGINE` (or trying to isolate by
temporarily gutting this class down to a near-empty shell and adding
sections back one at a time on your system, if you're willing, since
that would pinpoint the exact trigger directly rather than guessing
from this end).

### Test Case / Reproduction
1. Pull the repo in ABAPGit, Import.
2. If `ZCL_ESS_EMPLOYEE_PROVIDER_HCM` now imports successfully: one of
   `CONSTANTS:` or `EXPORTING`-only methods was the cause (still not
   which one specifically, since both were removed together) — update
   this entry's Status to "Resolved" if so.
3. If PA0101 doesn't exist on your system, expect a *different*,
   ordinary activation error naming that table — that would actually
   be good news (confirms the scanning-level issue is gone) and is
   separately actionable per the note in `is_suspended()`.

### Confirmed Resolved
The class now imports successfully and opens in SE24 Class Builder —
confirmed by the user pulling and seeing the class display, hitting a
genuinely different, ordinary ABAP syntax error next (Issue #008)
rather than the scanning error. Whichever of `CONSTANTS:` or the
`EXPORTING`-only methods was the actual cause (both were removed
together, so which one specifically remains unknown) — abapGit's
source scan now succeeds on this file.

### Lesson Learned
Not every abapGit import failure is a naming/metadata problem like
Issues #001-#006 — this was a different failure *class* entirely
(source-level parsing, not catalog registration). The first
single-factor guess (TRY/CATCH) was wrong and got ruled out cleanly by
retesting; a more disciplined line-by-line diff against working files
surfaced two other candidates, and removing both together this time
(rather than repeating another slow one-at-a-time cycle) worked.

---

## Issue #008: "A RETURNING parameter must be fully typed" (generic inline P-type)

- **Date Found:** 2026-08-31
- **Component:** `ZCL_ESS_EMPLOYEE_PROVIDER_HCM` (also fixed proactively in `ZIF_ESS_EMPLOYEE_PROVIDER`)
- **Severity:** Low (single, ordinary syntax error — not a scanning/import-level issue)
- **Status:** ✅ Resolved

### Description
With Issue #007 resolved, the class now opens in SE24 Class Builder,
which reported a normal activation error:
```
Private Section ZCL_ESS_EMPLOYEE_PROVIDER_HCM, Line 38
A RETURNING parameter must be fully typed.
```
Pointing at:
```abap
METHODS read_pa0008
  IMPORTING
    !iv_pernr        TYPE pernr_d
    !iv_key_date     TYPE dats
  RETURNING
    VALUE(rv_salary) TYPE p LENGTH 8 DECIMALS 2 .
```

### Root Cause
`TYPE p LENGTH n DECIMALS m` (an inline, fully-specified packed-number
type) is valid in `DATA`/`TYPES`/`CONSTANTS` statements, but **method
signature parameters** (`IMPORTING`/`EXPORTING`/`CHANGING`/`RETURNING`)
only accept a `TYPE <named-type>` reference — a data element, a
`TYPES`-defined type, or an object type — not an inline compound type
specification with `LENGTH`/`DECIMALS` add-ons. ABAP's parser treats
`TYPE p` in that position as the bare *generic* type `p` (since it
can't attach the length/decimals there), which is exactly what "must
be fully typed" means.

The identical pattern in `ZIF_ESS_EMPLOYEE_PROVIDER`'s `TYPES: BEGIN OF
ty_employee_data ... basic_salary TYPE p LENGTH 8 DECIMALS 2, END OF`
is **not** an error — that's a structure *component* inside a `TYPES`
statement, a different grammar position where inline `LENGTH`/
`DECIMALS` is allowed. It only became a problem the moment the exact
same clause was reused on a method parameter.

### Resolution
Replaced the inline generic type with a reference to the actual DDIC
field this value represents, matching the pattern already used for
every other business-data parameter in the codebase:
```abap
RETURNING
  VALUE(rv_salary) TYPE zhr_ess_req_head-basic_salary .
```
`ZHR_ESS_REQ_HEAD-BASIC_SALARY` is `DEC(15,2)`, which is the exact same
underlying packed representation as `P LENGTH 8 DECIMALS 2` — no
semantic change, just a named reference instead of an inline spec.

Also proactively updated `ZIF_ESS_EMPLOYEE_PROVIDER`'s
`ty_employee_data-basic_salary` to the same DDIC reference for
consistency, even though it wasn't erroring — one less place using an
inline generic spec that could bite again if ever copied into a
parameter position later.

**Audited the entire Service Layer** for the same class of mistake —
searched every `.clas.abap`/`.intf.abap` for bare `TYPE c`/`n`/`p`/`x`
(the four ABAP built-in types that are generic without a length/
decimals qualifier) and for every `RETURNING`/`VALUE(...)` declaration
across all 13 objects. This was the only occurrence; everything else
already referenced named data elements, DDIC fields, or `TYPES`-
declared structures/tables.

### Test Case / Reproduction
1. Pull the repo in ABAPGit, Import, then Activate
   `ZCL_ESS_EMPLOYEE_PROVIDER_HCM` (and re-check `ZIF_ESS_EMPLOYEE_PROVIDER`
   if previously activated).
2. Expect no "must be fully typed" error this time.

### Lesson Learned
A construct being valid in one ABAP statement type doesn't mean it's
valid in another that looks similar — `TYPE p LENGTH n DECIMALS m` is
fine in `TYPES`/`DATA` but not in a method's parameter list. When a
generic built-in type (`c`, `n`, `p`, `x`) needs to appear in a
signature, always route it through a named data element, DDIC field
reference, or a `TYPES`-declared type instead of writing the
length/decimals inline at the parameter.

---

## Issue #009: Stage 3 (RAP BO) — Scope Decisions & One Caught-Before-Push Fix

- **Date Found:** 2026-08-31
- **Component:** RAP Business Object (`ZI_ESS_*`, `ZC_ESS_*`, `ZBP_I_ESS_REQ_HEAD`)
- **Severity:** Informational (deliberate scoping) + Low (one format fix, caught pre-push)
- **Status:** Documented, ready for first Pull + Activate

### Part A — Round A / Round B split (deliberate)
This first Stage 3 push covers **entities + CRUD + associations only** —
1 root (`ZI_ESS_REQ_HEAD`/`ZC_ESS_REQ_HEAD`) and 4 children
(`LOANDTL`, `REQ_ITEM`, `APPRSTEP` read-only, `CUSTVAL`), 36 files total.
It deliberately does **not** yet include:
- `submit`/`withdraw` actions
- `resolveEmployeeData`/`calcEmiSchedule` determinations
- `validateEligibility` validation
- Any handler methods in `ZBP_I_ESS_REQ_HEAD` (it's an empty stub)

Reason: RAP determination/validation/action **handler method signatures**
(`REPORTED`/`FAILED`/`MAPPED` parameters, `for determine on save`, etc.)
are a category of syntax with **zero verified examples** in the
reference repo — even its own README describes struggling through
"three failed guesses" on a *simpler* problem (CDS metadata format)
before getting a working example. Shipping CRUD-only first gives a
much smaller, more isolable checkpoint: if this fails, the cause is in
entities/associations, not tangled up with new handler-method risk.
Business logic (Round B) will follow as soon as this activates cleanly.

### Part B — `authorization master ( global )` instead of `( instance )`
The reference repo's own root behavior definition uses
`authorization master ( instance )` — but per its own README, **none of
its RAP objects have been activated against a real system**, so that
combination (instance authorization + a completely empty behavior
class) is unverified, not a proven pattern. Instance authorization
requires implementing a `GET INSTANCE AUTHORIZATIONS` handler method;
global authorization is the simpler declaration, chosen here
specifically to keep the empty-stub behavior class viable for this
first pass. If activation demands a handler method even for `global`,
that will show up as a normal, diagnosable error to fix in the next
round.

### Part C — Fiori `@UI` annotations kept deliberately minimal
Only `@UI.headerInfo`, `@UI.facet` (`IDENTIFICATION_REFERENCE` /
`LINEITEM_REFERENCE` only), `@UI.lineItem`, `@UI.identification`, and
`@Semantics.amount.currencyCode`/`@Semantics.currencyCode` (root only)
are used — all patterns already shown activating successfully in the
reference repo's own `ZC_RAP_MT_HDR`. Richer annotations
(`@Consumption.valueHelpDefinition`, `@UI.selectionField`,
`@UI.dataPoint`, `@Search.*`) are deferred to Stage 4 (Fiori UI) as a
dedicated polish pass, rather than adding more unverified annotation
shapes on top of an already-large first CDS/BDEF push.

### Part D — Fixed before push: `.ddls.baseinfo` must have NO byte-order mark
While generating the 10 `.ddls.baseinfo` JSON files, the same generator
helper used for the `.xml` wrapper files (which correctly need a UTF-8
BOM, matching every verified DDIC/Service-Layer file) was reused
uncritically for the JSON files too. A hex-dump check against the
reference repo's own `.baseinfo` file
(`zi_rap_mt_hdr.ddls.baseinfo`, starts `7b 0d 0a` — a plain `{`, no
`ef bb bf` BOM) caught the mismatch before pushing. Added a separate
`Write-JsonFile` helper (UTF-8, no BOM) for `.baseinfo` files
specifically. **This is exactly the kind of check that would otherwise
have become Issue #010** — flagged here as a reminder that every new
file *type* introduced (not just every new object) needs its own
byte-level check against a real example, not an assumption that
"whatever worked for XML will work for JSON in the same repo."

### Test Case / Reproduction
1. Pull the repo in ABAPGit, Activate.
2. Expect: 5 interface views, 5 projection views, 2 behavior
   definitions, and `ZBP_I_ESS_REQ_HEAD` (empty stub) all activate.
3. If `authorization master ( global )` demands a handler method,
   that error will name it explicitly — implement per Part B's note.
4. Once this is confirmed clean, Round B adds actions, determinations,
   validations, and the real behavior-class logic wiring in the
   already-activated Service Layer classes.

### Lesson Learned
Carried forward from Issue #001: always verify a new file *type*
byte-for-byte against a real example before trusting it, even when a
sibling file type in the same object family already checked out fine.
BOM-vs-no-BOM is invisible in a normal text read — only a hex dump
would have caught it, and did.

---

## Known Issues & Resolutions (Phase 1)

### 1. Email Source Fallback
- **Issue:** PA0006 not always populated in some SAP systems
- **Resolution:** Implemented dual-source: Try IT0006 first → fallback to PA0006
- **Code:** `ZCL_ESS_EMPLOYEE_PROVIDER_HCM.get_employee_contact_info()`
- **Documented:** ✓ In architecture spec

### 2. Approval Chain Resolution
- **Issue:** Relationship_id (A002, A006) might not resolve for all org structures
- **Resolution:** Mandatory fallback_pernr in ZESS_WF_CONFIG
- **Code:** `ZCL_ESS_WORKFLOW_ENGINE.resolve_approval_chain()`
- **Documented:** ✓ In DDIC spec

### 3. Multi-Client Data Isolation
- **Issue:** Data leakage risk if client_id not filtered consistently
- **Resolution:** All CDS views include WHERE client_id filter
- **Code:** All RAP views & determinations filter by client_id
- **Documented:** ✓ In RAP architecture

---

## Debugging Checklist

Use this when troubleshooting issues during Phase 1:

- [ ] Check ZESS_CLIENT table — is test client (100) created?
- [ ] Check ZESS_WF_CONFIG — is approval config for PERSLOAN created?
- [ ] Check ZESS_LOAN_PARAM — is eligibility config present?
- [ ] Check HR data — is test employee (PA0000, PA0008) available?
- [ ] Check ZESS_VALIDATION_MSG — are all message IDs populated?
- [ ] Check RAP logs (SM37, Application Log) for determination/validation errors
- [ ] Check Fiori app console (F12) for JavaScript errors
- [ ] Check CDS view activation — all views active?
- [ ] Check interface implementation — all classes implement their interfaces?
- [ ] Check business object binding — are entities wired correctly in BDEF?

---

## Phase 1 Lessons Learned (Running Log)

As issues are encountered and resolved, key learnings will be added here:

- **[TBD]** DDIC layer learnings
- **[TBD]** Service layer learnings
- **[TBD]** RAP BO learnings
- **[TBD]** Fiori UI learnings
- **[TBD]** Integration learnings

---

## Escalation Contacts

For issues requiring external help:

- **ABAP/RAP Questions:** [TBD]
- **Fiori UI Questions:** [TBD]
- **HR Data Integration:** [TBD]
- **System Admin:** [TBD]

---

**End of Bugs & Issues Log**
