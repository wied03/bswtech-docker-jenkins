module DockerSpecHelper
  def current_container_id
    Specinfra.backend.instance_variable_get(:@container).id
  end
end

class Serverspec::Type::DockerBase
  include DockerSpecHelper

  def initialize(name=nil, options = {})
    super
    @name = current_container_id
  end

  def inspection
    # we're now returning a string
    @inspection ||= ::MultiJson.load(get_inspection)[0]
  end

  def exist?
    # need to use the Ruby exit status
    get_inspection && @inspection_status.success?
  end

  private

  def get_inspection
    # we can't run docker inside the container, run it on the host
    @get_inspection ||= begin
      result = `docker inspect #{@name}`
      @inspection_status = $?
      result
    end
  end
end
