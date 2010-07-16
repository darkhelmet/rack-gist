require 'hpricot'

module Rack
  class Gist
    def initialize(app, options = {})
      @app = app
      @options = options
    end

    def call(env)
      status, headers, body = @app.call(env)
      body = [body].flatten
      if 'text/html' == headers['Content-Type'] && body.respond_to?(:map!)
        body.map! do |part|
          Hpricot(part.to_s).tap do |doc|
            css = false
            doc.search('script[@src*="gist.github.com"]').each do |tag|
              css = true
              tag['src'].match(regex).tap do |match|
                id, file = match[1, 2]
                suffix, extra = file ? ["#file_#{file}", "rack-gist-file='#{file}'"] : ['', '']
                tag.swap("<div class='rack-gist' id='rack-gist-#{id}' #{extra}>Can't see this Gist? <a rel='nofollow' href='http://gist.github.com/#{id}#{suffix}'>View it on Github!</a></div>")
              end
            end
            doc.search('head').append(css_html) if css
          end.to_s
        end
      end
      [status, headers, body]
    end

  private

    def regex
      @regex ||= %r{gist\.github\.com/(\d+)\.js(?:\?file=(.*))?}
    end

    def css_html
      "<link rel='stylesheet' href='http://gist.github.com/stylesheets/gist/embed.css' />\n"
    end
  end
end