require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Rack::Gist" do
  before(:all) do
    @gist_id = 348301
  end

  def pbody(body)
    ''.tap do |b|
      body.each { |part| b << part.to_s } # For giggles
    end
  end

  def app(headers)
    lambda do |env|
      body = File.read(File.join(File.dirname(__FILE__), "body-#{env['PATH_INFO'].gsub(/[^\w]/, '')}.html")) rescue ''
      status = 404 if body.empty?
      [status || 200, headers, [body]]
    end
  end

  def mock_env(path = '/full')
    Rack::MockRequest.env_for(path)
  end

  def middleware(options = {}, headers = { 'Content-Type' => 'text/html' })
    Rack::Gist.new(app(headers), options)
  end

  it 'should pass Rack::Lint' do
    status, headers, body = Rack::Lint.new(middleware).call(mock_env)
    status, headers, body = Rack::Lint.new(middleware).call(mock_env('/multiple'))
    status, headers, body = Rack::Lint.new(middleware).call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
  end

  it 'should rewrite gist embed tags for full gists' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env)
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      pbody(body).should have_html_tag('p').with('id' => "rack-gist-#{@gist_id}", 'gist-id' => @gist_id, 'class' => 'rack-gist')
    end
  end

  it 'should rewrite gist embed tags for full gists when content_type includes other things' do
    middleware({}, { 'Content-Type' => 'text/html; charset=utf-8' }).tap do |a|
      status, headers, body = a.call(mock_env)
      status.should == 200
      headers['Content-Type'].should == 'text/html; charset=utf-8'
      pbody(body).should have_html_tag('p').with('id' => "rack-gist-#{@gist_id}", 'gist-id' => @gist_id, 'class' => 'rack-gist')
    end
  end

  it 'should rewrite gist embed tags for partial gists' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env('/partial'))
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      pbody(body).should have_html_tag('p').with('id' => "rack-gist-#{@gist_id}", 'gist-id' => @gist_id, 'class' => 'rack-gist', 'rack-gist-file' => 'example.pig')
    end
  end

  it 'should not include the github css file if no gists are present' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env('/none'))
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      pbody(body).should_not have_html_tag('link').with('rel' => 'stylesheet', 'href' => 'http://gist.github.com/stylesheets/gist/embed.css')
    end
  end

  it 'should include the github css file once' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env('/multiple'))
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      pbody(body).should have_html_tag('link').with('rel' => 'stylesheet', 'href' => 'http://gist.github.com/stylesheets/gist/embed.css')
    end
  end

  it 'should include jquery by default' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env)
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      pbody(body).should have_html_tag('script[@src*="jquery"]')
    end
  end

  it 'should not include jquery if the option is passed to disable it' do
    middleware(:jquery => false).tap do |a|
      status, headers, body = a.call(mock_env)
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      pbody(body).should_not have_html_tag('script[@src*="jquery"]')
    end
  end

  it 'should include required jquery helper' do
    middleware(:jquery => false).tap do |a|
      status, headers, body = a.call(mock_env)
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      pbody(body).should have_html_tag('script').containing('CDATA')
    end
  end

  it "shouldn't include the jquery helper if no gist is present" do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env)
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      pbody(body).should_not have_html_tag('script')
    end
  end

  it 'should update Content-Length' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env)
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      headers['Content-Length'].should == '1066'
    end
  end

  it 'should proxy/serve single gists' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
      status.should == 200
      headers['Content-Type'].should == 'application/javascript'
      pbody(body).should == %q{$('#rack-gist-%s[rack-gist-file="example.pig"]').replaceWith('<div id=\"gist-348301\" class=\"gist\">\n  \n  \n    \n            \n\n      <div class=\"gist-file\">\n        <div class=\"gist-data gist-syntax\">\n          \n          \n          \n            <div class=\"gist-highlight\"><pre><div class=\'line\' id=\'LC1\'>REGISTER com.darkhax.blog.pig.jar;<\/div><div class=\'line\' id=\'LC2\'>DEFINE Parser com.darkhax.blog.pig.LogParser();<\/div><div class=\'line\' id=\'LC3\'><br/><\/div><div class=\'line\' id=\'LC4\'>logs = LOAD \'apache.log.bz2\' USING TextLoader AS (line: chararray);<\/div><div class=\'line\' id=\'LC5\'>log_events = FOREACH logs GENERATE FLATTEN(Parser(line));<\/div><div class=\'line\' id=\'LC6\'><br/><\/div><div class=\'line\' id=\'LC7\'>by_action = GROUP log_events BY action;<\/div><div class=\'line\' id=\'LC8\'>counts = FOREACH by_action GENERATE group, COUNT(log_events);<\/div><div class=\'line\' id=\'LC9\'>STORE counts INTO \'count_summary\';<\/div><\/pre><\/div>\n        \n        <\/div>\n\n        <div class=\"gist-meta\">\n          <a href=\"http://gist.github.com/raw/348301/07d20a92ce5e56bde493066a0154f200da37c953/example.pig\" style=\"float:right;\">view raw<\/a>\n          <a href=\"http://gist.github.com/348301#file_example.pig\" style=\"float:right;margin-right:10px;color:#666\">example.pig<\/a>\n          <a href=\"http://gist.github.com/348301\">This Gist<\/a> brought to you by <a href=\"http://github.com\">GitHub<\/a>.\n        <\/div>\n      <\/div>\n    \n            \n  \n<\/div>\n')} % @gist_id
    end
  end

  it 'should proxy/server multiple gists' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env("/gist.github.com/#{@gist_id}.js"))
      status.should == 200
      headers['Content-Type'].should == 'application/javascript'
      pbody(body).should == %q{$('#rack-gist-%s').replaceWith('<div id=\"gist-348301\" class=\"gist\">\n  \n  \n    \n            \n\n      <div class=\"gist-file\">\n        <div class=\"gist-data gist-syntax\">\n          \n          \n          \n            <div class=\"gist-highlight\"><pre><div class=\'line\' id=\'LC1\'>REGISTER com.darkhax.blog.pig.jar;<\/div><div class=\'line\' id=\'LC2\'>DEFINE Parser com.darkhax.blog.pig.LogParser();<\/div><div class=\'line\' id=\'LC3\'><br/><\/div><div class=\'line\' id=\'LC4\'>logs = LOAD \'apache.log.bz2\' USING TextLoader AS (line: chararray);<\/div><div class=\'line\' id=\'LC5\'>log_events = FOREACH logs GENERATE FLATTEN(Parser(line));<\/div><div class=\'line\' id=\'LC6\'><br/><\/div><div class=\'line\' id=\'LC7\'>by_action = GROUP log_events BY action;<\/div><div class=\'line\' id=\'LC8\'>counts = FOREACH by_action GENERATE group, COUNT(log_events);<\/div><div class=\'line\' id=\'LC9\'>STORE counts INTO \'count_summary\';<\/div><\/pre><\/div>\n        \n        <\/div>\n\n        <div class=\"gist-meta\">\n          <a href=\"http://gist.github.com/raw/348301/07d20a92ce5e56bde493066a0154f200da37c953/example.pig\" style=\"float:right;\">view raw<\/a>\n          <a href=\"http://gist.github.com/348301#file_example.pig\" style=\"float:right;margin-right:10px;color:#666\">example.pig<\/a>\n          <a href=\"http://gist.github.com/348301\">This Gist<\/a> brought to you by <a href=\"http://github.com\">GitHub<\/a>.\n        <\/div>\n      <\/div>\n    \n            \n\n      <div class=\"gist-file\">\n        <div class=\"gist-data gist-syntax\">\n          \n          \n          \n            <div class=\"gist-highlight\"><pre><div class=\'line\' id=\'LC1\'><span class=\"kn\">package<\/span> <span class=\"n\">com<\/span><span class=\"o\">.<\/span><span class=\"na\">codebaby<\/span><span class=\"o\">.<\/span><span class=\"na\">monitor<\/span><span class=\"o\">.<\/span><span class=\"na\">pig<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC2\'><br/><\/div><div class=\'line\' id=\'LC3\'><span class=\"kn\">import<\/span> <span class=\"nn\">java.io.IOException<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC4\'><br/><\/div><div class=\'line\' id=\'LC5\'><span class=\"kn\">import<\/span> <span class=\"nn\">org.apache.pig.EvalFunc<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC6\'><span class=\"kn\">import<\/span> <span class=\"nn\">org.apache.pig.data.DataType<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC7\'><span class=\"kn\">import<\/span> <span class=\"nn\">org.apache.pig.data.Tuple<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC8\'><span class=\"kn\">import<\/span> <span class=\"nn\">org.apache.pig.data.TupleFactory<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC9\'><span class=\"kn\">import<\/span> <span class=\"nn\">org.apache.pig.impl.logicalLayer.schema.Schema<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC10\'><br/><\/div><div class=\'line\' id=\'LC11\'><span class=\"c1\">// Inherit from EvalFunc&lt;Tuple&gt; to implement a EvalFunc that returns a Tuple<\/span><\/div><div class=\'line\' id=\'LC12\'><span class=\"kd\">public<\/span> <span class=\"kd\">class<\/span> <span class=\"nc\">LogParser<\/span> <span class=\"kd\">extends<\/span> <span class=\"n\">EvalFunc<\/span><span class=\"o\">&lt;<\/span><span class=\"n\">Tuple<\/span><span class=\"o\">&gt;<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC13\'><br/><\/div><div class=\'line\' id=\'LC14\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// The main method in question. Gets run for every &#39;thing&#39; that gets sent to<\/span><\/div><div class=\'line\' id=\'LC15\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// this UDF<\/span><\/div><div class=\'line\' id=\'LC16\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"kd\">public<\/span> <span class=\"n\">Tuple<\/span> <span class=\"nf\">exec<\/span><span class=\"o\">(<\/span><span class=\"n\">Tuple<\/span> <span class=\"n\">input<\/span><span class=\"o\">)<\/span> <span class=\"kd\">throws<\/span> <span class=\"n\">IOException<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC17\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">if<\/span> <span class=\"o\">(<\/span><span class=\"kc\">null<\/span> <span class=\"o\">==<\/span> <span class=\"n\">input<\/span> <span class=\"o\">||<\/span> <span class=\"n\">input<\/span><span class=\"o\">.<\/span><span class=\"na\">size<\/span><span class=\"o\">()<\/span> <span class=\"o\">!=<\/span> <span class=\"mi\">1<\/span><span class=\"o\">)<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC18\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">return<\/span> <span class=\"kc\">null<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC19\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC20\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<\/div><div class=\'line\' id=\'LC21\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">String<\/span> <span class=\"n\">line<\/span> <span class=\"o\">=<\/span> <span class=\"o\">(<\/span><span class=\"n\">String<\/span><span class=\"o\">)<\/span> <span class=\"n\">input<\/span><span class=\"o\">.<\/span><span class=\"na\">get<\/span><span class=\"o\">(<\/span><span class=\"mi\">0<\/span><span class=\"o\">);<\/span><\/div><div class=\'line\' id=\'LC22\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">try<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC23\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// In Soviet Russia, factory builds you!<\/span><\/div><div class=\'line\' id=\'LC24\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">TupleFactory<\/span> <span class=\"n\">tf<\/span> <span class=\"o\">=<\/span> <span class=\"n\">TupleFactory<\/span><span class=\"o\">.<\/span><span class=\"na\">getInstance<\/span><span class=\"o\">();<\/span><\/div><div class=\'line\' id=\'LC25\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">Tuple<\/span> <span class=\"n\">t<\/span> <span class=\"o\">=<\/span> <span class=\"n\">tf<\/span><span class=\"o\">.<\/span><span class=\"na\">newTuple<\/span><span class=\"o\">();<\/span><\/div><div class=\'line\' id=\'LC26\'><br/><\/div><div class=\'line\' id=\'LC27\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">t<\/span><span class=\"o\">.<\/span><span class=\"na\">append<\/span><span class=\"o\">(<\/span><span class=\"n\">getHttpMethod<\/span><span class=\"o\">());<\/span><\/div><div class=\'line\' id=\'LC28\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">t<\/span><span class=\"o\">.<\/span><span class=\"na\">append<\/span><span class=\"o\">(<\/span><span class=\"n\">getIP<\/span><span class=\"o\">());<\/span><\/div><div class=\'line\' id=\'LC29\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">t<\/span><span class=\"o\">.<\/span><span class=\"na\">append<\/span><span class=\"o\">(<\/span><span class=\"n\">getDate<\/span><span class=\"o\">());<\/span><\/div><div class=\'line\' id=\'LC30\'><br/><\/div><div class=\'line\' id=\'LC31\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// The tuple we are returning now has 3 elements, all strings.<\/span><\/div><div class=\'line\' id=\'LC32\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// In order, they are the HTTP method, the IP address, and the date.<\/span><\/div><div class=\'line\' id=\'LC33\'><br/><\/div><div class=\'line\' id=\'LC34\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">return<\/span> <span class=\"n\">t<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC35\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span> <span class=\"k\">catch<\/span> <span class=\"o\">(<\/span><span class=\"n\">Exception<\/span> <span class=\"n\">e<\/span><span class=\"o\">)<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC36\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// Any problems? Just return null and this one doesn&#39;t get<\/span><\/div><div class=\'line\' id=\'LC37\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// &#39;generated&#39; by pig<\/span><\/div><div class=\'line\' id=\'LC38\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">return<\/span> <span class=\"kc\">null<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC39\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC40\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC41\'><br/><\/div><div class=\'line\' id=\'LC42\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"kd\">public<\/span> <span class=\"n\">Schema<\/span> <span class=\"nf\">outputSchema<\/span><span class=\"o\">(<\/span><span class=\"n\">Schema<\/span> <span class=\"n\">input<\/span><span class=\"o\">)<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC43\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">try<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC44\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">Schema<\/span> <span class=\"n\">s<\/span> <span class=\"o\">=<\/span> <span class=\"k\">new<\/span> <span class=\"n\">Schema<\/span><span class=\"o\">();<\/span><\/div><div class=\'line\' id=\'LC45\'><br/><\/div><div class=\'line\' id=\'LC46\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">s<\/span><span class=\"o\">.<\/span><span class=\"na\">add<\/span><span class=\"o\">(<\/span><span class=\"k\">new<\/span> <span class=\"n\">Schema<\/span><span class=\"o\">.<\/span><span class=\"na\">FieldSchema<\/span><span class=\"o\">(<\/span><span class=\"s\">\"action\"<\/span><span class=\"o\">,<\/span> <span class=\"n\">DataType<\/span><span class=\"o\">.<\/span><span class=\"na\">CHARARRAY<\/span><span class=\"o\">));<\/span><\/div><div class=\'line\' id=\'LC47\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">s<\/span><span class=\"o\">.<\/span><span class=\"na\">add<\/span><span class=\"o\">(<\/span><span class=\"k\">new<\/span> <span class=\"n\">Schema<\/span><span class=\"o\">.<\/span><span class=\"na\">FieldSchema<\/span><span class=\"o\">(<\/span><span class=\"s\">\"ip\"<\/span><span class=\"o\">,<\/span> <span class=\"n\">DataType<\/span><span class=\"o\">.<\/span><span class=\"na\">CHARARRAY<\/span><span class=\"o\">));<\/span><\/div><div class=\'line\' id=\'LC48\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"n\">s<\/span><span class=\"o\">.<\/span><span class=\"na\">add<\/span><span class=\"o\">(<\/span><span class=\"k\">new<\/span> <span class=\"n\">Schema<\/span><span class=\"o\">.<\/span><span class=\"na\">FieldSchema<\/span><span class=\"o\">(<\/span><span class=\"s\">\"date\"<\/span><span class=\"o\">,<\/span> <span class=\"n\">DataType<\/span><span class=\"o\">.<\/span><span class=\"na\">CHARARRAY<\/span><span class=\"o\">));<\/span><\/div><div class=\'line\' id=\'LC49\'><br/><\/div><div class=\'line\' id=\'LC50\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">return<\/span> <span class=\"n\">s<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC51\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span> <span class=\"k\">catch<\/span> <span class=\"o\">(<\/span><span class=\"n\">Exception<\/span> <span class=\"n\">e<\/span><span class=\"o\">)<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC52\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// Any problems? Just return null...there probably won&#39;t be any<\/span><\/div><div class=\'line\' id=\'LC53\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"c1\">// problems though.<\/span><\/div><div class=\'line\' id=\'LC54\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">return<\/span> <span class=\"kc\">null<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC55\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC56\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC57\'><br/><\/div><div class=\'line\' id=\'LC58\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"kd\">public<\/span> <span class=\"n\">String<\/span> <span class=\"nf\">getHttpMethod<\/span><span class=\"o\">()<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC59\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">return<\/span> <span class=\"s\">\"\"<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC60\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC61\'><br/><\/div><div class=\'line\' id=\'LC62\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"kd\">public<\/span> <span class=\"n\">String<\/span> <span class=\"nf\">getIP<\/span><span class=\"o\">()<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC63\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">return<\/span> <span class=\"s\">\"\"<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC64\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC65\'><br/><\/div><div class=\'line\' id=\'LC66\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"kd\">public<\/span> <span class=\"n\">String<\/span> <span class=\"nf\">getDate<\/span><span class=\"o\">()<\/span> <span class=\"o\">{<\/span><\/div><div class=\'line\' id=\'LC67\'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"k\">return<\/span> <span class=\"s\">\"\"<\/span><span class=\"o\">;<\/span><\/div><div class=\'line\' id=\'LC68\'>&nbsp;&nbsp;&nbsp;&nbsp;<span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC69\'><span class=\"o\">}<\/span><\/div><div class=\'line\' id=\'LC70\'><br/><\/div><\/pre><\/div>\n          \n        <\/div>\n\n        <div class=\"gist-meta\">\n          <a href=\"http://gist.github.com/raw/348301/f249e58fe0fc9897e8d575764ecabf153d2da683/LogParser.java\" style=\"float:right;\">view raw<\/a>\n          <a href=\"http://gist.github.com/348301#file_log_parser.java\" style=\"float:right;margin-right:10px;color:#666\">LogParser.java<\/a>\n          <a href=\"http://gist.github.com/348301\">This Gist<\/a> brought to you by <a href=\"http://github.com\">GitHub<\/a>.\n        <\/div>\n      <\/div>\n    \n  \n<\/div>\n')} % @gist_id
    end
  end

  it 'should cache things if given a cache' do
    cache = ActiveSupport::Cache::MemoryStore.new
    middleware(:cache => cache).tap do |a|
      status, headers, body = a.call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
      status.should == 200
      headers['Content-Type'].should == 'application/javascript'

      RestClient.should_not_receive(:get)
      cache.should_receive(:fetch).once.with("rack-gist:#{@gist_id}:example.pig", :expires_in => 3600).and_return(pbody(body)) # 1.hour

      status, headers, body2 = a.call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
      status.should == 200
      headers['Content-Type'].should == 'application/javascript'
      pbody(body).should == pbody(body2)
    end
  end

  it 'should cache things for a different time if given cache_time' do
    cache = ActiveSupport::Cache::MemoryStore.new
    middleware(:cache => cache, :cache_time => 60).tap do |a|
      status, headers, body = a.call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
      status.should == 200
      headers['Content-Type'].should == 'application/javascript'

      RestClient.should_not_receive(:get)
      cache.should_receive(:fetch).once.with("rack-gist:#{@gist_id}:example.pig", :expires_in => 60).and_return(pbody(body)) # 1.hour

      status, headers, body2 = a.call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
      status.should == 200
      headers['Content-Type'].should == 'application/javascript'
      pbody(body).should == pbody(body2)
    end
  end

  it 'should not explode if not given a gist' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env('/gist.github.com'))
      status.should == 404
    end
  end

  it 'should set http caching headers by default' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
      headers['Vary'].should == 'Accept-Encoding'
      headers['Cache-Control'].should == 'public, must-revalidate, max-age=3600' # 1.hour
    end
  end

  it 'should be able to configure cache time' do
    middleware(:http_cache_time => 60).tap do |a|
      status, headers, body = a.call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
      headers['Vary'].should == 'Accept-Encoding'
      headers['Cache-Control'].should == 'public, must-revalidate, max-age=60' # 1.hour
    end
  end

  it 'should be able to disable caching by setting http_cache_time to nil' do
    middleware(:http_cache_time => nil).tap do |a|
      status, headers, body = a.call(mock_env("/gist.github.com/#{@gist_id}/example.pig.js"))
      headers['Vary'].should == 'Accept-Encoding'
      headers['Cache-Control'].should be_nil
    end
  end

  it 'should encode to the correct content type' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env)
      pbody(body).should match('utf-8')
    end

    middleware(:encoding => 'US-ASCII').tap do |a|
      status, headers, body = a.call(mock_env)
      pbody(body).should match('US-ASCII')
    end
  end
end