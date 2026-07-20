# HANDOFF — Power BI Dashboard Build (ChurnEconomics.pbix)

## STATUS: COMPLETE — all three pages built, verified and saved (2026-07-20)

All work described below is finished. Nothing remains except the one thing that cannot be
delegated: **a human opening the file and eyeballing it.** If you are picking this up in a new
session, do not rebuild anything — open the pbix and look at it.

---

## Project

Building the 3-page Power BI report specified in `powerbi/DASHBOARD_BRIEF.md` (read it in full — it is the spec), **entirely by GUI in Power BI Desktop** via computer-use (user's explicit choice), on the user's Windows laptop.

- **Report file (exists, saved):** `C:\Users\IC Clearwater\OneDrive\Documents\GitHub\Customer_Lifetime_Value_Churn_Prediction\powerbi\ChurnEconomics.pbix`
- **Theme file (exists, applied):** `powerbi/theme_churn_economics.json` (dark #0d0d0d/#1a1a19, blue #3987e5 = value created, red #e66767 = value destroyed, muted #c3c2b7 / #898781)
- Open the pbix in Power BI Desktop. In a new session: request_access for "Power BI Desktop" + "File Explorer", clipboardWrite+clipboardRead: true. Launch app, click ChurnEconomics.pbix in the recent list (top item).
- **SAVE (ctrl+s) after every completed visual.** An earlier unsaved session was lost once.
- All acceptance-check numbers were re-verified against the CSVs with pandas this session — every figure in brief §8 is correct in the data.

## State of the file — DONE, verified on screen, SAVED

1. **Data:** `customer_export` (7,043 rows) + `sensitivity_export` (8 rows), NO relationship (correct — never create one).
2. **`_Measures` table** holds all 27 measures (built via TMDL view earlier). Data categories set for latitude/longitude.
3. **Page 1 "Executive Summary" — COMPLETE** (title, 5 smart-textbox KPI tiles, return-breakdown column chart, sensitivity line chart, finding textbox).
4. **Page 2 "Segment Drill-Down" — COMPLETE** (canvas 1440×810 custom):
   - Title textbox "Segment drill-down" 22pt white + muted sub-line at (32,20) 500×76.
   - 3 slicers across top, style **Dropdown**, each 84h×272w / 340w: contract (556,16), tenure_band (844,16), spend_band (1132,16).
   - Hero clustered column "Net return by value group, targeted against contacting everyone" at (32,108) 330×880 — X value_decile (categorical), Y: Net if Targeted (blue) + Net if Contact Everyone (red), X-axis title "Value group (1 = most valuable)", Y-axis title off. Deciles 8–10 contrast renders exactly as the brief wants.
   - Matrix "Customers and net return by value group" at (928,108) 262×470: value_decile / Customers / Targeted Customers / Net if Targeted, subtotals off. Verified on screen: decile targeted counts 83/349/138/589/532/363/164/0/0/0.
   - Horizontal bar "Why leavers left — recorded after departure, excluded from the model" at (32,440) 320×620 — churn_reason by Customers, visual-level filters: churn_value = 1 AND Top 10 by Customers. Bars recolored MUTED #898781 (blue/red reserved for money). X-axis title "Customers".
   - Annotation textbox "Where the return sits" (14pt white heading, 11pt muted body, 3 findings from brief §2) at (684,440) 320×724.
   - **Map: intentionally OMITTED.** Map/filled-map visuals are disabled in this Power BI build's tenant/security settings (visual showed "map and filled map visuals are disabled"). User was asked and chose to leave it out (brief calls it the most expendable element). Do NOT try to re-add it.
5. **Page 3 "Model Performance" — ~80% complete** (canvas 1440×810 custom, tab renamed):
   - Title textbox "Model performance" 22pt white + muted note "Every figure on this page comes from the 1,761 held-back customers only — the model never saw them in training." at (32,20) 76h×980w.
   - KPI row, five smart text boxes, each 110h×262w at y=124, x = 32/310/588/866/1144: Recall 78.8% (white) / Precision 50.5% (white) / Accuracy 73.9% (white) / Baseline 73.5% (white) / Test Customers 1,761 (white). Labels 9pt muted under 24pt values.
   - Confusion tiles, four smart text boxes, each 110h×340w at y=262, x = 32/388/744/1100: Caught 368 (BLUE #3987e5) / Missed 99 (RED #e66767) / False alarm 361 (RED) / Correctly left alone 933 (BLUE). All values verified on screen against brief §6 (selected model: 368/99/361/933).
   - Outcome chart: clustered column "Every held-back customer, by outcome" at (32,400) 340×660 — X outcome_class, Y Test Customers measure (already test-filtered, so no extra filter needed). Title set.

## COMPLETED IN THE FINAL SESSION (2026-07-20)

**Page 3 finished:**

1. **Outcome chart per-category colors** — Correctly left alone + Caught = #3987E5, False alarm + Missed = #E66767. Data labels turned ON; they read 933 / 368 / 361 / 99, matching brief §8.
2. **Explanatory textbox "Reading the model honestly"** at (724,400) 340h×684w — 14pt white heading, 11pt muted (#C3C2B7) body. Covers ROC AUC 0.838 being inside the expected range (near 1.0 would point to leakage); accuracy 73.9% barely above the 73.5% baseline, hence precision/recall reported, model still finding ~4 in 5 leavers; ~1 flag in 2 being a false alarm as the limit of predicting from a profile, priced into the economics. Includes the required footnote on the rejected model (370/97/362, recall 79.2%, AUC 0.840).
3. **Confusion tiles re-sized for the 32px margin** — were 4×340w ending flush at canvas x=1440. Now 332w at x = 32/380/728/1076, right edge 1408, matching the KPI row and the explanatory box.

**Page 1 fixes found during verification:**

4. **Return-breakdown chart** — Y-axis title was truncating to "Value Recovered, Contact Cos…"; turned off. `Net if Targeted` series recolored from neutral grey to #3987E5, so the chart now reads blue (recovered) − red (cost) = blue (net), consistent with the brief's colour rule.
5. **Sensitivity chart** — Y-axis title was truncating to "Sens Net Targeted an…"; turned off.
6. **Title textbox** widened 600 → 980 to align its right edge with the subtitle box below it.

**Page 2 fixes found during verification:**

7. **Slicer dropdowns were unreadable** — the popup list rendered on a white background with white value text, so the options were invisible when opened. Fixed on all three slicers: Format → Visual → Values → Background → #1A1A19. Options now legible on the dark surface.
8. **Subtitle was truncating** ("…The slicers filter every visual on"). Rewritten to "Where the return sits, and who to leave alone. Slicers filter this page." — fits the box.

**Verification performed:**

- All brief §8 figures re-checked against the CSVs with pandas AND read off the screen: 7,043 customers / book R2,728,601.64; 2,218 targeted at +R39,662.37; 4,825 left alone at −R183,680.65; contact-everyone −R144,018.28; recovered R172,742.37 less cost R133,080.00; decile targeted counts 83/349/138/589/532/363/164/0/0/0; test set 1,761 = 368/99/361/933; churn_reason non-null 1,869 / null 5,174; sensitivity 8 rows.
- Page 2 slicers tested live (contract = Month-to-month) — hero chart, matrix and churn-reason bar all re-filtered correctly, then reset to All.
- Blue = money made / red = money lost confirmed consistent on all three pages.
- Checked for label collisions, truncation and overlapping visuals; the four items found are fixed above.

**Still outstanding: nothing buildable.** The user should open the pbix and eyeball it — that final human check cannot be delegated.

## LEGIBILITY PASS FOR NON-TECHNICAL READERS (2026-07-20, second session)

A review against all four write-ups with a recruiter's eye found five presentation gaps, all fixed:

1. **The 30% assumption is now marked on the sensitivity curve** (brief §5 required this; it had never been built). Dashed X-axis constant line at 0.3 in muted #898781 via the Analytics pane.
2. **The sensitivity X axis no longer reads `success_rate` in decimals.** Axis title is now "Retention success rate (offer accepted and customer stays)" and the `success_rate` column is formatted as a whole percentage in the model, so ticks read 10%–50% and the marker line falls at 30%.
3. **Raw field names removed from every visual.** Page 2 matrix row header `value_decile` → "Value group" (rename-for-this-visual); Page 3 outcome chart axis `outcome_class` → "Outcome" (axis title text); Page 2 slicer headers `contract` / `tenure_band` / `spend_band` → "Contract" / "Tenure" / "Spend level" (slicer header title text).
4. **Groups 8–10 no longer show blank in the matrix.** `Targeted Customers` and `Net if Targeted` measures had `+ 0` appended so they return 0 / R0 instead of BLANK — a blank read as missing data, when "zero qualify" is Finding 1. This is display coercion, not business logic; the decision column in SQL is untouched. KPI cards verified unchanged (2,218 / R39,662 / −R144,018 / R183,681).
5. Everything re-saved; §8 figures still on screen exactly as before.

## GUI quirks learned the hard way (follow these!)

- **Screen/UI:** 1456×816 screenshots, ~91% zoom. Left rail: Report (16,98), Table (16,128), Model (16,160).
- **Positioning:** never drag visuals. Select → Format pane → General → Properties → Size/Position fields. Textbox pane: Height (1218,281), Width (1218,320), Position header (1223,378), Horizontal (1218,418), Vertical (1218,457). Chart visuals sit one row lower: Height (1218,320), Width (1218,359), Position header (1223,417), H (1218,457), V (1218,496). **Verify after typing — fields sometimes swallow the first entry.**
- **Smart-textbox KPI tile recipe (per tile):** Insert → Text box → click inside → "+ Value" on floating toolbar → type measure name in Q&A box → click the suggestion (NOT the arrow if a suggestion list is showing — clicking the arrow with stale text can concatenate garbage; if the Q&A box ends up with concatenated text, ctrl+a and retype) → verify Result shows the right number → Save → caret sits after the chip on line 1 → press End, then Return, type the label → then format: click into value line, ctrl+Home + shift+Down selects value chip line; set size 24 via floating-toolbar font-size box (triple_click it, type, Return); color via A▾ → palette (White top-left; blue row1col3 #3987E5; red row1col4 #E66767); label line: click in label, Home, shift+End, size 9, color muted (#C3C2B7 via More colors, or Recent colors once used). Escape twice to exit edit mode before positioning.
- **Text-box copy/paste (ctrl+c/v) does NOT duplicate these tiles** — build each fresh. `type` actions paste via clipboard so ctrl+v pastes your last typed string.
- **Slicer style:** Format → Visual → Slicer settings → Options → Style → Dropdown (Tile style clips 3 options at 272w).
- **Chart series colors:** Format → Visual → Columns/Bars → Color; per-category via "Apply settings to → Categories" dropdown. More colors… → hex field, Return.
- **Visual-level filters:** drag field from Data pane onto "Filters on this visual"; Top N: filter type dropdown → Top N, count box, then drag the by-value measure into its well, Apply filter link. Basic filtering for churn_value: type 1 in the search/value box then tick.
- **Adding fields to wells:** search Data pane box (~1387,126), clear with its X (triple-click does NOT clear). Drag onto the exact well; checkbox-ticking can land fields in the wrong well; a wrong drag once created a secondary Y axis (forbidden) — remove and re-drag onto primary Y.
- **Renaming pages:** double-click tab, ctrl+a, Delete, type, Enter.
- **New page canvas:** Format page (paintbrush with page selected, nothing on canvas) → Canvas settings → Type Custom → width 1440 Tab, height 810 Tab.
- **Q&A "Test Customers"** resolves to the _Measures measure (suggestion list top item "Test Customers"). "Caught"/"Missed"/"False Alarms"/"Correctly Left Alone"/"Recall"/"Precision"/"Accuracy"/"Baseline Accuracy" all resolve correctly and match brief numbers (368/99/361/933, 78.8/50.5/73.9/73.5, 1761).
- **Map visuals are DISABLED on this machine** (org/security setting). Do not attempt.
- **Font-size box in the text-box floating toolbar is a `<select>`, not a text field.** Typing a number into it is treated as type-ahead and lands on an unpredictable option (typing "11" produced 10.5, then 12, then 9 on successive tries). Reliable method: triple_click the box, then press Down/Up one step at a time (8, 9, 10, 10.5, 11, 12, 14…), verify the displayed value, then Return. **Never press ctrl+a while the toolbar has focus** — it selects the text-box contents instead, and the next keystroke wipes the whole box.
- **Slicer dropdown popups are not covered by the theme.** A dark-themed slicer with white value text renders its dropdown as white-on-white. Set Format → Visual → Values → Background explicitly (#1A1A19) on every slicer.
- **shift+End only selects to the end of the visual (wrapped) line**, not the end of the logical paragraph. Editing a wrapped subtitle this way leaves a tail behind; use ctrl+End plus BackSpace to trim.
- **Position/Size fields swallow the first entry roughly half the time** (confirmed repeatedly). Always type, Tab, then zoom in on the field to confirm before moving on.

## Key numbers (must match on screen)

7,043 customers; book R2,728,601.64; targeted 2,218 → +R39,662.37; left alone 4,825 → −R183,680.65; contact-everyone −R144,018; swing ≈ R183,681; recovered R172,742.37, cost R133,080; decile targeted 83/349/138/589/532/363/164/0/0/0; test 1,761 = 368 caught / 99 missed / 361 false alarms / 933 correctly left alone; churn_reason non-null 1,869; sensitivity 8 rows, 30% row matches headline; AUC 0.838; rejected-model footnote figures 370/97/362, 79.2%, 0.840.
