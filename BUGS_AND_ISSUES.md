# ESS RAP Phase 1 — Bugs & Issues Log

**Purpose:** Track all bugs, issues, and lessons learned during Phase 1 implementation  
**Last Updated:** 2026-08-31  
**Maintainer:** Development Team

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
