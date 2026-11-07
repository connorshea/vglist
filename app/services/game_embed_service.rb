# frozen_string_literal: true

# Builds the link-preview metadata for a game page: Open Graph / Twitter tags
# and a Discord component embed.
#
# Link-preview crawlers (Discordbot, Slackbot, etc.) don't run JavaScript, so
# they never see anything the Vue SPA renders. The frontend's Caddy server
# routes those crawlers' requests for `/games/:id` to EmbedsController, which
# renders this metadata as a small HTML document.
#
# Discord component embed docs:
# https://docs.discord.com/developers/link-previews/component-embeds.md
class GameEmbedService
  # Discord rejects payloads over 3,000 bytes. Escapes count at full length,
  # so this is checked against the exact string written into the page.
  MAX_PAYLOAD_BYTES = 3_000

  # Discord allows at most 5 buttons in an action row.
  MAX_BUTTONS = 5

  # How many platforms/genres/developers to list before "and N more".
  LIST_LIMIT = 6

  # The left border color. Matches Bulma $primary in bulma-variables.scss.
  ACCENT_COLOR = 0x5957D6

  # Characters that Discord markdown treats specially. Escaping punctuation
  # with a backslash is always safe, so escape all of them rather than trying
  # to work out which ones matter in context.
  MARKDOWN_SPECIAL_CHARS = /([\\*_~`|\[\]()<>#\-:.!])/

  # Component types, see the Discord docs.
  ACTION_ROW = 1
  BUTTON = 2
  SECTION = 9
  TEXT_DISPLAY = 10
  THUMBNAIL = 11
  SEPARATOR = 14
  CONTAINER = 17
  LINK_BUTTON_STYLE = 5

  attr_reader :game

  def initialize(game)
    @game = game
  end

  def canonical_url
    "#{frontend_url}/games/#{game.id}"
  end

  def title
    game.name
  end

  # A one-line summary for og:description, e.g.
  # "Valve · Released November 16, 2004 · Windows, Xbox, PlayStation 3".
  def description
    parts = [
      developers.first(3).join(', ').presence,
      release_line,
      platforms.first(LIST_LIMIT).join(', ').presence
    ].compact

    parts.empty? ? "#{game.name} on vglist" : parts.join(' · ')
  end

  # The public URL of the `:large` cover variant on the R2 public host, or nil
  # when the game has no cover. This is a direct, non-redirecting URL, so
  # Discord can fetch it well within its 10-second limit.
  def image_url
    return @image_url if defined?(@image_url)

    @image_url = game.cover.attached? ? game.sized_cover(:large)&.url : nil
  end

  # The Discord component embed as the exact JSON string to put inside
  # `<script id="discord:component-embed" type="application/json">`, or nil
  # if no version of it fits within MAX_PAYLOAD_BYTES.
  #
  # Builds the full payload first, then drops optional detail (list lengths,
  # then whole sections) until it fits.
  def discord_payload_json
    return @discord_payload_json if defined?(@discord_payload_json)

    @discord_payload_json = detail_levels.lazy.map { |level| encode(discord_payload(**level)) }
                                         .find { |json| json.bytesize <= MAX_PAYLOAD_BYTES }
  end

  # @param list_limit [Integer] How many items of each list to show.
  # @param details [Boolean] Whether to include the platforms/genres/series text.
  # @param footer [Boolean] Whether to include the owners/rating footer.
  # @param external_links [Boolean] Whether to include buttons other than "View on vglist".
  def discord_payload(list_limit: LIST_LIMIT, details: true, footer: true, external_links: true)
    components = [header_component(list_limit: list_limit, details: details)]

    footer_text = footer ? footer_line : nil
    if footer_text
      components << { type: SEPARATOR }
      components << { type: TEXT_DISPLAY, content: footer_text }
    end

    components << { type: ACTION_ROW, components: buttons(external_links: external_links) }

    {
      component: {
        type: CONTAINER,
        accent_color: ACCENT_COLOR,
        components: components
      }
    }
  end

  private

  # Ordered from most to least detailed. The last level is the bare minimum:
  # title, developer, release date, cover, and a "View on vglist" button.
  def detail_levels
    [
      {},
      { list_limit: 3 },
      { list_limit: 1 },
      { list_limit: 1, footer: false },
      { list_limit: 1, footer: false, external_links: false },
      { list_limit: 1, footer: false, external_links: false, details: false }
    ]
  end

  # JSON with `<`, `>`, and `&` escaped so the payload can't close the
  # surrounding <script> element.
  def encode(payload)
    ERB::Util.json_escape(payload.to_json)
  end

  # The title, developer, and release date, plus the details text when
  # requested. With a cover, it's a Section with the cover as a thumbnail.
  # Sections require an accessory, so without a cover it's plain text.
  def header_component(list_limit:, details:)
    texts = [{ type: TEXT_DISPLAY, content: heading_text(list_limit: list_limit) }]
    details_content = details ? details_text(list_limit: list_limit) : nil
    texts << { type: TEXT_DISPLAY, content: details_content } if details_content.present?

    if image_url.nil?
      return texts.one? ? texts.first : { type: TEXT_DISPLAY, content: texts.pluck(:content).join("\n") }
    end

    {
      type: SECTION,
      components: texts,
      accessory: {
        type: THUMBNAIL,
        media: { url: image_url },
        description: "#{game.name} cover"
      }
    }
  end

  def heading_text(list_limit:)
    subtitle = [
      truncated_list(developers, list_limit).presence,
      release_line
    ].compact.join(' · ')

    lines = ["## [#{escape_markdown(game.name)}](#{canonical_url})"]
    lines << escape_markdown(subtitle) if subtitle.present?
    lines.join("\n")
  end

  def details_text(list_limit:)
    {
      'Platforms' => truncated_list(platforms, list_limit),
      'Genres' => truncated_list(genres, list_limit),
      'Series' => game.series&.name
    }.filter_map do |label, value|
      "**#{label}:** #{escape_markdown(value)}" if value.present?
    end.join("\n")
  end

  def footer_line
    parts = []
    owners = game.game_purchases.count
    parts << "Owned by #{owners.to_fs(:delimited)} vglist #{'user'.pluralize(owners)}" if owners.positive?
    parts << "Avg. rating #{game.avg_rating.round}" if game.avg_rating.present?
    return nil if parts.empty?

    "-# #{parts.join(' · ')}"
  end

  def buttons(external_links:)
    links = [['View on vglist', canonical_url]]
    links.concat(external_link_buttons) if external_links

    links.first(MAX_BUTTONS).map do |label, url|
      { type: BUTTON, style: LINK_BUTTON_STYLE, label: label, url: url }
    end
  end

  # Same links, labels, and URL formats as the game page in the SPA.
  def external_link_buttons
    links = []
    steam_app_id = game.steam_app_ids.min_by(&:id)&.app_id
    links << ['Steam', "https://store.steampowered.com/app/#{steam_app_id}"] if steam_app_id
    links << ['PCGamingWiki', "https://www.pcgamingwiki.com/wiki/#{game.pcgamingwiki_id}"] if game.pcgamingwiki_id.present?
    links << ['Epic Games Store', "https://store.epicgames.com/p/#{game.epic_games_store_id}"] if game.epic_games_store_id.present?
    links << ['GOG', "https://www.gog.com/game/#{game.gog_id}"] if game.gog_id.present?
    links
  end

  def release_line
    date = game.release_date
    return nil if date.nil?

    verb = date > Time.zone.today ? 'Releases' : 'Released'
    "#{verb} #{date.strftime('%B %-d, %Y')}"
  end

  def truncated_list(items, limit)
    return items.join(', ') if items.size <= limit

    "#{items.first(limit).join(', ')} and #{items.size - limit} more"
  end

  def developers
    @developers ||= game.developers.order(:name).pluck(:name)
  end

  def platforms
    @platforms ||= game.platforms.order(:name).pluck(:name)
  end

  def genres
    @genres ||= game.genres.order(:name).pluck(:name)
  end

  def escape_markdown(text)
    text.to_s.gsub(MARKDOWN_SPECIAL_CHARS) { "\\#{::Regexp.last_match(1)}" }
  end

  def frontend_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:5173').chomp('/')
  end
end
