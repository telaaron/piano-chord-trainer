# JazzChords — Masterplan zur Profitabilität

> Bestandsaufnahme, Bewertung und Umsetzungsplan.
> **Stand:** 26. Juli 2026 · **Autor:** CEO/PM-Rolle · **Ersetzt:** die Forecast-Teile von [BUSINESS.md](./BUSINESS.md) (Stand März 2026, überholt)

---

## 0. Die Kernaussage in fünf Sätzen

1. Das Produkt ist gebaut, die Kasse ist angeschlossen (`IS_BETA = false`, Stripe LIVE) — es kann **heute** Geld annehmen.
2. Es kommt trotzdem keins, weil in 4 Monaten **14 Nutzer** registriert wurden und **0 echte Zahlungen** eingegangen sind.
3. Das Problem ist **nicht** das Produkt und **nicht** der Markt — es ist, dass niemand von der Existenz weiß. Es gibt **null Akquisitionskanal**.
4. Die Zielgruppe, nach der du gefragt hast (erwachsener Hobby-Lerner, kein Student), ist **real, groß und die zahlungskräftigste** — und ist bereits die richtige Antwort auf deine Preisfrage.
5. Der B2B-Traum mit Open Studio ist **nicht** der erste Schritt, sondern der dritte. Wir haben aktuell nichts, was wir dort verkaufen könnten, ohne uns zu blamieren.

---

## 1. Bestandsaufnahme: die harten Zahlen

Direkt aus der Produktionsdatenbank (Supabase `chpoqghvlojwyunoplab`, abgefragt 26.07.2026):

| Kennzahl | Wert | Bewertung |
|---|---|---|
| Registrierte Nutzer gesamt | **14** | seit März 2026 |
| Neuanmeldungen letzte 30 Tage | **4** | ≈1 pro Woche |
| Aktiv letzte 7 Tage | **2** | |
| Subscriptions-Zeilen | **1** | `pro/active`, **ohne** `stripe_customer_id` → **manuell gesetzt, kein echter Umsatz** |
| **Bezahlte Abos (echt)** | **0** | **MRR = 0 €** |
| Coach-Telemetrie-Events | 390 | |
| Devices im Coach | **10** | davon 6 mit ≤2 Events |

### Was die Telemetrie über das Produkt sagt

| Signal | Wert | Diagnose |
|---|---|---|
| `session_start` | 36 | |
| `session_end` | 17 | **Nur 47 % der gestarteten Sessions melden ein Ende.** |
| `quit_midblock` | 5 | |
| Feedback-Ventil | 4× `justRight`, 2× `tooEasy`, **0× `tooHard`** | |
| Device-Retention | **max. 1 Tag Spanne**, kein einziges Device über mehrere Tage | **D7-Retention ≈ 0** |

**Die drei wichtigsten Erkenntnisse aus den Daten:**

**a) Kein einziger Nutzer kommt an einem zweiten Tag wieder.** Bei einer Übungs-App, deren ganzer Wert auf Wiederholung beruht, ist das die einzige Zahl, die zählt. Alles andere ist nachrangig.

**b) Niemand sagt „zu schwer", aber 2 von 6 sagen „zu leicht".** Deine Sorge, der Auto-Modus sei nicht nutzerfreundlich, bestätigt sich in den Daten *nicht* als Überforderung, sondern als **Unterforderung**. Zahlenbasis mit n=6 dünn, Richtung aber eindeutig und billig zu korrigieren.

**c) Der Abbruch passiert *vor* dem ersten Ton, nicht mittendrin.** Das ist der eigentliche Fund, und er widerlegt die naheliegende Vermutung:

| Blocktyp | gestartete Blöcke | davon abgeschlossen |
|---|---|---|
| review | 94 | **94** |
| focus | 91 | **91** |
| warmup | 23 | **23** |
| new | 11 | **11** |
| calibrate | 6 | **6** |

**Jeder einzelne begonnene Block wird zu Ende gespielt — 225 von 225.** Und bei 4 der 5 Abbrüche steht `atChord: 0`: der Nutzer springt ab, *bevor* er den ersten Akkord gespielt hat. Die Sessions sind zudem **1–2,5 Minuten** lang, nicht zu lang.

