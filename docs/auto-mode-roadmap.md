# Auto-Modus („Coach") — Roadmap bis zum fertigen Produkt

> Konzept: siehe [auto-mode-design.md](./auto-mode-design.md).
> Entschieden (2026-07-23, Aaron): **frei für alle** · **anonyme Telemetrie, Opt-out** · **Web zuerst, dann iOS** · volle Roadmap in einem Zug.

**Definition „fertig":** Auto-Modus ist auf Web UND iOS der Default-Einstieg, Telemetrie läuft,
Coach-Parameter sind remote tunebar, und es existiert ein Tuning-Playbook, mit dem wir wöchentlich
aus den Daten lernen, wie der Lehrer besser wird.

---

## Erfolgsmetriken (woran der Lehrer gemessen wird)

| Metrik | Definition | Ziel-Richtung |
|---|---|---|
| **Time-to-Mastery** | Ø Übungszeit bis eine Skill-Unit `mastered` erreicht | ↓ über Parameter-Iterationen |
| **Wiederkehr-Rate** | D1/D7-Return anonymer Devices | ↑ |
| **Completion-Rate** | Sessions beendet vs. mitten im Block abgebrochen | ↑ (Abbruch im „Neu"-Block = zu schwer) |
| **Feedback-Ventil** | Verteilung zu-leicht/passt/zu-schwer | „passt" > 70 % |

Explizit NICHT die Messlatte: XP, Session-Anzahl.

---

## Architektur der neuen Teile

```
src/lib/engine/coach.ts          Skill-Map + Controller + Composer (pure, → Coach.swift)
src/lib/engine/coach-params.ts   Alle Stellschrauben als ein Default-Objekt (remote-overridebar)
src/lib/services/coach-state.ts  Persistenz chord-trainer-coach-state (+ SYNC_KEYS)
src/lib/services/telemetry.ts    Anonyme Events → Supabase, gebatcht, Opt-out-fähig
src/lib/services/coach-config.ts Remote-Config + Kohorten-Zuweisung (Hash der Device-ID)
supabase/migrations/…            coach_events (insert-only RLS), coach_config
docs/coach-tuning-playbook.md    Wöchentlicher Lern-Loop: Queries → Diagnose → Parameter-Änderung
```

### Telemetrie-Schema
`coach_events(id, device_id, user_id?, ts, app 'web'|'ios', version, cohort, event_type, payload jsonb)`
Event-Typen: `session_start`, `block_result`, `session_end`, `coach_decision` (promotion/hold/demotion + Begründung), `feedback_valve`, `quit_midblock`, `calibration_result`.
RLS: anon darf nur INSERT; SELECT nur service_role. Keine Personendaten, Device-ID = zufällige UUID.

### Coach-Parameter (Defaults in `coach-params.ts`, remote überschreibbar)
`masteryThresholdMs 2000 · masteryWindow 20 · promotionRatio 0.8 · demotionAfterHolds 2 ·
blockMix {warmup .15, review .20, focus .25, new .25, apply .15} · shortSessionCutoffMin 8 ·
weights {weak 4, new 2.5, strong 0.3, focus 10} · calibrationChords 12 ·
feedbackBiasStep 0.15 (clamp ±0.5) · srsLapseDemotes true`

### Experimentier-Strategie (ehrlich bei kleinem N)
1. **Jetzt:** Innerhalb des Nutzers lernen (`difficultyBias` aus dem Ventil) + globales Hand-Tuning
   per Playbook-Queries.
2. **Ab genug Traffic:** Kohorten (Device-Hash → A/B) über `coach_config.cohort` — Infrastruktur
   steht ab M2, wird aber erst aktiviert, wenn ~200+ wöchentlich aktive Devices da sind.

---

## Meilensteine & Tasks

Modell-Zuteilung: **[O] = Opus** (groß/riskant), **[S] = Sonnet** (klein/mechanisch). Orchestrierung: Hauptsession.

### M1 — Web-MVP (spielbar)
| # | Task | Modell | Hängt ab von |
|---|---|---|---|
| 1.1 | `coach.ts` + `coach-params.ts` + `coach-state.ts`: Skill-Leiter aus ultimate-plan generiert, Controller (Promotion/Hold/Demotion, Kalibrierungs-Placement), Composer (Block-Liste), Unit-Tests | O | — |
| 1.2 | `progress.ts`: `ChordTiming.correct?`, `SessionResult.blockKind?` (abwärtskompatibel) | S | — |
| 1.3 | Telemetrie-Fundament: Migration (coach_events, coach_config), `telemetry.ts` (Batching, Device-ID, Opt-out), `coach-config.ts` (merged Params) — Migrationsdateien, noch nicht deployed | S | — |
| 1.4 | Train-Page-Integration: Auto-Session-Flow mit Blöcken, Block-Übergangsscreens, correct-Flag-Aufzeichnung, Feedback-Ventil, Lehrer-Feedback-Screen, `applySessionToCoach`-Aufruf | O | 1.1, 1.2 |
| 1.5 | Einstieg: „Weiter üben"-Hero in QuickStart + Coach-Ansage, bestehende Modi unter „Selbst wählen"; i18n de/en für alle Coach-Texte | S | 1.1 (Keys), parallel zu 1.4 nur wenn Dateien disjunkt → läuft NACH 1.4 |

### M2 — Coach-Lab live (lernender Lehrer)
| # | Task | Modell | Hängt ab von |
|---|---|---|---|
| 2.1 | Migration auf Supabase deployen, Telemetrie-Calls in Train-Flow verdrahten, Opt-out-Toggle in Account/Settings | S | 1.3, 1.4 |
| 2.2 | Remote-Config-Fetch beim App-Start (Fallback: Defaults), Kohorten-Feld mitschreiben | S | 1.3 |
| 2.3 | Metrik-Views (`v_time_to_mastery`, `v_retention`, `v_completion`, `v_feedback`) + `docs/coach-tuning-playbook.md` | S | 2.1 |

### M3 — iOS-Parität
| # | Task | Modell | Hängt ab von |
|---|---|---|---|
| 3.1 | `Coach.swift`-Port (1:1, ParityTests analog Bestand), `CoachStore`, StoreKey | O | M1 stabil |
| 3.2 | TodayView-Hero „Weiter üben", TrainerStore-Block-Flow, Feedback-Ventil, Telemetrie iOS | O | 3.1 |

### M4 — Härtung & Rollout
| # | Task | Modell | Hängt ab von |
|---|---|---|---|
| 4.1 | Verifikation: Typecheck/Build/Tests Web, `swift test`, Browser-Durchlauf des kompletten Auto-Flows | Orchestrator | alles |
| 4.2 | Review-Pass (Korrektheit + Vereinfachung) über den gesamten Diff | O | 4.1 |
| 4.3 | Tuning-Loop starten: erste Playbook-Auswertung nach 1 Woche Live-Daten (menschlicher Prozess, wiederkehrend) | Aaron + Claude | Launch |

---

## Risiken & Leitplanken

- **`train/+page.svelte` ist ein 124-KB-Monolith** — Task 1.4 ist der riskanteste Schritt.
  Leitplanke: Auto-Flow als additiver Pfad (eigener State), bestehende Modi dürfen sich nicht ändern.
- **Parity-Pflicht:** Jede spätere Parameter-/Logik-Änderung an `coach.ts` MUSS nach `Coach.swift`
  gespiegelt werden (ParityTests erzwingen das). Deshalb Web-Tuning VOR dem Port (M3 nach M1/M2).
- **Alte Sessions ohne `correct`-Flag:** Mastery-Logik muss mit `undefined` umgehen (nur Timing zählt dann).
- **Dirty Working Tree:** Es liegen unkommittete Änderungen auf `ios/native` — vor dem Merge sauber
  in Feature-Commits trennen.
