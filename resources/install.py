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
  parser.add_argument('-smu', '--sysd_main_unit', nargs='*', help='Additional systemd unit settings for main service')
  parser.add_argument('-sms', '--sysd_main_svc', nargs='*', help='Additional systemd service settings for main service')
  parser.add_argument('-sbu', '--sysd_back_unit', nargs='*', help='Additional systemd unit settings for backup service')
  parser.add_argument('-sbs', '--sysd_back_svc', nargs='*', help='Additional systemd service settings for backup service')
  parser.add_argument('docker_args', nargs='*', type=str, help='Args to pass to docker')
  return parser.parse_args()

def sysd_args(arg):
  return "\n".join(arg) if arg else ''

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

  jenkins_template = lambda temp: temp.substitute(jenkins_home=args.home_dir,
                                                  backup_directory=args.backup_dir,
                                                  addl_main_unit_set=sysd_args(args.sysd_main_unit),
                                                  addl_main_svc_set=sysd_args(args.sysd_main_svc),
                                                  addl_backup_unit_set=sysd_args(args.sysd_back_unit),
                                                  addl_backup_svc_set=sysd_args(args.sysd_back_svc))
  install_systemd('jenkins_template.service',
                  '%s.service' % os.environ['NAME'],
                  jenkins_template,
                  True)
  install_systemd('jenkins_backup_template.service',
                  '%s_backup.service' % os.environ['NAME'],
                  jenkins_template)
  install_systemd('jenkins_backup_template.timer',
                  '%s_backup.timer' % os.environ['NAME'],
                  jenkins_template,
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
