require "test_helper"

# DeploymentVersion is a pure Ruby class, doesn't need database
class DeploymentVersionTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  setup do
    # Reset cached version before each test
    DeploymentVersion.reset!
  end

  test "returns version from file when it exists" do
    version_file = Rails.root.join("config", "version.txt")
    FileUtils.mkdir_p(File.dirname(version_file))
    File.write(version_file, "abc123\n")

    assert_equal "abc123", DeploymentVersion.current
  ensure
    File.delete(version_file) if File.exist?(version_file)
  end

  test "returns dev in development environment when file does not exist" do
    version_file = Rails.root.join("config", "version.txt")
    File.delete(version_file) if File.exist?(version_file)

    # Stub Rails.env to return development
    Rails.env.stub(:development?, true) do
      Rails.env.stub(:test?, false) do
        DeploymentVersion.reset!
        assert_equal "dev", DeploymentVersion.current
      end
    end
  end

  test "returns dev in test environment when file does not exist" do
    version_file = Rails.root.join("config", "version.txt")
    File.delete(version_file) if File.exist?(version_file)

    # In test environment, should return "dev"
    DeploymentVersion.reset!
    assert_equal "dev", DeploymentVersion.current
  end

  test "returns unknown in production when file does not exist" do
    version_file = Rails.root.join("config", "version.txt")
    File.delete(version_file) if File.exist?(version_file)

    # Stub Rails.env to return production
    Rails.env.stub(:production?, true) do
      Rails.env.stub(:development?, false) do
        Rails.env.stub(:test?, false) do
          DeploymentVersion.reset!
          assert_equal "unknown", DeploymentVersion.current
        end
      end
    end
  end

  test "strips whitespace from version file" do
    version_file = Rails.root.join("config", "version.txt")
    FileUtils.mkdir_p(File.dirname(version_file))
    File.write(version_file, "  abc123  \n")

    assert_equal "abc123", DeploymentVersion.current
  ensure
    File.delete(version_file) if File.exist?(version_file)
  end

  test "returns unknown when file is empty" do
    version_file = Rails.root.join("config", "version.txt")
    FileUtils.mkdir_p(File.dirname(version_file))
    File.write(version_file, "\n")

    assert_equal "unknown", DeploymentVersion.current
  ensure
    File.delete(version_file) if File.exist?(version_file)
  end

  test "caches version after first read" do
    version_file = Rails.root.join("config", "version.txt")
    FileUtils.mkdir_p(File.dirname(version_file))
    File.write(version_file, "first\n")

    assert_equal "first", DeploymentVersion.current

    # Change file content
    File.write(version_file, "second\n")

    # Should still return cached version
    assert_equal "first", DeploymentVersion.current

    # After reset, should return new version
    DeploymentVersion.reset!
    assert_equal "second", DeploymentVersion.current
  ensure
    File.delete(version_file) if File.exist?(version_file)
  end
end

