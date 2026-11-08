# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VariantBackfillService do
  # Big enough that every cover size is a real downscale, with some detail so
  # differences in resizing would show up in the output bytes.
  let(:jpeg) do
    Vips::Image.gaussnoise(800, 1200, sigma: 40, mean: 128).cast(:uchar).bandjoin([128, 128]).write_to_buffer('.jpg')
  end
  let(:game) do
    game = create(:game)
    game.skip_cover_preprocessing = true
    game.cover.attach(io: StringIO.new(jpeg), filename: 'cover.jpg', content_type: 'image/jpeg')
    game
  end

  def with_original
    Tempfile.create(['original', '.jpg'], binmode: true) do |file|
      file.write(jpeg)
      file.flush
      file.rewind
      yield file
    end
  end

  it 'creates each missing size with its dimensions, from the given original' do
    created = with_original { |file| described_class.new(game.cover, Game::COVER_SIZES.keys).call(original: file) }

    expect(created).to eq(Game::COVER_SIZES.size)
    Game::COVER_SIZES.each do |name, (max_width, max_height)|
      image = game.cover.variant(name).image
      expect(image.metadata).to include('width' => be <= max_width, 'height' => be <= max_height, 'analyzed' => true)
      expect([image.metadata['width'], image.metadata['height']]).to include(max_width).or include(max_height)
    end
  end

  it 'makes the same files ActiveStorage would make from the original' do
    with_original { |file| described_class.new(game.cover, Game::COVER_SIZES.keys).call(original: file) }

    Game::COVER_SIZES.each_key do |name|
      variation = game.cover.variant(name).variation
      expected = with_original { |file| variation.transform(file) { |output| output.read } }

      expect(game.cover.variant(name).image.download).to eq(expected)
    end
  end

  it 'decodes the original once for every size, not once per size' do
    allow(Vips::Image).to receive(:new_from_file).and_call_original

    with_original do |file|
      described_class.new(game.cover, Game::COVER_SIZES.keys).call(original: file)

      expect(Vips::Image).to have_received(:new_from_file).with(file.path).once
    end
  end

  it 'downloads the original when none is given, and skips sizes that already exist' do
    service = described_class.new(game.cover, [:small])
    expect(service.call).to eq(1)

    expect(described_class.new(game.cover, Game::COVER_SIZES.keys).call).to eq(Game::COVER_SIZES.size - 1)
    expect(game.cover.blob.variant_records.count).to eq(Game::COVER_SIZES.size)
  end
end
