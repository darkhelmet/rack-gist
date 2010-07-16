require 'hpricot'
require 'rest-client'

module Rack
  class Gist
    def initialize(app, options = {})
      @app = app
      @gist_path =
      @options = {
        :jquery => true
      }.merge(options)
    end

    def call(env)
      if path(env).match(%r{^/gist\.github\.com})
        serve_gist(env)
      else
        status, headers, body = @app.call(env)
        rewrite(status, headers, body)
      end
    end

  private

    def rewrite(status, headers, body)
      body = [body].flatten
      if 'text/html' == headers['Content-Type'] && body.respond_to?(:map!)
        body.map! do |part|
          Hpricot(part.to_s).tap do |doc|
            extras = false
            doc.search('script[@src*="gist.github.com"]').each do |tag|
              extras = true
              tag['src'].match(regex).tap do |match|
                id, file = match[1, 2]
                suffix, extra = file ? ["#file_#{file}", "rack-gist-file='#{file}'"] : ['', '']
                tag.swap("<div class='rack-gist' id='rack-gist-#{id}' gist-id='#{id}' #{extra}>Can't see this Gist? <a rel='nofollow' href='http://gist.github.com/#{id}#{suffix}'>View it on Github!</a></div>")
              end
            end
            doc.search('head').tap do |head|
              head.append(css_html)
              head.append(jquery_link) if @options[:jquery]
              head.append(jquery_helper)
            end if extras
          end.to_s
        end
        headers['Content-Length'] = body.map { |part| Rack::Utils.bytesize(part) }.inject(0) { |sum, size| sum + size }.to_s
      end
      [status, headers, body]
    end

    def serve_gist(env)
      gist_id, file = path(env).match(%r{gist\.github\.com/(\d+)(?:/(.*))?})[1,2]
      cache = @options[:cache]
      gist = (cache ? cache.fetch(cache_key(gist_id, file), :expires_in => 3600) { get_gist(gist_id, file) } : get_gist(gist_id, file)).to_s
      [
        200,
        {
          'Content-Type' => 'text/html',
          'Content-Length' => Rack::Utils.bytesize(gist).to_s
        },
        [gist]
      ]
    end

    def get_gist(gist_id, file)
      gist = RestClient.get(gist_url(gist_id, file))
      gist = gist.split("\n").reject do |part|
        part.empty?
      end.last
      gist[%r{document\.write\('(.*)'\)}, 1].gsub(/\\(["'\/])/, '\1').gsub('\n', "\n").gsub('\\\\', '\\')
    end

    def cache_key(gist_id, file)
      key = "rack-gist:#{gist_id}"
      key << ":#{file.gsub(/\s/, '')}" unless file.nil?
      key
    end

    def gist_url(gist_id, file)
      url = "http://gist.github.com/#{gist_id}.js"
      url << "?file=#{file}" unless file.nil?
      url
    end

    def path(env)
      Rack::Utils.unescape(env['PATH_INFO'])
    end

    def regex
      @regex ||= %r{gist\.github\.com/(\d+)\.js(?:\?file=(.*))?}
    end

    def css_html
      "<link rel='stylesheet' href='http://gist.github.com/stylesheets/gist/embed.css' />\n"
    end

    def jquery_link
      "<script type='text/javascript' src='http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js'></script>\n"
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
              $.get(url, function(data) {
                $(this).replaceWith(data);
              });
            });
          });
          //]]>
        </script>
      EOJQ
    end
  end
end