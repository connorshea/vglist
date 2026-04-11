# frozen_string_literal: true

# Redirects browser visitors to the Vue SPA frontend.
#
# In this architecture the Rails app is API-only: GraphQL, REST, OAuth, and
# Devise HTML pages are all routed explicitly. Anything else that arrives as
# an HTML request — the root path, unknown paths, old bookmarks — gets
# redirected to the separately-deployed frontend, preserving the full path
# and query string so e.g. "/games?page=2" on the API host lands on the same
# path on the frontend host.
class SpaController < ActionController::API
  def index
    target = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}#{request.fullpath}"
    redirect_to target, allow_other_host: true, status: :found
  end
end
