# Pin npm packages by running ./bin/importmap

# 通用组件已经在 buildx_core 中加载，无需在此单独引入，见 engines/buildx_core/config/importmap.rb

pin_all_from "app/javascript/controllers", under: "controllers"
