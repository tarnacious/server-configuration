#!/usr/bin/env python3
"""Locked image build and graceful, root-only libvirt deployment."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import smtplib
import socket
import ssl
import subprocess
import tempfile
import time
import xml.etree.ElementTree as ET


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def digest(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def source_digest(source):
    result = hashlib.sha256()
    for path in sorted(source.rglob('*')):
        if path.is_symlink():
            raise RuntimeError(f'Builder source must not contain symlinks: {path}')
        if path.is_file():
            result.update(str(path.relative_to(source)).encode() + b'\0')
            result.update(str(path.stat().st_mode & 0o777).encode() + b'\0')
            result.update(digest(path).encode())
    return result.hexdigest()


def build(source, extra):
    if os.geteuid() == 0:
        raise RuntimeError('Run ./build as the builder user, not root')
    manifest = source.parent / 'build.json'
    before = source_digest(source)
    # Invalidate any previous successful build before starting new work.
    manifest.unlink(missing_ok=True)
    outputs = json.loads(run('nix', 'build', f'path:{source}#qcow2', '--json',
                             '--no-update-lock-file', '--out-link', str(source.parent / 'result'), *extra))
    if len(outputs) != 1 or set(outputs[0]['outputs']) != {'out'}:
        raise RuntimeError('Expected exactly one QCOW2 output')
    image = (Path(outputs[0]['outputs']['out']) / 'nixos.qcow2').resolve(strict=True)
    if (source.parent / 'result/nixos.qcow2').resolve(strict=True) != image:
        raise RuntimeError('Result link does not match the image Nix just built')
    system = run('nix', 'eval', '--raw', '--no-update-lock-file',
                 f'path:{source}#nixosConfigurations.mail-server.config.system.build.toplevel')
    if before != source_digest(source):
        raise RuntimeError('Source changed during build; rebuild before deploying')
    manifest.write_text(json.dumps({'sourceSha256': before, 'image': str(image),
                                    'imageSha256': digest(image), 'system': system}, indent=2) + '\n')
    print('Built image:', image)
    print('Build manifest:', manifest)


def artifact(source):
    info = json.loads((source.parent / 'build.json').read_text())
    image = (source.parent / 'result/nixos.qcow2').resolve(strict=True)
    if info['sourceSha256'] != source_digest(source):
        raise RuntimeError('Source changed since ./build; build again before deploying')
    if str(image) != info['image'] or digest(image) != info['imageSha256']:
        raise RuntimeError('Built image differs from build manifest; build again')
    return image, info


def canonical(node):
    return (node.tag, tuple(sorted(node.attrib.items())), (node.text or '').strip(),
            tuple(canonical(child) for child in node))


def disk_map(root):
    disks = root.findall('./devices/disk')
    if len(disks) != 5 or any(d.get('type') != 'file' or d.get('device') != 'disk' for d in disks):
        raise RuntimeError('Expected exactly five file-backed disks')
    return {d.find('target').get('dev'): d.find('source').get('file') for d in disks}


def domain_matches(root, desired, cfg):
    if root.findtext('name') != cfg['name'] or root.findtext('uuid') != cfg['uuid']:
        raise RuntimeError('Production domain identity mismatch')
    if disk_map(root) != cfg['disks'] or canonical(root) != canonical(desired):
        raise RuntimeError('Libvirt XML differs from rendered production XML; review drift first')


def wait_off(virsh, vm, timeout=180):
    deadline = time.monotonic() + timeout
    while virsh('domstate', vm) != 'shut off':
        if time.monotonic() >= deadline:
            raise RuntimeError('Graceful shutdown timed out; no disks replaced (never force-stop mail)')
        time.sleep(2)


def wait_mail(address, hostname, timeout=180):
    context = ssl.create_default_context()
    deadline = time.monotonic() + timeout
    while True:
        try:
            for port in (25, 587):
                with smtplib.SMTP(address, port, timeout=10) as client:
                    client._host = hostname
                    client.ehlo()
                    client.starttls(context=context)
                    client.ehlo()
            with socket.create_connection((address, 993), timeout=10) as raw:
                with context.wrap_socket(raw, server_hostname=hostname) as connection:
                    if not connection.recv(1024).startswith(b'* OK'):
                        raise RuntimeError('Unexpected IMAPS greeting')
            return
        except (OSError, smtplib.SMTPException, RuntimeError) as error:
            if time.monotonic() >= deadline:
                raise RuntimeError('Mail did not become ready; inspect VM. No automatic state rollback.') from error
            time.sleep(3)


def deploy(source, check=False):
    if os.geteuid() != 0:
        raise RuntimeError('Run ./deploy (it requests sudo)')
    with open('/run/lock/mail-server-deploy.lock', 'w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        image, info = artifact(source)
        cfg = json.loads((source.parent / 'host.json').read_text())
        vm = cfg['name']
        if (vm, cfg['hostname']) != ('mail-server', 'mail.tarnbarford.net'):
            raise RuntimeError('Routine deployment requires the production identity, never a test fixture')
        def virsh(*args):
            return run('virsh', '-c', 'qemu:///system', *args)
        xml = source.parent / 'domain.xml'
        desired = ET.fromstring(xml.read_text())
        before = ET.fromstring(virsh('dumpxml', vm, '--inactive'))
        domain_matches(before, desired, cfg)
        state = virsh('domstate', vm)
        if state not in ('running', 'shut off'):
            raise RuntimeError(f'Unexpected domain state: {state}')
        if state == 'running' and disk_map(ET.fromstring(virsh('dumpxml', vm))) != cfg['disks']:
            raise RuntimeError('Live and persistent disk mappings differ')
        for command in ('snapshot-list', 'checkpoint-list'):
            if virsh(command, vm, '--name'):
                raise RuntimeError('Snapshots/checkpoints require separate review')
        if Path(f'/var/lib/libvirt/qemu/save/{vm}.save').exists():
            raise RuntimeError('Managed-save state requires separate review')
        paths = [Path(p) for p in cfg['disks'].values()]
        root = Path(cfg['disks']['vda'])
        previous = root.with_name('root.previous.qcow2')
        for path in [*paths, previous]:
            if path.is_symlink() or path.resolve() != path:
                raise RuntimeError(f'Symlink disk path refused: {path}')
        if not all(path.is_file() for path in paths):
            raise RuntimeError('A production disk is missing; never recreate it during deployment')
        for name in virsh('list', '--all', '--name').splitlines():
            if name != vm:
                for mode in ((), ('--inactive',)):
                    other = ET.fromstring(virsh('dumpxml', name, *mode))
                    for entry in other.findall('.//disk/source') + other.findall('.//backingStore/source'):
                        if entry.get('file') and Path(entry.get('file')).resolve() in [*paths, previous]:
                            raise RuntimeError(f'Disk shared with {name}; inspect before deployment')
        # Refuse dependencies on a root filename that is about to be replaced.
        for path in Path('/var/kvm/images').rglob('*.qcow2'):
            chain = json.loads(run('qemu-img', 'info', '--force-share', '--backing-chain', '--output=json', str(path)))
            if path in paths and (len(chain) != 1 or chain[0].get('snapshots')):
                raise RuntimeError(f'Production disk has backing dependencies/internal snapshots: {path}')
            if any(Path(item['filename']).resolve() in (root, previous) for item in chain[1:]):
                raise RuntimeError(f'Backing consumer depends on replaceable root: {path}')
        built = json.loads(run('qemu-img', 'info', '--output=json', str(image)))
        if built['format'] != 'qcow2' or built.get('backing-filename') or built.get('snapshots'):
            raise RuntimeError('Build must be a standalone QCOW2 without snapshots')
        run('qemu-img', 'check', str(image))
        run('virt-xml-validate', str(xml), 'domain')
        print('Verified build, domain identity/XML, five standalone disks and no sharing/backing consumers.', flush=True)
        if check:
            print('CHECK ONLY: no shutdown or image replacement')
            return
        fd, name = tempfile.mkstemp(prefix='.root-new-', suffix='.qcow2', dir=root.parent)
        os.close(fd)
        staged = Path(name)
        try:
            # Copy and validate before downtime. Preserve the existing disk's access policy.
            run('cp', '--reflink=auto', '--sparse=always', '--', str(image), str(staged))
            stat = root.stat()
            os.chown(staged, stat.st_uid, stat.st_gid)
            shutil.copymode(root, staged)
            if digest(staged) != info['imageSha256']:
                raise RuntimeError('Staged root checksum mismatch')
            run('qemu-img', 'check', str(staged))
            artifact(source)  # Refuse a concurrent re-render before stopping mail.
            if state == 'running':
                virsh('shutdown', vm)  # Guest systemd stops mail services cleanly.
                wait_off(virsh, vm)
            if virsh('domstate', vm) != 'shut off':
                raise RuntimeError('Domain must be off before disk operations')
            domain_matches(ET.fromstring(virsh('dumpxml', vm, '--inactive')), desired, cfg)
            for path in [*paths, previous]:
                if path.exists():
                    result = subprocess.run(['fuser', str(path)], capture_output=True, text=True)
                    if result.returncode != 1 or result.stderr.strip():
                        raise RuntimeError(f'Disk still open or fuser failed: {path}')
            run(str(source.parent / 'verify-disks'))
            identities = {p: (p.stat().st_ino, p.stat().st_size, p.stat().st_mtime_ns) for p in paths if p != root}
            with staged.open('rb') as stream:
                os.fsync(stream.fileno())
            os.replace(root, previous)
            os.replace(staged, root)
            dir_fd = os.open(root.parent, os.O_DIRECTORY)
            try:
                os.fsync(dir_fd)
            finally:
                os.close(dir_fd)
            virsh('define', str(xml), '--validate')
            domain_matches(ET.fromstring(virsh('dumpxml', vm, '--inactive')), desired, cfg)
            for path, identity in identities.items():
                stat = path.stat()
                if (stat.st_ino, stat.st_size, stat.st_mtime_ns) != identity:
                    raise RuntimeError(f'Persistent disk unexpectedly changed: {path}')
            virsh('autostart', vm)
            virsh('start', vm)
            wait_mail(cfg['address'], cfg['hostname'])
            (source.parent / 'deployed.json').write_text(json.dumps(info, indent=2) + '\n')
            print('Deployed:', info['system'])
            print('Four persistent disks preserved. Previous root:', previous)
            print('Check guest services/queue through the mail-server Ansible inventory entry.')
        finally:
            staged.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('build', 'deploy', 'image'))
    parser.add_argument('source', type=Path)
    parser.add_argument('--check', action='store_true')
    args, extra = parser.parse_known_args()
    source = args.source.resolve(strict=True)
    if args.action == 'build':
        build(source, (['--check'] if args.check else []) + extra)
    elif args.action == 'image':
        if extra or args.check:
            parser.error('image takes no extra arguments')
        print(artifact(source)[0])
    else:
        if extra:
            parser.error('Unexpected deployment arguments')
        deploy(source, args.check)


if __name__ == '__main__':
    main()
