# JazzChords — Monetarisierungsplan

> Tarife, Konditionen, Featureschnitt und Umsetzungsreihenfolge.
> **Stand:** 30. Juli 2026 · Gehört zu [MASTERPLAN.md](./MASTERPLAN.md) (Phase 3) · Ersetzt den Preisteil von [BUSINESS.md](./BUSINESS.md)

---

## 1. Warum der aktuelle Schnitt kein Geld verdient

Der Ist-Zustand aus `FEATURE_GATES` (`src/lib/services/subscription.ts`):

```
FREE                                    PRO 4,99 €
Alle 4 Kurse                            Adaptive Difficulty
Coach (Auto-Modus)                      Custom Progressions
Alle 9 Voicing-Typen                    Erweiterte Statistiken
Voice Leading                           Cloud-Sync
Alle Progressionen
MIDI + Mikrofon
To-Go (7 Disziplinen)  ← komplett ungated
Habit-System
```

**Drei Konstruktionsfehler:**

1. **Das Gratisangebot ist das Produkt.** Coach, alle Voicings, alle Kurse, To-Go — der Kernnutzen „ich werde flüssig in allen 12 Tonarten" ist vollständig kostenlos erreichbar. Pro verkauft Randfunktionen.
2. **Die Pro-Features sind Nachzügler-Features.** Cloud-Sync und Statistiktiefe werden erst wertvoll, wenn jemand mehrere Wochen geübt und mehrere Geräte hat. Bei D7-Retention ≈ 0 erreicht diesen Punkt aktuell **niemand**. Wir verkaufen etwas, dessen Wert erst nach dem Zeitpunkt entsteht, an dem alle abspringen.
3. **Der Trial widerspricht dem Versprechen.** Checkout setzt `trial_period_days: 14` **mit Kartenpflicht**, während die Startseite „Free. No signup." verspricht. Wer nach dieser Zusage nach der Kreditkarte gefragt wird, erlebt einen Bruch. Kartenpflicht ist bei einem 5-€-Hobbyprodukt zudem die teuerste aller Hürden.

**Grundregel für den neuen Schnitt:**

> Kostenlos bleibt alles, was **Gewohnheit aufbaut**. Bezahlt wird alles, was **Gewohnheit verstärkt, beschleunigt oder absichert.**

Kein Feature, das ein Erstnutzer in Woche 1 braucht, darf hinter die Wand. Umgekehrt: Wer nach 4 Wochen noch da ist, muss regelmäßig an eine Grenze stoßen, deren Aufhebung offensichtlich 5 € wert ist.

---

## 2. Die Tarife

Vier Tarife, zwei Zielgruppen. Namen bewusst in der Bildsprache des Produkts („Die Uhr", „Der Saal") statt Free/Pro/Business.

### Übersicht

| # | Name | Zielgruppe | Preis | Abrechnung |
|---|---|---|---|---|
| I | **Übung** (Practice) | Alle. Dauerhaft kostenlos. | **0 €** | — |
| II | **Studio** | Der ernsthafte Selbstlerner | **7,99 €/Monat** oder **59 €/Jahr** | monatlich / jährlich |
| III | **Lehrpult** (Studio Teacher) | Einzelner Klavierlehrer | **29 €/Monat** oder **290 €/Jahr** | inkl. 30 Schülerplätze |
| IV | **Institut** (Campus) | Musikschule / Hochschule | **ab 690 €/Jahr** | Jahresrechnung, kein Self-Checkout |

**Studenten:** 50 % auf Studio und Lehrpult gegen Nachweis → **3,99 €/Monat** bzw. **29 €/Jahr**. Nicht als eigener Tarif geführt, sondern als Rabattcode. Begründung siehe Abschnitt 5.

---

### Tarif I — „Übung" · 0 €

**Versprechen:** *Alles, was du brauchst, um jazzpianistisch besser zu werden. Ohne Konto, ohne Karte, ohne Ablaufdatum.*

