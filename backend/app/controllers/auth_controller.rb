class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[signup login]

  def signup
    user = User.new(signup_params.merge(role: :member))

    if user.save
      render json: { user: user_response(user), token: JwtService.encode({ user_id: user.id }) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def login
    user = User.find_by(email: login_params[:email].downcase)

    if user&.authenticate(login_params[:password])
      render json: { user: user_response(user), token: JwtService.encode({ user_id: user.id }) }, status: :ok
    else
      render json: { errors: ["Invalid email or password"] }, status: :unauthorized
    end
  end

  def logout
    head :no_content
  end

  private

  def signup_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def login_params
    params.require(:user).permit(:email, :password)
  end

  def user_response(user)
    user.slice(:id, :name, :email, :role)
  end
end

