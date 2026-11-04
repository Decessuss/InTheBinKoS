# Import your styled KoS alert

1. Open **ForeverKoS-Sighting-Card-import.txt** and copy the entire line, starting `!WA:2!`.
2. In TBC WoW, type `/wa`, click **Import**, and paste it into the import box.
3. Review the preview and click **Import**. It creates one group called **<in the bin> KoS List — Sighting Card**.
4. Disable your earlier basic KoS text aura so you get one alert, rather than two. Keep it as a backup until you have tested the new card.
5. Close `/wa`. Open the KoS window and click **Test Alert**, or type `/kos test`.

The card appears above the middle of the screen for eight seconds. It shows the KoS player's name without the realm, the reason and the zone, with a red countdown line. It fades in and out. It has no sound actions; the addon handles sound. Location pins still use the clickable chat link.

To move it: open `/wa`, select the **whole group**, and drag its preview. Change the group's **Scale** to resize the entire design. Avoid moving each child individually.

When sightings arrive close together, the newest one replaces the card and resets its eight-second duration. Earlier sightings remain in chat. Long names/reasons may wrap; test with your actual list and adjust group scale or text sizes if necessary.

The preview PNG is an illustration of the layout, not an in-game screenshot. The import has been decoded and checked with your installed WeakAuras serialization libraries, and its Lua triggers and text functions have been executed in a simulated environment. Actual import, fonts, layering and animation still need an in-game check. This version targets your installed TBC WeakAuras 5.22.1; ForeverAuras import compatibility needs a separate test.
