# MACrossover_Bot

MQL5 Expert Advisor für MetaTrader 5 mit SMA-20/SMA-50-Crossover, Buy- und Sell-Signalen sowie dynamischer Positionsgröße.

Der Bot ist für Demo- und Cent-Kontotests bestimmt. Backtests sind keine Garantie für zukünftige Ergebnisse. Vor Echtgeldbetrieb müssen Brokerbedingungen, Tick-Value, Tick-Size und die tatsächliche Risikowirkung geprüft werden.

## Funktionen

- SMA 20 und SMA 50 auf `PRICE_CLOSE`
- Symbol und Zeitraum kommen vom Chart (`_Symbol`, `PERIOD_CURRENT`)
- Nur abgeschlossene Kerzen 1 und 2; Kerze 0 wird ignoriert
- Bullish: `MA20[2] < MA50[2]` und `MA20[1] > MA50[1]` → Buy
- Bearish: `MA20[2] > MA50[2]` und `MA20[1] < MA50[1]` → Sell
- Maximal eine offene Position über `PositionsTotal()`
- 1 % nominales Risiko, 500 Punkte SL, 1500 Punkte TP, 3:1 RR
- Buy am Ask, Sell am Bid; SL und TP werden mit `SYMBOL_DIGITS` normalisiert
- Lot-Berechnung mit Tick-Value, Tick-Size und `SYMBOL_POINT`
- Volumen wird mit `MathFloor` auf `SYMBOL_VOLUME_STEP` gerundet und auf Min/Max begrenzt
- Code enthält absichtlich keine Kommentare und keine `Print()`-Ausgaben

## Dateien

| Datei | Zweck |
|---|---|
| `MACrossover_Bot.mq5` | Expert-Advisor-Quellcode |
| `.gitignore` | Ausschluss von `.ex5`, Logs und Testerdateien |
| `README.md` | Installation und Betrieb |

## Voraussetzungen

- MetaTrader 5 und MetaEditor für Windows
- Brokerkonto mit aktiviertem Handel
- Windows-VPS für den Dauerbetrieb
- Demo- oder Cent-Konto für erste Tests
- Historische Kursdaten für den Strategy Tester

Die mobile MT5-App führt keine Expert Advisors aus. Der EA muss auf dem Windows-VPS laufen.

## Installation

```bash
git clone https://github.com/MuzzyWRLD/TradingbotM5.git
```

1. In MT5 `Datei -> Datenordner öffnen` wählen.
2. `MQL5/Experts` öffnen und `MACrossover_Bot.mq5` hineinkopieren.
3. Datei in MetaEditor öffnen und mit `F7` kompilieren.
4. Nach fehlerfreier Kompilierung im Navigator bei `Expert Advisors` rechtsklicken und `Aktualisieren` wählen.

Die `.ex5`-Datei wird lokal erzeugt und nicht in Git versioniert. Eine MetaEditor-Kompilierung ist nur in der MT5-Windows-Umgebung möglich.

## Chart einrichten

1. `Extras -> Optionen -> Expert Advisors` öffnen und `Algo-Trading zulassen` aktivieren.
2. Den globalen Algo-Trading-Schalter prüfen.
3. Den EA auf den vorbereiteten Chart ziehen und im Dialog unter `Allgemein` Algo-Trading erlauben.

Für erste Tests sind EURUSD oder GBPUSD sinnvoll. Der Bot handelt den Namen des Charts; Broker-Suffixe wie `EURUSD.pro` müssen berücksichtigt werden.

`PERIOD_CURRENT` übernimmt den Zeitrahmen des Charts. H1 oder H4 sind Ausgangspunkte für die 500-Punkte-Stop-Distanz. M1/M5 dürfen nicht ungeprüft verwendet werden.

Für die visuelle Kontrolle zwei Moving Averages ergänzen: Periode `20`, Methode `Simple`, Anwenden auf `Close`; sowie Periode `50`, Methode `Simple`, Anwenden auf `Close`.

Bullish: Buy am `Ask`, SL `Ask - 500 × Point`, TP `Ask + 1500 × Point`.

Bearish: Sell am `Bid`, SL `Bid + 500 × Point`, TP `Bid - 1500 × Point`.

SL und TP werden mit `NormalizeDouble()` auf `SYMBOL_DIGITS` gerundet.

`PositionsTotal() > 0` beendet die Tickverarbeitung. Die Prüfung gilt für das gesamte Konto, nicht nur für das Chart-Symbol.

## Risiko- und Lot-Berechnung

