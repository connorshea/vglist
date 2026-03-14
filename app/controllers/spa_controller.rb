# Serves the Vue SPA's index.html for client-side routing.
# In production, the built frontend is copied to public/.
class SpaController < ActionController::API
  def index
    index_path = Rails.root.join('public', 'index.html')

    if File.exist?(index_path)
      render file: index_path, layout: false, content_type: 'text/html'
    else
      render json: { error: 'Frontend not built. Run: cd frontend && npx vite build && cp -r dist/* ../public/' }, status: :not_found
    end
  end
end
