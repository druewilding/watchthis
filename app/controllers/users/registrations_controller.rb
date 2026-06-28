class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |user|
      if user.persisted?
        user.lists.create!(name: "Inbox", is_default: true)
      end
    end
  end
end
