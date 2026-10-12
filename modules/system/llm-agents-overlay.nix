{ inputs, ... }:
{
  flake.modules.darwin.llm-agents-overlay = {
    nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
  };
}
