# Rewards / Loyalty Downstream – Integration with CardDemo

This document describes **possible integration** of a Rewards/Loyalty downstream system (COBOL or other) with the CardDemo legacy: **data flow sequence**, **exact VSAM and sequential files**, and **record layouts**.

---

## Super Simplified: CardDemo ↔ Glue ↔ Rewards

```
     ┌─────────────────────┐         ┌─────────────────────────────────────┐         ┌─────────────────────┐
     │                     │         │         INTEGRATION GLUE              │         │                     │
     │   AWS CardDemo      │  write  │                                     │  read   │   Rewards System    │
     │   (legacy)          │────────►│  • TRANSACT.VSAM.KSDS (transactions) │────────►│   (new)             │
     │                     │         │  • TRANTYPE.VSAM.KSDS (type codes)  │         │                     │
     │  • CICS online      │         │  • TRANCATG.VSAM.KSDS (categories)  │         │  • REWARDSCALC      │
     │  • Batch: POSTTRAN  │         │  • CARDXREF.VSAM.KSDS (card→acct)   │         │  • Points / balance  │
     │    INTCALC, COMBTRAN│         │  (or: TRANSACT.BKUP / EXPORT.DATA)   │         │  • Statements       │
     │  • Accounts, cards  │         │                                     │         │                     │
     │    transactions     │         │  One-way: CardDemo → Glue → Rewards  │         │                     │
     └─────────────────────┘         └─────────────────────────────────────┘         └─────────────────────┘
```

**Glue = shared datasets** (VSAM or sequential) that CardDemo writes and Rewards reads. No API or message queue required; batch job ordering (Rewards after COMBTRAN) is the integration.

---

## Big Picture: CardDemo + New Rewards System

