# typed: true
class Mutations::Companies::CreateCompany < Mutations::BaseMutation
  description "Create a new game company. **Only available when using a first-party OAuth Application.**"

  required_permissions :first_party

  argument :name, String, required: true, description: 'The name of the company.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the company item in Wikidata.'

  field :company, Types::CompanyType, null: true, description: "The company that was created."

  sig { params(name: String, wikidata_id: T.nilable(T.any(String, Integer))).returns(T::Hash[Symbol, Company]) }
  def resolve(name:, wikidata_id: nil)
    company = Company.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, company.errors.full_messages.join(", ") unless company.save

    {
      company: company
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    raise GraphQL::ExecutionError, "You aren't allowed to create a company." unless CompanyPolicy.new(@context[:current_user], nil).create?

    return true
  end
end
