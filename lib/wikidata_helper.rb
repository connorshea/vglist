# frozen_string_literal: true

class WikidataHelper
  require "addressable/template"
  require "open-uri"
  require "json"

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

    begin
      response = JSON.parse(URI.parse(api_uri.to_s).open.read)
    rescue OpenURI::HTTPError => e
      # Surface useful detail on rate limiting (429) and other HTTP errors,
      # since open-uri's default message ("429 Too Many Requests") hides the
      # Retry-After hint and the request that triggered it.
      io = e.io
      warn "Wikidata API request failed: #{io.status.join(' ')}"
      warn "  URL: #{api_uri}"
      warn "  Retry-After: #{io.meta['retry-after']}" if io.meta['retry-after']
      %w[x-ratelimit-limit x-ratelimit-remaining x-ratelimit-reset].each do |header|
        warn "  #{header}: #{io.meta[header]}" if io.meta[header]
      end
      warn "  Headers: #{io.meta.inspect}" if ENV['DEBUG']
      raise
    end

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

  # Get aliases for a set of Wikidata items.
  #
  # @param [String] ids Wikidata item IDs.
  #
  # @return [Hash] Hash of aliases.
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

  # Get claims about an Wikidata entity.
  # https://www.wikidata.org/w/api.php?action=help&modules=wbgetclaims
  #
  # @param [String] entity Wikidata entity ID, e.g. 'Q123'
  # @param [String] property Wikidata property ID, e.g. 'P123'
  #
  # @return [Hash] Returns a hash with the properties of the entity.
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
