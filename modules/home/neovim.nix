{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
{
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  sops.secrets.wakatime-api-key = { };
  sops.templates."wakatime.cfg" = {
    content = # toml
      ''
        [settings]
        debug = false
        hidefilenames = false
        ignore =
            COMMIT_EDITMSG$
            PULLREQ_EDITMSG$
            MERGE_MSG$
            TAG_EDITMSG$
        api_key=${config.sops.placeholder.wakatime-api-key}
      '';
    path = "${config.home.homeDirectory}/.wakatime.cfg";
  };

  xdg.desktopEntries."nvim" = {
    name = "nvim";
    icon = "nvim";
    exec = ''sh -c "exec \\$TERMINAL nvim %F"'';
    terminal = false;
  };

  home.packages = with pkgs; [
    nixfmt # allows overriding of nixfmt in a devshell to use project specific formatting
  ];

  programs.nvf = {
    enable = true;
    enableManpages = true;
    defaultEditor = true;
  };

  programs.nvf.settings.vim = {
    vimAlias = true;

    options = {
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      expandtab = true;
      autoindent = true;
      smartindent = true;
      wrap = false;
      hlsearch = true;
      incsearch = true;
      termguicolors = true;
      cursorline = true;
      undofile = true;
      undodir = "${config.home.homeDirectory}/.vim/undodir";
    };

    lsp = {
      enable = true;
      formatOnSave = true;
      lightbulb.enable = true;
      trouble.enable = true;
      lspSignature.enable = true;

      servers = {
        "json-ls" = {
          cmd = [
            "vscode-json-language-server"
            "--stdio"
          ];
          filetypes = [ "json" ];
        };

        clangd.cmd = lib.mkForce [
          "clangd"
          "--background-index"
          "--query-driver=**"
        ];

        basedpyright.settings = {
          disableOrganizeImports = true;
          basedpyright.analysis = {
            typeCheckingMode = "basic";
            diagnosticSeverityOverrides.reportAny = "none";
          };
        };

        nixd = {
          cmd = lib.mkForce [
            (lib.getExe pkgs.nixd)
            "--semantic-tokens=true"
          ];
          settings.nixd = {
            options =
              let
                flake = ''(builtins.getFlake "$HOME/code/nix-infra")'';
              in
              {
                nixos = {
                  expr = "${flake}.nixosConfigurations.${osConfig.networking.hostName}.options";
                };
                home_manager = {
                  expr = "${flake}.nixosConfigurations.${osConfig.networking.hostName}.home-manager.users.type.getSubOptions []";
                };
                flake_parts = {
                  expr = "${flake}.debug.options";
                };
                flake_parts2 = {
                  expr = "${flake}.currentSystem.options";
                };
              };
          };
        };
      };
    };

    extraPackages = with pkgs; [
      vscode-json-languageserver
      fixjson
    ];

    startPlugins = with pkgs.vimPlugins; [ cmp-async-path ];

    extraPlugins = {
      remember-nvim = {
        package = pkgs.vimPlugins.remember-nvim;
        setup = "require('remember').setup {}";
      };

      guess-indent-nvim = {
        package = pkgs.vimPlugins.guess-indent-nvim;
        setup = "require('guess-indent').setup {}";
      };
    };

    binds = {
      whichKey.enable = true;
      cheatsheet.enable = true;
    };

    keymaps = [
      {
        key = "t";
        mode = "n";
        silent = true;
        unique = true;
        action = ":Neotree toggle<CR>";
      }
      {
        key = "<leader>t";
        mode = "n";
        silent = true;
        unique = true;
        action = ":Trouble diagnostics toggle<CR>";
      }
      {
        key = "<leader>ca";
        mode = "n";
        silent = true;
        lua = true;
        action = "vim.lsp.buf.code_action";
      }
      {
        key = "<C-h>";
        mode = "i";
        silent = true;
        lua = true;
        action = "vim.lsp.buf.signature_help";
      }
      {
        # don't override buffer when pasting
        key = "p";
        mode = [
          "v"
        ];
        action = ''"_dP'';
      }
      {
        # copy to system clipboard
        key = "<leader>y";
        mode = [
          "n"
          "v"
        ];
        action = ''"+y'';
      }
      {
        # no macro menu
        key = "q";
        mode = "n";
        silent = true;
        action = "<nop>";
      }
      {
        key = "<C-h>";
        mode = "n";
        silent = true;
        action = "<C-w>h";
      }
      {
        key = "<C-j>";
        mode = "n";
        silent = true;
        action = "<C-w>j";
      }
      {
        key = "<C-k>";
        mode = "n";
        silent = true;
        action = "<C-w>k";
      }
      {
        key = "<C-l>";
        mode = "n";
        silent = true;
        action = "<C-w>l";
      }
    ];

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix = {
        enable = true;
        lsp.servers = [ "nixd" ];
        format.type = [ "nixfmt" ];
      };
      markdown.enable = true;
      bash.enable = true;
      clang.enable = true;
      sql.enable = true;
      go.enable = true;
      zig.enable = true;
      rust = {
        enable = true;
        format.enable = true;
        lsp.opts = ''
          ['rust-analyzer'] = {
            cargo = {allFeature = true},
            checkOnSave = true,
            procMacro = {
              enable = true,
            },
          },
        '';
      };
      python = {
        enable = true;
        format.type = [
          "ruff"
          "ruff-check"
        ];
      };

      # web dev
      ts.enable = true;
      css.enable = true;
      html.enable = true;
      tailwind.enable = true;
      astro.enable = true;
      svelte.enable = true;
    };

    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        formatters_by_ft = {
          nix = [ "nixfmt" ];
          glsl = [ "clang-format" ];
          json = [ "fixjson" ];
        };
      };
    };

    visuals = {
      nvim-web-devicons.enable = true;
      nvim-cursorline.enable = true;
      highlight-undo.enable = true;
      indent-blankline.enable = true;
    };

    statusline.lualine = {
      enable = true;
      globalStatus = false;
    };

    theme = {
      enable = true;
      name = "dracula";
      transparent = true;
    };

    autopairs.nvim-autopairs.enable = true;

    autocomplete.nvim-cmp = {
      enable = true;
      setupOpts = {
        completion.completeopt = "menu,menuone,longest,fuzzy";
      };
      sources = lib.mkForce {
        "nvim_lsp" = "[LSP]";
        "nvim_lsp_signature_help" = null;
        "async_path" = "[Path]";
      };
    };

    treesitter.grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      regex
      ini
      yaml
      toml
      diff
      hcl
    ];

    filetree.neo-tree = {
      enable = true;
      setupOpts = {
        git_status_async = true;
        filesystem.follow_current_file = {
          enabled = true;
          leave_dirs_open = false;
        };
      };
    };

    highlight = {
      Normal.bg = "none";
      NormalFloat.bg = "none";
      WinSeparator = {
        bg = "none";
        fg = "#eaeaea";
      };
      VirtColumn.fg = "#000000";
      SignColumn.bg = "none";
      Pmenu.bg = "none";
    };

    git = {
      enable = true;
      gitsigns.enable = true;
    };

    notify.nvim-notify = {
      enable = true;
      setupOpts.background_colour = "#000000";
    };

    ui = {
      borders = {
        enable = true;
        plugins = {
          lsp-signature.enable = true;
          nvim-cmp.enable = true;
          which-key.enable = true;
        };
      };
      colorizer.enable = true;
    };

    comments.comment-nvim.enable = true;

    telescope.enable = true;

    utility = {
      vim-wakatime.enable = true;
    };
  };
}
