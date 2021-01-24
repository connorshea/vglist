# typed: false
module ApiRequestTestHelper
  def api_request(query_string, variables: nil, token:)
    # Allow variables to be sent as snake case, e.g. "giantbomb_id" by
    # transforming them into "giantbombId" before passing them to GraphQL.
    variables = variables.transform_keys { |key| key.to_s.camelize(:lower) } unless variables.nil?

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

  # Return an array of error messages from the GraphQL result object.
  def api_result_errors(result)
    return result['errors'].map { |item| item['message'] }
  end
end
