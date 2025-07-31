{
  pkgs,
  user,
  inputs,
  ...
}:
{
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  xdg.desktopEntries."nvim" = {
    name = "nvim";
    icon = "nvim";
    exec = ''sh -c "exec \\$TERMINAL nvim %F"'';
    terminal = false;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = with pkgs; [
    nixfmt
  ];

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    nixpkgs.config.allowUnfree = true;

    extraPackages = with pkgs; [
      glslls
      ripgrep
    ];

    opts = {
      number = true;
      relativenumber = true;
      scrolloff = 8;
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
      signcolumn = "yes";
      backup = false;
      swapfile = false;
      undofile = true;
      undodir = "/${user.home}/.vim/undodir";
      exrc = true;
    };

    files = {
      "ftplugin/sh.lua" = {
        opts = {
          shiftwidth = 4;
          tabstop = 4;
          softtabstop = 4;
        };
      };
      "ftplugin/markdown.lua" = {
        opts = {
          wrap = true;
          breakindent = true;
          linebreak = true;
        };
      };
      "ftplugin/make.lua" = {
        opts = {
          tabstop = 4;
        };
      };
    };

    colorschemes.dracula.enable = true;
    highlightOverride = {
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

    globals.mapleader = " ";
    keymaps = [
      {
        action = ":CHADopen<CR>";
        key = "t";
        mode = "n";
      }
      {
        action = "<cmd>Trouble diagnostics toggle<CR>";
        key = "<leader>t";
        mode = "n";
      }
      {
        # this is here because it needs insert mode
        action.__raw = "vim.lsp.buf.signature_help";
        key = "<C-h>";
        mode = "i";
      }
      {
        # don't override buffer when pasting
        action = ''"_dP'';
        key = "p";
        mode = "x";
      }
      {
        # copy to system clipboard
        action = ''"+y'';
        key = "<leader>y";
        mode = [
          "n"
          "x"
        ];
      }
      {
        # no macro menu
        action = "<nop>";
        key = "q";
        mode = "n";
      }
      # move between windows with ctrl hjkl
      {
        action = "<C-w>h";
        key = "<C-h>";
        mode = "n";
      }
      {
        action = "<C-w>j";
        key = "<C-j>";
        mode = "n";
      }
      {
        action = "<C-w>k";
        key = "<C-k>";
        mode = "n";
      }
      {
        action = "<C-w>l";
        key = "<C-l>";
        mode = "n";
      }
      {
        action = ":Telescope find_files<CR>";
        key = "<leader>ff";
        mode = "n";
      }
      {
        action = ":Telescope live_grep<CR>";
        key = "<leader>fg";
        mode = "n";
      }
    ];

    plugins = {
      # languages
      nix.enable = true;
      markdown-preview.enable = true;
      rustaceanvim.enable = true;

      treesitter = {
        enable = true;
        settings = {
          indent.enable = true;
          highlight.enable = true;
        };
      };

      chadtree = {
        enable = true;
        keymap = {
          windowManagement.quit = [
            "q"
            "t"
          ];
          fileOperations.trash = [ "D" ];
        };
      };

      colorizer = {
        enable = true;
        settings.user_default_options.names = false;
      };
      fidget.enable = true;
      lightline.enable = true;
      indent-blankline = {
        settings.indent.char = "|";
        enable = true;
      };
      gitgutter.enable = true;
      telescope.enable = true;
      nvim-autopairs.enable = true;
      trouble.enable = true;
      nvim-lightbulb.enable = true;
      comment.enable = true;
      barbecue.enable = true;
      lastplace.enable = true;
      illuminate.enable = true;
      wakatime.enable = true;
      web-devicons.enable = true;
      cmp-treesitter.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-nvim-lsp-signature-help.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          window.completion.border = "rounded";
          window.documentation.border = "rounded";
          sources = [
            {
              groupIndex = 1;
              name = "nvim_lsp_signature_help";
            }
            {
              groupIndex = 2;
              name = "nvim_lsp";
            }
            {
              groupIndex = 3;
              name = "async_path";
            }
          ];
          preselect = "Item";
          mapping = {
            "<CR>" =
              # lua
              ''
                cmp.mapping({
                  i = function(fallback)
                    if cmp.visible() and cmp.get_active_entry() then
                      cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                    else
                      fallback()
                    end
                  end,
                  s = cmp.mapping.confirm({ select = true }),
                  c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
                })
              '';

            "<C-e>" =
              # lua
              ''cmp.mapping.abort()'';

            "<Tab>" =
              # lua
              ''
                cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  else
                    fallback()
                  end
                end, { "i", "s" })
              '';

            "<S-Tab>" =
              # lua
              ''
                cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_prev_item()
                  else
                    fallback()
                  end
                end, { "i", "s" })
              '';
          };
        };
      };
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            glsl = [ "clang-format" ];
          };
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 500;
          };
        };
      };

      lsp-format.enable = true;

      none-ls = {
        enable = true;
        enableLspFormat = true;
        sources = {
          code_actions = {
            statix.enable = true;
            refactoring.enable = true;
          };
          diagnostics = {
            deadnix.enable = true;
            gitlint = {
              enable = true;
              settings.extraArgs = [
                "--ignore"
                "body-is-missing"
              ];
            };
            selene.enable = true;
          };
          formatting = {
            markdownlint.enable = true;
            sqlfluff.enable = true;
            shfmt = {
              enable = true;
              settings.extraArgs = [
                "-i"
                "4"
                "-ci"
              ];
            };
            stylua.enable = true;
            terraform_fmt.enable = true;
            gofumpt.enable = true;
          };
        };
      };

      lsp = {
        enable = true;
        inlayHints = true;
        keymaps = {
          diagnostic = {
            # vim.diagnostic.#
            "<leader>vd" = "open_float";
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };
          lspBuf = {
            # vim.lsp.buf.#
            "gd" = "definition";
            "gt" = "type_definition";
            "gr" = "references";
            "gi" = "implementation";
            "K" = "hover";
            "<leader>ca" = "code_action";
            "<leader>rn" = "rename";
          };
        };
        servers = {
          nixd = {
            enable = true;
            settings = {
              formatting.command = [ "nixfmt" ];
            };
          };
          lua_ls.enable = true;
          bashls.enable = true;
          tailwindcss.enable = true;
          ts_ls.enable = true;
          hls.enable = true;
          hls.installGhc = false;
          jsonls.enable = true;
          terraformls.enable = true;
          svelte.enable = true;
          eslint.enable = true;
          clangd.enable = true;
          pyright.enable = true;
          ruff.enable = true;
          gopls.enable = true;
          zls.enable = true;
          astro.enable = true;
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [ smartcolumn-nvim ];

    extraConfigLua =
      # lua
      ''
        local cmp_autopairs = require('nvim-autopairs.completion.cmp')
        local cmp = require('cmp')
        cmp.event:on(
          'confirm_done',
          cmp_autopairs.on_confirm_done()
        )

        local _border = "rounded"

        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
          vim.lsp.handlers.hover, {
            border = _border
          }
        )

        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
          vim.lsp.handlers.signature_help, {
            border = _border
          }
        )

        vim.diagnostic.config{
          float={border=_border}
        }

        require('lspconfig.ui.windows').default_options = {
          border = _border
        }

        require("smartcolumn").setup()

        require'lspconfig'.glslls.setup{
          cmd = { 'glslls', '--stdin', '--target-env', 'opengl' },
        }
      '';
  };
}
