# typed: true
class Mutations::Companies::UpdateCompany < Mutations::BaseMutation
  description "Update an existing game company. **Not available in production for now.**"

  argument :company_id, ID, required: true, description: 'The ID of the company record.'
  argument :name, String, required: false, description: 'The name of the company.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the company item in Wikidata.'

  field :company, Types::CompanyType, null: false, description: "The company that was updated."

  # Use **args so we don't replace existing fields that aren't provided with `nil`.
  sig { params(company_id: T.any(String, Integer), args: T.untyped).returns(T::Hash[Symbol, Company]) }
  def resolve(company_id:, **args)
    company = Company.find(company_id)

    raise GraphQL::ExecutionError, company.errors.full_messages.join(", ") unless company.update(**args)

    {
      company: company
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    company = Company.find(object[:company_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this company." unless CompanyPolicy.new(@context[:current_user], company).update?

    return true
  end
end
