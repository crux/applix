module OAttr
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def oattr *names
      container = "@options"
      if names.last.kind_of? Hash
        container = "@#{(names.pop)[:container]}"
      end
      names.each do |name|
        class_eval "def #{name}; #{container}['#{name}'.to_sym]; end"
      end
    end
  end
end
