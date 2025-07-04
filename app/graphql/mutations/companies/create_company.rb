# typed: true
class Mutations::Companies::CreateCompany < Mutations::BaseMutation
  description "Create a new game company. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the company.'
  argument :wikidata_id, ID, required: true, description: 'The ID of the company item in Wikidata.'

  field :company, Types::CompanyType, null: true, description: "The company that was created."

  def resolve(name:, wikidata_id:)
    company = Company.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, company.errors.full_messages.join(", ") unless company.save

    {
      company: company
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create a company." unless CompanyPolicy.new(@context[:current_user], nil).create?

    return true
  end
end
