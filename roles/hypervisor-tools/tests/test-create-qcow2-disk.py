#!/usr/bin/env python3
"""Offline tests: all disk/module commands and NBD paths are fake."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/create-qcow2-disk'


class CreateDiskTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.events = self.root / 'events'
        self.image = self.root / 'data.qcow2'
        self.device = self.root / 'dev/nbd0'
        self.device.parent.mkdir()
        self.device.touch()
        self.env = dict(os.environ, PATH=str(self.bin), EVENTS=str(self.events))
        mock = self.root / 'mock'
        mock.write_text(f'#!{sys.executable}\n' + '''
import os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['EVENTS'], 'a') as f:
    f.write(name + ' ' + ' '.join(args) + '\\n')
if name == 'id':
    print('0')
if name == 'qemu-nbd' and args[0].startswith('--connect=') and os.getenv('FAIL_CONNECT'):
    sys.exit(1)
if name == 'mkfs.ext4' and os.getenv('FAIL_MKFS'):
    sys.exit(1)
''')
        mock.chmod(0o755)
        for name in ['id', 'qemu-img', 'qemu-nbd', 'mkfs.ext4', 'modprobe', 'sleep']:
            (self.bin / name).symlink_to(mock)
        for name in ['mkdir', 'dirname', 'flock']:
            (self.bin / name).symlink_to(shutil.which(name))
        # Only redirect device/lock paths in a temporary copy, never real /dev.
        source = SCRIPT.read_text().replace('/dev/nbd', str(self.root / 'dev/nbd'))
        source = source.replace('/sys/block/nbd', str(self.root / 'sys/nbd'))
        source = source.replace('/run/lock/server-configuration-nbd.lock', str(self.root / 'nbd.lock'))
        self.script = self.root / 'create-disk'
        self.script.write_text(source)

    def run_script(self):
        return subprocess.run([shutil.which('bash'), str(self.script), str(self.image), 'data', '1G'],
                              env=self.env, text=True, capture_output=True)

    def calls(self):
        return self.events.read_text() if self.events.exists() else ''

    def test_success(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Successfully created and formatted', result.stdout)
        self.assertIn('mkfs.ext4 -L data', self.calls())
        self.assertEqual(self.calls().count('qemu-nbd --disconnect'), 1)
        self.assertNotIn('modprobe -r', self.calls())

    def test_missing_nbd_creates_nothing(self):
        (self.bin / 'qemu-nbd').unlink()
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertFalse(self.image.exists())
        self.assertNotIn('qemu-img', self.calls())

    def test_busy_device_creates_nothing(self):
        pid = self.root / 'sys/nbd0/pid'
        pid.parent.mkdir(parents=True)
        pid.write_text('123')
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertFalse(self.image.exists())

    def test_existing_image_is_untouched(self):
        self.image.write_bytes(b'important data')
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertEqual(self.image.read_bytes(), b'important data')
        self.assertNotIn('qemu-img', self.calls())

    def test_connection_failure_never_formats_or_disconnects(self):
        self.env['FAIL_CONNECT'] = '1'
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('mkfs.ext4', self.calls())
        self.assertNotIn('--disconnect', self.calls())
        self.assertIn('partial image', result.stderr)

    def test_format_failure_disconnects_and_reports_failure(self):
        self.env['FAIL_MKFS'] = '1'
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('qemu-nbd --disconnect', self.calls())
        self.assertNotIn('Successfully', result.stdout)
        self.assertIn('partial image', result.stderr)


if __name__ == '__main__':
    unittest.main()
