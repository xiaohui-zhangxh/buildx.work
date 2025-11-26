require "test_helper"

class InstallationFormTest < ActiveSupport::TestCase
  setup do
    SystemConfig::Current.values.clear
    SystemConfig.set("installation_completed", "0", description: "安装完成标志", category: "system")
    SystemConfig::Current.values.clear
  end

  test "should be valid with valid attributes" do
    form = InstallationForm.new(
      site_name: "Test Site",
      site_description: "Test Description",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert form.valid?
  end

  test "should validate site_name presence" do
    form = InstallationForm.new(
      site_name: "",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert_not form.valid?
    assert form.errors[:site_name].any?
  end

  test "should validate site_name length" do
    form = InstallationForm.new(
      site_name: "A", # Too short
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert_not form.valid?
  end

  test "should validate time_zone presence" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert_not form.valid?
    assert form.errors[:time_zone].any?
  end

  test "should validate locale inclusion" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "invalid",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert_not form.valid?
    assert form.errors[:locale].any?
  end

  test "should validate admin_email format" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "invalid-email",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert_not form.valid?
    assert form.errors[:admin_email].any?
  end

  test "should validate password match" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "different123",
      admin_name: "Admin User"
    )

    assert_not form.valid?
    assert_includes form.errors[:admin_password_confirmation], "密码不匹配"
  end

  test "should validate password strength" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "onlyletters",
      admin_password_confirmation: "onlyletters",
      admin_name: "Admin User"
    )

    assert_not form.valid?
    assert_includes form.errors[:admin_password], "密码必须至少 8 位，且包含字母和数字"
  end

  test "should validate password minimum length" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "short",
      admin_password_confirmation: "short",
      admin_name: "Admin User"
    )

    assert_not form.valid?
    assert form.errors[:admin_password].any?
  end

  test "should validate admin_name presence" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: ""
    )

    assert_not form.valid?
    assert form.errors[:admin_name].any?
  end

  test "should not save when already installed" do
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig::Current.values.clear

    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert_not form.valid?
    assert_includes form.errors[:base], "系统已经安装，无法重复安装"
  end

  test "should save and create system configs" do
    form = InstallationForm.new(
      site_name: "Test Site",
      site_description: "Test Description",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert form.save

    SystemConfig::Current.values.clear
    assert_equal "Test Site", SystemConfig.get("site_name")
    assert_equal "Test Description", SystemConfig.get("site_description")
    assert_equal "Asia/Shanghai", SystemConfig.get("time_zone")
    assert_equal "zh-CN", SystemConfig.get("locale")
    assert_equal "1", SystemConfig.get("installation_completed")
    assert SystemConfig.get("installation_completed_at").present?
  end

  test "should save and create admin user" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert_difference "User.count", 1 do
      assert form.save
    end

    admin = User.find_by(email_address: "admin@example.com")
    assert admin.present?
    assert_equal "Admin User", admin.name
    assert admin.authenticate("password123")
  end

  test "should save and assign admin role" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert form.save

    admin = User.find_by(email_address: "admin@example.com")
    assert admin.has_role?(:admin)
  end

  test "should extract domain from localhost with port" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert form.save("localhost:3001")

    SystemConfig::Current.values.clear
    assert_equal "localhost:3001", SystemConfig.get("site_domain")
  end

  test "should extract domain from valid domain with port" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert form.save("www.example.com:8080")

    SystemConfig::Current.values.clear
    site_domain = SystemConfig.get("site_domain")
    assert site_domain.present?
    assert_match(/www\.example\.com/, site_domain)
    assert_match(/8080/, site_domain)
  end

  test "should save domain for IP address" do
    form = InstallationForm.new(
      site_name: "Test Site",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert form.save("192.168.1.1:8080")

    SystemConfig::Current.values.clear
    # IP addresses should be saved
    assert_equal "192.168.1.1:8080", SystemConfig.get("site_domain")
  end

  test "should not save site_description if blank" do
    form = InstallationForm.new(
      site_name: "Test Site",
      site_description: "",
      time_zone: "Asia/Shanghai",
      locale: "zh-CN",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_password_confirmation: "password123",
      admin_name: "Admin User"
    )

    assert form.save

    SystemConfig::Current.values.clear
    # site_description should not be set if blank
    assert_nil SystemConfig.get("site_description")
  end
end
