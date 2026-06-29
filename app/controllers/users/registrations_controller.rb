class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |user|
      if user.persisted?
        user.lists.create!(name: "Inbox", is_default: true)
      end
    end
  end

  private

  def sign_up(resource_name, resource)
    super
    remember_me(resource)
  end
end
