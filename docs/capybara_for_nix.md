Yes, there is a recommended setup that aligns perfectly with a joyful, reproducible Nix environment.

The issue you're facing is common. Gems like `webdrivers` attempt to download binaries at runtime, which conflicts with Nix's philosophy of declaring all dependencies upfront. The solution is to have Nix provide the browser and configure Capybara to use a modern, headless driver that communicates with it directly.

The recommended driver is **`cuprite`**. It's fast, simple, and connects directly to Chrome/Chromium via the Chrome DevTools Protocol (CDP), eliminating the need for Selenium. [cite\_start]This approach is more elegant and results in less friction. [cite: 14]

-----

### Step 1: Configure Your Nix Environment

First, update your `flake.nix` to include Chromium and configure the environment for `cuprite`. This ensures your testing tools are as declared and reproducible as the rest of your stack.

```nix
# flake.nix

{
  description = "A joyful Sinatra application with Capybara testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Ruby and Bundler
            ruby
            bundler

            # The headless browser
            chromium

            # For native gem extensions
            gcc
            make
            pkg-config
          ];

          shellHook = ''
            # Tell Cuprite where to find the Chromium binary provided by Nix
            export CHROME_BIN="${pkgs.chromium}/bin/chromium"

            echo "🧪 Testing environment is ready."
            # Ensure gems are installed locally
            export BUNDLE_PATH="vendor/bundle"
            bundle install
          '';
        };
      });
}
```

-----

### Step 2: Configure Capybara

Next, configure Capybara in your test setup (`spec_helper.rb` or `test_helper.rb`) to use the `cuprite` driver.

```ruby
# spec/spec_helper.rb

require 'capybara/rspec'
require 'capybara/cuprite'

# ... other setup ...

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    # The CHROME_BIN environment variable we set in our flake.nix
    # tells Cuprite which browser to use.
    headless: true # Ensure it runs headlessly
  )
end

# Set cuprite as the default driver for javascript-enabled tests
Capybara.javascript_driver = :cuprite
```

-----

### The Joyful Workflow

With this configuration, your testing process becomes frictionless and perfectly integrated:

1.  You enter the development shell by running `nix develop` in your terminal.
2.  The `shellHook` automatically exports the correct path to the **Chromium** binary that Nix provides.
3.  When you run your Capybara feature specs (e.g., from the Testing Panel in your IDE), `cuprite` launches the Nix-provided browser instance seamlessly.

[cite\_start]This setup is robust, reproducible, and avoids the complexities of runtime driver management, allowing you to focus on the craft of writing excellent, user-centric tests. [cite: 19, 46, 48]