# typed: strict
class VideoGameListSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)
end
