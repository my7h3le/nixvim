{ pkgs, ... }:
{
  # Empty configuration
  empty = {
    plugins.lazy.enable = true;
  };

  test = {
    plugins.lazy = with pkgs.vimPlugins; {
      enable = true;

      # Setup properties can be directly passed
      setup = {
        performance = {
          rtp = {
            # disable some rtp plugins
            disabled_plugins = [
              "gzip"
              "tarPlugin"
              "tohtml"
              "tutor"
              "zipPlugin"
            ];
          };
        };
      };

      plugins = [
        vim-closer

        # Test freeform
        {
          pkg = vim-dispatch;
          # The below is not actually a property in the `lazy.nvim` plugin spec
          # but is purely to test freeform capabilities of the `pluginType`.
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
}
