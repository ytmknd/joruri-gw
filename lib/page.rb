class Page
  STORAGE_KEYS = %i[
    site uri layout title current_item current_piece mobile ruby error
  ].freeze

  class << self
    STORAGE_KEYS.each do |key|
      define_method(key) { storage[key] }
      define_method("#{key}=") { |value| storage[key] = value }
    end
  end

  def self.initialize
    storage.clear
  end
  
  def self.mobile?
    return true if mobile
    return nil unless site
    Core.script_uri =~ /^#{site.mobile_full_uri}/ if !site.mobile_full_uri.blank?
  end
  
  def self.head_tag
    return nil if !layout || !layout.id
    tag = layout.head_tag(mobile?)
    tag
  end
  
  def self.body_id
    return nil unless uri
    id = uri.gsub(/^\/_.*?\/[0-9]+\//, '/')
    id += 'index.html' if /\/$/ =~ id
    id = id.slice(1, id.size)
    id = id.gsub(/\..*$/, '')
    id = id.gsub(/\.[0-9a-zA-Z]+$/, '')
    id = id.gsub(/[^0-9a-zA-Z_\.\/]/, '_')
    id = id.gsub(/(\.|\/)/, '-').camelize(:lower)
    return %Q(id="page-#{id}").html_safe
  end

  def self.body_class
    nil
  end
  
  def self.title
    return storage[:title] if storage[:title]
###    return Core.current_node.title if Core.current_node
###    return @@site.name
  end

  def self.window_title
    return title if title == site.name
    return title + ' | ' + site.name
  end

private
  def self.storage
    Thread.current[:joruri_page_storage] ||= {}
  end
end
