# Chord Trainer – Produkt-Roadmap

> Von v0.5.0 zum nachhaltigen Produkt.
> **Stand:** Maerz 2026

---

## Aktuelle Version: 0.5.0

**Was existiert:**
- Speed-Drill Trainer mit 16 Akkord-Typen, 9 Voicings, 4+ Progressions-Modi
- 4 Kurse (Intervals, Shell Voicings, Scale Degrees, Ultimate Plan)
- 3-Phasen-Lektionssystem (Theory → Practice → Challenge)
- Habit-Engine (XP, Levels, Streaks, Smart Goals, Spaced Repetition)
- MIDI + Mikrofon + Click-Piano Input
- Vollstaendige Zweisprachigkeit (DE/EN)
- 12 Routen, 18 Komponenten, 132+ Tests
- 0 TS-Errors, 0 svelte-check Warnings

---

## Q2 2026 — Polish und Content (v0.6 – v0.7)

### Kurse erweitern
- [ ] Rootless Voicings Kurs (A-Form und B-Form)
- [ ] Rhythmisches Training Kurs (In-Time Comping mit Metronom)
- [ ] Ear Training Kurs (Akkorde am Klang erkennen)
- [ ] Mehr Intervall-Lektionen (zusammengesetzte Intervalle)

### QA durcharbeiten
- [ ] Voice Leading + MIDI Validierung abschliessen
- [ ] In-Time Comping ohne MIDI loesen
- [ ] Ear Training Feedback bei falschem Spielen
- [ ] Adaptive Drill Regression-Test
- [ ] Settings-Persistenz (inTimeMode, adaptiveEnabled etc.)

### Tests
- [ ] voice-leading.test.ts schreiben
- [ ] adaptive.test.ts schreiben
- [ ] Integration-Tests fuer Lesson-Flow

### UX-Verbesserungen
- [ ] Touch-Optimierung fuer Mobile Piano
- [ ] Onboarding fuer Erstnutzer (Trainer)
- [ ] Performance-Dashboard ueberarbeiten
- [ ] Ladezeit-Optimierung (basic-pitch Modell lazy loaden)

---

## Q3 2026 — Launch und Wachstum (v0.8 – v0.9)

### Product Hunt Launch
- [ ] Hero-Screenshot und Demo-GIF erstellen
- [ ] Tagline und Description finalisieren
- [ ] Launch durchfuehren (Dienstag/Mittwoch 9:01 CET)
- [ ] Erste 2h aktiv kommentieren

### Content Marketing
- [ ] DEV.to Artikel: "How I Built a MIDI Chord Validator"
- [ ] Reddit Posts: r/JazzPiano, r/WeAreTheMusicMakers, r/webdev
- [ ] Indie Hackers Milestone Post
- [ ] YouTube Demo-Video (3 Min)

### SEO
- [ ] AlternativeTo Listings (4x)
- [ ] Jazz Education Blog Outreach (5 Blogs)
- [ ] Ressourcen-Listen Outreach
- [ ] Google Search Console Monitoring

### B2B Pilot
- [ ] Open Studio Follow-Up mit Kurs-Demo
- [ ] Embed-Demo fuer Pianogroove vorbereiten
- [ ] Educator Landing Page aktualisieren
- [ ] Lesson-Context-API Spec entwerfen

---

## Q4 2026 — Monetarisierung (v1.0)

### Pro-Tier
- [ ] Freemium-Gate definieren (welche Features hinter Pro?)
- [ ] Stripe-Integration
- [ ] Pro-Badge und Premium-UI
- [ ] Zahlungsseite und Abo-Verwaltung
- [ ] Upgrade-Prompts an strategischen Stellen

### Benutzerkonten
- [ ] Auth-System (Supabase Auth oder eigenes)
- [ ] Cloud-Sync fuer Fortschritt
- [ ] Cross-Device-Nutzung
- [ ] Datenmigration localStorage → Cloud

### B2B v1
- [ ] Lesson-Context-API (postMessage)
- [ ] Schueler-Fortschritts-Dashboard fuer Lehrer
- [ ] Educator-Abo Stripe-Integration
- [ ] Erster zahlender B2B-Kunde

### Analytics
- [ ] Event-Tracking (anonym)
- [ ] Conversion-Funnel messen
- [ ] Retention-Metriken (D1, D7, D30)
- [ ] A/B-Testing Infrastruktur

---

## 2027 — Skalierung

### Q1 2027
- [ ] Institution-Tier (Custom Branding, SSO, LTI)
- [ ] API-Zugang fuer B2B
- [ ] Eigene Kurse erstellen (fuer Educators)
- [ ] Mehr Sprachen (FR, ES, JP)

### Q2-Q4 2027
- [ ] Social Features (Ranglisten, Friends)
- [ ] Backing Tracks (Play-Along)
- [ ] Progression Recording und Playback
- [ ] Mobile App Evaluation (PWA vs Native)
- [ ] Community-Features (geteilte Kurse, Lehrer-Marketplace)

---

## Metriken und Ziele

| Metrik | Q2 2026 | Q3 2026 | Q4 2026 | Q2 2027 |
|--------|---------|---------|---------|---------|
| Kurse | 4 | 7 | 8 | 12 |
| MAU | — | 500 | 2.000 | 10.000 |
| Pro-Abos | — | — | 50 | 500 |
| B2B-Kunden | 0 | 1 (Pilot) | 3 | 10 |
| MRR | 0 EUR | 0 EUR | 250 EUR | 2.500 EUR |
| Test-Coverage | 132 | 200 | 300 | 500 |
| Sprachen | 2 | 2 | 2 | 4 |

---

## Priorisierungs-Prinzipien

1. **Kurse vor Features** — Mehr Lern-Inhalte > mehr UI-Features
2. **Retention vor Akquisition** — Habit-Engine verbessern > Marketing
3. **B2C vor B2B** — Organisches Wachstum beweist Product-Market-Fit
4. **Free vor Paid** — Reichweite maximieren, dann monetarisieren
5. **Quality vor Quantity** — 4 exzellente Kurse > 12 mittelsmaessige

---

## Risiken

| Risiko | Mitigation | Deadline |
|--------|-----------|----------|
| Kein PMF nach Launch | Nutzer-Feedback einbauen, Pivotieren | Q3 2026 |
| Mobile-Erlebnis zu schlecht | Touch-Piano optimieren, PWA testen | Q2 2026 |
| B2B-Pipeline blockiert | B2C als eigenstaendiger Kanal | Laufend |
| Solo-Dev Burnout | Scope begrenzen, AI-Tools nutzen | Laufend |
| Wettbewerber (Simply Piano etc.) | Jazz/Voicing-Nische vertiefen | Laufend |

---

*Zuletzt aktualisiert: Maerz 2026*
