class Mutations::Companies::UpdateCompany < Mutations::BaseMutation
  description "Update an existing game company. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :company_id, ID, required: true, description: 'The ID of the company record.'
  argument :name, String, required: false, description: 'The name of the company.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the company item in Wikidata.'

  field :company, Types::CompanyType, null: false, description: "The company that was updated."

  # Use **args so we don't replace existing fields that aren't provided with `nil`.
  def resolve(company_id:, **args)
    company = Company.find(company_id)

    raise GraphQL::ExecutionError, company.errors.full_messages.join(", ") unless company.update(**args)

    {
      company: company
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    company = Company.find(object[:company_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this company." unless CompanyPolicy.new(@context[:current_user], company).update?

    return true
  end
end
