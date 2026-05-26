{
  description = "Software Crafters Meetup - nix run .\#develop-draft";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pt3d = {
      url = "github:omega-800/pt3d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      treefmt-nix,
      typix,
      pt3d,
    }:
    let
      fs = nixpkgs.lib.fileset;
      inherit (nixpkgs.lib)
        concatMapStringsSep
        cleanSourceWith
        removeSuffix
        cleanSource
        listToAttrs
        hasSuffix
        platforms
        genAttrs
        getExe
        split
        pipe
        flip
        id
        ;
      inherit (builtins)
        concatMap
        elemAt
        match
        elem
        any
        ;
      eachSystem =
        f:
        genAttrs platforms.unix (
          system:
          f (
            import nixpkgs {
              inherit system;
              config = { };
              overlays = [ ];
            }
          )
        );
      mkApp = drv: {
        type = "app";
        program = "${drv}${drv.passthru.exePath or "/bin/${drv.pname or drv.name}"}";
      };
      treefmt = eachSystem (
        pkgs:
        treefmt-nix.lib.evalModule pkgs (_: {
          projectRootFile = "flake.nix";
          programs = {
            typstyle.enable = true;
            # mdformat.enable = true;
            nixfmt.enable = true;
            statix.enable = false;
          };
          # settings.formatter.mdformat = {
          #   excludes = [ "presentation.md" ];
          #   number = true;
          #   wrap = 80;
          # };
        })
      );

      formats = [
        "a4"
        "display"
      ];

      src =
        let
          getFst = flip elemAt 0;
          sources = pipe ./src [
            (fs.fileFilter (f: f.name == "default.typ"))
            fs.toList
            (map toString)
            (map (match ".*/([^/]+/[^/]+\\.typ)$"))
            (map getFst)
          ];
        in
        {
          inherit sources;
          names = map (flip pipe [
            (match "([^/]+/.*)\\.typ$")
            getFst
            (split "/")
          ]) sources;
        };

      typixUtil =
        pkgs:
        let
          unpublishedTypstPackages = pkgs.linkFarm "unpublished-typst-packages" {
            # "local/pt3d/0.0.1" = pt3d;
          };
        in
        {
          typixLib = typix.lib.${pkgs.system};
          commonArgs = {
            typstOpts = {
              root = ".";
              font-path = "lib/fonts";
            };
            typstSource = "templates/default.typ";
            fontPaths = with pkgs; [
              "${nerd-fonts.jetbrains-mono}/share/fonts/truetype"
              "${fira-math}/share/fonts/opentype"
              "${libertinus}/share/fonts/opentype"
            ];
            virtualPaths = [ ];
          };
          extraArgs = {
            TYPST_PACKAGE_PATH = unpublishedTypstPackages;
            unstable_typstPackages = [
              {
                name = "codetastic";
                version = "0.2.2";
                hash = "";
              }
            ];
            src = cleanSourceWith {
              src = cleanSource ./.;
              filter =
                path: type:
                let
                  hasAcceptedSuffix = any (flip hasSuffix path) [
                    ".typ"
                    ".bib"
                    ".png"
                    ".jpg"
                    ".md"
                  ];
                  isSpecialFile = elem (baseNameOf path) [
                    "typst.toml"
                    "metadata.toml"
                  ];
                in
                any id [
                  (type == "directory")
                  hasAcceptedSuffix
                  isSpecialFile
                ];
            };
          };
          watchArgs.typstWatchCommand = "TYPST_PACKAGE_PATH=${pkgs.lib.escapeShellArg unpublishedTypstPackages} typst watch";
        };

      typixPkgs =
        pkgs:
        let
          inherit (src) sources names;
          inherit (typixUtil pkgs)
            typixLib
            commonArgs
            extraArgs
            watchArgs
            ;
          # mkBulkAction =
          #   action:
          #   let
          #     name = "${action}-all";
          #     doWatch = action == "watch";
          #   in
          #   {
          #     "${name}" = pkgs.writeShellApplication {
          #       inherit name;
          #       text =
          #         (if doWatch then "(trap 'kill 0' SIGINT; " else "")
          #         + "${concatMapStringsSep (if doWatch then " & " else "; ") getExe (
          #           map (
          #             src:
          #             let
          #               typstSource = "advertisements/" + src;
          #             in
          #             typixLib."${if doWatch then "watchTypstProject" else "buildTypstProjectLocal"}" (
          #               commonArgs
          #               // (if doWatch then watchArgs else extraArgs)
          #               // {
          #                 inherit typstSource;
          #                 typstOutput = (removeSuffix "default.typ" typstSource) + "{p}.png";
          #               }
          #             )
          #           ) sources
          #         )}"
          #         + (if doWatch then ")" else "");
          #     };
          #   };
        in
        # (mkBulkAction "watch")
        # // (mkBulkAction "compile")
        # //
        (listToAttrs (
          # TODO: use intersperse thingy function
          concatMap (
            path:
            concatMap (
              format:
              let
                type = elemAt path 2;
                dir = elemAt path 0;
                name = dir;
                suffix = if format == "display" then "" else "-${format}";
                # TODO: clean this up
                dname = "develop-${name}${suffix}";
                oname = "open-${name}${suffix}";
                typstSource = "src/${dir}/${type}.typ";
                typstOutput = "src/${dir}/${if format == "display" then "{p}.png" else type + ".pdf"}";
                opts = if format == "display" then { format = "png"; } else { };
                opencmd =
                  if format == "display" then
                    "${pkgs.feh}/bin/feh src/${dir}/*.png"
                  else
                    "${pkgs.zathura}/bin/zathura ${typstOutput}";
              in
              [
                # {
                #   name = oname;
                #   value = pkgs.writeShellApplication {
                #     name = oname;
                #     text = "${getExe pkgs.zathura} ${typstOutput}";
                #   };
                # }
                {
                  name = dname;
                  value = pkgs.writeShellApplication {
                    name = dname;
                    text = ''
                      (trap 'kill 0' SIGINT; 
                        ${opencmd} &
                          ${
                            typixLib.watchTypstProject (
                              commonArgs
                              // watchArgs
                              // {
                                typstOpts =
                                  commonArgs.typstOpts
                                  // opts
                                  // {
                                    input = "format=" + format;
                                  };
                                inherit typstSource typstOutput;
                              }
                            )
                          }/bin/typst-watch
                      )
                    '';
                  };
                }
              ]
            ) formats
          ) names
        ));
    in
    {
      devShells = eachSystem (
        pkgs:
        let
          inherit (typixUtil pkgs) typixLib commonArgs;
          inherit (self.checks.${pkgs.system}) pre-commit-check;
          oss-meetup = typixLib.devShell {
            inherit (pre-commit-check) shellHook;
            inherit (commonArgs) fontPaths virtualPaths;
            buildInputs = pre-commit-check.enabledPackages;
            packages = (pkgs.lib.attrValues self.packages.${pkgs.system}) ++ [ pkgs.typstyle ];
          };
        in
        {
          inherit oss-meetup;
          default = oss-meetup;
        }
      );

      packages = eachSystem (
        pkgs:
        (typixPkgs pkgs)
        // {
          copy = pkgs.writeShellApplication {
            name = "copy-template";
            text = ''
              { [ "$#" -lt 1 ] || [ -z "$1" ]; } && echo "Usage: $0 <date>" && exit 1
              dir="./src/$1"
              [ -e "$dir" ] && echo "$dir already exists" && exit 1
              mkdir "$dir"
              cp -r "./templates/"* "$dir"
            '';
          };
        }
      );

      apps = eachSystem (pkgs: pkgs.lib.mapAttrs (_: mkApp) self.packages.${pkgs.system});

      formatter = eachSystem (pkgs: treefmt.${pkgs.system}.config.build.wrapper);

      checks = eachSystem (pkgs: {
        pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
          src = ./.;
          hooks.treefmt = {
            enable = true;
            packageOverrides.treefmt = treefmt.${pkgs.system}.config.build.wrapper;
          };
        };
      });

      templates = {
        advertisement = {
          description = "Advertisement in typst";
          path = ./templates;
        };
      };
    };
}
