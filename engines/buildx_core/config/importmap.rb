# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from File.expand_path("../app/javascript/controllers", __dir__), under: "controllers"

pin "highlight.js/lib/core", to: "highlight.js/lib/core.js"
pin "highlight.js/lib/languages/ruby", to: "highlight.js/lib/languages/ruby.js"
pin "highlight.js/lib/languages/javascript", to: "highlight.js/lib/languages/javascript.js"
pin "highlight.js/lib/languages/bash", to: "highlight.js/lib/languages/bash.js"
pin "highlight.js/lib/languages/yaml", to: "highlight.js/lib/languages/yaml.js"
pin "highlight.js/lib/languages/json", to: "highlight.js/lib/languages/json.js"
pin "highlight.js/lib/languages/xml", to: "highlight.js/lib/languages/xml.js"
pin "highlight.js/lib/languages/css", to: "highlight.js/lib/languages/css.js"
pin "highlight.js/lib/languages/sql", to: "highlight.js/lib/languages/sql.js"
