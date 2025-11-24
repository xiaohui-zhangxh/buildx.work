ENV["RAILS_ENV"] ||= "test"

# Start SimpleCov before loading Rails environment
# SimpleCov must be required and started before any other code is loaded
require "simplecov"

SimpleCov.start "rails" do
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

require_relative "../config/environment"

# Eager load to ensure all code is loaded for coverage tracking
# This is especially important when using Spring or parallel tests
Rails.application.eager_load!

require "rails/test_help"
require "warden/test/helpers"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include Warden test helpers
    include Warden::Test::Helpers

    # Reset Warden after each test
    teardown do
      Warden.test_reset!
    end

    # Add more helper methods to be used by all tests here...
  end
end
