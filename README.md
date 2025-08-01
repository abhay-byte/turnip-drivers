# Turnip Vulkan Driver for Qualcomm Adreno GPUs

`Turnip` is a fully conformant, open-source Vulkan driver for Qualcomm Adreno 6xx series (and newer) GPUs (Adreno 8xx not supported yet). It is part of the Freedreno project within the Mesa 3D Graphics Library.

# How to build (Fedora 42)

1. Install all build dependenies for mesa.

    ```bash
    sudo dnf builddep mesa
    ```
2. clone mesa repository
    ```bash
    git clone https://gitlab.freedesktop.org/mesa/mesa.git
    cd mesa
    ```
3. Configuring the Build with Meson
    ```bash
    # 1. Configure the build for Turnip (using a new build directory)
    meson build-turnip/ -Dgallium-drivers=freedreno -Dvulkan-drivers=freedreno

    # 2. Compile the driver
    ninja -C build-turnip/
    ```

# How to use 

on Termux

### 1. Install Termux

* Download **Termux** from F-Droid:
   [Download](https://f-droid.org/packages/com.termux/)

* Open Termux and update:

  ```bash
  pkg update && pkg upgrade -y
  ```

---

### 2. Install Termux\:X11

* Install **Termux\:X11** from F-Droid:
  [Download](https://f-droid.org/packages/io.github.termux.x11/)

* Launch Termux\:X11 (black window should appear)

---

### 3. Run Installer Script

Paste this into Termux:

```bash
curl -sL https://raw.githubusercontent.com/abhay-byte/turnip-drivers/refs/heads/master/scripts/install_turnip.sh | bash
```

This sets up everything: Turnip driver, ICD, `vkcube`, and launches the demo.