```
                              ╔═══════════════════════════════════════════════════════════════════════════════╗
                              ║                    CARDDEMO (Legacy) + REWARDS (New System)                   ║
                              ╚═══════════════════════════════════════════════════════════════════════════════╝

     ┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
     │                              CARDDEMO – LEGACY MAINFRAME                                              │
     └─────────────────────────────────────────────────────────────────────────────────────────────────────┘

     ┌──────────────────────┐                    ┌──────────────────────┐                    ┌──────────────────────┐
     │   ONLINE (CICS)      │                    │   BATCH (JCL)         │                    │   EXTERNAL INPUT      │
     │                      │                    │                      │                    │                      │
     │  • Sign-on (CC00)    │                    │  POSTTRAN            │                    │  DALYTRAN.PS         │
     │  • Accounts, Cards   │                    │  INTCALC             │◄───────────────────│  (daily transactions) │
     │  • Transactions      │                    │  TRANBKP             │                    │                      │
     │  • Bill payment      │                    │  COMBTRAN            │                    └───────────┬──────────┘
     │  • Reports           │                    │  CREASTMT            │                                  │
     │  • Admin / Users     │                    │  TRANREPT            │                                  │
     └──────────┬───────────┘                    └──────────┬───────────┘                                  │
                │                                           │                                               │
                │         READ/WRITE                         │         READ/WRITE                            │
                ▼                                           ▼                                               ▼
     ╔═══════════════════════════════════════════════════════════════════════════════════════════════════════╗
     ║                           SHARED DATA (VSAM + SEQUENTIAL)                                            ║
     ║                                                                                                       ║
     ║   MASTERS                 TRANSACTIONS              REFERENCE              OUTPUT                     ║
     ║   ────────                ─────────────             ──────────             ───────                    ║
     ║   CUSTDATA.VSAM.KSDS      TRANSACT.VSAM.KSDS  ◄───   TRANTYPE.VSAM.KSDS    DALYREJS                   ║
     ║   ACCTDATA.VSAM.KSDS      (posted trans)            TRANCATG.VSAM.KSDS    STATEMNT.PS / .HTML        ║
     ║   CARDDATA.VSAM.KSDS      TCATBALF.VSAM.KSDS         DISCGRP.VSAM.KSDS     TRANREPT                   ║
     ║   CARDXREF.VSAM.KSDS      SYSTRAN (interest)        TRANTYPE.PS           EXPORT.DATA                ║
     ║                          TRANSACT.BKUP              TRANCATG.PS           TRANSACT.COMBINED          ║
     ╚═══════════════════════════════════════════════════════════════════════════════════════════════════════╝
                │                                           │
                │         READ ONLY (no write back)         │
                ▼                                           ▼
     ┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
     │                         NEW SYSTEM – REWARDS / LOYALTY (Downstream)                                   │
     └─────────────────────────────────────────────────────────────────────────────────────────────────────┘

     ┌──────────────────────┐                    ┌──────────────────────┐
     │   REWARDS BATCH      │                    │   REWARDS DATA       │
     │   (new COBOL/JCL)    │                    │   (new VSAM/DB2)    │
     │                      │                    │                      │
     │  REWARDSCALC         │   ─────────────►  │  REWARDS.POINTS      │
     │  • Read TRANSACT     │   points activity  │  REWARDS.BALANCE     │
     │  • Read TRANTYPE     │                    │  REWARDS.STATEMENT    │
     │  • Read TRANCATG     │                    │  (optional)          │
     │  • Apply points rules│                    │                      │
     │  • Write points      │                    │                      │
     └──────────────────────┘                    └──────────────────────┘

     ┌──────────────────────┐
     │   REWARDS ONLINE     │   (optional – future)
     │   • View points      │
     │   • Redeem           │
     │   • Rewards statement│
     └──────────────────────┘


     ═══════════════════════════════════════════════════════════════════════════════════════════════════════
     DATA FLOW SUMMARY
     ═══════════════════════════════════════════════════════════════════════════════════════════════════════

       [External]                    [CardDemo]                         [New Rewards]
            │                             │                                    │
            │  DALYTRAN.PS                │                                    │
            │  (daily trans)              │                                    │
            ├────────────────────────────►│  POSTTRAN → INTCALC → COMBTRAN     │
            │                             │       │                            │
            │                             │       │  TRANSACT.VSAM.KSDS        │
            │                             │       │  TRANTYPE.VSAM.KSDS        │
            │                             │       │  TRANCATG.VSAM.KSDS        │
            │                             │       │  CARDXREF.VSAM.KSDS        │
            │                             │       ▼                            │
            │                             │  ────────────────────────────────►│  REWARDSCALC (read)
            │                             │                                    │
            │                             │                                    │  REWARDS.POINTS
            │                             │                                    │  REWARDS.BALANCE
            │                             │                                    ▼
            │                             │                              (points ledger,
            │                             │                               statements)

     ═══════════════════════════════════════════════════════════════════════════════════════════════════════
```

- **CardDemo** stays the system of record for accounts, cards, and transactions.
- **Rewards** runs **after** CardDemo batch (after COMBTRAN); it **only reads** CardDemo VSAM (or sequential backup/export) and writes to **its own** Rewards files.
- No write-back from Rewards into CardDemo; integration is one-way (CardDemo → Rewards).

---

## 1. Integration Options (Where Rewards Can Hook In)

A Rewards system can consume CardDemo data in three main ways:

| Option | Source | When data is available | Best for |
|--------|--------|------------------------|----------|
| **A. After POSTTRAN** | Transaction VSAM + type/category VSAM | After daily posting | Real-time or same-day batch rewards |
| **B. After COMBTRAN** | Combined transaction VSAM (full picture) | After interest + combine | End-of-day rewards on full ledger |
| **C. Export / sequential** | EXPORT file or TRANSACT.BKUP / TRANSACT.DALY | After TRANBKP or CBEXPORT | Off-mainframe or separate region |

Recommended for a **batch Rewards job**: run **after COMBTRAN** (and optionally after CREASTMT), reading the **transaction master VSAM** plus **TRANTYPE** and **TRANCATG** VSAM for category rules.

---

## 2. Batch Data Flow Sequence (CardDemo + Rewards)

