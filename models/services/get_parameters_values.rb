include Java

java_import Java.hudson.model.StringParameterDefinition
java_import Java.hudson.model.StringParameterValue

module GitlabWebHook
  class GetParametersValues
  java_import Java.java.util.logging.Level
    def with(project, details)
      raise ArgumentError.new('project is required') unless project
      raise ArgumentError.new('details are required') unless details

      values = build_from_payload_or_default(details, project)
      remove_empty(values)
      apply_branch(project, details, values)

      values
    end

    def with_mr(project, details)
      raise ArgumentError.new('project is required') unless project
      raise ArgumentError.new('details are required') unless details

      logger.info(project.to_s)
      logger.info(details.to_s)

      project.get_default_parameters.collect do |parameter|
        from_payload(parameter, details.payload) || parameter.getDefaultParameterValue()
      end.reject { |value| value.nil? }
    end

    private

    def build_from_payload_or_default(details, project)
      project.get_default_parameters.collect do |parameter|
        from_payload(parameter, details.flat_payload) || parameter.getDefaultParameterValue()
      end
    end

    def remove_empty(values)
      values.reject! { |value| value.nil? }
    end

    def apply_branch(project, details, values)
      branch_parameter = project.get_branch_name_parameter
      if branch_parameter
        tagname = branch_parameter.name.downcase == 'tagname'
        if ( tagname && details.tagname ) || ( !tagname && details.tagname.nil? )
          values.reject! { |value| value.name.downcase == branch_parameter.name.downcase }
          values << StringParameterValue.new(branch_parameter.name, tagname ? details.tagname : details.branch)
        end
      end
    end

    def from_payload(parameter, payload)
      # TODO possibly support other types as well?
      return nil unless parameter.java_kind_of?(StringParameterDefinition)

      value = payload.find do |key, _|
        key.downcase == parameter.name.downcase
      end.to_a[1]
      value.nil? ? value : StringParameterValue.new(parameter.name, value.to_s.strip)
    end
    def logger
      @logger ||= Java.java.util.logging.Logger.getLogger(Api.class.name)
    end
  end
end
