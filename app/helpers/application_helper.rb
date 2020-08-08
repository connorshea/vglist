# typed: true
module ApplicationHelper
  extend T::Sig

  sig { params(level: T.any(String, Symbol)).returns(String) }
  def flash_class(level)
    case level.to_sym
    when :notice then "is-info"
    when :success then "is-success"
    when :error then "is-danger"
    when :alert then "is-warning"
    else "not-possible"
    end
  end

  # A helper for displaying user avatars.
  sig { params(user_id: T.any(Integer, String), size: Integer, css_class_name: String).returns(T.untyped) }
  def user_avatar(user_id, size, css_class_name: 'user-avatar')
    user = User.find(user_id)
    if user.avatar&.attached? && user.avatar&.variable?
      # Resize the image, center it, and then crop it to a square.
      # This prevents users from having images that aren't either
      # too wide or too tall.
      image_tag T.must(user.avatar).variant(
        combine_options: {
          resize: "#{size}x#{size}^",
          gravity: 'Center',
          crop: "#{size}x#{size}+0+0"
        }
      ),
      height: "#{size}px",
      width: "#{size}px",
      class: css_class_name,
      alt: "Avatar for #{user.username}."
    elsif user.avatar&.attached? && !user.avatar&.variable?
      image_tag user.avatar, width: "#{size}px", height: "#{size}px", class: css_class_name, alt: "Avatar for #{user.username}."
    else
      image_tag 'default-avatar.png',
        height: "#{size}px",
        width: "#{size}px",
        class: css_class_name,
        alt: "Placeholder avatar for #{user.username}."
    end
  end

  # A helper for displaying game covers.
  sig { params(game: Game, width: Integer, height: Integer).returns(T.untyped) }
  def game_cover(game, width, height)
    if game.cover&.attached? && game.cover&.variable?
      image_tag T.must(game.cover).variant(
        resize: "#{width}x#{height}>"
      ),
      width: "#{width}px",
      height: "#{height}px",
      alt: "Cover for #{game.name}."
    elsif game.cover&.attached? && !game.cover&.variable?
      image_tag game.cover, width: "#{width}px", height: "#{height}px", alt: "Cover for #{game.name}."
    else
      image_tag 'no-cover.png', width: "#{width}px", height: "#{height}px", alt: "Placeholder cover for #{game.name}."
    end
  end

  # rubocop:disable Style/StringConcatenation
  sig { params(title: String).returns(String) }
  def meta_title(title)
    return (title + " | " if title.present?).to_s + "vglist"
  end
  # rubocop:enable Style/StringConcatenation

  sig { params(description: String).returns(String) }
  def meta_description(description)
    return description.presence || "vglist helps you track your entire video game library across every store and platform."
  end

  # Takes an array and creates a humanized string out of it.
  #
  # @examples
  #   summarize(['PlayStation 2', 'Xbox 360', 'Wii U', 'Windows'], limit: 2)
  #     => "PlayStation 2, Xbox 360, and 2 more"
  #
  #   summarize(['PlayStation 2', 'Xbox 360', 'Wii U', 'Windows'], limit: 4)
  #     => "PlayStation 2, Xbox 360, Wii U, Windows"
  #
  #   summarize(['PlayStation 2', 'Xbox 360', 'Wii U', 'Windows'], limit: 1)
  #     => "PlayStation 2 and 3 more"
  sig { params(array: T::Array[String], limit: Integer).returns(T.nilable(String)) }
  def summarize(array, limit: 3)
    raise ArgumentError, 'Limit must be a positive integer' unless limit.positive?

    return "#{array.first} and #{(array.length - limit)} more" if limit == 1 && array.length > 1
    return "#{T.must(array[0...limit]).join(', ')}, and #{(array.length - limit)} more" if array.length > limit
    return array.join(', ') if array.length <= limit
  end

  # This returns the `:page` parameter for Kaminari, it's a convenience method
  # for helping Sorbet understand the parameter.
  sig { params(param: Symbol).returns(T.nilable(Integer)) }
  def page_param(param: :page)
    return T.cast(params[param].to_i, T.nilable(Integer))
  end

  # Embeds an SVG icon.
  #
  # @param [String] icon The name of the SVG in `app/javascript/icons/`.
  # @param [Integer] height Height in pixels, defaults to 20.
  # @param [Integer] width Width in pixels, optional.
  # @param [String, Symbol] fill The name or color value for the , e.g. `'red'`, `:red`, or `'#fff'`.
  # @param [String] css_class CSS class names for the `svg` element, will always include `svg-icon`
  # @param [Boolean] aria Whether to include ARIA information for accessibility purposes. If `false`, aria-hidden is set.
  # @param [String] title The ARIA title for the element.
  # @param [Hash] options A hash of options to pass inline_svg_pack_tag.
  #
  # @return [any] An inline svg pack tag.
  sig do
    params(
      icon: String,
      height: Integer,
      width: T.nilable(Integer),
      fill: T.nilable(T.any(String, Symbol)),
      css_class: T.nilable(String),
      aria: T::Boolean,
      title: String,
      options: T::Hash[Symbol, T.untyped]
    ).returns(T.untyped)
  end
  def svg_icon(icon, height: 20, width: nil, fill: nil, css_class: nil, aria: true, title: "Icon", options: {})
    options[:aria] = aria
    options[:aria_hidden] = true unless aria
    options[:title] = title if aria
    options[:height] = "#{height}px"
    options[:width] = "#{width}px" unless width.nil?
    options[:style] = "fill: #{fill};" unless fill.nil?
    options[:class] = "svg-icon "
    options[:class] += css_class unless css_class.nil?
    return inline_svg_pack_tag("media/icons/#{icon}.svg", options)
  end

  # Return titles and paths for each item that should be displayed in the
  # navbar. A `nil` value means that the item can either be ignored or
  # should be a divider.
  sig { returns(T::Array[T::Hash[Symbol, T.nilable(String)]]) }
  def navbar_items
    items = []

    # Include profile, admin, settings, and sign out if the user is logged in.
    if user_signed_in?
      items << {
        title: 'Profile',
        path: user_path(current_user&.slug)
      }

      if current_user&.admin?
        items << {
          title: 'Admin',
          path: admin_path
        }
      end

      items = items.concat(
        [
          {
            title: 'Settings',
            path: settings_path
          },
          {
            title: 'Sign out',
            path: destroy_user_session_path
          },
          {
            title: nil,
            path: nil
          }
        ]
      )
    end

    # Always provide the links to extra information no matter if the user is
    # logged in or not.
    items = items.concat(
      [
        {
          title: 'About',
          path: about_path
        },
        {
          title: 'Changelog',
          path: 'https://github.com/connorshea/vglist/blob/master/CHANGELOG.md'
        },
        {
          title: 'GitHub',
          path: 'https://github.com/connorshea/vglist'
        },
        {
          title: 'API Docs',
          path: 'https://github.com/connorshea/vglist/blob/master/API.md'
        },
        {
          title: 'GraphiQL',
          path: graphiql_path
        },
        {
          title: 'Discord',
          path: 'https://discord.gg/Ma8Ztcc'
        }
      ]
    )

    return items
  end
end
