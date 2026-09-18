# Third-party components shipped with PIDscope

PIDscope is distributed under the GNU General Public License v3.0; see `LICENSE`.

The packages below also contain programs written by other authors. Those
programs are covered by their own licences, and the corresponding source for
each is identified here so that anyone who receives a PIDscope package can
obtain it. This satisfies the "clear directions" requirement of GPL-3.0
section 6(d).

## blackbox_decode (Betaflight)

| | |
| --- | --- |
| Upstream | https://github.com/betaflight/blackbox-tools |
| Revision built | `f832acf9cd9dbe5ad8220de1a5f4eb4021523d72` |
| Licence | GPL-3.0 |
| Copyright | the Betaflight / Cleanflight blackbox-tools contributors |

Shipped as `blackbox_decode` (`blackbox_decode.exe` on Windows). Built from
unmodified upstream source. The build scripts that produce it are part of the
corresponding source and live in this repository:

- `packaging/windows/Dockerfile` (Windows, cross-compiled with mingw-w64)
- `packaging/appimage/Dockerfile` (AppImage)
- `packaging/flatpak/com.pidscope.PIDscope.yml` (Flatpak)
- `.github/workflows/release.yml` (macOS, native runners)

## blackbox_decode_INAV (iNav)

| | |
| --- | --- |
| Upstream | https://github.com/iNavFlight/blackbox-tools |
| Revision built | tag `v9.0.0` |
| Licence | GPL-3.0 |
| Copyright | the iNavFlight blackbox-tools contributors |

Shipped as `blackbox_decode_INAV` (`blackbox_decode_INAV.exe` on Windows).
Built from unmodified upstream source on Windows and Linux. The macOS packages
instead ship the official upstream release binaries from
https://github.com/iNavFlight/blackbox-tools/releases/tag/v9.0.0

## GNU Octave (Windows packages only)

| | |
| --- | --- |
| Upstream | https://ftpmirror.gnu.org/gnu/octave/ |
| Version | 11.3.0 |
| Licence | GPL-3.0 |
| Copyright | John W. Eaton and others |

The Windows ZIP bundles the official prebuilt Octave distribution
(`octave-11.3.0-w64.7z`), unmodified apart from the removal of components not
needed at runtime. Source: `octave-11.3.0.tar.lz` from the same location.

Octave itself bundles further third-party libraries; their licence and
copyright notices are kept in place inside the bundled `octave/` directory.

The AppImage links against the system Octave of its build container. The
Flatpak uses the `org.octave.Octave` base from Flathub and does not bundle
Octave itself.

## MATLAB File Exchange helpers

`src/` contains a small number of helper functions originating from the
MathWorks File Exchange. Their original headers, author names and licence
terms are retained in the respective files.

## Obtaining the source

All of the above is public at the URLs and revisions listed. If any of those
locations becomes unavailable, or you would prefer to receive the corresponding
source directly, open an issue at https://github.com/dzikus/PIDscope/issues
and it will be provided.
