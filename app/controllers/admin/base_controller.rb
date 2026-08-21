module Admin
  class BaseController < ApplicationController
    include RoleAuthorization

    before_action { require_role!(:admin) }
  end
end
