#!/usr/bin/env python

import argparse
import sys
import os
import subprocess
from string import Template

def parse_args():
  parser = argparse.ArgumentParser(description="Installs container", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  parser.add_argument('-d', '--home_dir', type=str, help='Where should Jenkins be', required=True)
  parser.add_argument('-bd', '--backup_dir', type=str, help='Where daily backups should go', required=True)
  parser.add_argument('-sc', '--systemd', nargs='*', help='Additional systemd unit settings')
  parser.add_argument('docker_args', nargs='*', type=str, help='Args to pass to docker')
  return parser.parse_args()

def systemd_file(args, template_filename, dest_filename, enable_service=False):
  print "Reading template for file %s" % template_filename
  template_file = open('/'+template_filename, 'r')
  template = Template(template_file.read())
  template_file.close()
  unit_settings = "\n".join(args.systemd) if args.systemd else ''
  result = template.substitute(jenkins_home=args.home_dir,
                               backup_directory=args.backup_dir,
                               addl_unit_settings=unit_settings)

  systemd_filename = '/etc/systemd/system/%s' % dest_filename
  destination = os.environ['HOST'] + systemd_filename

  print "Setting up systemd file in %s" % systemd_filename
  systemd_file = open(destination, 'w')
  systemd_file.write(result)
  systemd_file.close()
  if subprocess.call(['chroot',
                      os.environ['HOST'],
                      'systemctl',
                      'daemon-reload']) != 0:
    raise Exception('while trying to do a daemon reload for %s' % systemd_filename)

  if not enable_service:
    return

  print "Enabling systemd service %s" % systemd_filename
  if subprocess.call([
    'chroot',
    os.environ['HOST'],
    'systemctl',
    'enable',
    systemd_filename
    ]) != 0:
    raise Exception('systemd enable failed for %s!' % systemd_filename)

def main():
  args = parse_args()

  print "Creating container using Jenkins home %s. Adding rest of docker args as well: %s" % (args.home_dir, args.docker_args)
  safe_docker_args = args.docker_args if args.docker_args else []
  create_args = [
    'chroot',
    os.environ['HOST'],
    'docker',
    'create',
    '--name',
    os.environ['NAME'],
    '--cap-drop=all',
    '--read-only',
    '--tmpfs',
    '/run',
    '--tmpfs',
    '/tmp:exec',
    '-v',
    '%s:/var/jenkins_home:Z' % args.home_dir] + safe_docker_args + [os.environ['IMAGE']]

  if subprocess.call(create_args) != 0:
    raise Exception('Docker container create failed!')

  systemd_file(args,
               'jenkins_template.service',
               '%s.service' % os.environ['NAME'],
               True)
  systemd_file(args,
               'jenkins_backup_template.service',
               '%s_backup.service' % os.environ['NAME'])
  systemd_file(args,
               'jenkins_backup_template.timer',
               '%s_backup.timer' % os.environ['NAME'],
               True)

  print 'Installation complete'
  print 'Run the following commands on the host before starting the container:'
  print "groupadd -g %s %s" % (os.environ['JENKINS_GID'], os.environ['JENKINS_GROUP'])
  print "useradd -r -d %s -u %s -g %s -m -s /bin/bash %s" % (os.environ['JENKINS_HOME'],
                                                             os.environ['JENKINS_UID'],
                                                             os.environ['JENKINS_GID'],
                                                             os.environ['JENKINS_USER'])

if __name__ == '__main__':
    sys.exit(main())
