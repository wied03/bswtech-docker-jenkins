#!/usr/bin/env python

import argparse
import sys
import os
import subprocess
import shutil

def parse_args():
    parser = argparse.ArgumentParser(description="Installs container", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-d', '--home_dir', type=str, help='Where should Jenkins', required=True)
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

    src = '/jenkins_template.service'
    if args.systemd:
      print 'Adding in systemd arguments'
      flat_args = "\\\n".join(args.systemd)
      subprocess.call(['sed',
                       '-e',
                       "s/ADDL_UNIT_SETTINGS/%s/g" % flat_args,
                       '-i',
                       src])

    systemd_file = '/etc/systemd/system/%s.service' % os.environ['NAME']
    destination = os.environ['HOST'] + systemd_file

    print "Setting up systemd file in %s" % systemd_file
    shutil.copyfile(src, destination)

    print "Enabling systemd service"
    if subprocess.call([
      'chroot',
      os.environ['HOST'],
      'systemctl',
      'enable',
      systemd_file
      ]) != 0:
      raise Exception('systemd enable failed!')

    print 'Installation complete'
    print 'Run the following commands on the host before starting the container:'
    print "groupadd -g %s %s" % (os.environ['JENKINS_GID'], os.environ['JENKINS_GROUP'])
    print "useradd -r -d %s -u %s -g %s -m -s /bin/bash %s" % (os.environ['JENKINS_HOME'],
                                                               os.environ['JENKINS_UID'],
                                                               os.environ['JENKINS_GID'],
                                                               os.environ['JENKINS_USER'])

if __name__ == '__main__':
    sys.exit(main())
