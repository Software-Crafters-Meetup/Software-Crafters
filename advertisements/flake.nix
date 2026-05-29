{
  description = "Software Crafters Meetup - nix run .#develop-draft";

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
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      pre-commit-hooks,
    }:
    let
      inherit (nixpkgs.lib)
        cartesianProduct
        listToAttrs
        platforms
        concatMap
        mapAttrs
        genAttrs
        fileset
        getExe
        pipe
        flip
        ;
      inherit (builtins)
        elemAt
        match
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

      treefmtPkg =
        pkgs:
        (treefmt-nix.lib.evalModule pkgs (_: {
          projectRootFile = "flake.nix";
          programs = {
            typstyle.enable = true;
            nixfmt.enable = true;
            statix.enable = false;
          };
        })).config.build.wrapper;

      srcDir = "src";
      typstPkg = pkgs: pkgs.typst.withPackages (p: [ p.codetastic ]);
      scripts =
        pkgs:
        let
          typstOpts = "--root . --font-path 'lib/fonts'";
          formats = [
            {
              suffix = "-a4";
              out = "default.pdf";
              opts = "--format pdf --input format=a4";
              opencmd = d: "${getExe pkgs.zathura} ${srcDir}/${d}/default.pdf";
            }
            {
              suffix = "";
              out = "{p}.png";
              opts = "--format png --input format=display";
              opencmd = d: "${getExe pkgs.feh} ${srcDir}/${d}/*.png";
            }
          ];
          dirs = pipe ./${srcDir} [
            (fileset.fileFilter (f: f.name == "default.typ"))
            fileset.toList
            (map toString)
            (map (match ".*/([^/]+)/default.typ$"))
            (map (flip elemAt 0))
          ];
          typst = typstPkg pkgs;
          napp = name: text: {
            inherit name;
            value = pkgs.writeShellApplication {
              inherit name text;
            };
          };
        in
        listToAttrs (
          concatMap
            (
              { dir, format }:
              let
                inherit (format)
                  opencmd
                  suffix
                  opts
                  out
                  ;
                path = "${srcDir}/${dir}/";
                typstArgs = "${typstOpts} ${opts} \"${path}default.typ\" \"${path}${out}\"";
              in
              [
                (napp "open-${dir}${suffix}" (opencmd dir))
                (napp "develop-${dir}${suffix}" "(trap 'kill 0' SIGINT; ${opencmd dir} & ${getExe typst} watch ${typstArgs})")
                (napp "compile-${dir}${suffix}" "${getExe typst} compile ${typstArgs}")
              ]
            )
            (cartesianProduct {
              dir = dirs;
              format = formats;
            })
        );
    in
    {
      devShells = eachSystem (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          inherit (self.checks.${system}) pre-commit-check;
          software-crafters-meetup = pkgs.mkShellNoCC {
            inherit (pre-commit-check) shellHook;
            buildInputs = pre-commit-check.enabledPackages;
            packages = (pkgs.lib.attrValues self.packages.${system}) ++ [
              pkgs.typstyle
              (typstPkg pkgs)
            ];
          };
        in
        {
          inherit software-crafters-meetup;
          default = software-crafters-meetup;
        }
      );

      packages = eachSystem (
        pkgs:
        (scripts pkgs)
        // {
          copy = pkgs.writeShellApplication {
            name = "copy-template";
            text = ''
              { [ "$#" -lt 1 ] || [ -z "$1" ]; } && echo "Usage: $0 <date>" && exit 1
              dir="./${srcDir}/$1"
              [ -e "$dir" ] && echo "$dir already exists" && exit 1
              mkdir "$dir"
              cp -r "./templates/"* "$dir"
            '';
          };
        }
      );

      apps = eachSystem (pkgs: mapAttrs (_: mkApp) self.packages.${pkgs.stdenv.hostPlatform.system});

      formatter = eachSystem treefmtPkg;

      checks = eachSystem (pkgs: {
        pre-commit-check = pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
          src = ./.;
          hooks.treefmt = {
            enable = true;
            packageOverrides.treefmt = treefmtPkg pkgs;
          };
        };
      });

      templates.advertisement = {
        description = "Advertisement in typst";
        path = ./templates;
      };
    };
}
