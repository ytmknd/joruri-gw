class Core
  STORAGE_KEYS = %i[
    now title map_key env params script_uri request_uri internal_uri
    ldap imap user user_group dispatched messages
  ].freeze

  class << self
    STORAGE_KEYS.each do |key|
      define_method(key) { storage[key] }
      define_method("#{key}=") { |value| storage[key] = value }
    end
  end

  ## Initializes.
  def self.initialize(env = {})
    terminate
    storage.clear

    core_config   = config
    self.now      = Time.now.to_fs(:db)
    self.title    = core_config['title'] || 'Joruri'
    self.map_key  = core_config['map_key']
    self.env      = env
    self.params   = parse_query_string(env)
###    @@mode         = nil
###    @@site         = nil
    self.script_uri   = env['SCRIPT_URI'] || "http://#{env['HTTP_HOST']}#{env['PATH_INFO']}"
    self.request_uri  = nil
    self.internal_uri = nil
###    @@current_node = nil
    self.ldap         = nil
    self.imap         = nil
    self.user         = nil
    self.user_group   = nil
    self.dispatched   = nil
###    @@concept      = nil
    self.messages     = []

    #require 'page'
    Page.initialize
  end

  def self.config
    @config ||= Util::Config.load(:core)
  end

  ## Now.
  def self.now
    storage[:now] ||= Time.now.to_fs(:db)
  end

  ## Absolute path.
  def self.uri
    config['uri'].sub(/^[a-z]+:\/\/[^\/]+\//, '/')
  end

  ## Full URI.
  def self.full_uri
    config['uri']
  end

  ## Proxy.
  def self.proxy
    config['proxy']
  end

  def self.proxy_uri
    URI(config['proxy']) rescue nil
  end

  ## Parses query string.
  def self.parse_query_string(env)
    # CGI.parse removed in Ruby 4.0; use URI.decode_www_form instead
    qs = env['QUERY_STRING']
    return nil unless qs&.present?
    URI.decode_www_form(qs).each_with_object({}) { |(k, v), h| (h[k] ||= []) << v }
  end

###  ## Sets the mode.
###  def self.set_mode(mode)
###    old = @@mode
###    @@mode = mode
###    return old
###  end

  ## LDAP.
  def self.ldap
    storage[:ldap] ||= Sys::Lib::Ldap.new
  end

  ## IMAP.
  def self.imap
    storage[:imap] ||= Sys::Lib::Net::Imap.connect
  end

  ## Controller was dispatched?
  def self.dispatched?
    storage[:dispatched]
  end

  ## Controller was dispatched.
  def self.dispatched
    self.dispatched = true
  end

  ## Recognizes the path for dispatch.
  def self.recognize_path(path)
###    Page.error    = false
    Page.uri      = path
###    @@request_uri = path
    self.request_uri = self.internal_uri = path

###    self.recognize_mode
###    self.recognize_site if @mode != 'script'
###
###    @@internal_uri = '/404.html' unless @@internal_uri
  end

###  def self.search_node(path)
###    return nil unless Page.site
###
###    if path =~ /\.html\.r$/
###      Page.ruby = true
###      path = path.gsub(/\.r$/, '')
###    end
####    if path =~ /\/index\.html$/
####      path = path.gsub(/index\.html$/, '')
####    end
###    if path =~ /\/$/
###      path += 'index.html'
###    end
###
###    node     = nil
###    rest     = ''
###    paths    = path.gsub(/\/+/, '/').split('/')
###    paths[0] = '/'
###
###    paths.size.times do |i|
###      if i == 0
###        current = Cms::Node.find(Page.site.node_id)
###      else
###        n = Cms::Node.new
###        n.and :site_id  , Page.site.id
###        n.and :parent_id, node.id
###        n.and :name     , paths[i]
###        n.public if @@mode != 'preview'
###        current = n.find(:first)
###      end
###      break unless current
###
###      node = current
###      rest = paths.slice(i + 1, paths.size).join('/')
###    end
###    return nil unless node
###
###    @@current_node = node
###    return "/_public/#{node.model.underscore.pluralize.gsub(/^(.*?\/)/, "\\1node_")}/#{rest}"
###  end

###  def self.concept(key = nil)
###    return nil unless @@concept
###    key.nil? ? @@concept : @@concept.send(key)
###  end

###  def self.set_concept(session, concept_id = nil)
###    if concept_id
###      @@concept = Cms::Concept.find_by(id: concept_id)
###      @@concept = Cms::Concept.new.readable_children[0] unless @@concept
###      session[:cms_concept] = (@@concept ? @@concept.id : nil)
###    else
###      concept_id = session[:cms_concept]
###      @@concept = Cms::Concept.find_by(id: concept_id)
###      @@concept = Cms::Concept.new.readable_children[0] unless @@concept
###    end
###  end

  def self.terminate
    if storage[:ldap]
      storage[:ldap].connection.unbind rescue nil
      storage[:ldap] = nil
    end
    if storage[:imap]
      storage[:imap].logout rescue nil
      storage[:imap].disconnect rescue nil
      storage[:imap] = nil
    end
  end

private
  def self.storage
    Thread.current[:joruri_core_storage] ||= {}
  end

###  def self.recognize_mode
###    if (@@request_uri =~ /^\/_[a-z]+(\/|$)/)
###      @@mode = @@request_uri.gsub(/^\/_([a-z]+).*/, '\1')
###    else
###      @@mode = 'public'
###    end
###  end

###  def self.recognize_site
###    case @@mode
###    when 'admin'
###      @@site         = self.get_site_by_cookie
###      Page.site      = @@site
###      @@internal_uri = @@request_uri
###      @@current_node = nil
###    when 'preview'
###      site_id        = @@request_uri.gsub(/^\/_[a-z]+\/([0-9]+)(.*)/, '\1').to_i
###      @@site         = Cms::Core.find(site_id)
###      Page.site      = @@site
###      @@internal_uri = search_node @@request_uri.gsub(/^\/_[a-z]+\/[0-9]*(.*)/, '\1')
###    when 'public'
###      @@site         = Cms::Core.find_by(script_uri: @@script_uri)
###      Page.site      = @@site
###      #if @@site.nil? && env['SCRIPT_URI'].index(Core.full_uri) == 0
###      #  @@site       = Cms::Core.find(:first, :order => :id)
###      #end
###      @@internal_uri = search_node @@request_uri
###    when 'files'
###      @@site         = Cms::Core.find_by(script_uri: @@script_uri)
###      Page.site      = @@site
###      @@internal_uri = @@request_uri
###    when 'script'
###      @@site         = nil
###      Page.site      = @@site
###      @@internal_uri = @@request_uri
###      @@current_node = nil
###    end
###  end

###  def self.get_site_by_cookie
###    site_id = self.get_cookie('cms_site')
###    return Cms::Core.find_by(id: site_id) if site_id
###    return Cms::Core.find(:first, :order => :id)
###  end

###  def self.get_cookie(name)
###    cookies = CGI::Cookie.parse(Core.env['HTTP_COOKIE'])
###    return cookies[name].value.first if cookies.has_key?(name)
###    return nil
###  end
end
