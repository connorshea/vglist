class Mutations::Companies::DeleteCompany < Mutations::BaseMutation
  description "Delete a game company. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :company_id, ID, required: true, description: 'The ID of the company to delete.'

  field :deleted, Boolean, null: true, description: "Whether the company was successfully deleted."

  def resolve(company_id:)
    company = Company.find(company_id)

    raise GraphQL::ExecutionError, company.errors.full_messages.join(", ") unless company.destroy

    {
      deleted: true
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    company = Company.find(object[:company_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this company." unless CompanyPolicy.new(@context[:current_user], company).destroy?

    return true
  end
end
