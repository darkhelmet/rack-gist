require 'nokogiri'
require 'rest-client'

module Rack
  class Gist
    def initialize(app, options = {})
      @app = app
      @options = {
        :jquery => true,
        :cache_time => 3600,
        :http_cache_time => 3600,
        :encoding => 'utf-8'
      }.merge(options)
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
        b = ''
        body.each { |part| b << part }
        body = Nokogiri(b).tap do |doc|
          if swap_tags(doc)
            doc.at('head').add_child(css_html)
            doc.at('body').tap do |node|
              node.add_child(jquery_link) if @options[:jquery]
              node.add_child(jquery_helper)
            end
          end
        end.to_html(:encoding => @options[:encoding])
        body = [body]
        headers['Content-Length'] = Rack::Utils.bytesize(body.first).to_s
      end
      [status, headers, body]
    end

    def swap_tags(doc)
      extras = false
      doc.search('script[@src*="gist.github.com"]').each do |tag|
        extras = true
        tag['src'].match(%r{gist\.github\.com/(\d+)\.js(?:\?file=(.*))?}).tap do |match|
          id, file = match[1, 2]
          suffix, extra = file ? ["#file_#{file}", "rack-gist-file='#{file}'"] : ['', '']
          tag.swap("<p class='rack-gist' id='rack-gist-#{id}' gist-id='#{id}' #{extra}>Can't see this Gist? <a rel='nofollow' href='http://gist.github.com/#{id}#{suffix}'>View it on Github!</a></p>")
        end
      end
      extras
    end

    def serve_gist(env)
      gist_id, file = path(env).match(regex)[1,2]
      cache = @options[:cache]
      gist = (cache ? cache.fetch(cache_key(gist_id, file), :expires_in => @options[:cache_time]) { get_gist(gist_id, file) } : get_gist(gist_id, file)).to_s
      headers = {
        'Content-Type' => 'application/javascript',
        'Content-Length' => Rack::Utils.bytesize(gist).to_s,
        'Vary' => 'Accept-Encoding'
      }

      if @options[:http_cache_time]
        headers['Cache-Control'] = "public, must-revalidate, max-age=#{@options[:http_cache_time]}"
      end

      [200, headers, [gist]]
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
      @regex ||= %r{gist\.github\.com/(\d+)(?:/(.*))?\.js}
    end

    def css_html
      "<link rel='stylesheet' href='https://gist.github.com/stylesheets/gist/embed.css' />\n"
    end

    def jquery_link
      "<script type='text/javascript' src='http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js'></script>\n"
    end

    def jquery_helper
      <<-EOJQ
        <script type='text/javascript'>
          //<![CDATA[
          $(document).ready(function() {
            $('.rack-gist').each(function() {
              var url = '/gist.github.com/' + $(this).attr('gist-id');
              var file = false;
              if (file = $(this).attr('rack-gist-file')) {
                url += '/' + file;
              }
              $.ajax({
                url: url + '.js',
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