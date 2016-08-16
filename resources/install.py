#!/usr/bin/env python

import argparse
import sys
import os
import subprocess
from installer import install_systemd

def parse_args():
  parser = argparse.ArgumentParser(description="Installs container", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  parser.add_argument('-d', '--home_dir', type=str, help='Where should Jenkins be', required=True)
  parser.add_argument('-bd', '--backup_dir', type=str, help='Where daily backups should go', required=True)
  parser.add_argument('-sc', '--systemd', nargs='*', help='Additional systemd unit settings')
  parser.add_argument('docker_args', nargs='*', type=str, help='Args to pass to docker')
  return parser.parse_args()

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

  install_systemd(args,
                  'jenkins_template.service',
                  '%s.service' % os.environ['NAME'],
                  True)
  install_systemd(args,
                  'jenkins_backup_template.service',
                  '%s_backup.service' % os.environ['NAME'])
  install_systemd(args,
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
