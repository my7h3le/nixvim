{ lib, pkgs, ... }:
let
  inherit (lib.nixvim)
    defaultNullOpts
    mkNullOrOption
    mkNullOrLuaFn
    mkNullOrStrLuaFnOr
    ;
  inherit (lib) types;
in
lib.nixvim.neovim-plugin.mkNeovimPlugin {
  name = "lazy";
  originalName = "lazy.nvim";
  package = "lazy-nvim";

  maintainers = with lib.maintainers; [
    MattSturgeon
    my7h3le
  ];

  extraOptions =
    let
      # A plugin defined in the `nixvim.plugins.lazy.plugins` list can either
      # be of `types.package` or `types.str`. Depending on the type of the
      # given plugin this plugin will conditionally return an appropriate
      # plugin spec.
      coerceToLazyPluginSpec =
        plugin:
        if lib.isDerivation plugin then
          {
            dir = lib.mkDefault "${plugin}";
            name = lib.mkDefault "${lib.getName plugin}";
          }
        else if lib.isString plugin then
          { __unkeyed = lib.mkDefault plugin; }
        else
          plugin;

      lazyPluginCoercableType = with types; either str package;

      lazyPluginType = types.coercedTo lazyPluginCoercableType coerceToLazyPluginSpec (
        types.submodule (
          { config, ... }:

          let
            cfg = config;
          in
          with types;
          {
            freeformType = attrsOf anything;
            options = {
              __unkeyed = mkNullOrOption str ''
                The "unkeyed" attribute is the plugin's short plugin url.
                It ill be expanded using `config.git.url_format`. It can
                also be a url or dir.
              '';

              dir = mkNullOrOption str "A directory pointing to a local plugin";

              url = mkNullOrOption str "A custom git url where the plugin is hosted";

              pkg = mkNullOrOption package "Vim plugin to install";

              name = mkNullOrOption str "Name of the plugin to install";

              dev = defaultNullOpts.mkBool false ''
                When true, a local plugin directory will be used instead.
                See config.dev
              '';

              lazy = defaultNullOpts.mkBool true ''
                When true, the plugin will only be loaded when needed.
                Lazy-loaded plugins are automatically loaded when their Lua modules are required,
                or when one of the lazy-loading handlers triggers
              '';

              enabled = defaultNullOpts.mkStrLuaFnOr bool "`true`" ''
                When false then this plugin will not be included in the spec. (accepts fun():boolean)
              '';

              cond = defaultNullOpts.mkStrLuaFnOr bool "`true`" ''
                When false, or if the function returns false,
                then this plugin will not be loaded. Useful to disable some plugins in vscode,
                or firenvim for example. (accepts fun(LazyPlugin):boolean)
              '';

              # WARNING: Be very careful when changing the type of
              # `dependencies`. Choosing the wrong type may cause a stack
              # overflow due to infinite recursion, and it's possible that the
              # test cases won't catch this problem. To be safe, perform
              # thorough manual testing if you change the type of
              # `dependencies`. Also use `types.eitherRecursive` instead of
              # `types.either` here, as using just `types.either` also leads to
              # stack overflow. 
              dependencies = mkNullOrOption (types.eitherRecursive lazyPluginType lazyPluginsListType) ''
                A list of plugin names or plugin specs that should be
                loaded when the plugin loads. Dependencies are always
                lazy-loaded unless specified otherwise. When specifying a
                name, make sure the plugin spec has been defined somewhere
                else. This can also be a single string such as for a short
                  plugin url (See: https://lazy.folke.io/spec).
              '';

              init = mkNullOrLuaFn "init functions are always executed during startup";

              config = mkNullOrStrLuaFnOr (enum [ true ]) ''
                config is executed when the plugin loads.
                The default implementation will automatically run require(MAIN).setup(opts).
                Lazy uses several heuristics to determine the plugin's MAIN module automatically based on the plugin's name.
                See also opts. To use the default implementation without opts set config to true.
              '';

              main = mkNullOrOption str ''
                You can specify the main module to use for config() and opts(),
                in case it can not be determined automatically. See config()
              '';

              submodules = defaultNullOpts.mkBool true ''
                When false, git submodules will not be fetched.
                Defaults to true
              '';

              event =
                with types;
                mkNullOrOption (maybeRaw (either str (listOf str))) "Lazy-load on event. Events can be specified as BufEnter or with a pattern like BufEnter *.lua";

              cmd = with types; mkNullOrOption (maybeRaw (either str (listOf str))) "Lazy-load on command";

              ft = with types; mkNullOrOption (maybeRaw (either str (listOf str))) "Lazy-load on filetype";

              keys = with types; mkNullOrOption (maybeRaw (either str (listOf str))) "Lazy-load on key mapping";

              module = mkNullOrOption (enum [ false ]) ''
                Do not automatically load this Lua module when it's required somewhere
              '';

              priority = mkNullOrOption number ''
                Only useful for start plugins (lazy=false) to force loading certain plugins first.
                Default priority is 50. It's recommended to set this to a high number for colorschemes.
              '';

              optional = defaultNullOpts.mkBool false ''
                When a spec is tagged optional, it will only be included in the final spec,
                when the same plugin has been specified at least once somewhere else without optional.
                This is mainly useful for Neovim distros, to allow setting options on plugins that may/may not be part
                of the user's plugins
              '';

              opts =
                with types;
                mkNullOrOption (maybeRaw (attrsOf anything)) ''
                  opts should be a table (will be merged with parent specs),
                  return a table (replaces parent specs) or should change a table.
                  The table will be passed to the Plugin.config() function.
                  Setting this value will imply Plugin.config()
                '';
            };

            config.name = lib.mkIf (cfg.pkg != null) (lib.mkDefault "${lib.getName cfg.pkg}");
            config.dir = lib.mkIf (cfg.pkg != null) (lib.mkDefault "${cfg.pkg}");
          }
        )
      );

      lazyPluginsListType = types.listOf lazyPluginType;
    in
    {
      gitPackage = lib.mkPackageOption pkgs "git" { nullable = true; };
      luarocksPackage = lib.mkPackageOption pkgs "luarocks" { nullable = true; };

      plugins = lib.mkOption {
        type = lazyPluginsListType;
        default = [ ];
        description = "List of plugins";
      };
    };

  extraConfig =
    cfg:
    let
      # The `pkg` property isn't a part of the `lazy.nvim` plugin spec, while
      # it shouldn't do any harm it does take up unecessary space in the
      # init.lua file. Since we're done using it we will strip it from the
      # final spec.
      removePkgAttrFromPlugin =
        plugin:
        builtins.removeAttrs plugin [ "pkg" ]
        // lib.optionalAttrs (((plugin.dependencies or null) != null) && lib.isList plugin.dependencies) {
          dependencies = map removePkgAttrFromPlugin plugin.dependencies;
        };

      removePkgAttrFromPlugins = plugins: map removePkgAttrFromPlugin plugins;
    in
    {
      extraPackages = [
        cfg.gitPackage
        cfg.luarocksPackage
      ];
      plugins.lazy.settings.spec = removePkgAttrFromPlugins cfg.plugins;
    };
}
