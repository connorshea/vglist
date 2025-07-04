class Mutations::Series::DeleteSeries < Mutations::BaseMutation
  description "Delete a game series. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :series_id, ID, required: true, description: 'The ID of the series to delete.'

  field :deleted, Boolean, null: true, description: "Whether the series was successfully deleted."

  def resolve(series_id:)
    series = Series.find(series_id)

    raise GraphQL::ExecutionError, series.errors.full_messages.join(", ") unless series.destroy

    {
      deleted: true
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    series = Series.find(object[:series_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this series." unless SeriesPolicy.new(@context[:current_user], series).destroy?

    return true
  end
end
