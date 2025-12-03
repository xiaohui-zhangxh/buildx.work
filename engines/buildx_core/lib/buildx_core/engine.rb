module BuildxCore
  class Engine < ::Rails::Engine
    initializer "buildx_core.importmap", before: "importmap" do |app|
      app.config.importmap.paths << Engine.root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << Engine.root.join("app/javascript")
      app.config.assets.paths << Engine.root.join("app/javascript")
      app.config.assets.paths << Engine.root.join("vendor/javascript")
      app.config.assets.paths << Engine.root.join("vendor/assets/stylesheets")
    end
  end
end
