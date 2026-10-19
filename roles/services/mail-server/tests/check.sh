#!/usr/bin/env bash
# Render and evaluate only. Never boots a VM or contacts production.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT"
export ANSIBLE_CONFIG="$ROOT/roles/services/mail-server/tests/ansible.cfg"
export PYTHONDONTWRITEBYTECODE=1
OUT="$ROOT/.generated/mail-server/check"
mkdir -p "$OUT/source" "$OUT/nixos"
touch "$OUT/source/obsolete-generated-file" "$OUT/nixos/admin.pub" "$OUT/nixos/inventory.nix"
for run in first second; do
  ansible-playbook roles/services/mail-server/tests/render.yml \
    -e @roles/services/mail-server/tests/inventory-vars.yml \
    -e "mail_server_builder_dir=$OUT" > "$OUT/render-$run.log"
done
grep -q 'changed=0 ' "$OUT/render-second.log"
[[ ! -e "$OUT/source" && ! -e "$OUT/nixos/admin.pub" && ! -e "$OUT/nixos/inventory.nix" ]]
for script in build deploy bootstrap verify-disks; do bash -n "$OUT/$script"; done
CONFIG="path:$OUT/nixos#nixosConfigurations.mail-server.config"
nix eval --raw --no-update-lock-file "$CONFIG.system.build.toplevel.drvPath" > "$OUT/system.drv"
nix eval --json --no-update-lock-file "$CONFIG" --apply 'c: {
  inherit (c.mailserver) fqdn accounts domains;
  inherit (c.networking) hostName nameservers defaultGateway defaultGateway6;
  interfaces = builtins.mapAttrs (_: i: {
    ipv4.addresses = i.ipv4.addresses;
    ipv6.addresses = i.ipv6.addresses;
  }) c.networking.interfaces;
  systemDomain = c.mailserver.systemDomain;
  acmeEmail = c.security.acme.defaults.email;
  adminKeys = c.users.users.tarn.openssh.authorizedKeys.keys;
  ports = c.networking.firewall.allowedTCPPorts;
  firewall = c.networking.firewall.extraCommands;
  postfixCondition = c.systemd.services.postfix.unitConfig.ConditionPathExists or null;
  mounts = builtins.mapAttrs (_: f: f.device) c.fileSystems;
  requiredMounts = c.systemd.services.postfix.unitConfig.RequiresMountsFor;
  sourceFiles = builtins.attrNames (builtins.readDir c.environment.etc.nixos.source);
}' > "$OUT/evaluated.json"
python3 - "$OUT" <<'PY'
import json, pathlib, sys, xml.etree.ElementTree as ET
out = pathlib.Path(sys.argv[1])
c = json.loads((out / 'evaluated.json').read_text())
h = json.loads((out / 'host.json').read_text())
xml = ET.parse(out / 'domain.xml').getroot()
assert c['fqdn'] == h['hostname'] == 'mail.example.test'
assert c['hostName'] == 'mail-test'
assert c['domains'] == ['example.test'] and c['systemDomain'] == 'example.test'
assert c['acmeEmail'] == 'admin@example.test'
assert c['nameservers'] == ['192.0.2.53', '2001:db8::53']
assert [(i.find('mac').get('address'), i.find('source').get('bridge')) for i in xml.findall('./devices/interface')] == [
    ('52:54:00:00:00:04', 'testbr4'), ('52:54:00:00:00:06', 'testbr6')]

assert set(c['accounts']) == {'inbox@example.test', 'sender@example.test'}
for address, quota, send_only, path, aliases in [
    ('inbox@example.test', '512M', False, '/keys/accounts/synthetic-inbox.hash',
     ['postmaster@example.test', 'literal${alias}@example.test']),
    ('sender@example.test', '16M', True, '/keys/accounts/synthetic-sender.hash', []),
]:
    account = c['accounts'][address]
    assert account['quota'] == quota and account['sendOnly'] is send_only
    assert account['hashedPasswordFile'] == path and account['aliases'] == aliases
assert sorted(c['ports']) == [22, 25, 80, 443, 587, 993]
assert 'mail-maintenance' not in c['firewall'] and c['postfixCondition'] is None
assert set(c['requiredMounts']) == {'/keys', '/var/vmail', '/var/lib', '/var/log'}
assert set(c['sourceFiles']) == {'accounts.nix', 'configuration.nix', 'flake.nix', 'flake.lock', 'guest.nix', 'mail.nix'}
assert c['interfaces']['test4']['ipv4']['addresses'] == [{'address': h['address'], 'prefixLength': 25}]
assert h['address'] == '192.0.2.12'
assert c['interfaces']['test6']['ipv6']['addresses'] == [{'address': '2001:db8::12', 'prefixLength': 80}]
assert c['defaultGateway']['address'] == '192.0.2.1' and c['defaultGateway']['interface'] == 'test4'
assert c['defaultGateway6']['address'] == '2001:db8::1' and c['defaultGateway6']['interface'] == 'test6'
assert c['adminKeys'] == ['ssh-ed25519 AAAATEST first-test-key', 'ssh-ed25519 AAAATEST second-test-key']
assert xml.findtext('uuid') == h['uuid']
assert {d.find('target').get('dev'): d.find('source').get('file') for d in xml.findall('./devices/disk')} == h['disks']
for name, disk in h['storage'].items():
    mount = {'keys': '/keys', 'data': '/var/vmail', 'state': '/var/lib', 'logs': '/var/log'}[name]
    assert c['mounts'][mount] == '/dev/disk/by-label/' + disk['label']
assert (out / 'nixos/flake.lock').read_bytes() == pathlib.Path('roles/services/mail-server/files/nixos/flake.lock').read_bytes()
print('PASS: idempotent render; declarative production settings; Nix-only image source; host/disk consistency')
PY
python3 roles/services/mail-server/tests/test-builder.py
