# typed: true
class Mutations::Series::CreateSeries < Mutations::BaseMutation
  description "Create a new game series. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the series.'
  argument :wikidata_id, ID, required: true, description: 'The ID of the series item in Wikidata.'

  field :series, Types::SeriesType, null: true, description: "The series that was created."

  def resolve(name:, wikidata_id:)
    series = Series.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, series.errors.full_messages.join(", ") unless series.save

    {
      series: series
    }
  end

  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create a series." unless SeriesPolicy.new(@context[:current_user], nil).create?

    return true
  end
end
