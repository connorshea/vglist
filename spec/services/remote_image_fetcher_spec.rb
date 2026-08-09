# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoteImageFetcher, type: :service do
  # A 1x1 PNG, so the fetched bytes are a real image.
  let(:png) do
    [137, 80, 78, 71, 13, 10, 26, 10].pack('C*') +
      ['0000000d49484452000000010000000108060000001f15c489' \
       '0000000a49444154789c6360000002000100ffff03000006000557bfabd4' \
       '0000000049454e44ae426082'].pack('H*')
  end

  # Keep DNS out of the specs: every host that isn't an IP literal resolves to
  # a public address unless a specific example says otherwise.
  before(:each) do
    allow(Addrinfo).to receive(:getaddrinfo).and_return([Addrinfo.ip('93.184.216.34')])
  end

  def resolves_to(host, *ips)
    allow(Addrinfo).to receive(:getaddrinfo).with(host, any_args).and_return(ips.map { |ip| Addrinfo.ip(ip) })
  end

  describe '.fetch' do
    it 'downloads an image from a public host' do
      stub_request(:get, 'https://images.example.com/covers/half-life.png')
        .to_return(status: 200, body: png, headers: { 'Content-Type' => 'image/png' })

      image = described_class.fetch('https://images.example.com/covers/half-life.png')

      expect(image.io.read).to eq(png)
      expect(image.filename).to eq('half-life.png')
      expect(image.extension).to eq('png')
    end

    it 'ignores the query string when deriving the filename' do
      stub_request(:get, 'https://images.example.com/covers/half-life.png?width=500')
        .to_return(status: 200, body: png, headers: { 'Content-Type' => 'image/png' })

      image = described_class.fetch('https://images.example.com/covers/half-life.png?width=500')

      expect(image.filename).to eq('half-life.png')
    end

    context 'with a URL that points somewhere internal' do
      # The URLs in these examples are the shapes an attacker would use after
      # editing a cover URL into an upstream service's data.
      [
        'http://127.0.0.1/latest/meta-data/',
        'http://localhost:3000/admin',
        'http://169.254.169.254/latest/meta-data/iam/security-credentials',
        'http://10.0.0.5/internal',
        'http://192.168.1.1/',
        'http://172.16.0.1/',
        'http://[::1]:8080/',
        'http://[fd00::1]/',
        'http://[::ffff:127.0.0.1]/'
      ].each do |url|
        it "refuses to request #{url}" do
          resolves_to('localhost', '127.0.0.1')

          expect { described_class.fetch(url) }.to raise_error(described_class::UnsafeUrlError, /non-public address/)
          expect(a_request(:get, /.*/)).not_to have_been_made
        end
      end

      it 'refuses a public hostname that resolves to a private address' do
        resolves_to('rebind.example.com', '10.1.2.3')

        expect { described_class.fetch('https://rebind.example.com/cover.png') }
          .to raise_error(described_class::UnsafeUrlError, /non-public address/)
        expect(a_request(:get, /.*/)).not_to have_been_made
      end

      it 'refuses a hostname that resolves to both a public and a private address' do
        resolves_to('mixed.example.com', '93.184.216.34', '127.0.0.1')

        expect { described_class.fetch('https://mixed.example.com/cover.png') }
          .to raise_error(described_class::UnsafeUrlError, /non-public address/)
      end

      it 'refuses a redirect into private address space' do
        stub_request(:get, 'https://images.example.com/cover.png')
          .to_return(status: 302, headers: { 'Location' => 'http://169.254.169.254/latest/meta-data/' })

        expect { described_class.fetch('https://images.example.com/cover.png') }
          .to raise_error(described_class::UnsafeUrlError, /non-public address/)
        expect(a_request(:get, 'http://169.254.169.254/latest/meta-data/')).not_to have_been_made
      end
    end

    context 'with a URL that is not fetchable at all' do
      it 'refuses a non-HTTP scheme' do
        expect { described_class.fetch('file:///etc/passwd') }
          .to raise_error(described_class::UnsafeUrlError, /scheme/)
      end

      it 'refuses a URL with no host' do
        expect { described_class.fetch('https:///cover.png') }
          .to raise_error(described_class::UnsafeUrlError, /no host/)
      end

      it 'refuses an unparseable URL' do
        expect { described_class.fetch('http://exa mple.com/cover.png') }
          .to raise_error(described_class::UnsafeUrlError, /Invalid URL/)
      end

      it 'refuses a nil URL' do
        expect { described_class.fetch(nil) }.to raise_error(described_class::UnsafeUrlError)
      end
    end

    context 'with a response that is not a usable image' do
      it 'rejects a non-image content type' do
        stub_request(:get, 'https://images.example.com/cover.png')
          .to_return(status: 200, body: '{"token":"secret"}', headers: { 'Content-Type' => 'application/json' })

        expect { described_class.fetch('https://images.example.com/cover.png') }
          .to raise_error(described_class::Error, /Expected an image/)
      end

      it 'rejects a response whose declared size is over the cap' do
        stub_request(:get, 'https://images.example.com/cover.png').to_return(
          status: 200,
          body: png,
          headers: { 'Content-Type' => 'image/png', 'Content-Length' => (described_class::MAX_SIZE + 1).to_s }
        )

        expect { described_class.fetch('https://images.example.com/cover.png') }
          .to raise_error(described_class::Error, /larger than/)
      end

      it 'rejects a response whose body exceeds the cap while streaming' do
        stub_request(:get, 'https://images.example.com/cover.png')
          .to_return(status: 200, body: 'a' * (described_class::MAX_SIZE + 1), headers: { 'Content-Type' => 'image/png' })

        expect { described_class.fetch('https://images.example.com/cover.png') }
          .to raise_error(described_class::Error, /larger than/)
      end

      it 'raises on an error response' do
        stub_request(:get, 'https://images.example.com/cover.png').to_return(status: 404)

        expect { described_class.fetch('https://images.example.com/cover.png') }
          .to raise_error(described_class::Error, /404/)
      end

      it 'falls back to the host\'s other addresses when a connection fails' do
        resolves_to('images.example.com', '93.184.216.34', '93.184.216.35')
        stub_request(:get, 'https://images.example.com/cover.png')
          .to_raise(Errno::ECONNREFUSED)
          .then.to_return(status: 200, body: png, headers: { 'Content-Type' => 'image/png' })

        expect(described_class.fetch('https://images.example.com/cover.png').io.read).to eq(png)
      end

      it 'raises when the connection fails' do
        stub_request(:get, 'https://images.example.com/cover.png').to_raise(SocketError.new('getaddrinfo failed'))

        expect { described_class.fetch('https://images.example.com/cover.png') }
          .to raise_error(described_class::Error, /getaddrinfo failed/)
      end
    end

    context 'with redirects' do
      it 'follows a redirect to another public host' do
        stub_request(:get, 'https://images.example.com/cover')
          .to_return(status: 301, headers: { 'Location' => 'https://cdn.example.net/covers/final.jpg' })
        stub_request(:get, 'https://cdn.example.net/covers/final.jpg')
          .to_return(status: 200, body: png, headers: { 'Content-Type' => 'image/jpeg' })

        image = described_class.fetch('https://images.example.com/cover')

        expect(image.io.read).to eq(png)
        expect(image.filename).to eq('final.jpg')
      end

      it 'follows a relative redirect' do
        stub_request(:get, 'https://images.example.com/cover')
          .to_return(status: 302, headers: { 'Location' => '/covers/final.png' })
        stub_request(:get, 'https://images.example.com/covers/final.png')
          .to_return(status: 200, body: png, headers: { 'Content-Type' => 'image/png' })

        expect(described_class.fetch('https://images.example.com/cover').filename).to eq('final.png')
      end

      it 'gives up after too many redirects' do
        stub_request(:get, 'https://images.example.com/cover')
          .to_return(status: 302, headers: { 'Location' => 'https://images.example.com/cover' })

        expect { described_class.fetch('https://images.example.com/cover') }
          .to raise_error(described_class::Error, /Too many redirects/)
      end

      it 'raises when a redirect has no Location header' do
        stub_request(:get, 'https://images.example.com/cover').to_return(status: 302)

        expect { described_class.fetch('https://images.example.com/cover') }
          .to raise_error(described_class::Error, /Location/)
      end
    end
  end
end
