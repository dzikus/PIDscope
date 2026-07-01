# Running PIDscope via GNU Octave Flatpak (User-space / No-Sudo)

This guide explains how to install GNU Octave and its required packages in user-space using Flatpak, allowing you to run PIDscope without administrative (`sudo`) privileges.

---

## 1. Prerequisites
Ensure `flatpak` is installed on your Linux system. (If not, install it using your system's package manager).

## 2. Install GNU Octave (User-space)
To install Octave without administrative privileges, add the Flathub repository to your user configuration and install GNU Octave:

```bash
# Add Flathub repository for the user
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install GNU Octave
flatpak install --user -y flathub org.octave.Octave
```

## 3. Install Octave Forge Packages
PIDscope requires several Octave packages. When installing from Octave Forge, they must be compiled in a specific sequence due to inter-package dependencies. Run the following commands in order:

```bash
# 1. Install 'control' (required by signal)
flatpak run org.octave.Octave --no-gui --eval "pkg install -forge control"

# 2. Install 'signal'
flatpak run org.octave.Octave --no-gui --eval "pkg install -forge signal"

# 3. Install 'datatypes' (required by statistics)
flatpak run org.octave.Octave --no-gui --eval "pkg install -forge datatypes"

# 4. Install 'statistics' and 'image'
flatpak run org.octave.Octave --no-gui --eval "pkg install -forge statistics image"
```

To verify the installation, you can list the installed packages:
```bash
flatpak run org.octave.Octave --no-gui --eval "pkg list"
```

## 4. Setup Log Decoders
PIDscope requires `blackbox_decode` and `blackbox_decode_INAV` binaries to be present in the project root directory.

If you already have pre-compiled decoders, copy them into the PIDscope project directory:
```bash
cp /path/to/your/blackbox_decode /path/to/PIDscope/blackbox_decode
cp /path/to/your/blackbox_decode /path/to/PIDscope/blackbox_decode_INAV

# Ensure they are executable
chmod +x /path/to/PIDscope/blackbox_decode /path/to/PIDscope/blackbox_decode_INAV
```
*(Alternatively, you can compile them from source by running `make fetch-blackbox` if you have build dependencies installed.)*

## 5. Verify Installation (Optional)
Run the test suite to ensure everything is set up correctly:
```bash
flatpak run org.octave.Octave --no-gui --eval "addpath(genpath('src')); addpath('tests'); run_tests"
```

## 6. Execute PIDscope
Run the following command to start the PIDscope graphical interface:

```bash
flatpak run org.octave.Octave --gui --persist --eval "cd('/path/to/PIDscope'); PIDscope"
```
*(Replace `/path/to/PIDscope` with the actual path where the repository is cloned on your system).*
