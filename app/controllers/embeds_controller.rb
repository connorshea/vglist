# frozen_string_literal: true

# Server-rendered link-preview pages for link-preview crawlers.
#
# Crawlers like Discordbot and Slackbot don't run JavaScript, so the Vue SPA's
# `index.html` gives them nothing to unfurl. The frontend's Caddy server
# (frontend/Caddyfile) matches those crawlers by User-Agent and proxies their
# `/games/:id` requests here. Humans never get routed here, but if one does
# land on this page, it redirects to the real game page.
class EmbedsController < ApplicationController
  include ERB::Util
  # Lets the Disk storage service (dev/test) build cover URLs from the request
  # host. In production R2 serves covers from its public host regardless.
  include ActiveStorage::SetCurrent

  skip_before_action :reject_banned_users

  def game
    skip_authorization

    game = Game.find_by(id: params[:id])
    if game.nil?
      head :not_found
      return
    end

    # Discord doesn't document how long it caches unfurls. Keep ours short so
    # cover and metadata edits show up in new previews reasonably quickly.
    expires_in 1.hour, public: true
    render html: game_html(GameEmbedService.new(game)).html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  # Every interpolated value is escaped with `h`, except the Discord payload,
  # which GameEmbedService has already escaped for use inside <script>.
  def game_html(embed)
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
      <meta charset="utf-8">
      <title>#{h(embed.title)} - vglist</title>
      <link rel="canonical" href="#{h(embed.canonical_url)}">
      <meta http-equiv="refresh" content="0; url=#{h(embed.canonical_url)}">
      <meta name="description" content="#{h(embed.description)}">
      <meta property="og:site_name" content="vglist">
      <meta property="og:type" content="website">
      <meta property="og:title" content="#{h(embed.title)}">
      <meta property="og:description" content="#{h(embed.description)}">
      <meta property="og:url" content="#{h(embed.canonical_url)}">
      #{image_tags(embed)}<meta name="twitter:card" content="summary">
      #{discord_tag(embed)}</head>
      <body>
      <p><a href="#{h(embed.canonical_url)}">#{h(embed.title)} on vglist</a></p>
      </body>
      </html>
    HTML
  end

  def image_tags(embed)
    return '' if embed.image_url.nil?

    <<~HTML
      <meta property="og:image" content="#{h(embed.image_url)}">
      <meta property="og:image:alt" content="#{h("#{embed.title} cover")}">
    HTML
  end

  def discord_tag(embed)
    json = embed.discord_payload_json
    return '' if json.nil?

    <<~HTML
      <script id="discord:component-embed" type="application/json">#{json}</script>
    HTML
  end
end
