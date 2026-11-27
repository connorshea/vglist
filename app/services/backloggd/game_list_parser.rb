# frozen_string_literal: true

module Backloggd
  # Parses one page of a Backloggd user's games list
  # (backloggd.com/u/<name>/games/...) into the games on it.
  #
  # Backloggd has no API or export, so this reads the page's HTML.
  class GameListParser
    # Backloggd's game URLs use IGDB's slugs, e.g. /games/hollow-knight/.
    GAME_PATH = %r{\A/games/([a-z0-9][a-z0-9-]*)/?(?:[?#].*)?\z}i

    Entry = Struct.new(:slug, :name, :rating, :status, keyword_init: true)

    class Error < StandardError; end

    # Raised for Backloggd's bot protection (Anubis) challenge page.
    class BlockedError < Error; end

    # status: the list filter the page was fetched with (played, playing,
    # backlog or wishlist), which applies to every game on it.
    def initialize(html, status: nil)
      @document = Nokogiri::HTML5(html.to_s)
      @status = status
    end

    attr_reader :status

    def blocked?
      title = @document.at_css('title')&.text.to_s.strip
      return true if ["Oh noes!", "Making sure you're not a bot!"].include?(title)

      # Anubis serves its challenge assets from this path.
      @document.css('script[src], link[href]').any? do |node|
        (node['src'] || node['href']).to_s.include?('/.within.website/')
      end
    end

    def entries
      raise BlockedError, 'Backloggd returned its bot check page instead of the games list.' if blocked?

      cards.filter_map do |card|
        slug = slug_for(card)
        next if slug.nil?

        Entry.new(slug: slug, name: name_for(card, slug), rating: rating_for(card), status: status)
      end.uniq(&:slug)
    end

    # Whether the list continues on another page.
    def next_page?
      @document.at_css('a[rel~="next"], .next-page a[href], nav.pagy a.next[href]').present?
    end

    private

    # Each game in the grid is a `.game-cover` card wrapping a link to the game.
    def cards
      @document.css('.game-cover').select { |card| slug_for(card) }
    end

    def slug_for(card)
      card.css('a[href]').each do |link|
        match = GAME_PATH.match(link['href'].to_s.strip)
        return match[1].downcase if match
      end
      nil
    end

    def name_for(card, slug)
      name = card.at_css('.game-text-centered')&.text.to_s.squish
      name = card.at_css('img[alt]')&.[]('alt').to_s.squish if name.blank?
      name.presence || slug.tr('-', ' ').titleize
    end

    # Ratings are drawn as a row of stars clipped to a width, so 4.5 stars is
    # `width: 90%`. That percentage is a vglist rating as-is. The stars sit
    # next to the cover, inside the `.rating-hover` wrapper around both.
    def rating_for(card)
      container = card.ancestors('.rating-hover').first || card
      style = container.at_css('.stars-top[style]')&.[]('style').to_s
      percent = style[/width:\s*(\d+(?:\.\d+)?)%/i, 1]
      return nil if percent.nil?

      percent.to_f.round.clamp(0, 100).then { |r| r.zero? ? nil : r }
    end
  end
end
