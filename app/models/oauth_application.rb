# typed: strict
class OauthApplication < Doorkeeper::Application
  # Custom model for the Doorkeeper Applications so it can have a grant_flow enum.

  enum grant_flow: {
    authorization_code: 0,
    implicit: 1
  }
end