> **Das Problem ist also nicht der Algorithmus und nicht die Session-Länge — es ist der Moment zwischen „Session startet" und „erster Akkord".** Wer einmal spielt, spielt durch. Wer abspringt, tut es an der Schwelle. Wahrscheinlichste Ursachen: MIDI-Gerät nicht verbunden/erkannt, unklar was zu tun ist, oder Ton läuft nicht. Das ist ein **Onboarding- und Geräte-Setup-Problem**, kein Coach-Tuning-Problem — und deutlich billiger zu lösen.

*(Anmerkung zur Datenqualität: 2 der 17 `session_end`-Events melden `completedBlocks` 39/41 bei `totalBlocks` 3 — ein Zählfehler in der Instrumentierung, der vor der Auswertung in Phase 1 zu fixen ist.)*

> ✅ **Datenlücke geschlossen (31.07.2026).** Bis dahin gab es **kein Web-Analytics** — wir kannten nur die, die schon im Trainer waren. Jetzt messen zwei getrennte Systeme: **Vercel Analytics** die Besucherseite (wer kommt, woher, welche Seiten) und die bestehende **Supabase-Telemetrie** den Trichter. Nicht Plausible, wie ursprünglich geplant: Vercel braucht keinen Account, keinen Server und keine dritte Partei in der Datenschutzerklärung — und die behauptete ohnehin schon, wir würden es nutzen. Der Wechsel zu Plausible Cloud ist eine halbe Stunde, sobald Traffic da ist und Tiefe fehlt.

---

## 2. Deine Fragen — beantwortet

### „Ist die Zielgruppe eher der Nicht-Student, der einfach so Jazz lernen will?"

**Ja. Und das ist die wichtigste strategische Korrektur in diesem Dokument.**

Marktdaten 2025/2026:
- **Selbstzahlende Hobbyisten = 59,4 %** der Ausgaben im Online-Musikunterricht.
- **Erwachsene 25–55 = 32,7 %** Segmentanteil, das am schnellsten wachsende Segment.
- Erwachsene Selbstlerner geben **120–240 € pro Jahr** für App-Abos aus.
- Erwachsene sind **verbindlicher** als Kinder: 73 % wöchentliche Übungstreue vs. 58 %.
- Klavier ist mit **38,85 %** die größte Instrumentenkategorie online.

**Das Profil:** 30–55, Beruf, verdient gut, hatte als Kind Klavierunterricht oder spielt seit Jahren Pop/Klassik, will endlich „richtig" Jazz können. Übt abends 20 Minuten. Hat ein MIDI-Keyboard herumstehen. Kauft ohne Zögern ein 5-€-Abo, wenn es ihm etwas bringt — für ihn ist das ein Bruchteil einer einzigen Klavierstunde (40–100 €/Stunde).

**Konsequenz für die Preisfrage:** Deine Sorge, Studenten hätten wenig Geld, ist berechtigt — aber sie führt zur falschen Schlussfolgerung. Studenten sind **nicht** unsere Kernzielgruppe. Wir sollten nicht das Produkt verbilligen, um Studenten zu erreichen, sondern **den zahlungskräftigen Erwachsenen adressieren und Studenten separat rabattieren**. Genau das macht Open Studio: 39 $/Monat regulär, 50 % Studentenrabatt. Das ist die erprobte Mechanik — Vollpreis als Anker, Rabatt als Ausnahme mit Nachweis.

### „Ist der Markt nicht überfüllt?"

**Der breite Markt ja — unsere Nische nein, aber das Zeitfenster schließt sich.**

Überfüllt sind die Generalisten: Simply Piano, Flowkey, Skoove, Synthesia. Gegen die treten wir nicht an.

Unsere Nische — *MIDI-validiertes Voicing-Drilling für Jazz* — hatte bis vor Kurzem faktisch keinen direkten Wettbewerb. Das hat sich **dieses Jahr geändert**:

