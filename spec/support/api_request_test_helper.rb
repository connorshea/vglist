# typed: false
module ApiRequestTestHelper
  def api_request(query_string, variables: nil, token:)
    post graphql_path,
      params: {
        query: query_string,
        variables: variables
      },
      headers: {
        'Authorization': "Bearer #{token.token}"
      }

    response_body = JSON.parse(response.body)
    puts "ERRORS: #{response_body['errors'].inspect}" if ENV['DEBUG'] && response_body['errors']&.any?
    return response_body
  end
end
