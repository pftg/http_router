class TestMisc < MiniTest::Unit::TestCase
  def test_cloning
    r1 = HttpRouter.new { add('/test').name(:test_route).to(:test) }
    r2 = r1.clone

    r2.add('/test2').name(:test).to(:test2)
    assert_equal 2, r2.routes.size

    assert_equal nil, r1.recognize(Rack::Request.new(Rack::MockRequest.env_for('/test2')))
    assert r2.recognize(Rack::MockRequest.env_for('/test2'))
    assert_equal r1.routes.first, r1.named_routes[:test_route].first
    assert_equal r2.routes.first, r2.named_routes[:test_route].first

    r1.add('/another').name(:test).to(:test2)

    assert_equal r1.routes.size, r2.routes.size
    assert_equal '/another', r1.url(:test)
    assert_equal '/test2',   r2.url(:test)
    assert_equal :test, r1.routes.first.dest
    assert_equal :test, r2.routes.first.dest
  end

  def test_reseting
    r = HttpRouter.new { add('/hi').to(:test) }
    assert r.recognize(Rack::MockRequest.env_for('/hi'))
    r.reset!
    assert !r.recognize(Rack::MockRequest.env_for('/hi'))
  end

  def test_redirect_trailing_slash
    r = HttpRouter.new(:redirect_trailing_slash => true) { add('/hi').to(:test) }
    response = r.recognize(Rack::MockRequest.env_for('/hi/'))
    assert 304, response[0]
    assert "/hi", response[1]["Location"]
  end

  def test_multi_name_gen
    r = HttpRouter.new
    r.add('/').name(:index).default_destination
    r.add('/:name').name(:index).default_destination
    r.add('/:name/:category').name(:index).default_destination
    assert_equal '/', r.url(:index)
    assert_equal '/name', r.url(:index, 'name')
    assert_equal '/name/category', r.url(:index, 'name', 'category')
  end

  def test_regex_generation
    r = HttpRouter.new
    r.add(%r|/test/.*|, :path_for_generation => '/test/:variable').name(:route).default_destination
    assert_equal '/test/var', r.url(:route, "var")
  end

  def test_regex_generation
    r = HttpRouter.new
    r.add(%r|/test/.*|, :path_for_generation => '/test/:variable').name(:route).default_destination
    assert_equal '/test/var', r.url(:route, "var")
    assert_equal '/test/var', r.url(:route, :variable => "var")
    assert_raises(HttpRouter::InvalidRouteException) { r.url(:route) }
  end

  def test_public_interface
    methods = HttpRouter.public_instance_methods.map(&:to_sym)
    assert methods.include?(:url_mount)
    assert methods.include?(:url_mount=)
    assert methods.include?(:call)
    assert methods.include?(:recognize)
    assert methods.include?(:url)
    assert methods.include?(:pass_on_response)
    assert methods.include?(:ignore_trailing_slash?)
    assert methods.include?(:redirect_trailing_slash?)
    assert methods.include?(:process_destination_path)
    assert methods.include?(:rewrite_partial_path_info)
    assert methods.include?(:rewrite_path_info)
  end
end
