module OAttr
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def oattr *names
      container = if names.last.kind_of? Hash
                    "@#{(names.pop)[:container]}"
                  else
                    "@options"
                  end
      names.each do |name|
        class_eval "def #{name}; #{container}['#{name}'.to_sym]; end"
      end
    end
  end
end
