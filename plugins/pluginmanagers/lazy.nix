{
  lib,
  helpers,
  pkgs,
  ...
}:
with lib;
nixvim.neovim-plugin.mkNeovimPlugin {
  name = "lazy";
  originalName = "lazy.nvim";
  package = "lazy-nvim";

  maintainers = with maintainers; [
    MattSturgeon
    my7h3le
  ];

  extraOptions =
    let
      # A plugin defined in the `nixvim.plugins.lazy.plugins` list can either
      # be of `types.package`, `types.str`. Depending on the type of the given
      # plugin this plugin will conditionally return an appropriate plugin
      # spec.
      coerceToLazyPluginSpec =
        plugin:
        if lib.isDerivation plugin then
          {
            dir = "${plugin}";
            name = "${lib.getName plugin}";
          }
        else if lib.isString plugin then
          { __unkeyed = plugin; }
        else
          plugin;

      lazyPluginType =
        types.coercedTo (helpers.nixvimTypes.eitherRecursive types.str types.package) coerceToLazyPluginSpec
          (
            types.submodule (
              { config, ... }:

              with types;
              {
                freeformType = attrsOf anything;
                options = {
                  __unkeyed = helpers.mkNullOrOption str ''
                    The "unkeyed" attribute is the plugin's short plugin url.
                    It ill be expanded using `config.git.url_format`. It can
                    also be a url or dir.
                  '';

                  dir = helpers.mkNullOrOption str "A directory pointing to a local plugin";

                  url = helpers.mkNullOrOption str "A custom git url where the plugin is hosted";

                  pkg = helpers.mkNullOrOption package "Vim plugin to install";

                  name = helpers.mkNullOrOption str "Name of the plugin to install";

                  dev = helpers.defaultNullOpts.mkBool false ''
                    When true, a local plugin directory will be used instead.
                    See config.dev
                  '';

                  lazy = helpers.defaultNullOpts.mkBool true ''
                    When true, the plugin will only be loaded when needed.
                    Lazy-loaded plugins are automatically loaded when their Lua modules are required,
                    or when one of the lazy-loading handlers triggers
                  '';

                  enabled = helpers.defaultNullOpts.mkStrLuaFnOr bool "`true`" ''
                    When false then this plugin will not be included in the spec. (accepts fun():boolean)
                  '';

                  cond = helpers.defaultNullOpts.mkStrLuaFnOr bool "`true`" ''
                    When false, or if the function returns false,
                    then this plugin will not be loaded. Useful to disable some plugins in vscode,
                    or firenvim for example. (accepts fun(LazyPlugin):boolean)
                  '';

                  # WARN: be careful changing the type of `dependencies`, if
                  # `helpers.nixvimTypes.eitherRecursive` is not used or a
                  # different type is used without careful manual testing as
                  # well, stack overflow can be caused that won't be picked up
                  # the tests. This happened when changing the type to
                  # `types.listOf lazyPluginsListType`.
                  #
                  # `dependencies` can be a single string as well. Example:
                  #
                  # ```
                  # require("lazy").setup({})
                  #   "hrsh7th/nvim-cmp",
                  #   -- load cmp on InsertEnter
                  #   event = "InsertEnter",
                  #   -- these dependencies will only be loaded when cmp loads
                  #   -- dependencies are always lazy-loaded unless specified otherwise
                  #   dependencies = "hrsh7th/cmp-nvim-lsp",
                  #   config = function()
                  #     -- ...
                  #   end,
                  # },
                  # ```
                  dependencies = helpers.mkNullOrOption (helpers.nixvimTypes.eitherRecursive str lazyPluginsListType) ''
                    A list of plugin names or plugin specs that should be
                    loaded when the plugin loads. Dependencies are always
                    lazy-loaded unless specified otherwise. When specifying a
                    name, make sure the plugin spec has been defined somewhere
                    else. This can also be a single string such as for a short
                      plugin url (See: https://lazy.folke.io/spec).
                  '';

                  init = helpers.mkNullOrLuaFn "init functions are always executed during startup";

                  config = helpers.mkNullOrStrLuaFnOr (enum [ true ]) ''
                    config is executed when the plugin loads.
                    The default implementation will automatically run require(MAIN).setup(opts).
                    Lazy uses several heuristics to determine the plugin's MAIN module automatically based on the plugin's name.
                    See also opts. To use the default implementation without opts set config to true.
                  '';

                  main = helpers.mkNullOrOption str ''
                    You can specify the main module to use for config() and opts(),
                    in case it can not be determined automatically. See config()
                  '';

                  submodules = helpers.defaultNullOpts.mkBool true ''
                    When false, git submodules will not be fetched.
                    Defaults to true
                  '';

                  event =
                    with helpers.nixvimTypes;
                    helpers.mkNullOrOption (maybeRaw (either str (listOf str))) "Lazy-load on event. Events can be specified as BufEnter or with a pattern like BufEnter *.lua";

                  cmd =
                    with helpers.nixvimTypes;
                    helpers.mkNullOrOption (maybeRaw (either str (listOf str))) "Lazy-load on command";

                  ft =
                    with helpers.nixvimTypes;
                    helpers.mkNullOrOption (maybeRaw (either str (listOf str))) "Lazy-load on filetype";

                  keys =
                    with helpers.nixvimTypes;
                    helpers.mkNullOrOption (maybeRaw (either str (listOf str))) "Lazy-load on key mapping";

                  module = helpers.mkNullOrOption (enum [ false ]) ''
                    Do not automatically load this Lua module when it's required somewhere
                  '';

                  priority = helpers.mkNullOrOption number ''
                    Only useful for start plugins (lazy=false) to force loading certain plugins first.
                    Default priority is 50. It's recommended to set this to a high number for colorschemes.
                  '';

                  optional = helpers.defaultNullOpts.mkBool false ''
                    When a spec is tagged optional, it will only be included in the final spec,
                    when the same plugin has been specified at least once somewhere else without optional.
                    This is mainly useful for Neovim distros, to allow setting options on plugins that may/may not be part
                    of the user's plugins
                  '';

                  opts =
                    with helpers.nixvimTypes;
                    helpers.mkNullOrOption (maybeRaw (attrsOf anything)) ''
                      opts should be a table (will be merged with parent specs),
                      return a table (replaces parent specs) or should change a table.
                      The table will be passed to the Plugin.config() function.
                      Setting this value will imply Plugin.config()
                    '';
                };

                config.name = lib.mkIf (config.pkg != null) (lib.mkDefault "${lib.getName config.pkg}");
                config.dir = lib.mkIf (config.pkg != null) (lib.mkDefault "${config.pkg}");
              }
            )
          );

      lazyPluginsListType = types.listOf lazyPluginType;
    in
    {
      gitPackage = lib.mkPackageOption pkgs "git" { nullable = true; };
      luarocksPackage = lib.mkPackageOption pkgs "luarocks" { nullable = true; };

      plugins = mkOption {
        type = lazyPluginsListType;
        default = [ ];
        description = "List of plugins";
      };
    };

  extraConfig = cfg: {
    extraPackages = [
      cfg.gitPackage
      cfg.luarocksPackage
    ];
    plugins.lazy.settings.spec = cfg.plugins;
  };
}
