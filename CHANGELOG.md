# Changelog

## 0.9.5 (15/11/2026)
- Fix: the help button was hidden behind the window's border.
- Updated a line in the welcome window to match the current design.

## 0.9.4 (15/11/2026)
- Prices now show WoW's gold, silver and copper coin icons.
- Fix: the welcome window could mark itself as seen before it appeared. It shows once more after this update.
- Fix: the help button was invisible in Forever. It's now a question-mark icon in the title bar.

## 0.9.3 (15/11/2026)
- Docks further right, clear of the profession window's tabs.
- Open recipe is greyed out for recipes you haven't learned.
- Hides when you switch to a profession it doesn't guide (Fishing, Skinning, Mining, Herbalism), and comes back when you switch back.

## 0.9.2 (15/11/2026)
- Recipe name now uses the full width, with the Open recipe button on its own row underneath.
- "Not learned yet" is now a red badge beside the Open recipe button (hover to see where to learn it).
- Removed the "Materials checked in game" label.
- More spacing in the step details.

## 0.9.1 (15/11/2026)
- Removed the profession tabs: the guide shows whichever profession window you open, or the last one you viewed.
- Docks further right, so it no longer covers the profession window's own tabs.
- Open recipe: also searches for the recipe and shows unlearned recipes, and says in chat if it can't.
- Fix: a profession from another character could show up after switching characters. Primary professions now come only from your character's own professions list.
- The "move on" tip no longer shows for recipes you haven't learned.

## 0.9.0 (15/11/2026)
- Docks beside your profession window: opens automatically, switches to that profession, and goes back where it was when you close the window. `/pg dock` turns it on or off.
- Auction House prices: with TSM or Auctionator installed, each reagents box shows the Auction House cost of what you still need, and the shopping list shows the total cost to 300.
- Skill-up colours: each step shows the recipe's colour (orange, yellow, green or grey) from your last profession-window scan, with a tip to move on when it turns green or grey.

## 0.8.0 (15/11/2026)
- Welcome window the first time the add-on opens: what it does, how its data becomes accurate, and handy commands.
- Help button (i) in the title bar, and `/pg help`, to open it again.

## 0.7.0 (15/11/2026)
- Vendor ingredient costs: each reagents box shows the total price of the shop-bought items you still need (thread, dye, salt, vials, flux, spices).
- Hover a vendor item to see its price each and the cost of what you still need.
- Prices start as Classic-era estimates, marked "(est.)", and are replaced by the real price when you open a vendor that sells the item.

## 0.6.0 (15/11/2026)
- New WoW-style window: profession portrait, title bar, skill bar, inset content area and "Reagents" box.
- "This step" and "Shopping list" are now proper WoW tabs under the window.
- Profession icon tabs down the right edge replace the dropdown. Only your character's professions are shown.
- "Open recipe" button opens your profession window on the current step's recipe.
- Characters with no professions see a short "visit a trainer" message.

## 0.5.1 (14/11/2026)
- Fix: after switching characters, the profession list could show the previous character's skills. Saved skill numbers are cleared once and refill as you play.
- Per-character data is only saved once the character's name is known.

## 0.5.0 (14/11/2026)
- "Not learned yet" label on steps whose recipe this character hasn't learned (read from your profession window).
- Nearest trainer: steps that need a trainer or a new rank show the closest one for your faction and rank. Click it to open the map; hover to see the next closest.
- `/pg trainers` lists the five nearest trainers in chat.
- Trainer list for all eight professions, including Zephras Isle.

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
