# PIDscope

**A free, open-source GNU Octave fork of PIDtoolbox for multirotor PID tuning using flight blackbox logs.**

PIDscope is a continuation of [PIDtoolbox](https://github.com/bw1129/PIDtoolbox). It provides graphical tools for analyzing blackbox flight data - spectral analysis, step response, noise heatmaps, PID balance diagnostics, and filter delay estimation - all running natively on GNU Octave without requiring a MATLAB license.

---

## Why PIDscope exists

PIDtoolbox was once the gold standard for blackbox log analysis in the FPV multirotor community. For years it was published on GitHub under the GPL-3.0 license (with individual source files carrying the even more permissive "Beer-Ware" license), and the community embraced it, wrote guides around it, and built entire tuning workflows on top of it.

Then, in May 2024, Brian closed the project's GitHub development, removed all downloadable installers - including those for older, previously free versions - and moved all new releases behind a Patreon paywall. He incorporated a commercial entity (PTB Labs Drone Technology Inc.) and now distributes PIDtoolbox exclusively as a paid subscription product, with a tiered model splitting features between a basic version and a "PRO" variant.

**I fully respect any developer's right to change the licensing of their work and to earn money from their efforts.** Brian invested years of work into PIDtoolbox. If he had simply stopped publishing new code under GPL-3.0, there would be nothing to criticize.

**But that is not what happened.**

### Sabotaging the GPL-published code

What happened went beyond a simple license change. The open-source versions already published under GPL-3.0 were left in a degraded state:

- **Left the source code on GitHub in a deliberately degraded state.** The code remaining in the repository (v0.58) contains errors and missing algorithmic sections that render it unable to properly parse log files from Betaflight 4.x and later. Core analysis routines - the very heart of what makes PIDtoolbox useful - were stripped or broken in the publicly available GPL-licensed codebase.

- **Stripped key algorithmic sections from already-published GPL code.** Critical portions of the signal processing pipeline, spectral analysis routines, and log parsing logic were removed or neutered in the repository that remains publicly visible under the GPL-3.0 license.

This is why PIDscope exists. Not because of the paywall - but because the GPL-licensed code left on GitHub was no longer functional, and the community deserved a working tool.

### What PIDscope does about it

PIDscope is built on top of the GPL-3.0 code that Brian published before he chose to switch to a paid model. I am:

- **Restoring and fixing** the broken algorithmic sections that were stripped from the public repository.
- **Porting everything to GNU Octave** so you don't need a MATLAB license.
- **Adding modern features** - Betaflight 4.x/2025.12 support, Linux packaging (AppImage, Flatpak), and more firmware support (FETTEC, QuickSilver, Rotorflight).
- **Keeping it GPL-3.0 forever.** This code will never disappear behind a paywall. Period.

I am continuing Brian's original work in the spirit he once championed - back when PIDtoolbox carried the Beer-Ware license and an invitation to buy the author a beer if you found his work worthwhile. I thought it was worthwhile.

### Supporting PIDscope

PIDscope is free. It will always be free. There is no paywall, no "PRO" tier, no subscription, no locked features. You get the full thing, no strings attached.

That said - if you find PIDscope useful and want to buy me a coffee (not a beer, I'm not making that joke twice), you can do so here. There is absolutely no obligation. I built this because I needed it and because the community deserves an open tool - not because I'm looking to monetize your hobby.

<a href="https://www.buymeacoffee.com/dzikus" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
---

## License

PIDscope is licensed under the [GNU General Public License v3.0](LICENSE).

This project is a derivative work based on PIDtoolbox, originally published under GPL-3.0. All rights granted by that license are exercised in accordance with its terms.