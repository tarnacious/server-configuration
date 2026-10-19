#!/usr/bin/env python3
"""Offline tests: no real VM, disk, mount or NBD device is accessed."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/set-qcow2-password'


class PasswordTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.fs = self.root / 'filesystem'
        self.fs.mkdir()
        self.image = self.root / 'keys.qcow2'
        self.image.touch()
        self.events = self.root / 'events'
        device = self.root / 'dev/nbd0'
        device.parent.mkdir()
        device.touch()
        self.env = dict(os.environ, PATH=str(self.bin), EVENTS=str(self.events),
                        FAKE_FS=str(self.fs), IMAGE=str(self.image))
        mock = self.root / 'mock'
        mock.write_text(f'#!{sys.executable}\n' + '''
import os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['EVENTS'], 'a') as f:
    f.write(name + ' ' + ' '.join(args) + '\\n')
if name == 'id': print('0')
if name == 'virsh':
    if os.getenv('FAIL_VIRSH'): sys.exit(1)
    if 'list' in args and os.getenv('ACTIVE_VM'): print('test-uuid')
    if 'dumpxml' in args:
        print('<domain><devices><disk><source file="' + os.environ['IMAGE'] + '"/></disk></devices></domain>')
if name == 'qemu-nbd' and any(a.startswith('--connect=') for a in args) and os.getenv('FAIL_CONNECT'):
    sys.exit(1)
if name == 'mount':
    if os.getenv('FAIL_MOUNT'): sys.exit(1)
    target = pathlib.Path(args[-1])
    target.rmdir()
    target.symlink_to(os.environ['FAKE_FS'], target_is_directory=True)
if name == 'umount':
    if os.getenv('FAIL_UMOUNT'): sys.exit(1)
    target = pathlib.Path(args[-1])
    target.unlink()
    target.mkdir()
if name == 'openssl':
    sys.stdin.read()
    if os.getenv('FAIL_HASH'): sys.exit(1)
    print('$6$synthetic$hash')
''')
        mock.chmod(0o755)
        for name in ['id', 'qemu-nbd', 'modprobe', 'sleep', 'virsh', 'mount', 'umount', 'openssl', 'sync']:
            (self.bin / name).symlink_to(mock)
        for name in ['flock', 'mktemp', 'mv', 'chmod', 'rm', 'rmdir']:
            (self.bin / name).symlink_to(shutil.which(name))
        (self.bin / 'python3').symlink_to(sys.executable)
        source = SCRIPT.read_text().replace('/dev/nbd', str(self.root / 'dev/nbd'))
        source = source.replace('/sys/block/nbd', str(self.root / 'sys/nbd'))
        source = source.replace('/run/lock/server-configuration-nbd.lock', str(self.root / 'nbd.lock'))
        source = source.replace('/tmp/qcow2-password.', str(self.root / 'mount.'))
        self.script = self.root / 'set-password'
        self.script.write_text(source)
        self.password_file = self.fs / 'tarn-password'
        self.password_file.write_text('old hash\n')

    def run_script(self, username='tarn', passwords='synthetic-test-password\nsynthetic-test-password\n'):
        result = subprocess.run([shutil.which('bash'), str(self.script), str(self.image), username],
                                env=self.env, input=passwords, text=True, capture_output=True)
        self.assertNotIn('synthetic-test-password', result.stdout + result.stderr)
        return result

    def calls(self):
        return self.events.read_text() if self.events.exists() else ''

    def test_success(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.password_file.read_text(), '$6$synthetic$hash\n')
        self.assertEqual(self.password_file.stat().st_mode & 0o777, 0o600)
        self.assertIn('umount ', self.calls())
        self.assertIn('qemu-nbd --disconnect', self.calls())
        self.assertEqual(list(self.fs.glob('.password.*')), [])

    def test_active_vm_rejected_before_attachment(self):
        self.env['ACTIVE_VM'] = '1'
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertNotIn('qemu-nbd ', self.calls())

    def test_inspection_failure_is_fatal(self):
        self.env['FAIL_VIRSH'] = '1'
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertNotIn('qemu-nbd ', self.calls())

    def test_invalid_username(self):
        self.assertNotEqual(self.run_script('../escape').returncode, 0)
        self.assertNotIn('mount ', self.calls())

    def test_connection_failure_does_not_mount_or_disconnect(self):
        self.env['FAIL_CONNECT'] = '1'
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertNotIn('mount ', self.calls())
        self.assertNotIn('--disconnect', self.calls())

    def test_mount_failure_disconnects(self):
        self.env['FAIL_MOUNT'] = '1'
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertIn('--disconnect', self.calls())

    def test_mismatch_preserves_old_hash(self):
        self.assertNotEqual(self.run_script(passwords='one\ntwo\n').returncode, 0)
        self.assertEqual(self.password_file.read_text(), 'old hash\n')
        self.assertIn('--disconnect', self.calls())

    def test_hash_failure_preserves_old_hash(self):
        self.env['FAIL_HASH'] = '1'
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertEqual(self.password_file.read_text(), 'old hash\n')
        self.assertEqual(list(self.fs.glob('.password.*')), [])
        self.assertIn('--disconnect', self.calls())

    def test_unmount_failure_does_not_disconnect(self):
        self.env['FAIL_UMOUNT'] = '1'
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('--disconnect', self.calls())
        self.assertNotIn('Created tarn-password', result.stdout)

    def test_destination_symlink_is_not_followed(self):
        outside = self.root / 'outside'
        outside.write_text('untouched')
        self.password_file.unlink()
        self.password_file.symlink_to(outside)
        self.assertEqual(self.run_script().returncode, 0)
        self.assertFalse(self.password_file.is_symlink())
        self.assertEqual(outside.read_text(), 'untouched')


if __name__ == '__main__':
    unittest.main()
