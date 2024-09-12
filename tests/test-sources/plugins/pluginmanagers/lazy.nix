{ pkgs, ... }:

# Note: do not use `plenary-nvim` or any plugin that is a `rockspec` for tests,
# this is because `lazy.nvim` by default uses the luarocks package manager to
# process rockspecs. It might be possible to use a rockspec in a test if the
# rockspec itself does not depend on any other rockspecs but this has not been
# tested (See:
# https://github.com/nix-community/nixvim/pull/2082#discussion_r1746585453).
#
# Also the plugins and dependency combinations used in the tests are
# arbitrary.

{
  # Empty configuration
  empty = {
    plugins.lazy.enable = true;
  };

  no-packages = {
    plugins.lazy = {
      enable = true;
      gitPackage = null;
      luarocksPackage = null;
    };
  };

  nix-package-plugins = {
    plugins.lazy = {
      enable = true;

      plugins = with pkgs.vimPlugins; [
        # A plugin can be just a nix package
        vim-closer

        # A plugin can also be an attribute set with `source` set to a nix
        # package.
        { source = trouble-nvim; }
        # `source` can also be a nix store path or path in general.
        { source = "${telescope-nvim}"; }
      ];
    };
  };

  out-of-tree-plugins = {
    # Don't run neovim for this test, as it's purely to test module evaluation.
    test.runNvim = false;
    plugins.lazy = {
      enable = true;

      plugins = with pkgs.vimPlugins; [
        # `source` can also be a short git url of the form `owner/repo`
        { source = "echasnovski/mini.align"; }

        # `source` can also be a full git url with `http://` or `https://`
        {
          source = "https://github.com/nvim-telescope/telescope.nvim";
          enabled = true;
          version = false;
        }
        {
          source = "http://github.com/norcalli/nvim-colorizer.lua";
          enabled = true;
          version = false;
        }
      ];
    };
  };

  general-tests = {
    plugins.lazy = with pkgs.vimPlugins; {
      enable = true;

      plugins = [
        # Test freeform
        {
          source = trouble-nvim;
          # The below is not actually a property in the `lazy.nvim` plugin spec
          # but is purely to test freeform capabilities of the `lazyPluginType`.
          blah = "test";
        }

        # Load on specific commands
        {
          source = vim-dispatch;
          optional = true;
          cmd = [
            "Dispatch"
            "Make"
            "Focus"
            "Start"
          ];
        }

        # Load on an autocommand event
        {
          source = vim-matchup;
          event = "VimEnter";
        }

        # Load on a combination of conditions: specific filetypes or commands
        {
          source = ale;
          name = "w0rp/ale";
          ft = [
            "sh"
            "zsh"
            "bash"
            "c"
            "cpp"
            "cmake"
            "html"
            "markdown"
            "racket"
            "vim"
            "tex"
          ];
          cmd = "ALEEnable";
        }

        # Plugins can have post-install/update hooks
        {
          source = markdown-preview-nvim;
          cmd = "MarkdownPreview";
        }

        # Post-install/update hook with neovim command
        {
          source = nvim-treesitter;
          opts = {
            ensure_installed = { };
          };
        }
      ];
    };
  };
}

# disabling_plugins = {
#   plugins.lazy =
#     with pkgs.vimPlugins;
#     let
#       test_plugin1_path = "${yanky-nvim}";
#       test_plugin2_path = "${whitespace-nvim}";
#     in
#     {
#       enable = true;
#       plugins = [
#         # Enable and then later disable a plugin using it's custom name.
#         {
#           name = "test-mini-nvim";
#           source = mini-nvim;
#           enabled = true;
#         }
#         {
#           source = "test-mini-nvim";
#           enabled = false;
#         }
#
#         # Enable and then later disable a plugin using `source`.
#         {
#           source = vim-closer;
#           enabled = true;
#         }
#         {
#           source = vim-closer;
#           enabled = false;
#         }
#
#         # Enable plugin using `source` and then later disable it using the nix
#         # package's default name.
#         {
#           source = vim-dispatch;
#           enabled = true;
#         }
#         {
#           source = "vim-dispatch";
#           enabled = true;
#         }
#
#         # Enable a plugin using it's path given to `source`
#         {
#           source = test_plugin1_path;
#           # We don't need to specify name to be able to disable it later,
#           # it's just here purely for the sake of the test case.
#           name = "test_plugin1";
#           enabled = true;
#         }
#         # Disable previously enabled test_plugin1 using `source`.
#         {
#           source = test_plugin1_path;
#           enabled = false;
#         }
#
#         # Enable a plugin using it's path given to `source`, but not giving it a
#         # custom name.
#         {
#           source = test_plugin2_path;
#           enabled = true;
#         }
#         # Disable previously enabled test_plugin2 using `source`.
#         {
#           source = test_plugin2_path;
#           enabled = false;
#         }
#       ];
#
#     };
# };

