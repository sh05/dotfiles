{ flakeRoot, sourceRoot, seedSource, testUser }:
let
  flake = builtins.getFlake flakeRoot;
  mkDarwin = flake.lib.mkDarwin;
  sourceDir = builtins.toPath sourceRoot;
  seedPath = builtins.toPath seedSource;
  personalHost = sourceDir + "/hosts/sh05MacminiM2/default.nix";

  external = mkDarwin "policy-eval-external" {
    user = testUser;
    hostModule = { };
  };
  personal = mkDarwin "sh05MacminiM2" {
    user = testUser;
    hostModule = personalHost;
  };
  seeded = mkDarwin "policy-eval-seeded" {
    user = testUser;
    hostModule = {
      imports = [ personalHost ];
      dotfiles.goose.configMode = "seed";
      dotfiles.goose.seedSource = seedPath;
    };
  };
  badClaudeHelper = mkDarwin "policy-eval-bad-claude-helper" {
    user = testUser;
    hostModule = {
      dotfiles.goose.providerHelpers = [ "claude-code" ];
    };
  };
  badSeed = mkDarwin "policy-eval-bad-seed" {
    user = testUser;
    hostModule = {
      dotfiles.goose.configMode = "seed";
    };
  };
  badBoolType = mkDarwin "policy-eval-bad-bool-type" {
    user = testUser;
    hostModule = {
      dotfiles.ai.claudeCode.enable = "true";
    };
  };
  badHelperType = mkDarwin "policy-eval-bad-helper-type" {
    user = testUser;
    hostModule = {
      dotfiles.goose.providerHelpers = [ "unknown" ];
    };
  };

  externalHome = external.config.home-manager.users.${testUser};
  personalHome = personal.config.home-manager.users.${testUser};
  seededHome = seeded.config.home-manager.users.${testUser};

  packageNames = home: map (package: package.name) home.home.packages;
  hasPackage = home: prefix:
    builtins.any
      (name: builtins.substring 0 (builtins.stringLength prefix) name == prefix)
      (packageNames home);
  hasText = needle: haystack:
    builtins.replaceStrings [ needle ] [ "" ] haystack != haystack;
  hasConfig = home: name: builtins.hasAttr name home.xdg.configFile;
  rejectSystem = system:
    let
      evaluated = builtins.tryEval (
        builtins.deepSeq system.config.system.build.toplevel.drvPath true
      );
    in
    !evaluated.success;
  typeRejects = option: value: !(option.type.check value);

  helperName = "zsh/61_goose_provider_helpers.zsh";
  gooseConfigName = "goose/config.yaml";
  coreToolsRemain = home: casks:
    hasPackage home "goose-"
    && hasPackage home "codex-"
    && hasPackage home "herdr-"
    && hasConfig home "zsh/60_agents.zsh"
    && builtins.elem "block-goose" (map (cask: cask.name) casks)
    && !(hasConfig home "herdr/config.toml")
    && builtins.hasAttr ".agents/plugins/sh05-goose" home.home.file
    && !(hasConfig home gooseConfigName);

  checks = {
    externalDefaults =
      external.config.dotfiles.ai.claudeCode.enable == false
      && external.config.dotfiles.ai.antigravity.enable == false
      && external.config.dotfiles.goose.configMode == "unmanaged"
      && external.config.dotfiles.goose.providerHelpers == [ ]
      && external.config.dotfiles.goose.seedSource == null;

    externalGates =
      !(hasPackage externalHome "claude-code-")
      && !(hasPackage externalHome "antigravity-cli-")
      && !(hasPackage externalHome "ccstatusline-")
      && !(hasPackage externalHome "get_cwd_from_grandparent")
      && !(hasConfig externalHome "ccstatusline")
      && !(hasConfig externalHome helperName)
      && !(builtins.elem "antigravity" (map (cask: cask.name) external.config.homebrew.casks));

    publicPersonalHostOptsIn =
      personal.config.dotfiles.ai.claudeCode.enable
      && personal.config.dotfiles.ai.antigravity.enable
      && personal.config.dotfiles.goose.providerHelpers == [ "claude-code" "chatgpt_codex" ]
      && hasPackage personalHome "claude-code-"
      && hasPackage personalHome "antigravity-cli-"
      && hasPackage personalHome "ccstatusline-"
      && hasPackage personalHome "get_cwd_from_grandparent"
      && hasConfig personalHome "ccstatusline"
      && builtins.elem "antigravity" (map (cask: cask.name) personal.config.homebrew.casks)
      && hasConfig personalHome helperName
      && hasText "g-claude()" personalHome.xdg.configFile.${helperName}.text
      && hasText "g-openai()" personalHome.xdg.configFile.${helperName}.text;

    coreAiIntegrationsRemain =
      coreToolsRemain externalHome external.config.homebrew.casks
      && coreToolsRemain personalHome personal.config.homebrew.casks;

    seedModePropagates =
      seeded.config.dotfiles.goose.configMode == "seed"
      && seeded.config.dotfiles.goose.seedSource == seedPath
      && builtins.hasAttr "gooseConfigSeed" seededHome.home.activation
      && hasText (toString seedPath) seededHome.home.activation.gooseConfigSeed.data;

    claudeHelperRequiresFeature = rejectSystem badClaudeHelper;
    seedRequiresSource = rejectSystem badSeed;
    boolOptionRejectsString = rejectSystem badBoolType;

    optionTypesRejectInvalidValues =
      typeRejects external.options.dotfiles.ai.claudeCode.enable "true"
      && typeRejects external.options.dotfiles.ai.antigravity.enable 1
      && typeRejects external.options.dotfiles.goose.configMode "inherit"
      && rejectSystem badHelperType
      && typeRejects external.options.dotfiles.goose.seedSource true
      && external.options.dotfiles.goose.seedSource.type.check seedPath;
  };

  failed = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
in
if failed != [ ] then
  throw "policy-eval failed checks: ${builtins.concatStringsSep ", " failed}"
else
  {
    result = "passed";
    checks = builtins.attrNames checks;
  }
