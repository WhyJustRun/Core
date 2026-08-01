module Users
  class SessionsController < Devise::SessionsController
    rate_limit to: 10, within: 1.minute, only: :create
  end
end
