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

    return JSON.parse(response.body)
  end
end
