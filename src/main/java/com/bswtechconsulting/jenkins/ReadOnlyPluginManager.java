package com.bswtechconsulting.jenkins;

import hudson.LocalPluginManager;
import jenkins.model.Jenkins;
import java.io.File;

// TODO: set hudson.PluginManager.className to com.bswtechconsulting.jenkins.ReadOnlyPluginManager
public class ReadOnlyPluginManager extends LocalPluginManager {
  public ReadOnlyPluginManager(Jenkins jenkins) {
    // this is set in the Docker image
    super(jenkins.servletContext, new File(System.getenv("JENKINS_WAR_DIR")));
  }

  // TODO: Prevent install/uninstall/upgrade here
}
