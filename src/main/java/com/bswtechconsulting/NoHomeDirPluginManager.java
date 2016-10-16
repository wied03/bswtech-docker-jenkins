import hudson.LocalPluginManager;
import jenkins.model.Jenkins;

public class NoHomeDirPluginManager extends LocalPluginManager {
  public NoHomeDirPluginManager(Jenkins jenkins) {
    super(jenkins.servletContext, jenkins.getRootDir());
  }
}
