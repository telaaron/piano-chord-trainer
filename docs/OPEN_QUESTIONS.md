# Chord Trainer – Offene Fragen

> Punkte die noch geklaert oder entschieden werden muessen.
> **Stand:** Maerz 2026

---

## Produkt

1. **Freemium-Gate Position:** Welche Features genau hinter Pro? Kurse kostenlos halten oder begrenzen?
2. **Kurs-Reihenfolge:** Sollen Kurse linear freigeschaltet werden oder immer alle verfuegbar?
3. **Mobile UX:** Click-Piano ist funktional aber nicht ideal fuer Speed-Drills — reicht das oder brauchen wir Touch-Optimierungen?

## Technik

4. **Cloud-Sync Architektur:** Supabase vs. eigenes Backend vs. Firebase? Entscheidung steht noch aus.
5. **Lesson-Context-API Format:** postMessage-Schema fuer B2B-Embed noch nicht spezifiziert.
6. **Audio-Latenz Mikrofon:** basic-pitch hat ~200ms Latenz — akzeptabel fuer Practice, zu hoch fuer Challenge?

## Business

7. **Open Studio Follow-Up:** Naechster Schritt nach dem Pitch — warten oder aktiv nachhaken?
8. **Product Hunt Timing:** Launch vor oder nach Pro-Tier? (Empfehlung: vor Pro, als Free-Launch)

## QA

9. **Voice Leading + MIDI:** MIDI-Erkennung mit voice-led Voicings noch nicht vollstaendig getestet (siehe QA_CHECKLIST.md)
10. **In-Time ohne MIDI:** Session endet nie ohne MIDI-Input — automatische Markierung als korrekt oder Done-Button?

---

*Zuletzt aktualisiert: Maerz 2026*
