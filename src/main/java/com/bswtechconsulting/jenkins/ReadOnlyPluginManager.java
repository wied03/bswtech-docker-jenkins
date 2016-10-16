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

public class ReadOnlyPluginManager extends LocalPluginManager {
  private static final String ERROR = "Plugins cannot be changed through the GUI!";

  public ReadOnlyPluginManager(Jenkins jenkins) {
    // this is set in the Docker image, LocalPluginManager will add 'plugins' so go 1 level higher
    super(jenkins.servletContext, new File(System.getenv("JENKINS_PLUGIN_DIR"), ".."));
  }

  // TODO: Prevent uninstall/upgrade here
  @Override
  public List<Future<UpdateCenter.UpdateCenterJob>> install(Collection<String> plugins, boolean dynamicLoad) {
    throw new RuntimeException(ERROR);
  }

  @Override
  public HttpResponse doUploadPlugin(StaplerRequest req) throws IOException, ServletException {
    throw new RuntimeException(ERROR);
  }
}
