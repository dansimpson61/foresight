# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use
  channel = "unstable"; # or "unstable"

  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.ruby_3_3
    pkgs.bundler
    pkgs.foreman
    pkgs.gcc
    pkgs.gnumake
    pkgs.chromium
  ];

  # Sets environment variables in the workspace
  env = {
    NIXPKGS_ALLOW_UNFREE = "1";
    CHROME_BIN = "${pkgs.chromium}/bin/chromium";
  };
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "rebornix.ruby"
      "kaiwood.endwise"
    ];

    # Enable previews
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["bundle" "exec" "rackup" "--host" "0.0.0.0" "--port" "$PORT"];
          manager = "web";
        };
      };
    };

    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        # Example: install JS dependencies from NPM
        npm-install = "bundle install";
      };
      # Runs when the workspace is (re)started)
      onStart = {
        # Example: start a background task to watch and re-build backend code
        # watch-backend = "npm run watch-backend";
      };
    };
  };
}
