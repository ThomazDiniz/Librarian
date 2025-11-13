module AuthHelper
  def auth_headers(user)
    {
      "Authorization" => "Bearer #{JwtService.encode({ user_id: user.id })}",
      "Content-Type" => "application/json"
    }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end

