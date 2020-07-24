# typed: true
class WikidataHelper
  require "addressable/template"
  require "open-uri"
  require "json"
  extend T::Sig

  # Make an API call.
  #
  # @param [String] action The action to perform, see https://www.wikidata.org/w/api.php?action=help&modules=main
  # @param [String] ids Wikidata IDs, e.g. 'Q123' or 'P123'
  # @param [String] props Property type
  # @param [String] languages Language code
  # @param [String] entity Wikidata entity ID, e.g. 'Q123'
  # @param [String] property
  #
  # @return [Hash, nil] Ruby hash form of the Wikidata JSON Response.
  sig do
    params(
      action: T.nilable(String),
      ids: T.nilable(String),
      props: T.nilable(String),
      languages: T.nilable(String),
      entity: T.nilable(String),
      property: T.nilable(String)
    ).returns(T.nilable(T::Hash[T.untyped, T.untyped]))
  end
  def self.api(action: nil, ids: nil, props: nil, languages: 'en', entity: nil, property: nil)
    query_options = [
      :format,
      :action,
      :props,
      :languages,
      :ids,
      :sitelinks,
      :entity,
      :property
    ]
    query_options_string = query_options.join(',')

    template = T.unsafe(Addressable::Template).new("https://www.wikidata.org/w/api.php{?#{query_options_string}}")
    template = template.expand(
      {
        'action': action,
        'format': 'json',
        'ids': ids,
        'languages': languages,
        'props': props,
        'entity': entity,
        'property': property
      }
    )

    puts template if ENV['DEBUG']
    api_uri = URI.parse(template.to_s)

    puts api_uri if ENV['DEBUG']

    response = JSON.parse(T.must(T.must(URI.open(api_uri.to_s)).read))

    return response['entities'] if response['success'] && action == 'wbgetentities'

    return response['claims'] if action == 'wbgetclaims'

    return nil
  end

  sig { params(ids: String).returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
  def self.get_all_entities(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids
    )

    return response
  end

  sig { params(ids: String).returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
  def self.get_descriptions(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'descriptions'
    )

    return response
  end

  sig { params(ids: String).returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
  def self.get_datatype(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'datatype'
    )

    return response
  end

  # Get aliases for a set of Wikidata items.
  #
  # @param [String] ids Wikidata item IDs.
  #
  # @return [Hash] Hash of aliases.
  sig { params(ids: String).returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
  def self.get_aliases(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'aliases'
    )

    return response
  end

  # Get labels ('names') of the given items
  #
  # @param [String, Array<String>] ids Wikidata IDs, e.g. 'Q123' or ['Q123', 'Q124']
  # @param [String, Array<String>] languages A country code or array of country codes, e.g. 'en' or ['en', 'es']
  #
  # @return [Hash] Hash of labels in the listed languages.
  sig do
    params(
      ids: T.any(String, T::Array[String]),
      languages: T.nilable(T.any(String, T::Array[String]))
    ).returns(T.nilable(T::Hash[T.untyped, T.untyped]))
  end
  def self.get_labels(ids:, languages: nil)
    ids = ids.join('|') if ids.is_a?(Array)
    languages = languages.join('|') if languages.is_a?(Array)

    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'labels',
      languages: languages
    )

    return response
  end

  # Get sitelinks for a given Wikidata item.
  #
  # @param [String] ids Wikidata IDs, e.g. 'Q123' or 'P123'
  #
  # @return [Array] Returns a hash of sitelinks.
  #
  # {
  #   "afwiki"=>{
  #     "site"=>"afwiki",
  #     "title"=>"Douglas Adams",
  #     "badges"=>[]
  #   },
  #   "bswiki"=>{
  #     "site"=>"bswiki",
  #     "title"=>"Douglas Adams",
  #     "badges"=>[]
  #   }
  # }
  #
  sig { params(ids: String).returns(T.nilable(T::Array[T.untyped])) }
  def self.get_sitelinks(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'sitelinks'
    )

    sitelinks = []
    T.must(response)['sitelinks'].each { |sitelink| sitelinks << sitelink[1] }

    return sitelinks
  end

  # Get claims about an Wikidata entity.
  # https://www.wikidata.org/w/api.php?action=help&modules=wbgetclaims
  #
  # @param [String] entity Wikidata entity ID, e.g. 'Q123'
  # @param [String] property Wikidata property ID, e.g. 'P123'
  #
  # @return [Hash] Returns a hash with the properties of the entity.
  sig { params(entity: String, property: T.nilable(String)).returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
  def self.get_claims(entity:, property: nil)
    response = api(
      action: 'wbgetclaims',
      entity: entity,
      languages: nil,
      property: property
    )

    return response
  end
end
