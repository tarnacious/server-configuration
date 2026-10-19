#!/usr/bin/env python3
"""Offline build/deploy tests. All libvirt, QEMU, sudo and network calls are mocked."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('builder', Path(__file__).parents[1] / 'files/scripts/builder.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class BuilderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.source = self.base / 'nixos'
        self.source.mkdir()
        self.image = self.base / 'built/nixos.qcow2'
        self.image.parent.mkdir()
        self.image.write_bytes(b'new-root')
        (self.base / 'result').symlink_to(self.image.parent, target_is_directory=True)
        disks = self.base / 'disks'
        disks.mkdir()
        self.paths = {f'vd{letter}': str(disks / f'{name}.qcow2')
                      for letter, name in zip('abcde', ['root', 'keys', 'data', 'state', 'logs'])}
        for target, path in self.paths.items():
            Path(path).write_bytes(target.encode())
        self.cfg = {'name': 'mail-server', 'uuid': 'test-uuid', 'disks': self.paths,
                    'address': '192.168.122.12', 'hostname': 'mail.tarnbarford.net'}
        root = ET.Element('domain', type='kvm')
        ET.SubElement(root, 'name').text = 'mail-server'
        ET.SubElement(root, 'uuid').text = 'test-uuid'
        devices = ET.SubElement(root, 'devices')
        for target, path in self.paths.items():
            disk = ET.SubElement(devices, 'disk', type='file', device='disk')
            ET.SubElement(disk, 'source', file=path)
            ET.SubElement(disk, 'target', dev=target, bus='virtio')
        self.xml = ET.tostring(root, encoding='unicode')
        (self.base / 'domain.xml').write_text(self.xml)
        (self.base / 'host.json').write_text(json.dumps(self.cfg))
        self.manifest()

    def manifest(self):
        info = {'sourceSha256': builder.source_digest(self.source), 'image': str(self.image),
                'imageSha256': builder.digest(self.image), 'system': '/nix/store/test-system'}
        (self.base / 'build.json').write_text(json.dumps(info))
        return info

    def test_reject_stale_source_and_modified_artifact(self):
        builder.artifact(self.source)
        (self.source / 'changed').write_text('new configuration')
        with self.assertRaisesRegex(RuntimeError, 'Source changed'):
            builder.artifact(self.source)
        self.manifest()
        self.image.write_bytes(b'wrong-image')
        with self.assertRaisesRegex(RuntimeError, 'differs'):
            builder.artifact(self.source)

    def test_reject_source_symlinks(self):
        (self.source / 'external').symlink_to(self.image)
        with self.assertRaisesRegex(RuntimeError, 'symlinks'):
            builder.source_digest(self.source)

    def test_reject_identity_disk_and_hardware_drift(self):
        desired = ET.fromstring(self.xml)
        for element, attribute, value in [('uuid', None, 'wrong'),
                                           ('./devices/disk/source', 'file', '/wrong'),
                                           ('./devices/disk/target', 'bus', 'sata')]:
            root = ET.fromstring(self.xml)
            if attribute:
                root.find(element).set(attribute, value)
            else:
                root.find(element).text = value
            with self.subTest(element=element), self.assertRaises(RuntimeError):
                builder.domain_matches(root, desired, self.cfg)

    def test_shutdown_timeout_never_forces_stop(self):
        virsh = mock.Mock(return_value='running')
        with mock.patch.object(builder.time, 'monotonic', side_effect=[0, 181]):
            with self.assertRaisesRegex(RuntimeError, 'never force-stop'):
                builder.wait_off(virsh, 'mail-server')
        self.assertEqual(virsh.call_args_list, [mock.call('domstate', 'mail-server')])

    def deploy_simulated(self, timeout=False, check=False, expect_error=None):
        calls = []
        state = 'running'
        def run(*args):
            nonlocal state
            calls.append(args)
            if args[0] == 'virsh':
                command = args[3]
                if command == 'dumpxml':
                    return self.xml
                if command == 'domstate':
                    return state
                if command == 'list':
                    return 'mail-server'
                if command == 'shutdown':
                    state = 'shut off'
                if command == 'start':
                    state = 'running'
                return ''
            if args[:2] == ('qemu-img', 'info'):
                return json.dumps([{'format': 'qcow2'}] if '--backing-chain' in args else {'format': 'qcow2'})
            if args[0] == 'cp':
                shutil.copyfile(args[-2], args[-1])
            return ''
        original_open = open
        def safe_open(path, *args, **kwargs):
            if path == '/run/lock/mail-server-deploy.lock':
                path = self.base / 'test.lock'
            return original_open(path, *args, **kwargs)
        with mock.patch.object(builder.os, 'geteuid', return_value=0), \
             mock.patch.object(builder.os, 'chown'), \
             mock.patch.object(builder.fcntl, 'flock'), \
             mock.patch('builtins.open', side_effect=safe_open), \
             mock.patch.object(builder, 'run', side_effect=run), \
             mock.patch.object(builder.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', '')), \
             mock.patch.object(builder, 'wait_mail'), \
             mock.patch.object(builder, 'wait_off', side_effect=RuntimeError('timeout') if timeout else None):
            if timeout or expect_error:
                with self.assertRaisesRegex(RuntimeError, expect_error or 'timeout'):
                    builder.deploy(self.source)
            else:
                builder.deploy(self.source, check)
        self.assertFalse(any('destroy' in call for call in calls))
        return calls

    def test_root_only_deployment_preserves_four_disks_and_previous_root(self):
        self.deploy_simulated()
        self.assertEqual(Path(self.paths['vda']).read_bytes(), b'new-root')
        self.assertEqual(Path(self.paths['vda']).with_name('root.previous.qcow2').read_bytes(), b'vda')
        for target in ('vdb', 'vdc', 'vdd', 'vde'):
            self.assertEqual(Path(self.paths[target]).read_bytes(), target.encode())
        self.assertTrue((self.base / 'deployed.json').exists())

    def test_check_only_and_failed_shutdown_do_not_replace_images(self):
        calls = self.deploy_simulated(check=True)
        self.assertFalse(any('shutdown' in call for call in calls))
        self.deploy_simulated(timeout=True)
        self.assertEqual(Path(self.paths['vda']).read_bytes(), b'vda')
        self.assertFalse(Path(self.paths['vda']).with_name('root.previous.qcow2').exists())
        self.assertEqual(list(Path(self.paths['vda']).parent.glob('.root-new-*')), [])

    def test_synthetic_identity_refuses_before_shutdown(self):
        self.cfg['hostname'] = 'mail-render.example.test'
        (self.base / 'host.json').write_text(json.dumps(self.cfg))
        self.manifest()
        calls = self.deploy_simulated(expect_error='never a test fixture')
        self.assertFalse(calls)
        self.assertEqual(Path(self.paths['vda']).read_bytes(), b'vda')

    def test_missing_state_disk_refuses_before_shutdown(self):
        Path(self.paths['vdc']).unlink()
        calls = self.deploy_simulated(expect_error='disk is missing')
        self.assertFalse(any('shutdown' in call for call in calls))
        self.assertEqual(Path(self.paths['vda']).read_bytes(), b'vda')

    def test_build_records_exact_nix_output(self):
        outputs = json.dumps([{'outputs': {'out': str(self.image.parent)}}])
        with mock.patch.object(builder.os, 'geteuid', return_value=1000), \
             mock.patch.object(builder, 'run', side_effect=[outputs, '/nix/store/new-system']):
            builder.build(self.source, [])
        _, info = builder.artifact(self.source)
        self.assertEqual(info['system'], '/nix/store/new-system')

    def test_build_refuses_stale_result_link(self):
        alternate = self.base / 'alternate'
        alternate.mkdir()
        (alternate / 'nixos.qcow2').write_bytes(b'new-build')
        outputs = json.dumps([{'outputs': {'out': str(alternate)}}])
        with mock.patch.object(builder.os, 'geteuid', return_value=1000), \
             mock.patch.object(builder, 'run', return_value=outputs):
            with self.assertRaisesRegex(RuntimeError, 'Result link'):
                builder.build(self.source, [])
        self.assertFalse((self.base / 'build.json').exists())

    def test_failed_build_invalidates_old_manifest(self):
        with mock.patch.object(builder.os, 'geteuid', return_value=1000), \
             mock.patch.object(builder, 'run', side_effect=subprocess.CalledProcessError(1, 'nix')):
            with self.assertRaises(subprocess.CalledProcessError):
                builder.build(self.source, [])
        self.assertFalse((self.base / 'build.json').exists())


if __name__ == '__main__':
    unittest.main()