```text
Risiko-Geld = Kontostand × 1 %
SL-Preisabstand = 500 × SYMBOL_POINT
SL-Ticks = SL-Preisabstand / SYMBOL_TRADE_TICK_SIZE
Verlust für 1 Lot = SL-Ticks × SYMBOL_TRADE_TICK_VALUE
Rohes Volumen = Risiko-Geld / Verlust für 1 Lot
```

Das rohe Volumen wird mit `MathFloor(raw_lot / SYMBOL_VOLUME_STEP) * SYMBOL_VOLUME_STEP` abgerundet und auf `SYMBOL_VOLUME_MIN` und `SYMBOL_VOLUME_MAX` begrenzt. Bei ungültigen Tick- oder Volume-Werten wird kein Trade eröffnet.

Wenn das Volumen kleiner als das Broker-Minimum ist, wird das Minimum verwendet. Das tatsächliche Risiko kann dann über 1 % liegen.

### Cent-Konten

Cent-Konten werden unterschiedlich dargestellt. Häufig steht `USC` oder `EUC` als Kontowährung und der Kontostand wird in Cent geliefert. Andere Broker melden die Hauptwährung und skalieren die Kontraktdaten anders.

Der EA berücksichtigt das vorgesehene Cent-Modell über Währungssuffix und Balance-Heuristik. Das ersetzt keine Prüfung: Kontowährung, Kontostand, Tick-Value, Tick-Size, Volume-Minimum und Volume-Step müssen in MT5 und im Tester geprüft werden. Bei unklarer Skalierung nicht mit Echtgeld starten.

Die Werte 1,0 % Risiko, 500 Punkte SL und 1500 Punkte TP sind fest im Code vorgegeben.

## Strategy Tester

Vor Echtgeldbetrieb mindestens einen historischen und einen Forward-Test durchführen:

1. `Strg+R` oder `Ansicht -> Strategietester` öffnen.
2. `MACrossover_Bot`, dasselbe Symbol und denselben Zeitraum wie im Live-Chart auswählen.
3. Modell `Jeder Tick basierend auf realen Ticks` wählen.
4. Sechs bis zwölf Monate testen und das Startkapital eintragen.
5. `Graph`, `Ergebnisse`, `Bericht` und `Journal` prüfen.

Kontrollieren: SL/TP-Richtung, maximal eine Position, Volumenlimits, Drawdown, Spread, Kommissionen und Trade-Anzahl. Ein Profit Factor über 1,0 allein ist keine Echtgeldfreigabe.

## Logs

Mit `Strg+T` öffnet sich die Toolbox. `Experten` zeigt EA-Meldungen, sofern der EA welche ausgibt. `Journal` zeigt MT5-System, Verbindung und Handelsereignisse.

Der Quellcode enthält absichtlich keine `Print()`-Ausgaben. Es gibt daher keine eigenen beschreibenden Statusmeldungen im Experten-Tab. Order- und Systemereignisse können im Journal und in den Terminal-Logs erscheinen. Typische Verzeichnisse sind `MQL5/Logs` und `Logs` im MT5-Datenordner.

## Mobile Kontrolle

Die offizielle MT5-App führt den EA nicht aus. Der EA läuft auf dem Windows-VPS. Auf dem Nothing Phone MT5 installieren, `Konten verwalten -> +` öffnen, Broker und exakten Kontoserver auswählen und die Kontodaten eingeben. Für reine Überwachung eignet sich ein Investor-Passwort; das Master-Passwort erlaubt manuelle Eingriffe.

## Versionskontrolle

Versioniert werden `MACrossover_Bot.mq5`, `README.md` und `.gitignore`. Nicht versioniert werden `.ex5`, MT5-Logs, Tester-Daten, Binärdateien und IDE-Benutzerdaten.

Vor jedem Live-Update muss die neue Datei kompiliert sowie im Strategy Tester und auf einem Demo-Konto geprüft werden.

## Sicherheitscheckliste

- [ ] MetaEditor kompiliert ohne Fehler und Warnungen.
- [ ] Reale-Ticks-Backtest und Demo-Forward-Test wurden ausgeführt.
- [ ] Tick-Value, Tick-Size, Volume-Minimum und Volume-Step sind geprüft.
- [ ] Risiko der Mindestlot-Regel ist verstanden.
- [ ] Algo-Trading ist global und am Chart aktiviert.
- [ ] VPS bleibt online und MT5 ist angemeldet.
- [ ] Symbol und Broker-Server sind korrekt.
- [ ] Nur Kapital einsetzen, dessen Verlust verkraftbar ist.
