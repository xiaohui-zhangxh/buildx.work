# frozen_string_literal: true

# SimpleCov 配置
# 注意：已禁用并行测试以获取准确的覆盖率数据
# 参考：https://github.com/simplecov-ruby/simplecov/issues/1111
require "simplecov"

SimpleCov.start("rails") do
  # 支持通过环境变量 COVERAGE_FILES 指定只检查某些文件的覆盖率
  # 格式：COVERAGE_FILES=app/models/user.rb,app/controllers/sessions_controller.rb
  if ENV["COVERAGE_FILES"]
    coverage_files = ENV["COVERAGE_FILES"].split(",").map(&:strip)
    add_filter do |source_file|
      # 过滤掉不在指定列表中的文件
      !coverage_files.any? { |pattern| source_file.filename.include?(pattern) }
    end
  else
    # 默认只统计 app/ 目录下的代码，排除配置文件和初始化文件
    add_filter "/config/"
    add_filter "/db/"
    add_filter "/lib/tasks/"
    add_filter "/test/"
    add_filter "/vendor/"
    add_filter "/bin/"
    add_filter "/script/"
    add_filter "/app/channels/application_cable/connection.rb" # ActionCable 连接测试较复杂，暂时排除
  end

  minimum_coverage 85
end