```
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │  CARDDEMO BATCH (existing)                                                   │
  └─────────────────────────────────────────────────────────────────────────────┘

  CLOSEFIL → ACCTFILE/CARDFILE/XREFFILE/CUSTFILE → TRANBKP → TRANCATG/TRANTYPE
       → DISCGRP → TCATBALF
              ↓
  POSTTRAN (CBTRN02C)
    • Reads:  DALYTRAN.PS, TRANFILE (TRANSACT.VSAM.KSDS), XREFFILE, ACCTFILE, TCATBALF
    • Writes: TRANFILE (TRANSACT.VSAM.KSDS), TCATBALF, ACCTFILE; DALYREJS(+1)
              ↓
  INTCALC (CBACT04C)
    • Reads:  TCATBALF, XREFFILE, ACCTFILE, DISCGRP
    • Writes: SYSTRAN(+1) [system interest/fee transactions]
              ↓
  TRANBKP (IDCAMS REPRO)
    • REPRO TRANSACT.VSAM.KSDS → TRANSACT.BKUP(+1)
              ↓
  COMBTRAN (SORT + IDCAMS)
    • SORT:   TRANSACT.BKUP(0) + SYSTRAN(0) → TRANSACT.COMBINED(+1)
    • REPRO:  TRANSACT.COMBINED(+1) → TRANSACT.VSAM.KSDS
              ↓
  CREASTMT (optional) – statements
  TRANREPT (optional) – transaction report
  TRANIDX  – rebuild AIX on TRANSACT
  OPENFIL

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │  REWARDS DOWNSTREAM (new)                                                    │
  └─────────────────────────────────────────────────────────────────────────────┘

  REWARDSCALC (new job)  ← RUN AFTER COMBTRAN (and optionally after TRANBKP)
    • Reads:  TRANSACT.VSAM.KSDS (or TRANSACT.BKUP(0) / TRANSACT.COMBINED(0))
    • Reads:  TRANTYPE.VSAM.KSDS, TRANCATG.VSAM.KSDS  [points per type/category]
    • Reads:  CARDXREF.VSAM.KSDS (optional: card → cust/acct for statement)
    • Writes: REWARDS.POINTS.VSAM.KSDS (or sequential REWARDS.POINTS.PS)
    • Writes: REWARDS.STATEMENT.PS (optional)
```

So the **sequence** for Rewards is:

1. Let CardDemo run: **POSTTRAN → INTCALC → TRANBKP → COMBTRAN** (and CREASTMT/TRANREPT if needed).
2. Run **REWARDSCALC** after COMBTRAN (and after TRANIDX if you use the AIX for “by card” access).
3. Optionally run Rewards after **CBEXPORT** and consume **EXPORT.DATA** (e.g. for a different platform).

---

## 3. Exact VSAM and Sequential Files (CardDemo)

HLQ used below: **AWS.M2.CARDDEMO** (replace with your HLQ if different).

### 3.1 Files Rewards Needs (primary)

| Purpose | Dataset name | DD name in JCL | Type | Key / LRECL | Copybook |
|---------|--------------|----------------|------|-------------|----------|
| **Transaction master** | AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS | TRANFILE or TRANSACT | VSAM KSDS | Key: TRAN-ID (16 bytes) | CVTRA05Y |
| **Transaction type** | AWS.M2.CARDDEMO.TRANTYPE.VSAM.KSDS | TRANTYPE | VSAM KSDS | Key: 2 bytes (TRAN-TYPE) | CVTRA03Y |
| **Transaction category** | AWS.M2.CARDDEMO.TRANCATG.VSAM.KSDS | TRANCATG | VSAM KSDS | Key: 6 bytes (TRAN-TYPE-CD + TRAN-CAT-CD) | CVTRA04Y |
| **Card xref** (optional) | AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS | XREFFILE / CARDXREF | VSAM KSDS | Key: XREF-CARD-NUM (16) | CVACT03Y |
| **Account** (optional) | AWS.M2.CARDDEMO.ACCTDATA.VSAM.KSDS | ACCTFILE | VSAM KSDS | Key: ACCT-ID (11) | CVACT01Y |

