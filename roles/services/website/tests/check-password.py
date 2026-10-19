#!/usr/bin/env python3
"""Render synthetic website configuration and evaluate password mount ordering."""
import json
from pathlib import Path
import subprocess
import tempfile

from jinja2 import Environment, StrictUndefined, meta

ROLE = Path(__file__).resolve().parents[1]
ROOT = ROLE.parents[2]
env = Environment(undefined=StrictUndefined)
sources = {name: (ROLE / 'templates' / name).read_text()
           for name in ['configuration.nix', 'guest.nix']}
variables = set().union(*(meta.find_undeclared_variables(env.parse(s)) for s in sources.values()))
values = dict.fromkeys(variables, 'test')
values.update(
    tarnbarford_vm_name='website-test',
    tarnbarford_fqdn='website.example.test',
    tarnbarford_acme_email='admin@example.test',
    tarnbarford_web_root='/var/www/test',
    tarnbarford_website_home='/var/lib/website',
    tarnbarford_root_label='nixos',
    tarnbarford_keys_label='test-keys',
    tarnbarford_logs_label='test-logs',
    tarnbarford_certificates_label='test-certs',
    tarnbarford_website_label='test-site',
    tarnbarford_nameservers='[ "192.0.2.53" ]',
    tarnbarford_ipv4_interface='test4',
    tarnbarford_ipv6_interface='test6',
    tarnbarford_ipv4='192.0.2.9',
    tarnbarford_ipv4_gateway='192.0.2.1',
    tarnbarford_ipv6='2001:db8::9',
    tarnbarford_ipv6_gateway='2001:db8::1',
    tarnbarford_ipv4_prefix=24,
    tarnbarford_ipv6_prefix=64,
    tarnbarford_logrotate_rotate=5,
    authorized_keys='ssh-ed25519 AAAATEST synthetic-test-key',
)
with tempfile.TemporaryDirectory() as directory:
    out = Path(directory)
    for name, source in sources.items():
        (out / name).write_text(env.from_string(source).render(values))
    expression = '''
      let
        nixpkgs = (builtins.getFlake ROOT).inputs.nixpkgs;
        system = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # Evaluate only storage and guest/user settings: website services use
          # unstable options while this repository's test shell pins stable.
          modules = [ ({ config, pkgs, lib, ... }:
            let raw = import CONFIG { inherit config pkgs lib; };
            in { inherit (raw) imports fileSystems; }
          ) ];
        };
        c = system.config;
      in {
        earlyKeys = c.fileSystems."/keys".neededForBoot;
        keyDevice = c.fileSystems."/keys".device;
        passwordFile = c.users.users.tarn.hashedPasswordFile;
        customPasswordService = c.systemd.services ? set-tarn-password;
      }
    '''.replace('ROOT', json.dumps(str(ROOT))).replace('CONFIG', str(out / 'configuration.nix'))
    result = json.loads(subprocess.check_output(
        ['nix', 'eval', '--impure', '--json', '--expr', expression], text=True))
    assert result == {
        'earlyKeys': True,
        'keyDevice': '/dev/disk/by-label/test-keys',
        'passwordFile': '/keys/tarn-password',
        'customPasswordService': False,
    }, result
print('PASS: runtime password file with boot-critical keys mount; no custom password service')
