/**
 * Connect to a Teleport service for remote access.
 *
 * TODO: nixify the config to provide type checked options
 */
{ config, pkgs, ... }:

let
  cluster  = "ACA_SYD";
in
  {
    imports = [ ./nixpkgs-unstable.nix ];

    # Ensure all teleport tools are available
    environment.systemPackages = with pkgs; [ unstable.teleport ];

    # Teleport config
    environment.etc."teleport.yaml".text = ''
      teleport:
        data_dir: /var/lib/teleport
        pid_file: /var/run/teleport.pid
        auth_token: cluster-join-token
        auth_servers:
          - 127.0.0.1:3025
        log:
          output: stderr
          severity: INFO
      auth_service:
        cluster_name: "${cluster}"
        listen_addr: 127.0.0.1:3025
        tokens:
          - proxy,node:cluster-join-token
      ssh_service:
        listen_addr: 127.0.0.1:3022
        labels:
          org: aca
          services: signage
      proxy_service:
        listen_addr: 127.0.0.1:3023
        web_listen_addr: 127.0.0.1:3080
        tunnel_listen_addr: 127.0.0.1:3024
    '';

    # Systemd unit for teleport autostart
    systemd.services.teleport =
      { description = "Teleport SSH Service";
        after = [ "network.target" "network-online.target" ];

        serviceConfig =
          { Type = "simple";
            ExecStart = "${pkgs.unstable.teleport}/bin/teleport start --config=/etc/teleport.yaml";
            Restart = "on-failure";
          };

        wantedBy = [ "multi-user.target" ];

        enable = true;
      };
  }
