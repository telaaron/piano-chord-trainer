# Chord Trainer – Business Plan & Monetarisierung

**Stand:** 17. Februar 2026  
**Verantwortlich:** Aaron Pfutzner / Aaron Technologies OÜ

---

## 1. Produkt-Positionierung

> **Chord Trainer ist das einzige Web-Tool, das MIDI-Echtzeit-Chord-Recognition mit systematischem Speed-Drill-Training für Jazz-Voicings verbindet.**

Kein anderer Anbieter hat:
- MIDI-validiertes Voicing-Training in allen 12 Keys
- Rootless-Voicings (Bill Evans A/B) + Inversions mit visueller Klaviatur
- Custom Progressions (Standards wie Autumn Leaves, All The Things You Are)
- Per-Chord Schwachstellen-Analyse + Improvement Trends
- White-Label-Theming für Plattform-Integration

---

## 2. Zielgruppen & Kanäle

### Primär: B2B – Jazz Education Platforms (Open Studio, Jazz-Academy.com, etc.)
- **Wer:** Online-Plattformen mit Video-Kursen für Jazz-Piano
- **Pain:** Haben Theorie-Lektionen, aber kein interaktives Übe-Tool. Studenten können nach dem Video nicht direkt üben.
- **Wert:** Höheres Engagement, niedrigere Churn, "Practice" als neue Produkt-Kategorie
- **Kanal:** Direkt-Pitch per Email/Demo. Erstkunde: Open Studio Jazz.

### Sekundär: B2B2C – Musikschulen & Private Lehrer
- **Wer:** Jazzklavierfakultäten, Privatlehrer mit Online-Präsenz (z.B. WordPress-Seite)
- **Pain:** Brauchen digitale Übungstools für Studenten, können keine eigenen bauen
- **Wert:** Tool als "Homework"-Modul, Lehrer sehen Fortschritt der Studenten
- **Kanal:** WordPress-Plugin, Teachable/Thinkific-Integration, Lehrer-Empfehlungen

### Tertiär: B2C – Einzelne Jazz-Studenten
- **Wer:** Selbstlernende Jazz-Pianisten, Hobby bis Semi-Profi
- **Pain:** Wollen strukturiert Voicings üben, haben kein systematisches Tool
- **Wert:** Free Tier bringt Traffic, Pro-Features konvertieren
- **Kanal:** SEO ("jazz chord trainer", "ii-V-I practice"), YouTube-Demos, Reddit r/jazz

---

## 3. Monetarisierungs-Modelle

### Modell A: Platform Licensing (B2B) — PRIORITÄT 1
| | |
|---|---|
| **Preis** | €200–500/Monat flat + Setup-Fee €1.000–3.000 |
| **Was Platform bekommt** | White-Label Embed (iframe/Widget), eigenes Branding, Lesson-Context-API |
| **Revenue-Upside** | Bei Plattformen >5.000 Membern: Revenue-Share 5–10% auf Attributable-Conversions |
| **Vertrag** | 12-Monat-Minimum, 30-day trial |

**Warum das funktioniert:** Open Studio hat **56K+ Spieler**, **2500+ Lektionen**, 20+ LIVE Classes/Woche (Pro). Standard-Plan: $33/mo (Jahrestarif). OS Pro: $47/mo (Jahrestarif), $97/mo (monatlich) — mit 12-Wochen-Journeys (Pro Seasons, aktuell: Duke Ellington). Mit diesem Mitglieder-Volumen rechtfertigt selbst eine konservative Adoptionsrate eine Platform-Lizenz. Chord Trainer ist das einzige Drill-Tool das 24/7 üben ermöglicht — auch wenn keine Live-Session läuft.

### Modell B: WordPress Plugin / Embed (B2B2C) — PRIORITÄT 2
| | |
|---|---|
| **Preis** | Freemium: Free for 1 drill. €9/Monat oder €79/Jahr für Full Access |
| **Was Lehrer bekommt** | WordPress Shortcode `[chord-trainer preset="ii-V-I"]`, custom presets |
| **Self-Serve** | Dashboard für Lehrer, Studenten-Fortschritt sehen |

### Modell C: Direct B2C — PRIORITÄT 3
| | |
|---|---|
| **Free Tier** | Random-Mode, 3 Voicing-Typen, begrenzte History |
| **Pro (€4.99/Monat)** | Alle Voicings, Custom Progressions, unbegrenzte History, Schwachstellen-Analyse |
| **Lifetime-Deal** | €49 einmalig (Launch-Aktion, FOMO) |

---

## 4. Go-to-Market Strategie

### Phase 1: Open Studio Pilot (Jetzt → +4 Wochen)
1. **Pitch-Page fertigstellen** → `/open-studio` mit OS-Branding + Live-Demo
2. **E-Mail an Open Studio** (Adam Maness / Peter Martin) mit Link zur Pitch-Page
3. **Ziel:** 30-Day Free Trial Agreement → embedded in 2–3 Lektionen
4. **Metriken:** Active Users, Session Count, Retention Impact

