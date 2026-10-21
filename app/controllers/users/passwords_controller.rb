module Users
  class PasswordsController < Devise::PasswordsController
    rate_limit to: 5, within: 5.minutes, only: :create
  end
end
