module Danger
  class DangerfileGenerator
    # returns the string for a Dangerfile based on a folder's contents'
    def self.create_dangerfile(_path, _ui)
      # Use this template for now, but this is a really ripe place to
      # improve now!
      dir = Danger.gem_path
      File.read(File.join(dir, "lib", "assets", "DangerfileTemplate"))
    end
  end
end
