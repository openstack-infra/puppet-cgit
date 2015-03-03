module Puppet::Parser::Functions
  newfunction(:resolve_option_list) do |args|
    defaults = args[0]
    override = args[1]
    final = {}
    defaults.each do |setting, value|
      if override.has_key?(setting)
        final[setting] = override[setting]
      else
        final[setting] = value
      end
    end
    return final
  end
end