| Wettbewerber | Status | Einschätzung |
|---|---|---|
| **Jazz Piano Voicings (iOS)** | Release **Jan 2026**, letztes Update vor 4 Tagen | **Der direkte Konkurrent.** 1.400 Voicing-Karten, 12 Tonarten, adaptives Curriculum, MIDI (Kabel + Bluetooth), Mastery-Level. Praktisch unser Feature-Set. Noch **zu wenige Bewertungen für einen Score** → auch sie sind früh. Sind gerade auf „einmalig kaufen statt Abo" umgestiegen. |
| **VoicingWorkout (iOS)** | aktiv | iPad + MIDI, Pop/Jazz-Voicings |
| **iReal Pro** | Platzhirsch, 19,99 $ einmalig | Play-Along, kein Voicing-Drill → **komplementär, kein Konkurrent** |
| **Pianogroove / Open Studio** | Video-Kurse | **Kein interaktives Übe-Tool → potenzielle Partner, nicht Gegner** |

**Fazit:** Wir sind nicht zu spät, aber wir sind auch nicht mehr allein. Der Vorsprung, den wir haben — Web-basiert (kein App-Store-Zwang, sofort teilbar per Link), zweisprachig DE/EN, Kurse + Coach, embeddable — ist real, aber er verfällt. Ein Jahr weiter UI-Politur ohne Nutzer und wir haben ihn verschenkt.

### „Kann man mit Lizenzen/Förderungen arbeiten?"

Kurz: **Förderungen ja, aber nicht jetzt.** Ausführlich in Abschnitt 6.

---

## 3. Die ehrliche Bewertung des Projekts

**Was stark ist:**
- Technisch weit überdurchschnittlich: 0 TS-Fehler, 132+ Tests, saubere Engine/Service-Trennung, Web + iOS mit 1:1 portierter Engine.
- Der Coach mit Telemetrie und Remote-Config ist ein echter Wettbewerbsvorteil — die Infrastruktur zum datengetriebenen Verbessern steht.
- Zahlungs- und Auth-Infrastruktur ist fertig und live.
- Freies Produkt ohne Signup-Zwang = niedrigste Einstiegshürde der ganzen Kategorie.

**Was das Kernproblem ist:**

> Dieses Projekt hat ein **Vertriebsproblem, das als Produktproblem missverstanden wird.**

Die Commit-Historie zeigt es unmissverständlich: Juli 2026 bestand fast vollständig aus Design-Iterationen — drei Landing-Varianten, drei Logo-Richtungen, „editorial pass", Hero-Umbauten. Parallel: 4 Neuanmeldungen im Monat. **Das Verhältnis von Bauaufwand zu Vertriebsaufwand liegt bei ungefähr 100:0.** Jede weitere Woche Politur an einer Seite, die niemand besucht, hat einen Ertrag von null.

Das ist kein Vorwurf — Bauen ist angenehmer und kontrollierbarer als Verkaufen. Aber als verantwortlicher PM ist das die eine Sache, die ich ändern muss.

**Zweitproblem — der Preis-Wert-Schnitt.** Pro kostet 4,99 €/Monat und enthält: Adaptive Difficulty, Custom Progressions, erweiterte Statistiken, Cloud-Sync. Alles andere ist frei — inklusive **Coach, aller Voicings, Voice Leading, MIDI und aller Kurse**. Das kostenlose Angebot ist so vollständig, dass für den typischen Hobby-Nutzer **kein Grund zum Zahlen** existiert. Cloud-Sync ist erst dann wertvoll, wenn man mehrere Geräte nutzt und seine Historie liebt — also nach Wochen der Nutzung, die aktuell niemand erreicht.

**Gesamturteil:** Fortführen, klar. Aber mit einer strikt umgekehrten Prioritätenordnung: **erst Nutzer, dann Retention, dann Geld, dann B2B.** Und mit einem Zeitlimit statt unbegrenzter Geduld (Abschnitt 7).

---

## 4. Strategie: die Reihenfolge, auf die es ankommt

Der Fehler wäre, jetzt parallel B2C-Marketing, Produktpolitur und Open-Studio-Akquise zu betreiben. Bei einer Person Kapazität heißt das, alles halb zu tun.

```
Phase 1  RETENTION      Aug 2026        Ohne Tag-2-Rückkehr ist alles andere Verschwendung
Phase 2  AKQUISE        Sep–Okt 2026    Die ersten 500 echten Besucher, Kanal für Kanal
Phase 3  MONETARISIERUNG Nov 2026       Erst wenn Leute bleiben, verkaufen wir ihnen etwas
Phase 4  B2B            Q1 2027         Mit Zahlen im Rücken, nicht mit Hoffnung
```