# plugins-with-dependencies = {
#   plugins.lazy = {
#     enable = true;
#     plugins = with pkgs.vimPlugins; [
#       # Plugins can have dependencies on other plugins
#       {
#         source = completion-nvim;
#         optional = true;
#         dependencies = [
#           {
#             source = vim-vsnip;
#             optional = true;
#           }
#           {
#             source = vim-vsnip-integ;
#             optional = true;
#           }
#         ];
#       }
#
#       # Use dependency and run lua function after load
#       {
#         source = nvim-colorizer-lua;
#         dependencies = [ nvim-cursorline ];
#         config = ''
#           function()
#             require("nvim-cursorline").setup{}
#           end '';
#       }
#
#       # Dependencies can be a single package
#       {
#         source = LazyVim;
#         dependencies = trouble-nvim;
#       }
#
#       # Dependencies can be multiple packages
#       {
#         source = nvim-cmp;
#         dependencies = [
#           cmp-cmdline
#           cmp-vsnip
#         ];
#       }
#
#       # Dependencies can be a single name that is defined elsewhere
#       {
#         source = nvim-autopairs;
#         dependencies = "luasnip";
#       }
#       {
#         name = "luasnip";
#         source = luasnip;
#       }
#
#       # Dependencies can be a list of names that are defined elsewhere
#       {
#         source = nvim-lightbulb;
#         dependencies = [
#           "nvim-lspconfig"
#           "cmp-nvim-lua"
#           "cmp-nvim-lsp"
#         ];
#       }
#       {
#         source = nvim-lspconfig;
#         name = "nvim-lspconfig";
#       }
#       {
#         source = cmp-nvim-lua;
#         name = "cmp-nvim-lua";
#       }
#       {
#         source = cmp-nvim-lsp;
#         name = "cmp-nvim-lsp";
#       }
#
#       # Dependencies can be a list of names that are defined elsewhere in the
#       # list of plugins. If the names given are just the default names of a
#       # package they need not be explicitly defined.
#       {
#         source = nui-nvim;
#         dependencies = [
#           "nvim-web-devicons"
#           "lsp-colors.nvim"
#         ];
#       }
#       nvim-web-devicons
#       lsp-colors-nvim
#     ];
#   };
# };

# local-plugin-sourceectory-plugins = {
#   plugins.lazy =
#     with pkgs.vimPlugins;
#     let
#       inherit (pkgs) lib;
#       mkEntryFromDrv = drv: {
#         name = "${lib.getName drv}";
#         path = drv;
#       };
#
#       # Symlink a bunch of test packages to a path in the nix store
#       devPath = pkgs.linkFarm "dev-test-plugins" (
#         map mkEntryFromDrv [
#           nui-nvim
#           vim-vsnip-integ
#           vim-vsnip
#           completion-nvim
#         ]
#       );
#     in
#     {
#       enable = true;
#       settings = {
#         dev = {
#           # Use `devPath` to simulate a local plugin sourceectory path
#           path = "${devPath}";
#           patterns = [ "." ];
#           fallback = false;
#         };
#       };
#
#       plugins = [
#         # Use local plugin that resides in path specified in `devPath` i.e.
#         # `plugins.lazy.settings.dev.path` (See: https://lazy.folke.io/spec)
#         {
#           source = "nui.nvim";
#           dev = true;
#         }
#         # local plugins can have dependencies on other plugins
#         {
#           source = "completion.nvim";
#           dev = true;
#           dependencies = [
#             {
#               source = "vim.vsnip";
#               dev = true;
#             }
#             {
#               source = "vim.vsnip.integ";
#               dev = true;
#             }
#           ];
#         }
#       ];
#     };
# };
# }
