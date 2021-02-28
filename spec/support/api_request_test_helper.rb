# typed: false
module ApiRequestTestHelper
  # @param query_string [String]
  # @param variables [Hash]
  # @param token [Doorkeeper::AccessToken]
  # @return [VglistApiRequestResponse]
  def api_request(query_string, variables: nil, token:)
    # Allow variables to be sent as snake case, e.g. "giantbomb_id" by
    # transforming them into "giantbombId" before passing them to GraphQL.
    variables = variables.transform_keys { |key| key.to_s.camelize(:lower) } unless variables.nil?

    post graphql_path,
      params: {
        query: query_string,
        variables: variables.to_json
      },
      headers: {
        'Authorization': "Bearer #{token.token}"
      }

    response_body = VglistApiRequestResponse.new(JSON.parse(response.body))
    puts "ERRORS: #{response_body.to_h['errors'].inspect}" if ENV['DEBUG'] && response_body.to_h['errors']&.any?
    return response_body
  end

  # Return an array of error messages from the GraphQL result object.
  #
  # @param result [VglistApiRequestResponse]
  # @return [Hash]
  def api_result_errors(result)
    return result.to_h['errors'].map { |item| item['message'] }
  end
end

class VglistApiRequestResponse
  attr_reader :body

  # @param body [Hash] The response body of the GraphQL query.
  def initialize(body)
    @body = body
  end

  # Returns the body as a hash.
  #
  # @return [Hash]
  def to_h
    body
  end

  # This will dig into the body, which is returned by `ApiRequestTestHelper`
  # above. It takes symbol keys and will stringify and camelize them. So it
  # will accept `:foo_bar` and transform it into `'fooBar'`.
  #
  # It digs into `data` automatically.
  #
  # @param args [Symbol] The keys to go through for digging into nested objects.
  # @return [Array<any>|Hash<any>] Returns a hash or an array by digging into the GraphQL response.
  def graphql_dig(*args)
    formatted_args = args.map { |arg| arg.to_s.camelize(:lower) }
    data = body.dig('data', *formatted_args)
    data.deep_symbolize_keys! if data.is_a?(Hash)
    data.map!(&:deep_symbolize_keys) if data.is_a?(Array)
    data
  end
end
