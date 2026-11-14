# ProfGuide Forever

An in-game profession levelling guide for **World of Warcraft: Forever**. Stop tabbing out to read guides.

## Features
- **This step:** shows your current recipe, how many crafts are left, where to learn it, and every material as *have / need*.
- **Shopping list:** shows everything you still need to reach 300, minus what's already in your bags and bank.
- Follows your skill automatically and moves to the next step as you level.
- Lets you browse ahead or back with Prev / Next.
- You can drag the panel anywhere; it remembers its position.
- A minimap button opens and closes the panel.
- Shows which recipes you haven't learned yet, and your nearest trainer (click to open the map).

## Professions
All crafting professions from 1 to 300: Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking and Tailoring, plus Cooking and First Aid.

Pick a profession from the dropdown in the panel's header. Your character's professions are listed first.

## Fast or Budget
Leatherworking has two routes. Switch between them with the **Fast | Budget** toggle on the panel:
- **Fast:** the fewest crafts. Some steps use pricier materials.
- **Budget:** cheaper, common materials, for a similar number of crafts.

## Self-correcting data
- Items are recognised **by name**. Their IDs are learned from your bags and profession windows.
- When you open a profession window, ProfGuide reads the real materials for every recipe on the route and uses them from then on. Steps checked this way show "Materials checked in game".

## Usage
| Command | What it does |
|---|---|
| `/pg` or `/pgf` | Show or hide the panel (`/pgf` always works, even if another add-on uses `/pg`) |
| `/pg check` | Check the current profession's data against the game |
| `/pg trainers` | List the nearest trainers for the current profession |
| `/pg minimap` | Hide or show the minimap button |
| `/pg reset` | Move the panel back to its starting position |
| `Esc` | Close the panel |

## Install
1. Download the latest release.
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns\`. You should end up with `AddOns\ProfGuideForever\ProfGuideForever.toc`.
3. Restart the game and make sure ProfGuide Forever is ticked in the AddOns list at character select.

## Project structure
| File | Role |
|---|---|
| `Data/*.lua` | One levelling route per profession (content only) |
| `Data/ItemIDs.lua` | Starter item IDs (hints; verified in game) |
| `Core.lua` | Reads your skill and bags, learns items, and works out what you need |
| `UI.lua` | The panel |

## Licence
MIT. See `LICENSE`.
