#!/usr/bin/env python3
"""Offline website ACPI/network template check; no VM or disk access."""
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

from jinja2 import Environment, StrictUndefined, meta

ROLE = Path(__file__).resolve().parents[1]
ROOT = ROLE.parents[2]
ENV = Environment(undefined=StrictUndefined)
SOURCES = {name: (ROLE / 'templates' / name).read_text()
           for name in ('domain.xml', 'guest.nix')}
variables = set().union(*(meta.find_undeclared_variables(ENV.parse(source))
                          for source in SOURCES.values()))
VALUES = dict.fromkeys(variables, 'synthetic-test')
# Read just these scalar defaults, without loading/decrypting inventory secrets.
inventory = (ROOT / 'inventory/host_vars/hypervisor/main.yml').read_text()
VALUES.update(dict(re.findall(r'^(tarnbarford_ipv[46]_interface): "([^"]+)"$',
                             inventory, re.MULTILINE)))
VALUES.update(
    tarnbarford_vm_name='website', tarnbarford_vm_uuid='test-uuid',
    tarnbarford_vm_memory=4, tarnbarford_vm_vcpu=2,
    tarnbarford_ipv4_mac='52:54:00:00:00:02', tarnbarford_ipv6_mac='52:54:00:00:00:03',
    tarnbarford_ipv4='192.0.2.9', tarnbarford_ipv6='2001:db8::9',
    tarnbarford_ipv4_gateway='192.0.2.1', tarnbarford_ipv6_gateway='2001:db8::1',
    tarnbarford_ipv4_prefix=24, tarnbarford_ipv6_prefix=64,
)


def render(name):
    return ENV.from_string(SOURCES[name]).render(VALUES)


class ACPITests(unittest.TestCase):
    def test_domain_features_and_layout(self):
        root = ET.fromstring(render('domain.xml'))
        self.assertEqual(root.findtext('name'), 'website')
        self.assertEqual(root.findtext('uuid'), 'test-uuid')
        self.assertEqual(root.find('os/type').get('machine'), 'pc-i440fx-10.0')
        for feature in ('acpi', 'apic'):
            self.assertIsNotNone(root.find('features/' + feature))
        nics = root.findall('devices/interface')
        self.assertEqual(len(nics), 2)
        for nic, family, slot in zip(nics, ('ipv4', 'ipv6'), ('0x02', '0x03')):
            self.assertEqual(nic.find('mac').get('address'), VALUES['tarnbarford_' + family + '_mac'])
            self.assertEqual(nic.find('address').attrib, {
                'type': 'pci', 'domain': '0x0000', 'bus': '0x00',
                'slot': slot, 'function': '0x0',
            })
        self.assertEqual(len(root.findall('devices/disk')), 5)

    def test_inventory_and_guest_network_use_acpi_names(self):
        self.assertEqual(VALUES['tarnbarford_ipv4_interface'], 'ens2')
        self.assertEqual(VALUES['tarnbarford_ipv6_interface'], 'ens3')
        guest = render('guest.nix')
        for name, family, address in [('ens2', 'ipv4', '192.0.2.9'),
                                      ('ens3', 'ipv6', '2001:db8::9')]:
            self.assertIn(f'{name}.{family}.addresses = [ {{ address = "{address}";', guest)
        self.assertIn('defaultGateway = { address = "192.0.2.1"; interface = "ens2"; };', guest)
        self.assertIn('defaultGateway6 = { address = "2001:db8::1"; interface = "ens3"; };', guest)
        self.assertNotIn('enp0s', guest)


if __name__ == '__main__':
    unittest.main()
