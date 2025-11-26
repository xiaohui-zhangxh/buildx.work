require "test_helper"

class SystemConfigTest < ActiveSupport::TestCase
  setup do
    # Clear Current.values before each test
    SystemConfig::Current.values.clear
  end

  test "validates key presence" do
    config = SystemConfig.new(value: "test")
    assert_not config.valid?
    assert_includes config.errors[:key], "不能为空字符"
  end

  test "validates key format" do
    config = SystemConfig.new(key: "Invalid-Key", value: "test")
    assert_not config.valid?
    assert_includes config.errors[:key], "must be lowercase letters, numbers, and underscores only"
  end

  test "accepts valid key format" do
    config = SystemConfig.new(key: "valid_key_123", value: "test")
    assert config.valid?
  end

  test "get returns value for existing key" do
    SystemConfig.create!(key: "test_key", value: "test_value")
    SystemConfig::Current.values.clear

    assert_equal "test_value", SystemConfig.get("test_key")
  end

  test "get returns nil for non-existent key" do
    SystemConfig::Current.values.clear

    assert_nil SystemConfig.get("non_existent_key")
  end

  test "get caches value in Current.values" do
    SystemConfig.create!(key: "test_key", value: "test_value")
    SystemConfig::Current.values.clear

    # First call should query database
    assert_equal "test_value", SystemConfig.get("test_key")
    # Second call should use cache
    assert_equal "test_value", SystemConfig.get("test_key")
    assert SystemConfig::Current.values.key?(:test_key)
  end

  test "set creates new config if it does not exist" do
    assert_difference "SystemConfig.count", 1 do
      config = SystemConfig.set("new_key", "new_value", description: "Test", category: "test")
      assert_equal "new_value", config.value
      assert_equal "Test", config.description
      assert_equal "test", config.category
    end
  end

  test "set updates existing config if value changes" do
    config = SystemConfig.create!(key: "existing_key", value: "old_value")
    SystemConfig::Current.values.clear

    updated_config = SystemConfig.set("existing_key", "new_value")

    assert_equal config.id, updated_config.id
    assert_equal "new_value", updated_config.reload.value
  end

  test "set updates description and category if provided" do
    config = SystemConfig.create!(key: "test_key", value: "test_value")
    SystemConfig::Current.values.clear

    updated_config = SystemConfig.set("test_key", "test_value", description: "New Description", category: "new_category")

    assert_equal "New Description", updated_config.reload.description
    assert_equal "new_category", updated_config.category
  end

  test "set does not update if values are the same" do
    config = SystemConfig.create!(key: "test_key", value: "test_value", description: "Description", category: "category")
    original_updated_at = config.updated_at
    SystemConfig::Current.values.clear

    # Wait a bit to ensure updated_at would change if save was called
    sleep 0.1

    updated_config = SystemConfig.set("test_key", "test_value", description: "Description", category: "category")

    # updated_at should not change if nothing changed
    assert_equal original_updated_at.to_i, updated_config.reload.updated_at.to_i
  end

  test "set strips whitespace from value" do
    config = SystemConfig.set("test_key", "  test_value  ", description: "  Test  ", category: "  test  ")

    assert_equal "test_value", config.value
    assert_equal "Test", config.description
    assert_equal "test", config.category
  end

  test "installation_completed? returns true when value is 1" do
    SystemConfig.set("installation_completed", "1", description: "安装完成", category: "system")
    SystemConfig::Current.values.clear

    assert SystemConfig.installation_completed?
  end

  test "installation_completed? returns false when value is not 1" do
    SystemConfig.set("installation_completed", "0", description: "安装完成", category: "system")
    SystemConfig::Current.values.clear

    assert_not SystemConfig.installation_completed?
  end

  test "installation_completed? returns false when key does not exist" do
    # Delete the installation_completed config if it exists
    SystemConfig.where(key: "installation_completed").destroy_all
    SystemConfig::Current.values.clear

    assert_not SystemConfig.installation_completed?
  end

  test "after_save_commit updates Current.values" do
    SystemConfig::Current.values.clear
    config = SystemConfig.create!(key: "test_key", value: "test_value")

    assert_equal "test_value", SystemConfig::Current.values[:test_key]
  end

  test "after_destroy_commit removes from Current.values" do
    config = SystemConfig.create!(key: "test_key", value: "test_value")
    assert_equal "test_value", SystemConfig::Current.values[:test_key]

    config.destroy

    assert_not SystemConfig::Current.values.key?(:test_key)
  end

  test "Current.get returns cached value if available" do
    SystemConfig::Current.values[:test_key] = "cached_value"

    assert_equal "cached_value", SystemConfig::Current.get("test_key")
  end

  test "Current.get queries database if not cached" do
    SystemConfig.create!(key: "test_key", value: "db_value")
    SystemConfig::Current.values.clear

    assert_equal "db_value", SystemConfig::Current.get("test_key")
    assert_equal "db_value", SystemConfig::Current.values[:test_key]
  end
end
