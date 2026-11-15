require "rubygems/command"
require "open-uri"
require "yaml"
require "shellwords"

# module Rubygems; end

class Gem::Commands::ApiCommand < Gem::Command
  VERSION = "1.0.0"

  attr_accessor :creds

  def initialize
    defaults = { query: nil }

    super("api", "Send requests to rubygems' API.", defaults)

    add_option("-j", "--jq QUERY", "Pass results through jq with QUERY.") do |v, o|
      options[:query] = v
    end
  end

  def arguments # :nodoc:
    "URL           API endpoint to hit, with params"
  end

  def usage # :nodoc:
    "#{program_name} URL [-j jq-query]"
  end

  def description
    <<~EOF.lines.grep_v(/DELETE|POST|PATCH/).join # TODO: handle more?

      `gem api` lets you hit rubygems API endpoints on the commandline.

      It uses the credentials located at ~/.gem/credentials.

      Here's the current full API:

         GET    /api/v1/activity/just_updated
         GET    /api/v1/activity/latest
         PATCH  /api/v1/api_key
         POST   /api/v1/api_key.(json|yaml)
         GET    /api/v1/attestations/$NAME-$VERSION.json
         GET    /api/v1/downloads.(json|yaml)
         GET    /api/v1/downloads/$NAME-$VERSION.(json|yaml)
         GET    /api/v1/downloads/all.(json|yaml)
         POST   /api/v1/gems
         GET    /api/v1/gems.(json|yaml)
         GET    /api/v1/gems/$NAME.(json|yaml)
         GET    /api/v1/gems/$NAME/owners.(json|yaml)
         POST   /api/v1/gems/$NAME/owners
         DELETE /api/v1/gems/$NAME/owners
         PATCH  /api/v1/gems/$NAME/owners
         GET    /api/v1/gems/$NAME/reverse_dependencies.json
         DELETE /api/v1/gems/yank
         POST   /api/v1/oidc/trusted_publisher/exchange_token
         GET    /api/v1/owners/$username_or_id/gems.(json|yaml)
         GET    /api/v1/profile/me.(json|yaml)
         GET    /api/v1/profiles/$username_or_id.(json|yaml)
         GET    /api/v1/search.(json|yaml)?query=$query[&page=$N]
         GET    /api/v1/search/autocomplete?query=$query
         GET    /api/v1/timeframe_versions.json
         GET    /api/v1/versions/$NAME.(json|yaml)
         GET    /api/v1/versions/$NAME/latest.json
         POST   /api/v1/web_hooks
         GET    /api/v1/web_hooks.(json|yaml)
         POST   /api/v1/web_hooks/fire
         DELETE /api/v1/web_hooks/remove

      Currently, only the GET endpoints are currently supported, but
      most of the others are supported through other gem commands (eg
      `gem owner`).
    EOF
  end

  def read_url url
    URI.parse(url)
      .read("User-Agent"    => "rubygems-api/#{VERSION}",
            "Authorization" => creds)
  end

  def execute
    url = options[:args].shift

    base = "https://rubygems.org" # HACK: should look at sources

    url = base + url

    prefs = YAML.load File.read File.expand_path "~/.gem/credentials"
    self.creds = prefs[:rubygems_api_key]

    body = read_url url

    query = options[:query]
    if query then
      IO.popen ["jq", query].shelljoin, "r+" do |pipe|
        pipe.puts body
        pipe.close_write
        say pipe.read
      end
    else
      say body
    end
  end
end
