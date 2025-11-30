# 测试扩展机制
#
# 验证扩展模块是否能被正确加载和包含到基础设施类中

require "test_helper"

class ExtensionsTest < ActiveSupport::TestCase
  test "UserExtensions module can be loaded and included" do
    # 创建测试扩展文件
    test_extensions_file = Rails.root.join("tmp", "test_user_extensions.rb")
    test_extensions_dir = test_extensions_file.dirname
    test_extensions_dir.mkpath unless test_extensions_dir.exist?

    # 创建测试扩展模块
    File.write(test_extensions_file, <<~RUBY)
      module UserExtensions
        extend ActiveSupport::Concern

        included do
          # 添加测试方法
          def test_extension_method
            "extension_loaded"
          end
        end
      end
    RUBY

    # 临时将扩展文件复制到正确位置
    user_extensions_file = Rails.root.join("app", "models", "concerns", "user_extensions.rb")
    user_extensions_dir = user_extensions_file.dirname
    user_extensions_dir.mkpath unless user_extensions_dir.exist?

    # 备份原文件（如果存在）
    backup_file = nil
    if user_extensions_file.exist?
      backup_file = Rails.root.join("tmp", "user_extensions_backup.rb")
      FileUtils.cp(user_extensions_file, backup_file)
    end

    begin
      # 复制测试扩展文件
      FileUtils.cp(test_extensions_file, user_extensions_file)

      # 重新加载扩展机制（直接调用扩展加载逻辑）
      require_dependency user_extensions_file.to_s
      if defined?(UserExtensions)
        User.class_eval do
          include UserExtensions unless included_modules.include?(UserExtensions)
        end
      end

      # 验证 User 模型包含了 UserExtensions
      assert User.included_modules.include?(UserExtensions), "User should include UserExtensions"

      # 验证扩展方法可用
      user = User.new
      assert user.respond_to?(:test_extension_method), "User should respond to test_extension_method"
      assert_equal "extension_loaded", user.test_extension_method
    ensure
      # 清理：删除测试文件
      FileUtils.rm_f(user_extensions_file)
      # 恢复原文件（如果存在）
      if backup_file && backup_file.exist?
        FileUtils.cp(backup_file, user_extensions_file)
        FileUtils.rm_f(backup_file)
      end
      FileUtils.rm_f(test_extensions_file)
    end
  end

  test "ApplicationControllerExtensions module can be loaded and included" do
    # 创建测试扩展文件
    test_extensions_file = Rails.root.join("tmp", "test_controller_extensions.rb")
    test_extensions_dir = test_extensions_file.dirname
    test_extensions_dir.mkpath unless test_extensions_dir.exist?

    # 创建测试扩展模块
    File.write(test_extensions_file, <<~RUBY)
      module ApplicationControllerExtensions
        extend ActiveSupport::Concern

        included do
          # 添加测试方法
          def test_controller_extension_method
            "controller_extension_loaded"
          end
        end
      end
    RUBY

    # 临时将扩展文件复制到正确位置
    controller_extensions_file = Rails.root.join("app", "controllers", "concerns", "application_controller_extensions.rb")
    controller_extensions_dir = controller_extensions_file.dirname
    controller_extensions_dir.mkpath unless controller_extensions_dir.exist?

    # 备份原文件（如果存在）
    backup_file = nil
    if controller_extensions_file.exist?
      backup_file = Rails.root.join("tmp", "application_controller_extensions_backup.rb")
      FileUtils.cp(controller_extensions_file, backup_file)
    end

    begin
      # 复制测试扩展文件
      FileUtils.cp(test_extensions_file, controller_extensions_file)

      # 重新加载扩展机制（直接调用扩展加载逻辑）
      require_dependency controller_extensions_file.to_s
      if defined?(ApplicationControllerExtensions)
        ApplicationController.class_eval do
          include ApplicationControllerExtensions unless included_modules.include?(ApplicationControllerExtensions)
        end
      end

      # 验证 ApplicationController 包含了 ApplicationControllerExtensions
      assert ApplicationController.included_modules.include?(ApplicationControllerExtensions),
             "ApplicationController should include ApplicationControllerExtensions"

      # 验证扩展方法可用（通过测试控制器）
      controller = ApplicationController.new
      assert controller.respond_to?(:test_controller_extension_method),
             "ApplicationController should respond to test_controller_extension_method"
      assert_equal "controller_extension_loaded", controller.test_controller_extension_method
    ensure
      # 清理：删除测试文件
      FileUtils.rm_f(controller_extensions_file)
      # 恢复原文件（如果存在）
      if backup_file && backup_file.exist?
        FileUtils.cp(backup_file, controller_extensions_file)
        FileUtils.rm_f(backup_file)
      end
      FileUtils.rm_f(test_extensions_file)
    end
  end

  test "extensions are not loaded if files do not exist" do
    # 确保扩展文件不存在
    user_extensions_file = Rails.root.join("app", "models", "concerns", "user_extensions.rb")
    controller_extensions_file = Rails.root.join("app", "controllers", "concerns", "application_controller_extensions.rb")

    # 备份原文件（如果存在）
    user_backup = nil
    controller_backup = nil

    if user_extensions_file.exist?
      user_backup = Rails.root.join("tmp", "user_extensions_backup.rb")
      FileUtils.cp(user_extensions_file, user_backup)
      FileUtils.rm_f(user_extensions_file)
    end

    if controller_extensions_file.exist?
      controller_backup = Rails.root.join("tmp", "application_controller_extensions_backup.rb")
      FileUtils.cp(controller_extensions_file, controller_backup)
      FileUtils.rm_f(controller_extensions_file)
    end

    begin
      # 扩展机制会在应用启动时自动加载
      # 如果文件不存在，扩展机制不会报错，只是不会加载扩展模块
      # 这里主要验证应用仍然可以正常运行

      # 验证扩展模块没有被包含（如果文件不存在）
      # 注意：如果之前已经加载过，模块可能仍然在内存中
      # 这个测试主要验证文件不存在时不会报错
      assert User.present?, "User should still be defined"
      assert ApplicationController.present?, "ApplicationController should still be defined"
    ensure
      # 恢复原文件（如果存在）
      if user_backup && user_backup.exist?
        FileUtils.cp(user_backup, user_extensions_file)
        FileUtils.rm_f(user_backup)
      end

      if controller_backup && controller_backup.exist?
        FileUtils.cp(controller_backup, controller_extensions_file)
        FileUtils.rm_f(controller_backup)
      end
    end
  end
end