### 3.2 Alternative sequential inputs (no VSAM read)

| Purpose | Dataset name | When created | Record layout |
|---------|--------------|--------------|----------------|
| **Transaction backup** | AWS.M2.CARDDEMO.TRANSACT.BKUP(+1) | TRANBKP | Same as TRAN (CVTRA05Y), LRECL 350 |
| **Combined transactions** | AWS.M2.CARDDEMO.TRANSACT.COMBINED(+1) | COMBTRAN SORT | Same as TRAN, LRECL 350 |
| **Date-filtered trans** | AWS.M2.CARDDEMO.TRANSACT.DALY(+1) | TRANREPT SORT step | Same as TRAN, LRECL 350 |
| **Export (all entities)** | AWS.M2.CARDDEMO.EXPORT.DATA | CBEXPORT | CVEXPORT (multi-type: C/A/X/T/D), LRECL 500 |

### 3.3 Other VSAM files (reference – not required for basic Rewards)

| Dataset | DD name | Type | Use in CardDemo |
|---------|---------|------|------------------|
| AWS.M2.CARDDEMO.TCATBALF.VSAM.KSDS | TCATBALF | VSAM KSDS | Category balance (POSTTRAN, INTCALC) |
| AWS.M2.CARDDEMO.ACCTDATA.VSAM.KSDS | ACCTFILE | VSAM KSDS | Account master |
| AWS.M2.CARDDEMO.CARDDATA.VSAM.KSDS | CARDFILE | VSAM KSDS | Card master |
| AWS.M2.CARDDEMO.CUSTDATA.VSAM.KSDS | CUSTFILE | VSAM KSDS | Customer master |
| AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS | XREFFILE | VSAM KSDS | Card–cust–acct xref |
| AWS.M2.CARDDEMO.DISCGRP.VSAM.KSDS | DISCGRP | VSAM KSDS | Disclosure/interest group |
| AWS.M2.CARDDEMO.TRANSACT.VSAM.AIX | (PATH) | AIX | Alternate index (e.g. by card) |
| AWS.M2.CARDDEMO.TRXFL.VSAM.KSDS | TRNXFILE | VSAM KSDS | Trans by card (for statements), key 32 bytes |

### 3.4 Sequential files in main flow

| Dataset | DD name | Created by | Content |
|---------|---------|------------|---------|
| AWS.M2.CARDDEMO.DALYTRAN.PS | DALYTRAN | (input) | Daily transactions input to POSTTRAN |
| AWS.M2.CARDDEMO.DALYREJS(+1) | DALYREJS | POSTTRAN | Rejected transactions |
| AWS.M2.CARDDEMO.SYSTRAN(+1) | TRANSACT (out) | INTCALC | System transactions (interest/fees) |
| AWS.M2.CARDDEMO.TRANTYPE.PS | TRANTYPE | (source) | Flat file loaded into TRANTYPE VSAM |
| AWS.M2.CARDDEMO.TRANCATG.PS | TRANCATG | (source) | Flat file loaded into TRANCATG VSAM |

---

## 4. Record Layouts (Rewards-relevant)

### 4.1 TRAN record (CVTRA05Y) – LRECL 350

```
TRAN-RECORD
  TRAN-ID           PIC X(16)
  TRAN-TYPE-CD      PIC X(02)    ← link to TRANTYPE
  TRAN-CAT-CD       PIC 9(04)    ← link to TRANCATG (with TRAN-TYPE-CD)
  TRAN-SOURCE       PIC X(10)
  TRAN-DESC         PIC X(100)
  TRAN-AMT         PIC S9(09)V99
  TRAN-MERCHANT-ID  PIC 9(09)
  TRAN-MERCHANT-NAME PIC X(50)
  TRAN-MERCHANT-CITY PIC X(50)
  TRAN-MERCHANT-ZIP  PIC X(10)
  TRAN-CARD-NUM     PIC X(16)    ← link to CARDXREF
  TRAN-ORIG-TS      PIC X(26)
  TRAN-PROC-TS      PIC X(26)
  FILLER            PIC X(20)
```

