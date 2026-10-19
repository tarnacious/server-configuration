#!/usr/bin/env python3
"""Offline template regression: no VM, disk or network access."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from jinja2 import Environment, StrictUndefined

ROLE = Path(__file__).resolve().parents[1]
ENV = Environment(undefined=StrictUndefined)
VALUES = {
    'hosts': {'cloud': {
        'vm': {'uuid': 'test-uuid', 'memory': 4, 'vcpu': 2},
        'ipv4': '192.0.2.24', 'ipv6': '2001:db8::24',
        'ipv4_mac': '52:54:00:00:00:02', 'ipv6_mac': '52:54:00:00:00:03',
        'ipv4_bridge': 'virbr0', 'ipv6_bridge': 'br0',
        'ipv4_target_dev': 'test4', 'ipv6_target_dev': 'test6',
        'root_password_hash': 'synthetic-test-hash',
    }},
    'gateway4': '192.0.2.1', 'gateway6': '2001:db8::1',
    'authorized_keys': 'ssh-ed25519 AAAATEST synthetic-key',
}


def render(name):
    return ENV.from_string((ROLE / 'templates' / name).read_text()).render(VALUES)


class ACPITests(unittest.TestCase):
    def test_domain_features_and_layout(self):
        root = ET.fromstring(render('domain.xml'))
        self.assertEqual(root.findtext('name'), 'ocis')
        self.assertEqual(root.findtext('uuid'), 'test-uuid')
        self.assertEqual(root.find('os/type').get('machine'), 'pc-i440fx-10.0')
        for feature in ('acpi', 'apic'):
            self.assertIsNotNone(root.find('features/' + feature))
        nics = root.findall('devices/interface')
        self.assertEqual(len(nics), 2)
        for nic, family, slot in zip(nics, ('ipv4', 'ipv6'), ('0x02', '0x03')):
            self.assertEqual(nic.find('mac').get('address'), VALUES['hosts']['cloud'][family + '_mac'])
            self.assertEqual(nic.find('address').attrib, {
                'type': 'pci', 'domain': '0x0000', 'bus': '0x00',
                'slot': slot, 'function': '0x0',
            })
        self.assertEqual(len(root.findall('devices/disk')), 5)

    def test_guest_addresses_and_routes_use_acpi_names(self):
        guest = render('guest.nix')
        for name, family, address in [('ens2', 'ipv4', '192.0.2.24'),
                                      ('ens3', 'ipv6', '2001:db8::24')]:
            self.assertIn(f'{name}.{family}.addresses = [ {{ address = "{address}";', guest)
        self.assertIn('defaultGateway = { address = "192.0.2.1"; interface = "ens2"; };', guest)
        self.assertIn('defaultGateway6 = { address = "2001:db8::1"; interface = "ens3"; };', guest)
        self.assertNotIn('enp0s', guest)


if __name__ == '__main__':
    unittest.main()
