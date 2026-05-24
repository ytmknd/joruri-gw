class Util::Tree
  def self.climb(id, options = {})
    loop_count = 0
    tree = []
    while current = options[:class].find(id)
      tree.unshift(current)
      id = current.parent_id
      loop_count += 1
      raise 'infinite loop' if loop_count > 100
    end
    return tree
  rescue ActiveRecord::RecordNotFound
    return tree
  end
  
  def self.down(id, options = {})
    
  end
end
