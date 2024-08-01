begin
  require "chunky_png"
rescue
  # Download and install dependencies
  require "bundler/inline"
  gemfile do
    source "https://rubygems.org"
    gem "chunky_png"
  end
end

require_relative "chunky_png/image_ext"
require_relative "chunky_png/color_ext"
