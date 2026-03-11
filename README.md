# openlca-nix


A Nix flake for packaging [openLCA](https://www.openlca.org) - a free, open source software for Life Cycle Assessment (LCA) and sustainability analysis on NixOS.
### The packaging challenge

openLCA ships as a pre-built Eclipse RCP app bundled with its own JRE, Intel MKL, and SWT bindings. On standard distros, these "just work." On **NixOS**, they break. Because NixOS lacks a global `/lib`, bundled binaries can't find dependencies. This flake fixes that by: 
* ***Patching** ELF binaries for the Nix store. 
* **Wrapping** the app with the correct `LD_LIBRARY_PATH`. 
* **Fixing WebKitGTK** so the internal browser actually renders.
## Requirements

- NixOS with flakes enabled
- x86_64 architecture
- `nixpkgs.config.allowUnfree = true` (required for Intel MKL)

## Installation

### Option 1: Add to your NixOS system flake (recommended)

In your `/etc/nixos/flake.nix`, add `openlca-nix` as an input:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # ... your other inputs ...

  openlca-nix = {
    url = "github:peaceofsense/openlca-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Then pass it into your NixOS configuration and add the package:

```nix
outputs = { self, nixpkgs, openlca-nix, ... }@inputs:
{
  nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./configuration.nix
      {
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = [
          openlca-nix.packages.${system}.default
        ];
      }
    ];
  };
};
```

Then rebuild your system:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#yourhostname
```

### Option 2: Try it without installing

```bash
nix run github:peaceofsense/openlca-nix
```

### Option 3: Install temporarily with nix profile

```bash
nix profile install github:peaceofsense/openlca-nix
```

## Running

After installation, you can launch openLCA from your application menu or run:

```bash
openlca
```

On first launch, openLCA will create a workspace directory at `~/openLCA-data-1.4`.

## Updating to a new version

When GreenDelta releases a new version:

1. Get the new download URL from [openLCA downloads](https://www.openlca.org/download/)
2. Get the new hash:
   ```bash
   nix-prefetch-url --type sha256 "YOUR_NEW_DOWNLOAD_URL"
   ```
3. Update `version` and the `sha256` in `flake.nix`
4. Commit and push

## Acknowledgements

- [GreenDelta](https://www.greendelta.com) for developing and maintaining openLCA
- The NixOS community for `autoPatchelfHook` and packaging tooling

## License

The Nix packaging code in this repository is released under the MIT License.
openLCA itself is licensed under the [Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/2.0/).
Intel MKL is subject to the [Intel Simplified Software License](https://www.intel.com/content/www/us/en/developer/articles/license/end-user-license-agreement.html).
