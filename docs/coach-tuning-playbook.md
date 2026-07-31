# Coach-Tuning-Playbook — der wöchentliche Lern-Loop

> Ziel dieses Docs: die Datenquelle der Wahrheit für alles, was den Auto-Modus-Lehrer
> ("Coach") steuert — welche Metriken zählen, was jedes Event genau enthält, welche
> SQL-Abfragen wir jede Woche laufen lassen, wie wir von einem Symptom auf einen
> Parameter schließen, und wie wir diesen Parameter dann remote ändern.
>
> Gehört zu: [auto-mode-design.md](./auto-mode-design.md) · [auto-mode-roadmap.md](./auto-mode-roadmap.md)
> Tabellen/Views: `supabase/migrations/20260723184814_coach_lab_telemetry.sql` (Tabellen),
> `supabase/migrations/20260723185637_coach_lab_metric_views.sql` (Views für diesen Loop).

---

## 1. Die 4 Kernmetriken

Aus der Roadmap („Erfolgsmetriken"). Das und nur das ist die Messlatte für den Lehrer —
**explizit nicht** XP oder Session-Anzahl.

| Metrik | Definition | Ziel-Richtung | View |
|---|---|---|---|
| **Schwellen-Rate** | Anteil `session_start`, denen ein `first_chord_played` folgt — kam überhaupt ein Ton heraus? | ↑ (Ziel > 90 %) | `v_coach_threshold` |
| **Time-to-Mastery** | Ø/Median Übungszeit bis eine Skill-Unit `mastered` (= `coach_decision.decision='promoted'`) erreicht | ↓ über Parameter-Iterationen | `v_coach_time_to_mastery` |
| **Wiederkehr-Rate** | D1/D7-Return anonymer Devices, gemessen ab der ersten Aktivitätswoche (Kohorte) | ↑ | `v_coach_retention` |
| **Completion-Rate** | Anteil Sessions mit `completedBlocks = totalBlocks` vs. Abbruch mitten im Block (`quit_midblock`) | ↑ (Abbruch im „Neu"-Block = zu schwer) | `v_coach_completion` |
| **Feedback-Ventil** | Verteilung der `feedback_valve`-Signale (`tooEasy` / `justRight` / `tooHard`) | „justRight" > 70 % | `v_coach_feedback` |

Alle vier Views liegen in Schema `public`, sind aber **nicht** für `anon`/`authenticated`
lesbar — nicht weil die Views selbst RLS hätten (Postgres-Views haben keine eigene RLS),
sondern weil die zugrundeliegende Tabelle `coach_events` per RLS nur `INSERT` für
`anon`/`authenticated` erlaubt (siehe `20260723184814_coach_lab_telemetry.sql`). Jede
`SELECT` durch die Views scheitert für diese Rollen automatisch. Gelesen wird ausschließlich
mit `service_role` — Supabase SQL Editor, ein Server-Job, oder das `execute_sql`-MCP-Tool.

---

## 2. Event-Payload-Vertrag (verbindlich, Quelle der Wahrheit)

`coach_events(id, device_id, user_id?, ts, app 'web'|'ios', version, cohort, event_type, payload jsonb)`

Jeder `event_type` hat ein festes `payload`-Schema. Neue Felder dürfen ergänzt werden,
bestehende Feldnamen/Typen NICHT stillschweigend geändert werden (sonst brechen die Views
oben und alle Wochen-Queries unten rückwirkend).

| event_type | payload |
|---|---|
| `session_start` | `{ estMinutes, blocks: ["warmup",...], frontierUnitId, dayIndex }` |
| `first_chord_played` | `{ kind, blockIdx, input: "none"\|"midi"\|"mic"\|…, msSinceSessionStart? }` |
| `block_result` | `{ kind, unitId?, chords, avgMs, correctRate?, completed: boolean }` |
| `session_end` | `{ durationMs, totalChords, avgMs, completedBlocks, totalBlocks, frontierUnitId }` |
| `coach_decision` | `{ decision: "promoted"\|"held"\|"demoted"\|"placed", unitId }` |
| `feedback_valve` | `{ signal: "tooEasy"\|"justRight"\|"tooHard" }` |
| `quit_midblock` | `{ kind, atChord, targetChords }` |
| `calibration_result` | `{ placedUnits, frontierIndex }` |

`kind` (in `block_result` / `quit_midblock`) ist einer der Block-Typen aus dem Composer:
`warmup`, `review`, `focus`, `new`, `apply` (siehe `auto-mode-design.md`, Abschnitt 2.3).

---

## 3. Fertige SQL-Snippets für den Wochen-Check

Alle Snippets gegen die vier Views aus `20260723185637_coach_lab_metric_views.sql`.
Als `service_role` ausführen (Supabase SQL Editor oder `execute_sql` MCP-Tool).

### 3.1 Time-to-Mastery — pro Unit, letzte 4 Wochen

```sql
select distinct on (unit_id)
  unit_id,
  mastery_count_per_unit as n_promotions,
  avg_time_to_mastery_per_unit,
  median_time_to_mastery_per_unit
from v_coach_time_to_mastery
where promoted_ts >= now() - interval '28 days'
order by unit_id, median_time_to_mastery_per_unit desc;
```

Auffällig: Units mit deutlich höherem Median als der Rest der Leiter — Kandidat für
zu strenge Mastery-Schwelle oder zu kleinen Pool in diesem Bereich.

### 3.2 Retention — letzte 8 Kohorten-Wochen

```sql
select cohort_week, cohort_size, d1_return_rate, d7_return_rate
from v_coach_retention
where cohort_week >= now() - interval '8 weeks'
order by cohort_week desc;
```

Trend prüfen: sinkt `d1_return_rate` nach einer Parameter-Änderung, war die Änderung
wahrscheinlich zu aggressiv (Session fühlte sich schlechter an).

### 3.3 Completion — aktuelle Woche vs. Vorwoche, je Block-Art

```sql
select week, quit_block_kind, quit_count, block_result_count, quit_rate
from v_coach_completion
where week >= now() - interval '14 days'
  and quit_block_kind is not null
order by week desc, quit_rate desc nulls last;

-- Gesamt-Completion-Rate der letzten beiden Wochen (ein Wert pro Woche, quit_block_kind ignorieren):
select distinct week, total_sessions, fully_completed_sessions, completion_rate
from v_coach_completion
where week >= now() - interval '14 days'
order by week desc;
```

Roadmap-Faustregel: hohe `quit_rate` speziell bei `kind = 'new'` bedeutet „zu schwer",
nicht „Nutzer hat generell keine Zeit" (das würde alle `kind`s gleichmäßig treffen).

### 3.4 Feedback-Ventil — aktuelle Woche + Gesamt-Baseline

```sql
select week, signal, signal_count, week_total, share_of_week
from v_coach_feedback
where week = date_trunc('week', now())
   or week is null  -- null = Gesamt-Baseline über alle Wochen
order by week nulls last, signal;
```

Ziel: `share_of_week` für `signal = 'justRight'` > 0.70. Prüfen ob `tooEasy` oder
`tooHard` dominiert — bestimmt die Richtung der Parameter-Korrektur (siehe Diagnose-Tabelle).

---

## 4. Diagnose-Tabelle: Symptom → Ursache → Parameter

Parameter-Namen exakt aus `src/lib/engine/coach-params.ts` (`CoachParams`, Defaults in
`DEFAULT_COACH_PARAMS`). Immer nur **einen** Parameter je Iteration ändern (siehe Regel 6).

| Symptom (aus den Views) | Wahrscheinliche Ursache | Parameter in `coach-params.ts` | Richtung |
|---|---|---|---|
| Hohe `quit_midblock`-Rate im `new`-Block | Frontier-Unit zu schwer / Guided-Anteil zu klein | `promotionRatio` zu lax (Units werden zu früh als "kann er schon" behandelt) **oder** `blockMix.new` zu hoch (zu viel ungewohnter Stoff am Stück) | `promotionRatio` ↓ (strenger) **oder** `blockMix.new` ↓ |
| Viel `feedback_valve: "tooEasy"` | Schwierigkeit zieht Nutzer nicht mit | `masteryThresholdMs` zu hoch (zu leicht als "gemastert" gewertet) **oder** `promotionRatio` zu hoch (zu schnelle Beförderung) | `masteryThresholdMs` ↓ **oder** `promotionRatio` ↓ (strenger, wirkt hier gegenläufig zu Zeile 1 — siehe Hinweis unten) |
| Viel `feedback_valve: "tooHard"` | Schwierigkeit überfordert | `masteryThresholdMs` zu niedrig (zu strenge Latte) **oder** `weights.focus` zu hoch (zu viel Drill auf Schwachpunkt) | `masteryThresholdMs` ↑ **oder** `weights.focus` ↓ |
| Time-to-Mastery steigt für neue Units, obwohl `tooHard` nicht auffällig steigt | Mastery-Fenster zu groß / verlangt zu viele gute Versuche in Folge | `masteryWindow` zu groß **oder** `promotionRatio` zu hoch | `masteryWindow` ↓ **oder** `promotionRatio` ↓ |
| Häufige Demotions direkt nach Promotion ("Pendeln") | Demotion greift zu schnell nach vereinzelten Ausreißern | `demotionAfterHolds` zu niedrig | `demotionAfterHolds` ↑ |
| Niedrige D1/D7-Retention bei sonst guter Completion | Session fühlt sich nicht lohnend/kurzweilig an, nicht unbedingt "zu schwer" | `blockMix` unausgewogen (z. B. zu wenig `warmup`/`apply` = wenig Erfolgserlebnis) | `blockMix.warmup` ↑ und/oder `blockMix.apply` ↑ (bei gleichzeitiger Reduktion von `new`) |
| Review-Block wird oft mitten drin verlassen | SRS-Fälligkeiten stauen sich zu einem großen, ermüdenden Review-Batch | `blockMix.review` zu hoch für die Session-Länge | `blockMix.review` ↓ **oder** `shortSessionCutoffMin` prüfen (evtl. zu hoch, sodass Review in kurzen Sessions nicht rausfällt) |
| Onboarding: neue Nutzer landen zu oft auf Units, die für sie trivial sind | Kalibrierung stuft zu konservativ ein | `calibrationChords` zu niedrig (zu wenig Datenpunkte für Placement) | `calibrationChords` ↑ |
| Feedback-Ventil-Tap ändert spürbar nichts an der nächsten Session | Bias-Schritt zu klein oder Clamp zu eng | `feedbackBiasStep` zu niedrig **oder** `feedbackBiasClamp` zu eng | `feedbackBiasStep` ↑ und/oder `feedbackBiasClamp` ↑ |
| Nutzer mit gerissenem Übungs-Rhythmus (SRS-Lapse) bekommen keine spürbare Konsequenz | `srsLapseDemotes` steht auf `false` oder Demotion zu milde | `srsLapseDemotes` | auf `true` setzen |
| Blöcke fühlen sich zu kurz/abgehackt an (Nutzer beschwert sich implizit über viele Mini-Blöcke) | Chord-Budget pro Block zu knapp berechnet | `chordsPerMinute` zu hoch **oder** `minBlockChords` zu niedrig | `chordsPerMinute` ↓ und/oder `minBlockChords` ↑ |

**Hinweis zu Zeile 1 vs. Zeile 2:** `promotionRatio` wirkt gegenläufig auf `quit_midblock`
im `new`-Block und auf `tooEasy`-Feedback. Bei widersprüchlichem Symptombild (hohe
Quit-Rate im `new`-Block UND viel `tooEasy`) zuerst `blockMix.new` bzw. `masteryThresholdMs`
anfassen statt `promotionRatio` — das trennt die beiden Ursachen sauberer.

---

## 5. Einen Parameter per `coach_config` überschreiben

`coach_config(id, key, value jsonb, cohort text default 'default', active boolean default true)`,
`unique (key, cohort)`. Der Client liest per `key='coach-params', cohort='default'` (oder
einem A/B-Kohorten-Namen, sobald Kohorten ab M2 aktiviert sind) und merged `value` über die
Defaults aus `DEFAULT_COACH_PARAMS` — `value` muss deshalb **nicht** alle Felder enthalten,
nur die geänderten.

RLS erlaubt `anon`/`authenticated` nur `SELECT` auf `active = true`-Zeilen — Schreiben
geht ausschließlich über `service_role`.

### Beispiel: `masteryThresholdMs` von 2000 auf 2200 senken/anheben

**Erstmaliges Anlegen der Zeile** (falls für `cohort='default'` noch keine existiert):

```sql
insert into coach_config (key, value, cohort, active)
values (
  'coach-params',
  '{"masteryThresholdMs": 2200}'::jsonb,
  'default',
  true
);
```

**Update, falls die Zeile schon existiert** — nur den einen Schlüssel im JSON ändern,
Rest des `value`-Objekts unangetastet lassen:

```sql
update coach_config
set value = jsonb_set(value, '{masteryThresholdMs}', '2200'::jsonb)
where key = 'coach-params' and cohort = 'default';
```

**Mehrere Felder in einem Zug** (nur nötig, wenn Regel 6 unten bewusst gebrochen wird,
z. B. bei einem Rollback auf einen bekannten guten Zustand):

```sql
update coach_config
set value = value || '{"masteryThresholdMs": 2200, "promotionRatio": 0.75}'::jsonb
where key = 'coach-params' and cohort = 'default';
```

**Zurücksetzen auf Default** (Schlüssel aus `value` entfernen, damit der Client-Default wieder greift):

```sql
update coach_config
set value = value - 'masteryThresholdMs'
where key = 'coach-params' and cohort = 'default';
```

**Prüfen, was aktuell aktiv ist:**

```sql
select key, cohort, value, active from coach_config where key = 'coach-params';
```

---

## 6. Regel: eine Änderung, eine Woche, dokumentiert

1. **Immer nur einen Parameter pro Iteration ändern.** Bei mehreren gleichzeitigen
   Änderungen lässt sich der Effekt in den Views nicht mehr einem Symptom zuordnen.
2. **Mindestens 1 Woche wirken lassen**, bevor die nächste Änderung kommt — die Views
   sind wochenbasiert (`date_trunc('week', ts)`), kürzere Fenster sind zu verrauscht bei
   aktuell kleinem N (siehe `auto-mode-roadmap.md`, „Experimentier-Strategie": Kohorten-A/B
   erst ab ~200 wöchentlich aktiven Devices).
3. **Vorher/Nachher-Werte der 4 Kernmetriken notieren** (Abschnitt 1) — nicht nur
   die eine Metrik, die den Ausschlag gab. Ein Parameter kann eine Metrik verbessern und
   eine andere verschlechtern (siehe Hinweis zu `promotionRatio` in Abschnitt 4).

### Änderungs-Log

Neue Zeile pro Iteration anhängen, nie überschreiben — das ist die Historie.

| Datum | Parameter | Alt → Neu | Symptom (Auslöser) | Metriken vorher (TTM / D1 / D7 / Completion / justRight%) | Metriken nach 1 Woche | Behalten? |
|---|---|---|---|---|---|---|
| _(Beispielzeile, beim ersten echten Tuning entfernen)_ 2026-08-03 | `masteryThresholdMs` | 2000 → 2200 | `tooHard`-Anteil 42 % | TTM Ø 6.5 Tage / D1 38 % / D7 61 % / Completion 74 % / justRight 55 % | TTM Ø _tbd_ / D1 _tbd_ / D7 _tbd_ / Completion _tbd_ / justRight _tbd_ | _tbd_ |

---

## 7. Offene Punkte

- Kohorten-A/B (`coach_config.cohort` ≠ `'default'`) ist in den Views bewusst noch nicht
  berücksichtigt — sobald M2-Traffic-Schwelle (~200 WAU) erreicht ist, brauchen alle vier
  Views zusätzlich `cohort` als Gruppierungsspalte (aus `coach_events.cohort`).
- `v_coach_completion.quit_rate` nähert „Block-Versuche" über die Zahl der `block_result`-
  Zeilen dieser `kind` in derselben Woche an (ein abgebrochener Block erzeugt i. d. R. noch
  keinen `block_result`, ein abgeschlossener schon) — das ist eine Näherung, kein exaktes
  Attempt-Tracking pro Block-Instanz. Falls das in der Praxis zu ungenau ist, bräuchte es
  eine `block_id` im Payload, um Start und Ende exakt zu koppeln.
