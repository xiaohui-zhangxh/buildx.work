ENV["RAILS_ENV"] ||= "test"

# Suppress Tailwind CSS compilation output in tests
ENV["TAILWINDCSS_QUIET"] = "1" unless ENV["TAILWINDCSS_QUIET"]

# Start SimpleCov before loading Rails environment
# SimpleCov must be required and started before any other code is loaded
# 必须在加载任何应用代码之前启动 SimpleCov
# 这是 SimpleCov 能够正确跟踪代码覆盖率的必要条件
# 注意：已禁用并行测试以获取准确的覆盖率数据
# 参考：https://github.com/simplecov-ruby/simplecov/issues/1111
require_relative "supports/simplecov"

require_relative "../config/environment"

# Eager load to ensure all code is loaded for coverage tracking
# This is especially important when using Spring or parallel tests
Rails.application.eager_load!

require "rails/test_help"
require "warden/test/helpers"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # 已禁用并行测试以获取准确的覆盖率数据
    # 并行测试会导致 SimpleCov 覆盖率统计不准确
    # 参考：https://github.com/simplecov-ruby/simplecov/issues/1111
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include Warden test helpers
    include Warden::Test::Helpers

    # Setup: Ensure system is installed by default (unless test explicitly needs uninstalled state)
    setup do
      # Set installation_completed to "1" by default for all tests
      # Tests that need uninstalled state should explicitly set it to "0"
      SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system") unless SystemConfig.get("installation_completed") == "1"
    end

    # Reset Warden after each test
    teardown do
      Warden.test_reset!
    end

    # Add more helper methods to be used by all tests here...
  end
end
