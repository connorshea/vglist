class StaticPagesController < ApplicationController
  def about
    skip_authorization
  end
end
