class JwtService
  ALGORITHM = "HS256".freeze

  def self.encode(payload, exp: 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, secret_key, ALGORITHM)
  end

  def self.decode(token)
    decoded_token = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
    decoded_token.first.with_indifferent_access
  end

  def self.secret_key
    Rails.application.secret_key_base
  end
end

