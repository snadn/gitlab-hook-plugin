
require_relative '../util/settings'

module GitlabWebHook
  class CheckGitDetails
    include Settings

    def with(details)
      raise ArgumentError.new('details are required') unless details

      ignore_users = settings.ignore_users.split(',').collect(&:strip).reject(&:empty?)
      ignore_users.each do|ignore_user|
        return "Not processing request for a git action by #{ignore_user}" if details.user_name == ignore_user
      end

      return nil
    end
  end
end
