{ pkgs, ... }:
{
  # Empty configuration
  empty = {
    plugins.lazy.enable = true;
  };

  test = {
    plugins.lazy = with pkgs.vimPlugins; {
      enable = true;

      plugins = [
        vim-closer

        # Test freeform
        {
          pkg = vim-dispatch;
          # The below is not actually a property in the `lazy.nvim` plugin spec
          # but is purely to test freeform capabilities of the `lazyPluginType`.
          blah = "test";
        }

        # Load on specific commands
        {
          pkg = vim-dispatch;
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
          pkg = vim-matchup;
          event = "VimEnter";
        }

        # Load on a combination of conditions: specific filetypes or commands
        {
          pkg = ale;
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

        # Plugins can have dependencies on other plugins
        {
          pkg = completion-nvim;
          optional = true;
          dependencies = [
            {
              pkg = vim-vsnip;
              optional = true;
            }
            {
              pkg = vim-vsnip-integ;
              optional = true;
            }
          ];
        }

        # Plugins can have post-install/update hooks
        {
          pkg = markdown-preview-nvim;
          cmd = "MarkdownPreview";
        }

        # Post-install/update hook with neovim command
        {
          pkg = nvim-treesitter;
          opts = {
            ensure_installed = { };
          };
        }

        # Use dependency and run lua function after load
        {
          pkg = gitsigns-nvim;
          dependencies = [ plenary-nvim ];
          config = ''function() require("gitsigns").setup() end'';
        }
      ];
    };
  };

  name-only-plugin = {
    plugins.lazy = with pkgs.vimPlugins; {
      enable = true;
      plugins = [
        {
          name = "echasnovski/mini.ai";
          pkg = mini-nvim;
          enabled = false;
        }
        {
          name = "echasnovski/mini.ai";
          enabled = false;
        }
      ];

    };
  };

  url-spec-source-plugin = {
    test.runNvim = false;
    plugins.lazy = {
      settings = {
        dev = {
          fallback = true;
        };
      };
      enable = true;
      plugins = [
        {
          "__unkeyed" = "echasnovski/mini.ai";
          name = "m.ai";
          enabled = true;
          version = false;
        }
        {
          url = "https://github.com/echasnovski/mini.colors";
          name = "m.colors";
          enabled = true;
          version = false;
        }
      ];
    };
  };

  dir-only-plugin = {
    plugins.lazy = with pkgs.vimPlugins; {
      enable = true;
      plugins = [ { dir = "${LazyVim}"; } ];
    };
  };

  single-package = {
    plugins.lazy = with pkgs.vimPlugins; {
      enable = true;

      plugins = [ vim-closer ];
    };
  };

  no-packages = {
    plugins.lazy = {
      enable = true;
      gitPackage = null;
    };
  };

  single-spec = with pkgs.vimPlugins; {
    plugins.lazy =
      let
        devPath = "${vim-dispatch}";
      in
      {
        enable = true;
        settings = {
          dev = {
            path = devPath;
            patterns = [ "." ];
            fallback = false;
          };
        };

        plugins = [
          {
            pkg = vim-dispatch;
            optional = true;
            cmd = [
              "Dispatch"
              "Make"
              "Focus"
              "Start"
            ];
          }
        ];
      };
  };
}
