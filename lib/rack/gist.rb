require 'nokogiri'
require 'rest-client'

module Rack
  class Gist
    DefaultCacheTime = 3600

    def initialize(app, options = {})
      @app = app
      @options = options
    end

    def call(env)
      if path(env).match(regex)
        serve_gist(env)
      else
        status, headers, body = @app.call(env)
        rewrite(status, headers, body)
      end
    end

  private

    def rewrite(status, headers, body)
      if headers['Content-Type'].to_s.match('text/html')
        body = [rewrite_body(body)]
        headers['Content-Length'] = Rack::Utils.bytesize(body.first).to_s
      end
      [status, headers, body]
    end

    def rewrite_body(body)
      Nokogiri(stringify_body(body)).tap do |doc|
        if swap_tags(doc)
          doc.at('head').add_child(css_html)
          doc.at('body').tap do |node|
            node.add_child(jquery_link) if @options.fetch(:jquery, true)
            node.add_child(jquery_helper) if @options.fetch(:helper, true)
          end
        end
      end.to_html(:encoding => @options.fetch(:encoding, 'utf-8'))
    end

    def stringify_body(body)
      b = ''
      body.each { |part| b << part }
      b
    end

    def swap_tags(doc)
      extras = false
      doc.search('script[@src*="gist.github.com"]').each do |tag|
        extras = true
        tag['src'].match(%r{gist\.github\.com/([a-f0-9]+)\.js(?:\?file=(.*))?}).tap do |match|
          id, file = match[1, 2]
          url = "/gist.github.com/#{id}"
          if file
            url += "/#{file}"
            suffix = "#file_#{file}"
            extra = %Q{rack-gist-file="#{file}"}
          else
            suffix = nil
            extra = nil
          end
          tag.swap(%Q{<p class="rack-gist" id="rack-gist-#{id}"" gist-id="#{id}" rack-gist-url="#{url}.js" #{extra}>Can't see this Gist? <a rel="nofollow" href="http://gist.github.com/#{id}#{suffix}">View it on Github!</a></p>})
        end
      end
      extras
    end

    def serve_gist(env)
      gist_id, file = path(env).match(regex)[1,2]
      gist = fetch_gist(gist_id, file).to_s
      headers = {
        'Content-Type' => 'application/javascript',
        'Content-Length' => Rack::Utils.bytesize(gist).to_s,
        'Vary' => 'Accept-Encoding'
      }

      headers['Cache-Control'] = "public, must-revalidate, max-age=#{@options.fetch(:http_cache_time, DefaultCacheTime)}"

      [200, headers, [gist]]
    end

    def fetch_gist(gist_id, file)
      if cache = @options.fetch(:cache, false)
        expires = @options.fetch(:cache_time, DefaultCacheTime)
        cache.fetch(cache_key(gist_id, file), :expires_in => expires) { get_gist(gist_id, file) }
      else
        get_gist(gist_id, file)
      end
    end

    def get_gist(gist_id, file)
      gist = RestClient.get(gist_url(gist_id, file))
      gist = gist.split("\n").reject do |part|
        part.empty?
      end.last
      selector = "#rack-gist-#{gist_id}"
      selector << %Q{[rack-gist-file="#{file}"]} if file
      gist.sub(/document\.write/, %Q{$('#{selector}').replaceWith})
    end

    def cache_key(gist_id, file)
      key = "rack-gist:#{gist_id}"
      key << ":#{file.gsub(/\s/, '')}" unless file.nil?
      key
    end

    def gist_url(gist_id, file)
      url = "https://gist.github.com/#{gist_id}.js"
      url << "?file=#{file}" unless file.nil?
      url
    end

    def path(env)
      Rack::Utils.unescape(env['PATH_INFO'])
    end

    def regex
      @regex ||= %r{gist\.github\.com/([a-f0-9]+)(?:/(.*))?\.js}
    end

    def css_html
      "<link rel='stylesheet' href='https://gist.github.com/stylesheets/gist/embed.css' />\n"
    end

    def jquery_link
      "<script type='text/javascript' src='http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js'></script>\n"
    end

    def jquery_helper
      <<-EOJQ
        <script type='text/javascript'>
          //<![CDATA[
          $(document).ready(function() {
            $('.rack-gist').each(function() {
              $.ajax({
                url: $(this).attr('rack-gist-url'),
                dataType: 'script',
                cache: true
              });
            });
          });
          //]]>
        </script>
      EOJQ
    end
  end
end
