# typed: false
class WikidataHelper
  require "addressable/template"
  require "open-uri"
  require "json"

  #
  # Make an API call.
  #
  # @param [String] action The action to perform, see https://www.wikidata.org/w/api.php?action=help&modules=main
  # @param [String] ids Wikidata IDs, e.g. 'Q123' or 'P123'
  # @param [String] props Property type
  # @param [String] languages Language code
  # @param [String] entity Wikidata entity ID, e.g. 'Q123'
  #
  # @return [Hash] Ruby hash form of the Wikidata JSON Response.
  #
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

    template = Addressable::Template.new("https://www.wikidata.org/w/api.php{?#{query_options_string}}")
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

    response = JSON.parse(T.must(URI.open(api_uri)).read)

    return response['entities'] if response['success'] && action == 'wbgetentities'

    return response['claims'] if action == 'wbgetclaims'

    return nil
  end

  def self.get_all_entities(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids
    )

    return response
  end

  def self.get_descriptions(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'descriptions'
    )

    return response
  end

  def self.get_datatype(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'datatype'
    )

    return response
  end

  #
  # Get aliases for a set of Wikidata items.
  #
  # @param [Array<String>] ids Wikidata item IDs.
  #
  # @return [Hash] Hash of aliases.
  #
  def self.get_aliases(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'aliases'
    )

    return response
  end

  #
  # Get labels ('names') of the given items
  #
  # @param [String, Array<String>] ids Wikidata IDs, e.g. 'Q123' or ['Q123', 'Q124']
  # @param [String, Array<String>] languages A country code or array of country codes, e.g. 'en' or ['en', 'es']
  #
  # @return [Hash] Hash of labels in the listed languages.
  #
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

  #
  # Get sitelinks for a given Wikidata item.
  #
  # @param [String] ids Wikidata IDs, e.g. 'Q123' or 'P123'
  #
  # @return [Hash] Returns a hash of sitelinks.
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
  def self.get_sitelinks(ids:)
    response = api(
      action: 'wbgetentities',
      ids: ids,
      props: 'sitelinks'
    )

    sitelinks = []
    response['sitelinks'].each { |sitelink| sitelinks << sitelink[1] }

    return sitelinks
  end

  #
  # Get claims about an Wikidata entity.
  # https://www.wikidata.org/w/api.php?action=help&modules=wbgetclaims
  #
  # @param [String] entity Wikidata entity ID, e.g. 'Q123'
  # @param [String] property Wikidata property ID, e.g. 'P123'
  #
  # @return [Hash] Returns a hash with the properties of the entity.
  #
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
