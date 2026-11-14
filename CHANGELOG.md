# Changelog

## 0.4.1 (14/11/2026)
- Rank training reminders are hidden once you've already trained that rank.
- Budget Leatherworking route checked in game: all 20 steps confirmed.

## 0.4.0 (14/11/2026)
- New Fast / Budget route switch (Leatherworking for now).
- Budget Leatherworking route: no elixirs or gems, and about 180 Heavy Scorpid Scales instead of about 420, for a similar number of crafts.
- Each profession remembers which route you picked.

## 0.3.2 (14/11/2026)
- Renamed to ProfGuide Forever (folder: `ProfGuideForever`). Saved settings start fresh once.
- Added `/pgf` as a slash command that won't clash with other add-ons.

## 0.3.1 (14/11/2026)
- Reads both modern and Classic-style profession windows.
- `/pg check` now shows unconfirmed recipes, recipes whose materials differ in game, and when the last scan ran.
- Fix: game events are registered safely, so an unknown event can't stop the add-on loading.
- Fix: recipes for gathered materials (e.g. Light Leather) are now read from the profession window.
- Leatherworking checked in game: all 25 steps confirmed.

## 0.3.0 (14/11/2026)
- Minimap button: click to show or hide the panel, and drag it to move it around the minimap.
- `/pg minimap` hides or shows the button.
- Icon shown in the AddOns list and the minimap add-on menu.

## 0.2.0 (14/11/2026)
- Added Alchemy, Blacksmithing, Enchanting, Engineering, Tailoring, Cooking and First Aid.
- Rebuilt the Leatherworking route using WoW Forever's recipe and skill-range changes.
- Profession dropdown in the header, with your professions listed first.
- Items are recognised by name, and their IDs are learned automatically in game.
- Reads real recipe materials from your profession window and corrects the guide.
- Rank training reminders, plus a warning when you hit your skill cap.
- The shopping list turns crafted parts back into raw materials and shows at most 15 rows.
- New commands: `/pg check` and `/pg reset`.

## 0.1.0 (14/11/2026)
- First release.
- Leatherworking 1–300 route.
- "This step" view with have/need counts from your bags and bank.
- Shopping list from your current skill to 300.
- Movable panel that remembers its position, opened with `/pg`.
