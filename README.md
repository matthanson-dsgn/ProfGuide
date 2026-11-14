# ProfGuide

An in-game profession levelling guide for **World of Warcraft: Forever**. Stop tabbing out to read guides.

## Features
- **This step:** shows your current recipe, how many crafts are left, where to learn it, and every material as *have / need*.
- **Shopping list:** shows everything you still need to reach 300, minus what's already in your bags and bank.
- Follows your skill automatically and moves to the next step as you level.
- Lets you browse ahead or back with Prev / Next.
- You can drag the panel anywhere; it remembers its position.

## Professions
- Leatherworking (1–300)

More professions are coming.

## Usage
| Command | What it does |
|---|---|
| `/pg` or `/profguide` | Show or hide the panel |
| `Esc` | Close the panel |

## Install
1. Download the latest release.
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns\`. You should end up with `AddOns\ProfGuide\ProfGuide.toc`.
3. Restart the game and make sure ProfGuide is ticked in the AddOns list at character select.

## Project structure
| File | Role |
|---|---|
| `Data_Leatherworking.lua` | The levelling route (content only) |
| `Core.lua` | Reads your skill and bags, and works out what you need |
| `UI.lua` | The panel |

## Licence
MIT. See `LICENSE`.