**Die Begründung für diese Reihenfolge:** Nutzer in ein Produkt zu schicken, das eine D7-Retention von 0 hat, verbrennt sie unwiederbringlich. Man bekommt einen Menschen selten zweimal auf dieselbe Seite. Erst dichthalten, dann füllen.

---

## 5. Der Umsetzungsplan

### Phase 1 — Retention (August 2026)

**Ziel:** D1-Retention > 25 %, D7 > 10 %, Session-Start→erster-Akkord > 90 %.

Die Reihenfolge folgt direkt aus Erkenntnis (c): **die Schwelle zuerst, das Coach-Tuning danach.**

| # | Maßnahme | Warum | Aufwand |
|---|---|---|---|
| 1.1 | ✅ **Web-Analytics** — Vercel Analytics statt Plausible (0 €, kein Account, kein Cookie-Banner), verdrahtet in `src/lib/services/analytics.ts`, respektiert den bestehenden Telemetrie-Opt-out und läuft nicht auf `/embed` | erledigt |
| 1.2 | **Die Schwelle „Start → erster Akkord" reparieren** | **Der größte Einzelhebel.** 4 von 5 Abbrüchen passieren bei `atChord: 0`. Selbst durchspielen mit und ohne MIDI-Gerät, und die Frage beantworten: Was sieht jemand, der gerade auf „Start" gedrückt hat, und weiß er, was er tun soll? | 1–2 Tage |
| 1.3 | ✅ **`first_chord_played`** in `beginTimer()` — der einzige Punkt, an dem wirklich gespielt wird. Views `v_coach_threshold` (Schwellen-Rate pro Tag) und `v_coach_threshold_by_input` (nach Eingabegerät) sind deployed. Der `completedBlocks`-Zählfehler steht noch aus. | teilweise |
| 1.4 | **Kein-Keyboard-Pfad prominent machen** | Die Seite verspricht „works with or without a keyboard". Wenn der Abbruch am fehlenden MIDI-Gerät liegt, muss der tastaturlose Einstieg der sichtbare Default sein, nicht die Ausweichoption. | 0,5 Tag |
| 1.5 | **Auto-Modus: Einstieg härter kalibrieren** | Daten sagen „zu leicht", nicht „zu schwer". Einstiegslevel anheben, Frühpromotion beschleunigen. **Nach 1.2**, nicht davor. | 1 Tag |
| 1.6 | **Rückkehr-Anlass schaffen** | Der einzige Grund wiederzukommen ist aktuell Eigenmotivation. E-Mail-Reminder (opt-in) oder iOS-Push. Größter Hebel für D7 — aber erst sinnvoll, wenn Tag 1 funktioniert. | 2 Tage |
| 1.7 | **UI-Arbeit einfrieren** | Bis Phase 1 steht, keine weiteren Design-Varianten. Die Landingpage ist gut genug. | — |

> **Was hier nicht mehr auf der Liste steht:** „Sessions kürzer machen". Die Annahme war falsch — die Sessions dauern 1–2,5 Minuten und werden vollständig durchgespielt. Ein Beispiel dafür, warum die Datenabfrage vor der Maßnahmenliste kommt.

### Phase 2 — Akquise (September–Oktober 2026)

**Ziel:** 500 echte Besucher/Monat, 100 aktive Devices/Monat.

Nicht alle Kanäle gleichzeitig. Einer nach dem anderen, jeder wird gemessen (jetzt möglich, dank 1.1).