Das kostenlose Angebot bleibt **bewusst stark** — es ist unser einziger funktionierender Wachstumskanal und das Alleinstellungsmerkmal gegen die iOS-Konkurrenz (kein App Store, sofort per Link teilbar).

| Enthalten | Grenze |
|---|---|
| Coach / Auto-Modus | **1 Session pro Tag** |
| Alle 4 Kurse (Intervals, Shell, Scale Degrees, Ultimate Plan) | vollständig |
| Alle 16 Akkordtypen, alle 9 Voicings | vollständig |
| Alle Progressionsmodi (ii-V-I, Quartenzirkel, Turnaround) | vollständig |
| Freies Üben / Speed-Drill | **unbegrenzt** |
| MIDI, Mikrofon, Click-Piano | vollständig |
| To-Go (7 Disziplinen) | **3 der 7**: interval, quality, theory |
| Verlauf & Statistik | **letzte 7 Tage** |
| Metronom, Audio, DE/EN, Notationssysteme | vollständig |
| Kein Konto nötig | ja |

> **Die entscheidende Grenze ist „1 Coach-Session pro Tag".** Sie ist die einzige, die ein motivierter Nutzer *täglich* spürt — und sie bestraft niemanden, der wenig übt. Wer einmal am Tag übt, merkt nie, dass es eine Grenze gibt. Wer zweimal will, ist genau der Nutzer, der zahlen sollte. Freies Üben bleibt **unbegrenzt**, damit die Grenze nie wie eine Sperre wirkt, sondern wie ein Angebot.

---

### Tarif II — „Studio" · 7,99 €/Monat · 59 €/Jahr

**Versprechen:** *Üben ohne Limit — und ein Gedächtnis, das sich alles merkt.*

| Zusätzlich zu „Übung" | Warum das Geld wert ist |
|---|---|
| **Unbegrenzte Coach-Sessions** | Der Hauptgrund. Direkt spürbar, täglich. |
| **To-Go vollständig** (alle 7: + sing, time, lick, progression) | Üben in Bahn/Pause ohne Klavier — der Alltagsnutzen, der Gewohnheit trägt |
| **Vollständiger Verlauf** (statt 7 Tage) | Fortschritt über Monate sichtbar |
| **Erweiterte Statistiken** — Schwachstellen, Trends, Tonart-Heatmap | bereits gebaut (`analyzeWeakChords`, `analyzeChordTrends`, `analyzeWeakSpots`) |
| **Adaptive Difficulty** | bereits gebaut |
| **Custom Progressions** (eigene Stücke: Autumn Leaves etc.) | bereits gebaut |
| **Cloud-Sync** über alle Geräte + iOS | bereits gebaut |
| **Offline/iOS-Vollzugang** | |

**Konditionen:**
- **7 Tage Studio gratis, ohne Kreditkarte, ohne Konto-Zwang beim Start.** Ersetzt den heutigen 14-Tage-Trial mit Kartenpflicht.
- Jederzeit kündbar, Zugang bis Periodenende.
- **30 Tage Geld-zurück** ohne Begründung.
- Jahresabo: 59 € = **38 % Ersparnis** (entspricht 4,92 €/Monat).

**Preisbegründung:** 7,99 € statt 4,99 €. Die Zielgruppe zahlt 40–100 € für **eine** Klavierstunde; 96 €/Jahr ist ein Bruchteil davon und liegt im belegten Marktkorridor (120–240 €/Jahr für App-Abos bei erwachsenen Selbstlernern). 4,99 € signalisiert „Nebenprojekt". Wichtiger noch: Bei realistischen Nutzerzahlen ist der Unterschied zwischen 5 € und 8 € der Unterschied zwischen 500 € und 800 € MRR bei 100 Kunden — bei identischem Aufwand.

---

### Tarif III — „Lehrpult" · 29 €/Monat · 290 €/Jahr

**Versprechen:** *Deine Schüler üben zwischen den Stunden — und du siehst, was sie geübt haben.*

