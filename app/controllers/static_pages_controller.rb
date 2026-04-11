# frozen_string_literal: true

class StaticPagesController < ApplicationController
  skip_before_action :sign_out_banned_users

  def opensearch
    skip_authorization
    render xml: opensearch_xml
  end

  private

  def opensearch_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
        <ShortName>vglist</ShortName>
        <Description>Search vglist</Description>
        <Url type="text/html" template="#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/search?query={searchTerms}"/>
      </OpenSearchDescription>
    XML
  end
end