| Priorität | Kanal | Warum genau dieser | Erwartung |
|---|---|---|---|
| **A** | **Reddit: r/JazzPiano, r/piano, r/JazzTheory** | Exakt unsere Zielgruppe, kostenlos, hohe Kaufkraft. **Regel: kein Werbepost.** Echte Hilfe leisten, Tool erwähnen wo es passt. Ein „ich hab das gebaut, ist kostenlos, kein Signup" kommt dort gut an — *wenn* es stimmt, und es stimmt. | 100–300 Besucher pro guter Post |
| **B** | **SEO-Long-Tail** | Die `/chords/[chord]`- und `/learn`-Routen existieren bereits. Für „Cmaj7 voicing", „rootless voicings üben", „ii-V-I alle Tonarten" ranken. Wirkt langsam, aber dauerhaft und kostenlos. | 3–6 Monate bis Wirkung |
| **C** | **YouTube-Kooperationen** | Jazz-Klavier-Kanäle mit 10–100k Abos. Kein Geld anbieten — kostenlosen Zugang + ein Feature nach ihren Wünschen. Ihre Zuschauer *sind* die Zielgruppe. | 1 guter Kanal = 500+ Besucher |
| **D** | **Product Hunt** | Assets existieren laut Roadmap. Einmaliger Peak, gut für Backlinks/Glaubwürdigkeit. **Aber erst wenn Retention sitzt** — sonst verbrennt man den Launch. | 300–800 Besucher, einmalig |

**Bewusst nicht:** bezahlte Anzeigen. Bei 0 € MRR und unbekanntem LTV ist jeder Euro Ad-Spend geraten.

### Phase 3 — Monetarisierung (November 2026)

**Ziel:** die ersten 10 echten zahlenden Kunden. Nicht 100. Zehn.

> **Vollständig ausgearbeitet in → [MONETARISIERUNG.md](./MONETARISIERUNG.md)** (Tarife, Konditionen, Featureschnitt, Umsetzungsreihenfolge).

Kurzfassung der dort getroffenen Entscheidungen:

| # | Entscheidung | Begründung |
|---|---|---|
| 3.1 | **Vier Tarife: Übung (0 €) · Studio (7,99 €/59 € Jahr) · Lehrpult (29 €) · Institut (ab 690 €/Jahr)** | Zwei Zielgruppen, ein Preisgerüst |
| 3.2 | **Die eine wirksame Grenze: 1 Coach-Session/Tag im Gratistarif** | Täglich spürbar für Vielübende, unsichtbar für Gelegenheitsnutzer. Freies Üben bleibt unbegrenzt. |
| 3.3 | **Preis 4,99 € → 7,99 €, plus Jahresabo** | Zielgruppe zahlt 40–100 € pro Klavierstunde; 4,99 € signalisiert Nebenprojekt |
| 3.4 | **Trial: 14 Tage mit Karte → 7 Tage ohne Karte** | Kartenpflicht widerspricht „Free. No signup." und kostet uns Trial-Starts, die wir bei 4 Anmeldungen/Monat nicht entbehren können |
| 3.5 | **Studentenrabatt 50 % mit Nachweis statt niedrigem Grundpreis** | Vollpreis bleibt Anker; Institut-Tarif löst das Studentengeld-Problem strukturell (die Institution zahlt) |
| 3.6 | **Kurse, Voicings, MIDI und Coach-Qualität bleiben frei** | Reichweitenmotor und Alleinstellungsmerkmal — nur die *Menge* wird begrenzt, nie die *Qualität* |

### Phase 4 — B2B (ab Q1 2027)

**Warum erst dann, obwohl es dein ursprüngliches Ziel war:**

Ein Open-Studio-Gespräch ohne Nutzungsdaten ist ein Gespräch ohne Argumente. Sie werden genau eine Frage stellen: *„Wie viele Leute nutzen es, und wie lange bleiben sie?"* Heute lautet die ehrliche Antwort: 10 Devices, keins länger als einen Tag. Damit gewinnt man kein Enterprise-Gespräch — man verbrennt den Kontakt, und einen Erstkontakt hat man nur einmal.

Die Zahlen aus BUSINESS.md (15–80k € Lizenzen) sind nicht falsch, aber sie sind **Endzustandsphantasie ohne Zwischenschritte**. Realistisch:

1. **Voraussetzung:** ≥ 500 monatlich aktive Nutzer, D7-Retention > 15 %, dokumentierte Fallstudie.
2. **Erster Schritt nicht Open Studio, sondern der einzelne Klavierlehrer.** Der Educator-Tarif (29 €) ist verkaufbar, sobald es Nutzer gibt. Zehn Klavierlehrer = 290 €/Monat = tragfähig. Und jeder bringt seine Schüler mit.
3. **Dann Open Studio** — mit einer echten Zahl: „X unserer Nutzer haben angegeben, bei euch Kurse zu belegen."
4. **Nicht mit Exklusivität anfangen.** Ein kleiner bezahlter Pilot (500–1.000 €) ist leichter zu unterschreiben als ein 30k-Vertrag und öffnet dieselbe Tür.

