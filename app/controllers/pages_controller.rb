class PagesController < ApplicationController
  def home
    @landing = LandingContent.new
  end

  # Placeholder for pages scheduled in later stages. The title comes from the
  # route defaults (a fixed list), never from the request.
  def stub
    @title = request.path_parameters.fetch(:title)
  end
end