Zielgruppe: der **einzelne Klavierlehrer** mit 10–40 Schülern. Laut Masterplan der erste realistisch verkaufbare B2B-Tarif, lange vor Open Studio.

| Zusätzlich zu „Studio" | Status |
|---|---|
| **30 Schülerplätze** — jeder Schüler bekommt Studio-Vollzugang | zu bauen |
| **Lehrer-Dashboard**: wer hat wie lange geübt, wo hakt es | zu bauen (Kern) |
| **Aufgaben zuweisen** („Diese Woche: Shell Voicings, alle 12 Tonarten") | zu bauen |
| **Embed-Widget** für die eigene Website | `/embed` existiert |
| Namensnennung im Trainer („Übungsraum von …") | klein |

**Konditionen:**
- **30 Tage kostenlos testen** mit bis zu 5 Schülern, ohne Karte.
- Monatlich kündbar. Jahreszahlung: 290 € (2 Monate gratis).
- Zusätzliche Schüler über 30: **0,79 €/Schüler/Monat**.
- Schülerplätze sind **keine Konten mit Zahlungspflicht** — der Lehrer zahlt, der Schüler nutzt.

**Warum 29 € stimmen:** Der Lehrer nimmt pro Schüler und Monat 100–200 € ein. 29 € sind ~1 % seines Umsatzes bei 20 Schülern — er verkauft es intern als Serviceverbesserung. Und: **jeder Lehrer bringt 10–40 Nutzer mit**, die uns sonst je einzeln 5–10 € Akquisekosten gekostet hätten. Der Tarif ist daher zugleich unser günstigster Akquisekanal.

---

### Tarif IV — „Institut" · ab 690 €/Jahr

**Versprechen:** *Ein Übungswerkzeug für den gesamten Fachbereich. Die Institution zahlt, alle Studierenden nutzen es.*

Das ist die **strukturelle Antwort auf das Studentengeld-Problem**: Nicht der Student zahlt, sondern sein Budgetträger.

| Stufe | Umfang | Preis/Jahr |
|---|---|---|
| **Institut S** | bis 100 Nutzer, 3 Lehrerzugänge | **690 €** |
| **Institut M** | bis 400 Nutzer, 10 Lehrerzugänge | **1.900 €** |
| **Institut L / Campus** | unbegrenzt, SSO, Custom Branding | **ab 3.900 €**, individuell |

Enthalten: alles aus Lehrpult, plus Custom Branding, LMS/LTI-Anbindung, SSO, API-Zugang, benannter Ansprechpartner, Rechnung auf Institutionsadresse (kein Kreditkartenzwang — für öffentliche Einrichtungen zwingend).

**Konditionen:** Jahresvertrag, Rechnung mit 30 Tagen Zahlungsziel, kostenloses Semesterpilot-Angebot (ein Kurs, 30 Studierende, 3 Monate). Kein Self-Service-Checkout — Kontaktformular und Gespräch.

**Zu Open Studio & Co.:** Läuft nicht über diese Preisliste. Das ist ein individueller White-Label-/Lizenzvertrag (Masterplan Phase 4, ab Q1 2027) und setzt Nutzungsdaten voraus, die wir heute nicht haben.

---

## 3. Was bewusst NICHT hinter die Wand kommt

Diese Entscheidungen sind wichtiger als die, was Pro wird:

| Feature | Bleibt frei, weil |
|---|---|
| **Alle 4 Kurse** | Sie sind unser SEO- und Reichweitenmotor. Ein bezahlter Kurs wird nicht verlinkt und nicht geteilt. |
| **Alle Voicing-Typen** | Wer nur Shell Voicings bekommt, lernt nicht Jazz — er lernt einen Ausschnitt. Ein verkrüppeltes Gratisprodukt erzeugt schlechte Mundpropaganda, und Mundpropaganda ist momentan alles, was wir haben. |
| **MIDI & Mikrofon** | Das ist unser Alleinstellungsmerkmal. Es hinter eine Wand zu stellen, hieße den einen Grund zu verstecken, aus dem uns jemand der Konkurrenz vorzieht. |
| **Der Coach selbst** | Nur die *Menge* wird begrenzt, nie die *Qualität*. Der Coach ist das, worüber geredet wird. |
| **Freies Üben** | Muss immer unbegrenzt bleiben, damit das Tageslimit nie wie eine Aussperrung wirkt. |

---

## 4. Der Trial: Korrektur

**Heute:** `trial_period_days: 14` + `payment_method_collection: 'always'` → Karte vorab.

**Neu: 7 Tage Studio, ohne Karte.**

| | Heute | Neu |
|---|---|---|
| Dauer | 14 Tage | **7 Tage** |
| Karte vorab | ja | **nein** |
| Auslöser | Klick auf „Upgrade" | **automatisch bei Registrierung** |
| Ende | stille Abbuchung | **Ablauf, dann Angebot** |

**Warum ohne Karte:** Kartenpflicht erhöht die Konversion der *Startenden* zu Zahlenden, senkt aber die Zahl der Startenden drastisch — und wir haben ein Mengenproblem, kein Konversionsproblem. Bei 4 Anmeldungen im Monat ist jeder abgeschreckte Trial-Start ein echter Verlust. Außerdem: „Free. No signup." und „Karte bitte" im selben Produkt beschädigt Vertrauen dauerhaft.

**Warum 7 statt 14 Tage:** Wer täglich übt, hat in 7 Tagen den Wert erlebt. Wer in 7 Tagen nicht wiederkam, kommt auch in 14 nicht — er verlängert nur die Zeit bis zur Entscheidung.

**Der wirksamste Moment für das Angebot** ist nicht der Trial-Ablauf, sondern der **zweite Coach-Versuch an einem Tag**: „Deine heutige Session ist gespielt. Mit Studio übst du weiter, so oft du willst." Kontextbezogen, im Moment des echten Wollens.

---

## 5. Studentenrabatt — deine Frage, beantwortet

**Nicht** über einen niedrigen Grundpreis, **sondern** über einen sichtbaren Rabatt:

- **50 % auf Studio und Lehrpult**, Nachweis über Immatrikulationsbescheinigung oder `.edu`/Hochschul-Mailadresse.
- Studio Student: **3,99 €/Monat / 29 €/Jahr**. Jährlich erneuter Nachweis.
- Prominent auf `/pricing` sichtbar, nicht versteckt.

**Begründung:** Ein durchgehend niedriger Preis kostet uns bei jedem zahlungskräftigen Erwachsenen bares Geld und signalisiert allen ein billiges Produkt. Der Rabatt hält den Vollpreis als Anker, macht Großzügigkeit sichtbar und ist genau die Mechanik, die Open Studio bei 39 $/Monat erfolgreich fährt. Und für die wirklich klamme Gruppe ist ohnehin **Tarif I dauerhaft kostenlos und vollwertig** — kein Student ist je ausgeschlossen, er ist nur auf eine Session pro Tag begrenzt.

Ergänzend: „Kannst du es dir nicht leisten? Schreib uns." als stiller Satz auf der Preisseite. Kostet bei unserer Größe fast nichts und erzeugt Wohlwollen.

---

## 6. Erwartungsrechnung

Bewusst konservativ, keine Hockeyschläger.

**Annahmen:** Konversion Besucher → aktiver Nutzer 8 %, aktiver Nutzer → zahlend 3 % (branchenüblich 2–5 % bei starkem Gratisangebot), Jahresabo-Anteil 40 %, monatliche Abwanderung 6 %.

| Meilenstein | Aktive Nutzer/Monat | Studio | Lehrpult | Institut | MRR |
|---|---|---|---|---|---|
| Heute | ~10 | 0 | 0 | 0 | **0 €** |
| Ende Phase 1 (Sep 26) | 30 | 1 | 0 | 0 | **~8 €** |
| Ende Phase 2 (Nov 26) | 150 | 5 | 1 | 0 | **~69 €** |
| Q1 2027 | 400 | 12 | 3 | 0 | **~183 €** |
| Q2 2027 | 800 | 24 | 6 | 1 (S) | **~430 €** |
| Q4 2027 | 2.000 | 60 | 12 | 3 | **~1.000 €** |

**Break-Even (~31 €/Monat inkl. Plausible):** erreicht bei **4 Studio-Abos oder 1 Lehrpult-Kunden** — realistisch in Phase 2.

Die Tabelle sagt vor allem eines: **Der Hebel liegt nicht im Preis, sondern in der Nutzerzahl.** Selbst eine Verdopplung des Studio-Preises ändert weniger als eine Verdopplung der aktiven Nutzer. Deshalb bleibt Monetarisierung Phase 3 und nicht Phase 1.

---

## 7. Umsetzung — Reihenfolge

Nichts davon geschieht vor Abschluss von Masterplan Phase 1 (Retention). Ein Preisschild an einem Produkt, das niemand am zweiten Tag öffnet, verdient nichts.

### Stufe A — Vorbereitung (parallel zu Phase 1, geringer Aufwand)
| # | Aufgabe | Aufwand |
|---|---|---|
| A1 | Trial auf 7 Tage ohne Karte umstellen (`checkout/+server.ts`) | 1 h |
| A2 | Stripe: neue Preise anlegen (Studio 7,99/59, Lehrpult 29/290) + Student-Coupons | 1 h |
| A3 | `FEATURE_GATES` auf neuen Schnitt umstellen | 2 h |

### Stufe B — Die eine wirksame Grenze (Beginn Phase 3)
| # | Aufgabe | Aufwand |
|---|---|---|
| B1 | **Tageslimit für Coach-Sessions** + kontextbezogenes Angebot beim zweiten Versuch | 1–2 Tage |
| B2 | Verlaufsbegrenzung auf 7 Tage im Free-Tarif | 0,5 Tag |
| B3 | To-Go: 4 der 7 Disziplinen auf Studio legen | 0,5 Tag |
| B4 | `/pricing` auf die neuen Tarife und Namen umbauen, Studentenrabatt sichtbar | 1 Tag |
| B5 | Jahresabo im Checkout | 0,5 Tag |

### Stufe C — Lehrpult (nach den ersten 10 Studio-Kunden)
| # | Aufgabe | Aufwand |
|---|---|---|
| C1 | Schülerplätze: Einladungsmechanik, Zuordnung | 3–4 Tage |
| C2 | Lehrer-Dashboard (Übungszeit, Schwachstellen pro Schüler) | 4–5 Tage |
| C3 | Aufgabenzuweisung | 2–3 Tage |

### Stufe D — Institut (nach dem ersten Lehrpult-Kunden)
Kein Self-Service. Kontaktformular, Angebot per Hand, Rechnungsstellung manuell. Erst automatisieren, wenn es mehr als drei Kunden gibt.

---

## 8. Zwei Kennzahlen, die entscheiden

Damit wir nicht am falschen Ende drehen:

1. **Wie viele aktive Nutzer stoßen pro Woche an das Tageslimit?** Ist die Zahl niedrig, ist das Limit zu großzügig oder es üben zu wenige — dann ist Preisarbeit sinnlos und Retention das Thema.
2. **Trial → Zahlend.** Unter 5 % stimmt das Wertversprechen nicht; über 20 % ist das Gratisangebot zu knapp und wir bremsen unser Wachstum.

Beides ist mit der vorhandenen Telemetrie plus Plausible messbar. Vor jeder Preisänderung: erst diese zwei Zahlen ansehen.

---

*Grundlage: Codeanalyse `subscription.ts` / `checkout/+server.ts` / `progress.ts` / `togo.ts`, Produktionsdaten Supabase, Marktdaten 2025–2026, Wettbewerbsanalyse Juli 2026.*
