#!/usr/bin/env python

import os
import subprocess
import sys
from installer import uninstall_systemd

def main():
  uninstall_systemd('%s.service' % os.environ['NAME'],
                    True)
  uninstall_systemd('%s_backup.service' % os.environ['NAME'])
  uninstall_systemd('%s_backup.timer' % os.environ['NAME'],
                    True)

  print 'Uninstall complete'
  print 'Run the following commands on the host to remove user/data'
  print "userdel %s" % os.environ['JENKINS_USER']

if __name__ == '__main__':
    sys.exit(main())
