# AuthlogicRenrenConnect
# require "authlogic_renren_connect/version"
require "authlogic_renren_connect/acts_as_authentic"
require "authlogic_renren_connect/session"
require "authlogic_renren_connect/helper"

if ActiveRecord::Base.respond_to?(:add_acts_as_authentic_module)
  ActiveRecord::Base.send(:include, AuthlogicRenrenConnect::ActsAsAuthentic)
  Authlogic::Session::Base.send(:include, AuthlogicRenrenConnect::Session)
  ActionController::Base.helper AuthlogicRenrenConnect::Helper
end
