# typed: true
class Mutations::Series::UpdateSeries < Mutations::BaseMutation
  description "Update an existing game series. **Only available when using a first-party OAuth Application.**"

  argument :series_id, ID, required: true, description: 'The ID of the series record.'
  argument :name, String, required: false, description: 'The name of the series.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the series item in Wikidata.'

  field :series, Types::SeriesType, null: false, description: "The series that was updated."

  # Use **args so we don't replace existing fields that aren't provided with `nil`.
  sig { params(series_id: T.any(String, Integer), args: T.untyped).returns(T::Hash[Symbol, Series]) }
  def resolve(series_id:, **args)
    series = Series.find(series_id)

    raise GraphQL::ExecutionError, series.errors.full_messages.join(", ") unless series.update(**args)

    {
      series: series
    }
  end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    require_permissions!(:first_party)

    series = Series.find(object[:series_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this series." unless SeriesPolicy.new(@context[:current_user], series).update?

    return true
  end
end
