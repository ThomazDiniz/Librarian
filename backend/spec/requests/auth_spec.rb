require "rails_helper"

RSpec.describe "Auth API", type: :request do
  describe "POST /signup" do
    it "creates a member user and returns a token" do
      post "/signup", params: {
        user: {
          name: "Sam Reader",
          email: "sam@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(parsed_response["token"]).to be_present
      expect(parsed_response["user"]["role"]).to eq("member")
    end

    it "returns errors when data invalid" do
      post "/signup", params: { user: { email: "" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(parsed_response["errors"]).to include("Name can't be blank")
    end
  end

  describe "POST /login" do
    let!(:user) { create(:user, email: "login@example.com", password: "supersecret") }

    it "authenticates and returns a token" do
      post "/login", params: {
        user: {
          email: "login@example.com",
          password: "supersecret"
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(parsed_response["token"]).to be_present
      expect(parsed_response["user"]["email"]).to eq("login@example.com")
    end

    it "returns unauthorized with invalid credentials" do
      post "/login", params: {
        user: {
          email: "login@example.com",
          password: "wrong"
        }
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(parsed_response["errors"]).to include("Invalid email or password")
    end
  end
end