---

## 6. Förderungen und Lizenzen

Zu deiner Frage — es gibt zwei realistische Wege, aber beide sind Beschleuniger, kein Rettungsanker:

**a) Öffentliche Förderung.** Die Firma ist eine estnische OÜ, das Produkt ist Bildungstechnologie mit klarem kulturellen Auftrag (Jazz-Vermittlung) — das passt grundsätzlich in EU-Programme für Digitalisierung in der Bildung sowie in estnische Startup-Förderung. **Aber:** Anträge kosten realistisch 20–40 Stunden, laufen 3–9 Monate, und fast alle verlangen entweder Umsatz oder Nutzerzahlen als Nachweis. **Empfehlung: nach Phase 2 prüfen, nicht jetzt.** Der Aufwand wäre in Phase 1/2 besser in Retention investiert.

**b) Bildungslizenzen an Institutionen.** Musikhochschulen und Musikschulen haben eigene Budgets für Lehrmittel — das ist Geld, das nicht aus der Studententasche kommt und damit die elegante Antwort auf dein Bezahlbarkeitsproblem: **die Institution zahlt, der Student nutzt es gratis.** Eine Campus-Lizenz (z. B. 300–500 €/Jahr für unbegrenzt Studierende) ist für eine Hochschule ein kleiner Posten. Das ist der realistischere und schnellere B2B-Weg als der Open-Studio-Großdeal — und ein Weg, auf dem der bereits gebaute `/embed`-Pfad direkt zum Tragen kommt.

---

## 7. Abbruchkriterien

Damit dies ein Plan bleibt und keine offene Geduldsprobe wird — überprüfbare Haltepunkte:

| Zeitpunkt | Bedingung zum Weitermachen | Wenn nicht erfüllt |
|---|---|---|
| **Ende Sep 2026** | D1-Retention > 25 %, D7 > 10 % | Retention-Problem ist strukturell → Produktthese hinterfragen, nicht mehr Marketing draufwerfen |
| **Ende Nov 2026** | 500 Besucher/Monat, 100 aktive Devices | Akquisekanäle funktionieren nicht → auf reines B2B/Lizenz-Modell umschwenken |
| **Ende Jan 2027** | ≥ 10 zahlende Kunden | Zahlungsbereitschaft im B2C nicht vorhanden → Produkt als kostenloses Portfolio-/Lead-Stück führen, B2B-only |

Die laufenden Kosten sind mit ~22 €/Monat vernachlässigbar. Die eigentliche Investition ist **deine Zeit** — und die ist der einzige Posten, der hier ernsthaft auf dem Spiel steht.

---

## 8. Was diese Woche passiert

Nicht mehr als fünf Dinge, in dieser Reihenfolge:

1. ~~Analytics einbauen~~ ✅ erledigt (Vercel Analytics + `first_chord_played`).
2. **Die Schwelle selbst durchspielen** — einmal mit MIDI-Keyboard, einmal ohne, einmal auf dem Handy. Auf „Start" drücken und ehrlich beobachten: Ist in den ersten 10 Sekunden klar, was zu tun ist? **Hier liegt die Antwort auf „Auto-Modus nicht nutzerfreundlich" — nicht im Algorithmus.** (2 h)
3. **Was in 2. auffällt, sofort reparieren.** (1–2 Tage)
4. **`first_chord_played`-Event + `completedBlocks`-Zählfehler.** (0,5 Tag)
5. **Einen einzigen ehrlichen Reddit-Post** in r/JazzPiano — nicht als Kampagne, sondern als Test: kommt überhaupt jemand, und was macht er dann? Mit 1. messbar.

**Nicht diese Woche:** Logo, Landing-Varianten, Open-Studio-Mail, iOS-Store-Launch, Coach-Parameter-Tuning.

---

*Grundlage: Produktionsdaten Supabase (26.07.2026), Marktdaten Mordor/Astute/Metastat 2025–2026, Wettbewerbsrecherche App Store Juli 2026, Repository-Analyse.*
