{ config, pkgs, lib, ... }:
let
  ports = {
    lvm-homepage = 9000;
    immich = 2283;
    qbittorrent-webui = 8112;
    paperless = 28981;
    calibre-web = 8083;
    n8n = 5678;
    forgejo = 3000;
    homepage-dashboard = 8081;
    phush-nz = 8085;
    jellyfin = 8096;
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.enableAllTerminfo = true;

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "rishaan-nas";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "none";
  networking.useDHCP = false;
  networking.dhcpcd.enable = false;
  networking.nameservers = [
    "192.168.0.175"
    "8.8.8.8"
    "8.8.4.4"
    "1.1.1.1"
    "1.0.0.1"
  ];


  # Set your time zone.
  time.timeZone = "Pacific/Auckland";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_NZ.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_NZ.UTF-8";
    LC_IDENTIFICATION = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
    LC_MONETARY = "en_NZ.UTF-8";
    LC_NAME = "en_NZ.UTF-8";
    LC_NUMERIC = "en_NZ.UTF-8";
    LC_PAPER = "en_NZ.UTF-8";
    LC_TELEPHONE = "en_NZ.UTF-8";
    LC_TIME = "en_NZ.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account.
  users.users.phush = {
    isNormalUser = true;
    description = "Phush";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  
  users.groups.cloudflared = {};

  users.users.iceshelf = {
    isSystemUser = true;
    group = "iceshelf";
    extraGroups = [ "paperless" ];
  };
  
  users.users.ghrunner = {
    isSystemUser = true;
    group = "ghrunner";
  };

  users.groups.ghrunner.members = [
    "phush"
  ];

  users.groups.paperless.members = [
    "phush"
  ];

  users.groups.iceshelf.members = [
    "phush"
  ];

  users.groups.jfmedia.members = [
    "phush"
    "qbittorrent"
    "jellyfin"
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    wget

    # Net testing
    ethtool
    ookla-speedtest
    iperf
    
    # Encryption
    age
    sops
    
    #lspci
    pciutils

    openrgb

    # Git
    git
    gh
    gnupg
    pinentry-tty
    pinentry-curses
    gitui
    delta

    fastfetch
    eza
    dust
    dysk
    bat
    ripgrep
    htop
    btop

    yt-dlp
    ytdl-sub

    jellyfin
    jellyfin-web
    jellyfin-ffmpeg

    awscli
    iceshelf

    mkvtoolnix-cli
  ];

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  programs.bash.interactiveShellInit = ''
    export GPG_TTY=$(tty)
  '';

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      UseDns = true;
    };
  };

  services.jellyfin = {
    enable = true;
  };

  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = ports.immich;
    mediaLocation = "/storage/immich";
  };

  services.qbittorrent = {
    enable = true;
    webuiPort = ports.qbittorrent-webui;
    user = "qbittorrent";
    group = "jfmedia";
    serverConfig = {
      BitTorrent = {
        Session = {
          Interface = "protonvpn";
          InterfaceName = "protonvpn";
          DefaultSavePath = "/storage/torrents";
        };
      };
      Preferences = {
        WebUI = {
          Username = "admin";
          Password_PBKDF2 = builtins.readFile ./qbittorrent-webui-password;
        };
      };
    };
  };

  environment.etc."paperless-admin-pass".text = "admin";
  services.paperless = {
    enable = true;
    mediaDir = "/storage/paperless/media";
    consumptionDir = "/storage/paperless/consumption";
    passwordFile = "/etc/paperless-admin-pass";
    consumptionDirIsPublic = true;
    #database.createLocally = true;
    port = ports.paperless;
    address = "127.0.0.1";
  };

  services.calibre-web = {
    enable = true;
    listen = {
      ip = "127.0.0.1";
      port = ports.calibre-web;
    };
    options = {
      enableBookUploading = true;
      enableBookConversion = true;
    };
  };

  services.tt-rss = {
    enable = true;
    virtualHost = "rss.rishaan";
    selfUrlPath = "http://rss.rishaan";
  };

  # todo, need to setup https/lets encrypt/acme
  services.n8n = {
    enable = false;
    settings = {
      # Web frontend
      VUE_APP_URL_BASE_API = "http://n8n.rishaan/";
      # Disable diagnostics
      N8N_DIAGNOSTICS_ENABLED = "false";
      N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
      N8N_TEMPLATES_ENABLED = "false";
      EXTERNAL_FRONTEND_HOOKS_URLS = null;
      N8N_DIAGNOSTICS_CONFIG_FRONTEND = null;
      N8N_DIAGNOSTICS_CONFIG_BACKEND = null;
      # TZ
      GENERIC_TIMEZONE="Pacific/Auckland";
      #
      WEBHOOK_URL = "https://n8n.rishaan.nz/";
      N8N_PROXY_HOPS = "1";
      #
      N8N_HOST = "127.0.0.1";
      N8N_PORT = builtins.toString ports.n8n;
      #
      N8N_SECURE_COOKIE = false;
    };
  };

  services.github-runners = lib.attrsets.mergeAttrsList (map (repo: {
    "north_${repo}" = {
      name = "north_${repo}";
      enable = false;
      tokenFile = "/secrets/gh_runners/${repo}";
      url = "https://github.com/nofishleft/${repo}";
      user = "ghrunner";
      group = "ghrunner";
      workDir = "/home/ghrunner/${repo}/";
    };
  }) [ "foo" ]);

  # Git mirror
  services.forgejo = {
    enable = true;
    settings = {
      server = {
        DOMAIN = "forgejo.rishaan";
        ROOT_URL = "http://forgejo.rishaan:80/";
        HTTP_PORT = ports.forgejo;
      };
      mailer = {
        ENABLED = true;
        FROM = "nas@rishaan.nz";
        #PROTOCOL = "smtps+starttls";
        SMTP_ADDR = "smtp.protonmail.ch";
        SMTP_PORT = 587;
        USER = "nas@rishaan.nz";
      };
    };
    secrets = {
      mailer = {
        PASSWD = "/run/secrets/forgejo/mailer-token";
      };
    };
    lfs.enable = true;
  };

  services.grocy = {
    enable = true;
    hostName = "grocy.rishaan";
    nginx.enableSSL = false;
    settings = {
      currency = "NZD";
      culture = "en";
    };
  };

  services.lvm-homepage = {
    enable = true;
    host = "127.0.0.1";
    port = ports.lvm-homepage;
  };

  services.homepage-dashboard = let port = builtins.toString ports.homepage-dashboard; in {
    enable = true;
    allowedHosts = "localhost:${port},127.0.0.1:${port},192.168.0.64,dashboard.rishaan";
    listenPort = ports.homepage-dashboard;
    settings = {};
    widgets = [
      {
        resources = {
          cpu = true;
          disk = "/storage";
          memory = true;
        };
      }
      {
        search = {
          provider = "custom";
          url = "https://kagi.com/search?q=";
          target = "_blank";
          suggestionUrl = "https://kagi.com/api/autosuggest?q=";
          showSearchSuggestions = "true";
        };
      }
    ];
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              icon = "jellyfin.png";
              description = "Movies, shows & music";
              href = "http://jellyfin.rishaan";
              widget = {
                type = "jellyfin";
                url = "http://jellyfin.rishaan/";
                key = builtins.readFile ./homepage-jellyfin-key;
                enableBlocks = true;
                enableNowPlaying = true;
                enableUser = true;
                enableMediaControl = false;
              };
            };
          }
          {
            "Calibre" = {
              icon = "calibre-web.png";
              description = "E-Books";
              href = "http://calibre.rishaan";
              widget = {
                type = "calibreweb";
                url = "http://calibre.rishaan/";
                username = "dashboard";
                password = builtins.readFile ./homepage-calibre-password;
              };
            };
          }
        ];
      }
      {
        "Files" = [
          {
            "Paperless" = {
              icon = "paperless-ngx.png";
              description = "Documents";
              href = "http://paperless.rishaan";
              widget = {
                type = "paperlessngx";
                url = "http://paperless.rishaan/";
                key = builtins.readFile ./homepage-paperless-key;
              };
            };
          }
          {
            "qBitTorrent" = {
              icon = "qbittorrent.png";
              description = "Torrent manager";
              href = "http://torrent.rishaan";
              widget = {
                type = "qbittorrent";
                url = "http://torrent.rishaan";
                username = "admin";
                password = builtins.readFile ./homepage-qbittorrent-password;
                enableLeechProgress = "true";
              };
            };
          }
          {
            "Forgejo" = {
              icon = "forgejo.png";
              description = "Git mirror";
              href = "http://forgejo.rishaan";
            };
          }
          {
            "Immich" = {
              icon = "immich.png";
              description = "Photos & Videos";
              href = "http://immich.rishaan";
              widget = {
                type = "immich";
                url = "http://immich.rishaan/";
                key = builtins.readFile ./homepage-immich-key;
                version = "2";
              };
            };
          }
        ];
      }
      {
        "Network/LVM" = [
          {
            "Logical Volumes" = {
              icon = "";
              widget = {
                type = "customapi";
                url = "http://127.0.0.1:${builtins.toString ports.lvm-homepage}/lvs";
                refreshInterval = 30000;
                display = "dynamic-list";
                mappings = {
                  name = "value";
                  label = "name";
                };
              };
            };
          }
          {
            "Volume Groups" = {
              icon = "";
              widget = {
                type = "customapi";
                url = "http://127.0.0.1:${builtins.toString ports.lvm-homepage}/vgs";
                refreshInterval = 30000;
                display = "dynamic-list";
                mappings = {
                  name = "value";
                  label = "name";
                };
              };
            };
          }
          {
            "Physical Volumes" = {
              icon = "";
              widget = {
                type = "customapi";
                url = "http://127.0.0.1:${builtins.toString ports.lvm-homepage}/pvs";
                refreshInterval = 30000;
                display = "dynamic-list";
                mappings = {
                  name = "value";
                  label = "name";
                };
              };
            };
          }
          {
            "Cloudflare Tunnel" = {
              icon = "cloudflare.png";
              widget = {
                type = "cloudflared";
                accountid = builtins.readFile ./cf-tunnel-accountid;
                tunnelid = builtins.readFile ./cf-tunnel-tunnelid;
                key = builtins.readFile ./cf-tunnel-key;
              };
            };
          }
        ];
      }
    ];
  };

  # Todo: create widget for homepage
  networking.wg-quick.interfaces.protonvpn.configFile = "${./protonvpn-wg.conf}";

  services.cloudflared = {
    enable = true;
    tunnels."${builtins.readFile ./cf-tunnel-tunnelid}" = {
      credentialsFile = "/run/secrets/cloudflared/tunnel/public";
      default = "http_status:404";
      ingress = {
        "phush.nz" = "http://localhost:${builtins.toString ports.phush-nz}";
      };
    };
  };

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/phush/.config/sops/age/keys.txt";
    secrets = {
      "cloudflared/certificate" = {
        owner = "cloudflared";
        group = "cloudflared";
      };
      "cloudflared/tunnel/public" = {
        format = "binary";
        sopsFile = ./secrets/cloudflared_tunnel_public.json;
        owner = "cloudflared";
        group = "cloudflared";
      };
      "forgejo/mailer-token" = {
        format = "binary";
        sopsFile = ./secrets/forgejo-mailer-token;
        owner = "forgejo";
        group = "forgejo";
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.localhost = {
      root = "/var/www/phushnz";
      listen = [{
        addr = "127.0.0.1";
        port = ports.phush-nz;
      }];
    };
    virtualHosts."dashboard.rishaan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString ports.homepage-dashboard}";
        proxyWebsockets = true;
      };
    };
    virtualHosts."jellyfin.rishaan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString ports.jellyfin}";
        proxyWebsockets = true;
      };
    };
    virtualHosts."torrent.rishaan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.7:${builtins.toString ports.qbittorrent-webui}";
        proxyWebsockets = true;
      };
    };
    virtualHosts."paperless.rishaan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString ports.paperless}";
        proxyWebsockets = true;
      };
    };
    virtualHosts."calibre.rishaan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString ports.calibre-web}";
        proxyWebsockets = true;
        extraConfig = "client_max_body_size 1000M;";
      };
    };
    # "rss.rishaan" auto configured by tt-rss
    # "grocy.rishaan" auto configured by grocy
    virtualHosts."forgejo.rishaan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString ports.forgejo}";
        proxyWebsockets = true;
        extraConfig = "client_max_body_size 100M;";
      };
    };
    virtualHosts."immich.rishaan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString ports.immich}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 50000G;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout 600s;
        '';
      };
    };
    virtualHosts."n8n.rishaan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString ports.n8n}";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.enable = false;

  system.stateVersion = "25.05";

}
