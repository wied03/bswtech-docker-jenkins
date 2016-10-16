package com.bswtechconsulting.jenkins;

import hudson.LocalPluginManager;
import jenkins.model.Jenkins;
import java.io.File;
import org.kohsuke.stapler.HttpResponse;
import org.kohsuke.stapler.StaplerRequest;
import java.io.IOException;
import javax.servlet.ServletException;
import java.util.Collection;
import hudson.model.UpdateCenter;
import java.util.concurrent.Future;
import java.util.List;

// TODO: set hudson.PluginManager.className to com.bswtechconsulting.jenkins.ReadOnlyPluginManager
public class ReadOnlyPluginManager extends LocalPluginManager {
  private static final String ERROR = "Plugins cannot be changed through the GUI!";

  public ReadOnlyPluginManager(Jenkins jenkins) {
    // this is set in the Docker image
    super(jenkins.servletContext, new File(System.getenv("JENKINS_WAR_DIR")));
  }

  // TODO: Prevent uninstall/upgrade here
  @Override
  public HttpResponse doInstallPlugins(StaplerRequest req) throws IOException {
    throw new RuntimeException(ERROR);
  }

  @Override
  public List<Future<UpdateCenter.UpdateCenterJob>> install(Collection<String> plugins, boolean dynamicLoad) {
    throw new RuntimeException(ERROR);
  }

  @Override
  public HttpResponse doUploadPlugin(StaplerRequest req) throws IOException, ServletException {
    throw new RuntimeException(ERROR);
  }
}
