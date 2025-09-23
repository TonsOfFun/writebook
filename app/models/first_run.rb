class FirstRun
  ACCOUNT_NAME = "Writebook"

  def self.create!(user_params)
    account = Account.create!(name: ACCOUNT_NAME)

    User.create!(user_params.merge(role: :administrator)).tap do |user|
      DemoContent.create_manual(user)
    end
  end
end
