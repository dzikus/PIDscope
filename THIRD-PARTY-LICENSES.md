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

## Octave Forge packages

The AppImage and Flatpak install the packages below from the upstream release
tarballs listed. Each package keeps its own licence and copyright notices inside
its installed directory, under `packinfo/COPYING` and, where a package carries
additional terms, beside it.

| Package | Version | Upstream tarball | Licence |
| --- | --- | --- | --- |
| control | 4.2.1 | https://github.com/gnu-octave/pkg-control/releases/download/control-4.2.1/control-4.2.1.tar.gz | GPL-3.0-or-later; the bundled SLICOT routines are BSD-3-Clause |
| signal | 1.4.7 | https://github.com/gnu-octave/octave-signal/releases/download/1.4.7/signal-1.4.7.tar.gz | GPL-3.0-or-later; some files are public domain |
| datatypes | 1.1.8 | https://github.com/pr0m1th3as/datatypes/releases/download/release-1.1.8/datatypes-1.1.8.tar.gz | GPL-3.0; the package logo is CC BY-SA 4.0 |
| statistics | 1.8.1 | https://github.com/gnu-octave/statistics/releases/download/release-1.8.1/statistics-1.8.1.tar.gz | GPL-3.0-or-later |
| image | 2.18.1 | https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/image-2.18.1.tar.gz | GPL-3.0-or-later |

The SLICOT copyright notice and its BSD-3-Clause terms travel with the package
as `control-4.2.1/doc/SLICOT/LICENSE`.

The Windows ZIP installs none of these itself; it carries the package set of the
official Octave distribution (control 4.2.1, image 2.20.0, io 2.7.1,
signal 1.4.7, statistics 1.8.3) with their notices retained in place. The macOS
package ships no Octave packages at all - `pidscope.command` fetches them from
the upstream locations above on first launch.

## MATLAB File Exchange helpers

`src/` contains a small number of helper functions originating from the
MathWorks File Exchange. Their original headers, author names and licence
terms are retained in the respective files.

## Obtaining the source

All of the above is public at the URLs and revisions listed. If any of those
locations becomes unavailable, or you would prefer to receive the corresponding
source directly, open an issue at https://github.com/dzikus/PIDscope/issues
and it will be provided.
