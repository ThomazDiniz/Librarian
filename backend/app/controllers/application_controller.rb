class ApplicationController < ActionController::API
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_content
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  attr_reader :current_user

  private

  def authenticate_user!
    return @current_user if defined?(@current_user)

    token = authorization_token
    raise JWT::DecodeError if token.blank?

    payload = JwtService.decode(token)
    @current_user = User.find(payload["user_id"] || payload[:user_id])
  rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound
    render_unauthorized
  end

  def authorization_token
    pattern = /^Bearer /
    header = request.headers["Authorization"]
    header.gsub(pattern, "") if header&.match(pattern)
  end

  def require_librarian!
    return if current_user&.librarian?

    render json: { errors: ["Forbidden"] }, status: :forbidden
  end

  def render_unauthorized
    render json: { errors: ["Unauthorized"] }, status: :unauthorized
  end

  def render_not_found(exception)
    render json: { errors: [exception.message] }, status: :not_found
  end

  def render_unprocessable_content(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_content
  end

  def render_bad_request(exception)
    render json: { errors: [exception.message] }, status: :bad_request
  end
end