Rewards logic: use **TRAN-TYPE-CD** and **TRAN-CAT-CD** to look up points rules; use **TRAN-AMT** and **TRAN-CARD-NUM** (or account via XREF) to accumulate points per card/account.

### 4.2 TRAN-TYPE record (CVTRA03Y) – LRECL 60

```
TRAN-TYPE-RECORD
  TRAN-TYPE         PIC X(02)    ← key
  TRAN-TYPE-DESC    PIC X(50)
  FILLER            PIC X(08)
```

### 4.3 TRAN-CAT record (CVTRA04Y) – LRECL 60

```
TRAN-CAT-RECORD
  TRAN-CAT-KEY
    TRAN-TYPE-CD    PIC X(02)
    TRAN-CAT-CD     PIC 9(04)
  TRAN-CAT-TYPE-DESC PIC X(50)
  FILLER            PIC X(04)
```

Rewards: add a **points-per-dollar** (or per category) table keyed by (TRAN-TYPE-CD, TRAN-CAT-CD) — either in a new Rewards VSAM/DB2 or in an extended TRANCATG layout.

---

## 5. Suggested Rewards Job (JCL sketch)

```jcl
//REWARDSCALC JOB 'Rewards Calculation',CLASS=A,MSGCLASS=0,NOTIFY=&SYSUID
//STEP1    EXEC PGM=REWARDSC
//STEPLIB  DD   DSN=AWS.M2.CARDDEMO.LOADLIB,DISP=SHR
//TRANFILE DD   DISP=SHR,DSN=AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS
//TRANTYPE DD   DISP=SHR,DSN=AWS.M2.CARDDEMO.TRANTYPE.VSAM.KSDS
//TRANCATG DD   DISP=SHR,DSN=AWS.M2.CARDDEMO.TRANCATG.VSAM.KSDS
//XREFFILE DD   DISP=SHR,DSN=AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS
//REWARDS  DD   DISP=SHR,DSN=AWS.M2.CARDDEMO.REWARDS.POINTS.VSAM.KSDS
//SYSOUT   DD   SYSOUT=*
```

- **TRANFILE**: read all posted transactions (sequential read of VSAM or use TRANSACT.BKUP(0) as sequential).
- **TRANTYPE / TRANCATG**: random read by (TRAN-TYPE-CD) and (TRAN-TYPE-CD, TRAN-CAT-CD) to get descriptions and to drive points rules.
- **XREFFILE**: optional; resolve TRAN-CARD-NUM to CUST-ID/ACCT-ID for statement or tier logic.
- **REWARDS**: Rewards system’s own VSAM (or sequential) for points balance and/or activity.

---

## 6. Summary

| Question | Answer |
|----------|--------|
| **Sequence of data flow** | POSTTRAN → INTCALC → TRANBKP → COMBTRAN [→ CREASTMT / TRANREPT]; **Rewards after COMBTRAN** (or after TRANBKP if using backup file). |
| **Exact VSAM files for Rewards** | **TRANSACT.VSAM.KSDS** (transactions), **TRANTYPE.VSAM.KSDS** (type), **TRANCATG.VSAM.KSDS** (category). Optional: **CARDXREF.VSAM.KSDS**, **ACCTDATA.VSAM.KSDS**. |
| **Exact sequential alternative** | **TRANSACT.BKUP(0)** or **TRANSACT.COMBINED(0)** (LRECL 350, CVTRA05Y); or **EXPORT.DATA** (CVEXPORT, record type 'T' for transactions). |
| **Copybooks** | **CVTRA05Y** (TRAN), **CVTRA03Y** (TRAN-TYPE), **CVTRA04Y** (TRAN-CAT), **CVACT03Y** (CARD-XREF). |

This gives you the **possible integration**, **sequence of data flow**, and **exact VSAM (and sequential) files** to tie a Rewards/Loyalty downstream system to CardDemo.
