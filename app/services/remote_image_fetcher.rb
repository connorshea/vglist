# frozen_string_literal: true

require 'ipaddr'
require 'net/http'
require 'resolv'
require 'tempfile'

# Downloads a remote image (a game cover) over HTTP(S).
#
# Cover URLs come out of third-party API responses (PCGamingWiki, MobyGames,
# IGDB) rather than from an operator, and at least one of those is a wiki that
# anyone can edit, so the URLs have to be treated as attacker-controlled.
# Fetching one naively (e.g. `URI.parse(cover_url).open`) turns the import
# tasks into a server-side request forgery primitive: the request is made from
# inside the deployment network, where cloud metadata endpoints and
# unauthenticated internal services live.
#
# Every request made here is therefore checked before a connection is opened:
#
# - the scheme must be http or https,
# - the host must resolve only to public IP addresses,
# - the connection is pinned to the address that was checked, so a DNS record
#   that flips to a private address right after the check (DNS rebinding)
#   can't be used to reach it,
# - redirects are followed by hand, with every hop checked the same way,
# - the response must claim to be an image, and is capped in size.
#
# Anything that goes wrong — a rejected URL, a connection failure, a non-image
# response — raises RemoteImageFetcher::Error, so callers only need to rescue
# the one class.
class RemoteImageFetcher
  class Error < StandardError; end

  # Raised when a URL is rejected without a request being made.
  class UnsafeUrlError < Error; end

  ALLOWED_SCHEMES = ['http', 'https'].freeze

  # Address ranges a cover must never be fetched from: loopback, RFC 1918 and
  # other private space, link-local (which is where the cloud metadata
  # endpoints live), and the various reserved/special-use blocks. The
  # IPv4-mapped IPv6 range is blocked wholesale so `::ffff:127.0.0.1` can't
  # sneak a private IPv4 address past the IPv4 checks.
  BLOCKED_RANGES = [
    '0.0.0.0/8',          # "this network"
    '10.0.0.0/8',         # private
    '100.64.0.0/10',      # carrier-grade NAT
    '127.0.0.0/8',        # loopback
    '169.254.0.0/16',     # link-local, incl. the 169.254.169.254 metadata endpoint
    '172.16.0.0/12',      # private
    '192.0.0.0/24',       # IETF protocol assignments
    '192.0.2.0/24',       # TEST-NET-1
    '192.88.99.0/24',     # 6to4 relay anycast
    '192.168.0.0/16',     # private
    '198.18.0.0/15',      # benchmarking
    '198.51.100.0/24',    # TEST-NET-2
    '203.0.113.0/24',     # TEST-NET-3
    '224.0.0.0/4',        # multicast
    '240.0.0.0/4',        # reserved, incl. 255.255.255.255
    '::/128',             # unspecified
    '::1/128',            # loopback
    '::ffff:0:0/96',      # IPv4-mapped
    '64:ff9b::/96',       # NAT64
    '100::/64',           # discard-only
    '2001:db8::/32',      # documentation
    '2002::/16',          # 6to4
    'fc00::/7',           # unique local
    'fe80::/10',          # link-local
    'ff00::/8'            # multicast
  ].map { |range| IPAddr.new(range) }.freeze

  MAX_REDIRECTS = 5
  # Covers larger than this are rejected by the `Game#cover` size validation
  # anyway; the cap here just stops us buffering an unbounded response.
  MAX_SIZE = 8.megabytes
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 30

  # A downloaded image. `io` is a rewound binary Tempfile suitable for
  # `attach(io:)`, and `uri` is the URL it was ultimately fetched from (which
  # may differ from the requested one if redirects were followed).
  class Image
    attr_reader :io, :uri

    def initialize(io:, uri:)
      @io = io
      @uri = uri
    end

    # The last path segment of the URL, e.g. "cover.jpg". Falls back to
    # "cover" for URLs that don't end in a filename.
    def filename
      name = File.basename(uri.path.to_s)
      name.presence || 'cover'
    end

    # The file extension without the leading dot, e.g. "jpg". Empty when the
    # URL has none.
    def extension
      File.extname(uri.path.to_s).delete_prefix('.')
    end
  end

  # A URL that has passed validation, paired with the addresses the connection
  # may be pinned to, in the order the resolver preferred them.
  Target = Struct.new(:uri, :ips)
  private_constant :Target

  # @param url [String] the image URL, from an untrusted upstream response.
  # @return [RemoteImageFetcher::Image]
  # @raise [RemoteImageFetcher::Error]
  def self.fetch(url)
    new(url).fetch
  end

  def initialize(url)
    @url = url
  end

  # @return [RemoteImageFetcher::Image]
  # @raise [RemoteImageFetcher::Error]
  def fetch
    target = validated_target(@url)

    (MAX_REDIRECTS + 1).times do
      image = nil
      location = nil

      with_response(target) do |response|
        case response
        when Net::HTTPSuccess
          image = Image.new(io: buffer(response), uri: target.uri)
        when Net::HTTPRedirection
          location = response['location']
        else
          raise Error, "Unexpected response: #{response.code} #{response.message}."
        end
      end

      return image if image
      raise Error, "Redirected without a Location header." if location.nil?

      target = validated_target(location, relative_to: target.uri)
    end

    raise Error, "Too many redirects (more than #{MAX_REDIRECTS})."
  end

  private

  # Parse and check a URL, resolving its host so the connection can be pinned
  # to an address we've verified is public.
  def validated_target(url, relative_to: nil)
    uri = begin
      relative_to.nil? ? URI.parse(url.to_s) : URI.join(relative_to, url.to_s)
    rescue URI::Error => e
      raise UnsafeUrlError, "Invalid URL: #{e.message}."
    end

    raise UnsafeUrlError, "URL scheme must be http or https, got #{uri.scheme.inspect}." unless ALLOWED_SCHEMES.include?(uri.scheme)

    host = uri.hostname
    raise UnsafeUrlError, "URL has no host." if host.blank?

    Target.new(uri, public_addresses_for(host))
  end

  # Resolve a host and reject it unless *every* address it resolves to is
  # public — a host with one public and one private address is still a way to
  # reach the private one.
  def public_addresses_for(host)
    addresses = resolve(host)
    raise UnsafeUrlError, "#{host} did not resolve to any addresses." if addresses.empty?

    blocked = addresses.find { |address| blocked?(address) }
    raise UnsafeUrlError, "#{host} resolves to a non-public address (#{blocked})." if blocked

    addresses
  end

  def resolve(host)
    # The URL may name an address directly, in which case there's nothing to
    # look up.
    begin
      return [IPAddr.new(host)]
    rescue IPAddr::InvalidAddressError
      # Not a literal address, so fall through to DNS.
    end

    Addrinfo.getaddrinfo(host, nil, nil, :STREAM).map { |addrinfo| IPAddr.new(addrinfo.ip_address) }
  rescue SocketError => e
    raise Error, "Could not resolve #{host}: #{e.message}."
  end

  def blocked?(address)
    BLOCKED_RANGES.any? { |range| range.include?(address) }
  end

  # Make the request, trying each of the host's addresses in turn the way
  # Net::HTTP would if it were doing the resolving itself.
  def with_response(target, &block)
    last_error = nil

    target.ips.each do |ip|
      return request_from(target, ip, &block)
    rescue Net::HTTPBadResponse, Net::ProtocolError, OpenSSL::SSL::SSLError, SocketError, SystemCallError, IOError, Timeout::Error => e
      last_error = e
    end

    raise Error, "#{last_error.class}: #{last_error.message}"
  end

  def request_from(target, ip, &block)
    http = Net::HTTP.new(target.uri.host, target.uri.port)
    # Connect to the address we checked rather than resolving the host again.
    # Net::HTTP still uses the hostname for the Host header, SNI and
    # certificate verification, so this only closes the rebinding window.
    http.ipaddr = ip.to_s
    http.use_ssl = target.uri.scheme == 'https'
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT

    request = Net::HTTP::Get.new(target.uri)
    request['Accept'] = 'image/*'
    # Stream the bytes as-is so the size cap counts what we actually store.
    request['Accept-Encoding'] = 'identity'

    http.start do
      http.request(request, &block)
    end
  end

  # Stream the response body into a tempfile, refusing anything that isn't an
  # image or is over the size cap.
  def buffer(response)
    content_type = response['content-type'].to_s.split(';').first.to_s.strip
    raise Error, "Expected an image, got #{content_type.presence || 'no content type'}." unless content_type.start_with?('image/')

    declared_size = response['content-length']&.to_i
    raise Error, "Image is larger than #{MAX_SIZE} bytes (#{declared_size})." if declared_size && declared_size > MAX_SIZE

    tempfile = Tempfile.new('vglist-cover')
    tempfile.binmode
    size = 0

    begin
      response.read_body do |chunk|
        size += chunk.bytesize
        raise Error, "Image is larger than #{MAX_SIZE} bytes." if size > MAX_SIZE

        tempfile.write(chunk)
      end
    rescue StandardError
      tempfile.close
      tempfile.unlink
      raise
    end

    tempfile.rewind
    tempfile
  end
end
