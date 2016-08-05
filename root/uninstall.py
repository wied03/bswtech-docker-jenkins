#!/usr/bin/env python

import os
import subprocess
import sys

def systemd_file(dest_filename, main_service=False):
  systemd_file = '/etc/systemd/system/%s' % dest_filename
  destination = os.environ['HOST'] + systemd_file

  if main_service:
    print "Disabling systemd service %s" % systemd_file
    if subprocess.call([
      'chroot',
      os.environ['HOST'],
      'systemctl',
      'disable',
      systemd_file
      ]) != 0:
      raise Exception('systemd disable failed!')

  print "Removing systemd service %s" % systemd_file
  os.remove(destination)

def main():
  systemd_file('%s.service' % os.environ['NAME'],
               True)
  systemd_file('%s_backup.service' % os.environ['NAME'])
  systemd_file('%s_backup.timer' % os.environ['NAME'])

  print 'Uninstall complete'
  print 'Run the following commands on the host to remove user/data'
  print "userdel %s" % os.environ['JENKINS_USER']

if __name__ == '__main__':
    sys.exit(main())
