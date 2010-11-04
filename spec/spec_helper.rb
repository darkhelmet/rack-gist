$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rack/gist'

require 'rack/mock'
require 'rack/lint'

require 'active_support/core_ext/benchmark'
require 'active_support/core_ext/array'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/cache'
require 'active_support/cache/memory_store'

require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  config.include(Spec::Matchers)
end

require 'fakeweb'

# Disallow web access
FakeWeb.allow_net_connect = false
FakeWeb.register_uri(:get, 'https://gist.github.com/348301.js', :body => File.read(File.join(File.dirname(__FILE__), 'full-gist.js')), :content_type => 'text/javascript; charset=utf-8')
FakeWeb.register_uri(:get, 'https://gist.github.com/348301.js?file=example.pig', :body => File.read(File.join(File.dirname(__FILE__), 'partial-gist.js')), :content_type => 'text/javascript; charset=utf-8')

Spec::Matchers.define :have_html_tag do |tag|
  chain :count do |count|
    @count = count
  end

  chain :with do |contents|
    @contents = contents
  end

  chain :containing do |inner|
    @inner = inner
  end

  match do |doc|
    @count ||= 1
    @contents ||= {}
    @inner ||= //
    doc = Nokogiri(doc)
    doc.search(tag).tap do |results|
      results.size.should == @count
      results.each do |node|
        node.inner_html.match(@inner).should_not be_nil
        @contents.each_pair do |attribute, expected|
          node[attribute].should == expected.to_s
        end
      end
    end
  end

  failure_message_for_should do |doc|
    msg = "expected #{doc} to have HTML tag #{tag}"
    if @count > 1
      msg << " #{@count} times"
    end

    extra = []

    @contents.each_pair do |attribute, value|
      extra << "#{attribute} = #{value}"
    end

    msg << ' ' << extra.join(', ')
    msg
  end
end