class Hash
  # Alias for 1.8.7
  alias_method :key, :index unless method_defined?(:key)
end