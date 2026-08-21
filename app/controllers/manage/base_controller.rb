module Manage
  class BaseController < ApplicationController
    include RoleAuthorization

    before_action { require_role!(:project_manager, :admin) }
  end
end
