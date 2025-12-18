{
  description = "Joinemm's Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };

    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    flake-root.url = "github:srid/flake-root";
    flake-utils.url = "github:numtide/flake-utils";

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
        utils.follows = "flake-utils";
      };
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        website-builder.follows = "";
      };
    };

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs = {
        flake-utils.follows = "flake-utils";
      };
    };

    ghaf-infra = {
      url = "github:tiiuae/ghaf-infra";
      # we only want one file from here, none of the nix code needs to be evaluated.
      # save some space by not downloading all the inputs.
      flake = false;
    };

    copyparty = {
      url = "github:9001/copyparty";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./modules
        ./hosts
        ./keyboards
        ./nix
        ./pkgs
      ];
    };
}
