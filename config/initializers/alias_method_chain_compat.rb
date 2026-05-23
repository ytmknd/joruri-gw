# alias_method_chain was removed in Rails 5.2.
# render_component_vho 3.2.1 still uses it — restore the method for compatibility
# until render_component_vho is replaced or patched (Phase 4).
unless Module.method_defined?(:alias_method_chain)
  module ModuleAliasMethodChainCompat
    def alias_method_chain(target, feature)
      alias_method :"#{target}_without_#{feature}", target
      alias_method target, :"#{target}_with_#{feature}"
    end
  end
  Module.prepend ModuleAliasMethodChainCompat
end
