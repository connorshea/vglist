# frozen_string_literal: true

require 'net/http'

module Backloggd
  # Fetches the games on a Backloggd user's public games list.
  #
  # Backloggd has no API, so this reads the list's pages, one status filter at
  # a time (/u/<name>/games/added/type:played/?page=2). It's polite about it:
  # one request at a time with a pause between each, an honest User-Agent, and
  # a cap on the number of pages.
  #
  # Backloggd sits behind Anubis bot protection. If it serves us its challenge
  # page instead of the list, this raises BlockedError rather than trying to
  # get around it.
  class ListFetcher
    BASE_URL = 'https://backloggd.com'

    # vglist has no wishlist, so there's no need to fetch it.
    STATUSES = ['playing', 'played', 'backlog'].freeze

    MAX_PAGES_PER_STATUS = 50
    REQUEST_DELAY = 1.second
    MAX_REDIRECTS = 3

    USER_AGENT = 'vglist/1.0 (+https://vglist.co; imports a user\'s own Backloggd list when they ask)'

    # Backloggd usernames are letters, numbers, underscores and hyphens.
    USERNAME_FORMAT = /\A[A-Za-z0-9_-]{1,40}\z/

    class Error < StandardError; end

    class InvalidUsernameError < Error; end

    class UserNotFoundError < Error; end

    class RequestError < Error; end

    BlockedError = GameListParser::BlockedError

    # Accepts a username, "@username", or a Backloggd profile URL, and returns
    # the bare username.
    def self.username_from(input)
      value = input.to_s.strip
      value = Regexp.last_match(1) if value =~ %r{backloggd\.com/u/([^/?#\s]+)}i
      value = value.delete_prefix('@')

      raise InvalidUsernameError, "That doesn't look like a Backloggd username." unless USERNAME_FORMAT.match?(value)

      value
    end

    attr_reader :username

    # sleeper: called with the number of seconds to wait between requests, so
    # tests don't have to.
    def initialize(username, sleeper: ->(seconds) { sleep(seconds) })
      @username = self.class.username_from(username)
      @sleeper = sleeper
      @requests = 0
    end

    def entries
      STATUSES.flat_map { |status| entries_for(status) }
    end

    def list_url(status, page)
      url = "#{BASE_URL}/u/#{username}/games/added/type:#{status}/"
      page > 1 ? "#{url}?page=#{page}" : url
    end

    # One page of one list, parsed.
    def fetch_page(status, page)
      GameListParser.new(get(URI(list_url(status, page))), status: status)
    end

    private

    def entries_for(status)
      entries = []
      (1..MAX_PAGES_PER_STATUS).each do |page|
        parser = fetch_page(status, page)
        entries.concat(parser.entries)
        break unless parser.next_page?
      end
      entries
    end

    def get(uri, redirects = 0)
      @sleeper.call(REQUEST_DELAY.to_f) if @requests.positive?
      @requests += 1

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) do |http|
        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] = USER_AGENT
        request['Accept'] = 'text/html'
        http.request(request)
      end

      case response
      when Net::HTTPSuccess
        response.body.to_s
      when Net::HTTPRedirection
        follow_redirect(uri, response, redirects)
      when Net::HTTPNotFound
        raise UserNotFoundError, "Couldn't find a Backloggd user called #{username}."
      when Net::HTTPTooManyRequests, Net::HTTPServiceUnavailable
        raise RequestError, 'Backloggd is busy right now. Try again in a few minutes.'
      when Net::HTTPForbidden
        raise BlockedError, 'Backloggd refused the request.'
      else
        raise RequestError, "Backloggd responded with an error (#{response.code})."
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, OpenSSL::SSL::SSLError
      raise RequestError, "Couldn't reach Backloggd. Try again in a few minutes."
    end

    # Only follow redirects within Backloggd, e.g. to a username's canonical
    # capitalization.
    def follow_redirect(uri, response, redirects)
      raise RequestError, 'Backloggd redirected too many times.' if redirects >= MAX_REDIRECTS

      location = URI.join(uri, response['location'].to_s)
      raise RequestError, 'Backloggd redirected somewhere unexpected.' unless location.host == uri.host && location.scheme == 'https'

      get(location, redirects + 1)
    end
  end
end
