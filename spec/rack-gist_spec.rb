require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Rack::Gist" do
  before(:all) do
    @gist_id = 348301
    @app = lambda do |env|
      headers = { 'Content-Type' => 'text/html' }
      body =  File.read(File.join(File.dirname(__FILE__), "body-#{env['PATH_INFO'].gsub(/[^\w]/, '')}.html"))
      [200, headers, body]
    end
  end

  def mock_env(path = '/full')
    Rack::MockRequest.env_for(path)
  end

  def middleware(options = {})
    Rack::Gist.new(@app, options)
  end

  it 'should pass Rack::Lint' do
    status, headers, body = Rack::Lint.new(middleware).call(mock_env)
  end

  it 'should rewrite gist embed tags for full gists' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env)
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      body.to_s.should have_html_tag('div').with('id' => "rack-gist-#{@gist_id}", 'class' => 'rack-gist')
    end
  end

  it 'should rewrite gist embed tags for partial gists' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env('/partial'))
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      body.to_s.should have_html_tag('div').with('id' => "rack-gist-#{@gist_id}", 'class' => 'rack-gist', 'rack-gist-file' => 'example.pig')
    end
  end

  it 'should not include the github css file if no gists are present' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env('/none'))
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      body.to_s.should_not have_html_tag('link').with('rel' => 'stylesheet', 'href' => 'http://gist.github.com/stylesheets/gist/embed.css')
    end
  end

  it 'should include the github css file once' do
    middleware.tap do |a|
      status, headers, body = a.call(mock_env('/multiple'))
      status.should == 200
      headers['Content-Type'].should == 'text/html'
      body.to_s.should have_html_tag('link').with('rel' => 'stylesheet', 'href' => 'http://gist.github.com/stylesheets/gist/embed.css')
    end
  end

  it 'should include required jquery helper'
  it 'should proxy/serve single gists'
  it 'should proxy/server multiple gists'
  it 'should cache gist content' # Later
end