### Phase 2: Generalisieren (Monat 2–3)
1. **for-educators** Seite überarbeiten → generisches B2B Pitch-Deck
2. **WordPress Plugin** MVP bauen (iframe embed + Shortcode)
3. **2–3 weitere Plattformen pitchen** (Jazz-Academy, Pianote Jazz, Learn Jazz Standards)

### Phase 3: B2C + SEO (Monat 3–6)
1. **Freemium-Gating** einbauen (Free vs Pro Features)
2. **Content Marketing** (YouTube: "I practiced ii-V-I in all 12 keys for 30 days")
3. **SEO optimieren** (jazzchords.app Landingpage, Blog)
4. **Stripe Integration** für Subscriptions

---

## 5. Integration-Konzepte für Partner-Plattformen

### Konzept 1: Lesson-Tab Integration ⭐ BESTE OPTION
Neuer Tab neben "Overview", "Materials", "Shortcuts" → **"Practice Trainer"**
- Kontext-spezifisch: Lektion "Cush Chords" → Trainer zeigt genau diese Voicings
- Kein Kontextwechsel für den Studenten
- **Technisch:** iframe mit URL-Parametern (`?preset=cush-chords&theme=openstudio`)

### Konzept 2: Standalone Navigation
Eigener Punkt in der Platform-Navigation → "Practice Tools"
- Skalierbar: Chord Trainer, Scale Trainer, Ear Trainer (Zukunft)
- Für freies Üben, nicht an Lektion gebunden
- **Technisch:** Subdomain (`practice.openstudio.app`) oder eigene Sektion

### Konzept 3: Post-Lesson Practice Challenge
Call-to-Action nach Video-Ende → "Ready to practice? Test in all 12 keys!"
- Höchste Conversion: Motivation direkt nach Lernen
- Gamification: "Challenge completed ✅"
- **Technisch:** Overlay/Modal mit eingebettetem Trainer

### Konzept 4: Materials Tab Ergänzung
Innerhalb jeder Lektion unter "Materials" als interaktive Ressource
- Neben PDFs: "🎹 Practice this voicing interactively"
- Niedrige Integrations-Hürde
- **Technisch:** Link mit Preset-Parametern

### Empfehlung für Pitch:
**Haupt: Konzept 1** (Lesson-Tab) + **Zusatz: Konzept 2** (Standalone Nav)

---

## 6. Differenzierung & Wettbewerb

| Feature | Chord Trainer (wir) | Piano Marvel | Flowkey | Synthesia |
|---------|---------------------|-------------|---------|-----------|
| Jazz-Voicings | ✅ 9 Typen inkl. Rootless | ❌ | ❌ | ❌ |
| MIDI Chord Recognition | ✅ Lenient + Oktav-tolerant | ✅ (Note-by-note) | ❌ | ✅ (Note-by-note) |
| ii-V-I alle 12 Keys | ✅ | ❌ | ❌ | ❌ |
| Custom Progressions | ✅ | ❌ | ❌ | ❌ |
| Weakness Analysis | ✅ Per-Chord Timing | ❌ | ❌ | ❌ |
| White-Label / Embed | ✅ | ❌ | ❌ | ❌ |
| Preis | B2B Lizenz | $15/mo B2C | $10/mo B2C | $5/mo B2C |

**Unsere Nische:** Kein General-Purpose-Piano-Tutor, sondern das **spezialisierte Jazz-Voicing-Drill-Tool**.

---

## 7. Pitch-Argument (Elevator Pitch)

> "Stell dir vor: Ein Student schaut die Lektion 'Shell Voicings', klickt auf den Practice-Tab und übt genau diese Voicings sofort in allen 12 Tonarten — mit MIDI-Feedback, Timer und Schwachstellen-Analyse. Kein Tab-Wechsel, kein externes Tool. Alles in deiner Plattform."

**Für Open Studio spezifisch:**
> "Harmony Games Unlimited zeigt Konzepte. Unser Tool macht sie zu Muscle Memory. Adam Maness erklärt 'The Family' — der Student klickt 'Practice' und drillt die Voicings sofort durch alle Keys. Das ist das Feature, das keine andere Jazz-Plattform hat."

---

## 8. Kosten & Break-Even

| Posten | Monatlich |
|--------|-----------|
| Hosting (Vercel Pro) | €20 |
| Domain (jazzchords.app) | €1.50 |
| Dev-Zeit (Opportunitätskosten) | – |
| **Total Fix** | **~€22/Monat** |

**Break-Even:** 1 B2B-Kunde bei €200/Monat = profitabel ab Tag 1.

---

## 9. Nächste Schritte (priorisiert)

1. ✅ Open Studio Pitch-Page erstellen (`/open-studio`)
2. ⬜ Email an Open Studio senden mit Link
3. ⬜ for-educators Seite generalisieren (mehrere Plattformen ansprechen)
4. ⬜ iframe Embed-Modus bauen (`/embed?preset=...&theme=openstudio`)
5. ⬜ WordPress Shortcode Plugin (Phase 2)
6. ⬜ B2C Freemium-Gating (Phase 3)
