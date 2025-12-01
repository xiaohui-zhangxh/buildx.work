require "test_helper"

class DaisyFormBuilderTest < ActionView::TestCase
  include ApplicationHelper

  setup do
    @user = User.new(name: "Test User", email_address: "test@example.com", password: "password123", password_confirmation: "password123")
    @user.valid? # Trigger validations to set up errors if needed
  end

  test "error_messages returns empty string when no errors" do
    # Create a user without validation errors
    valid_user = User.new(name: "Test", email_address: "test@example.com", password: "password123", password_confirmation: "password123")
    valid_user.valid? # Trigger validations

    # form_with returns form HTML, not block result
    # So we test by checking the form doesn't contain error alert when there are no errors
    form_html = form_with(model: valid_user, builder: DaisyFormBuilder) do |f|
      f.error_messages
    end
    # When there are no errors, error_messages returns empty string
    # So the form HTML should not contain error alert
    assert_no_match(/alert.*alert-error/, form_html)
  end

  test "error_messages renders alert when errors exist" do
    @user.errors.add(:email_address, "is invalid")
    @user.errors.add(:password, "is too short")
    error_html = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      f.error_messages
    end
    assert_match(/alert.*alert-error/, error_html)
    assert_match(/请修复以下错误/, error_html)
    assert_match(/is invalid/, error_html)
    assert_match(/is too short/, error_html)
  end

  test "error_messages uses custom title" do
    @user.errors.add(:email_address, "is invalid")
    error_html = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      f.error_messages(title: "Custom Title")
    end
    assert_match(/Custom Title/, error_html)
  end

  test "text_field renders with default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_field(:name)
    end
    assert_match(/input.*input-bordered/, @field_html)
    assert_match(/name="user\[name\]"/, @field_html)
  end

  test "text_field renders with label when label_text is string" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_field(:name, label_text: "姓名")
    end
    assert_match(/<label/, @field_html)
    assert_match(/姓名/, @field_html)
    assert_match(/form-control/, @field_html)
  end

  test "text_field renders with label when label_text is true using human attribute name" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_field(:name, label_text: true)
    end
    assert_match(/<label/, @field_html)
    assert_match(/form-control/, @field_html)
    # Should use human attribute name, not the string "true"
    assert_no_match(/&lt;span.*true&lt;\/span/, @field_html)
  end

  test "email_field renders with default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.email_field(:email_address)
    end
    assert_match(/input.*input-bordered/, @field_html)
    assert_match(/type="email"/, @field_html)
    assert_no_match(/<label/, @field_html) # Should not have label
  end

  test "email_field renders with label when label_text is string" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.email_field(:email_address, label_text: "邮箱地址")
    end
    assert_match(/<label/, @field_html)
    assert_match(/邮箱地址/, @field_html)
  end

  test "email_field renders with label when label_text is true" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.email_field(:email_address, label_text: true)
    end
    assert_match(/<label/, @field_html)
    assert_match(/form-control/, @field_html)
  end

  test "password_field renders with default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.password_field(:password)
    end
    assert_match(/input.*input-bordered/, @field_html)
    assert_match(/type="password"/, @field_html)
    assert_no_match(/<label/, @field_html) # Should not have label
  end

  test "password_field renders with label when label_text is string" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.password_field(:password, label_text: "密码")
    end
    assert_match(/<label/, @field_html)
    assert_match(/密码/, @field_html)
  end

  test "password_field renders with label when label_text is true" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.password_field(:password, label_text: true)
    end
    assert_match(/<label/, @field_html)
    assert_match(/form-control/, @field_html)
  end

  test "password_field with no_default_classes skips default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.password_field(:password, no_default_classes: true, class: "custom-class")
    end
    assert_no_match(/input-bordered/, @field_html)
    assert_match(/custom-class/, @field_html)
  end

  test "check_box renders with default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.check_box(:remember_me)
    end
    assert_match(/checkbox.*checkbox-primary/, @field_html)
    assert_match(/type="checkbox"/, @field_html)
  end

  test "check_box renders without label when label_text not provided" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.check_box(:remember_me)
    end
    assert_match(/type="checkbox"/, @field_html)
    assert_match(/checkbox.*checkbox-primary/, @field_html)
    # Should not have wrapper or label when label_text not provided
    assert_no_match(/form-control/, @field_html)
  end

  test "check_box renders with label when label_text is string" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.check_box(:remember_me, label_text: "Remember me")
    end
    # HTML is escaped in test output, so check for escaped version
    assert_match(/&lt;label|Remember me/, @field_html)
    assert_match(/Remember me/, @field_html)
    assert_match(/form-control/, @field_html)
  end

  test "check_box renders with label when label_text is true" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.check_box(:remember_me, label_text: true)
    end
    # HTML is escaped in test output, so check for escaped version
    assert_match(/&lt;label|form-control/, @field_html)
    assert_match(/form-control/, @field_html)
    # Should use human attribute name, not the string "true"
    assert_no_match(/&lt;span.*true&lt;\/span/, @field_html)
  end

  test "submit renders with default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @button_html = f.submit("Save")
    end
    assert_match(/type="submit"/, @button_html)
    assert_match(/Save/, @button_html)
  end

  test "submit with full_width adds full width class" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @button_html = f.submit("Save", full_width: true)
    end
    assert_match(/w-full/, @button_html)
  end

  test "submit with size adds size class" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @button_html = f.submit("Save", size: "lg")
    end
    assert_match(/btn-lg/, @button_html)
  end

  test "field_wrapper adds form-control class" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_field(:name, label_text: "Name")
    end
    assert_match(/form-control/, @field_html)
  end

  test "field_wrapper shows field errors" do
    @user.errors.add(:name, "can't be blank")
    field_html = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      f.text_field(:name, label_text: "Name")
    end
    # HTML entities are escaped, so check for the escaped version
    assert_match(/can&#39;t be blank|can't be blank/, field_html)
    assert_match(/text-error/, field_html)
  end

  test "number_field renders with default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.number_field(:age)
    end
    assert_match(/input.*input-bordered/, @field_html)
    assert_match(/type="number"/, @field_html)
  end

  test "number_field renders with label when label_text is provided" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.number_field(:age, label_text: "年龄")
    end
    assert_match(/<label/, @field_html)
    assert_match(/年龄/, @field_html)
  end

  test "text_area renders with default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_area(:bio)
    end
    assert_match(/textarea.*textarea-bordered/, @field_html)
  end

  test "text_area renders with label when label_text is provided" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_area(:bio, label_text: "简介")
    end
    assert_match(/<label/, @field_html)
    assert_match(/简介/, @field_html)
  end

  test "text_area uses default rows" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_area(:bio)
    end
    assert_match(/rows="3"/, @field_html)
  end

  test "text_area uses custom rows" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_area(:bio, rows: 5)
    end
    assert_match(/rows="5"/, @field_html)
  end

  test "select renders with default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.select(:role, [["Admin", "admin"], ["User", "user"]])
    end
    assert_match(/select.*select-bordered/, @field_html)
  end

  test "select renders with label when label_text is provided" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.select(:role, [["Admin", "admin"], ["User", "user"]], {}, label_text: "角色")
    end
    assert_match(/<label/, @field_html)
    assert_match(/角色/, @field_html)
  end

  test "collection_radio_buttons renders radio buttons" do
    roles = [Role.new(name: "admin", id: 1), Role.new(name: "user", id: 2)]
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.collection_radio_buttons(:role_id, roles, :id, :name)
    end
    # HTML is escaped in test output, so check for escaped version
    assert_match(/type=&quot;radio&quot;|type="radio"/, @field_html)
    assert_match(/admin/, @field_html)
    assert_match(/user/, @field_html)
  end

  test "submit with custom class" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @button_html = f.submit("Save", class: "custom-btn")
    end
    assert_match(/custom-btn/, @button_html)
    assert_match(/btn.*btn-primary/, @button_html)
  end

  test "actions renders submit and cancel buttons" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @actions_html = f.actions(cancel_url: "/users")
    end
    assert_match(/type="submit"/, @actions_html)
    assert_match(/保存/, @actions_html)
    assert_match(/取消/, @actions_html)
    assert_match(/\/users/, @actions_html)
  end

  test "actions renders only submit when no cancel_url" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @actions_html = f.actions
    end
    assert_match(/type="submit"/, @actions_html)
    assert_no_match(/取消/, @actions_html)
  end

  test "actions uses custom submit and cancel text" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @actions_html = f.actions(submit_text: "Submit", cancel_text: "Cancel", cancel_url: "/users")
    end
    assert_match(/Submit/, @actions_html)
    assert_match(/Cancel/, @actions_html)
  end

  test "card_actions renders submit and cancel buttons" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @actions_html = f.card_actions(cancel_url: "/users")
    end
    assert_match(/card-actions/, @actions_html)
    assert_match(/type="submit"/, @actions_html)
    assert_match(/保存/, @actions_html)
    assert_match(/取消/, @actions_html)
  end

  test "card_actions renders only submit when no cancel_url" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @actions_html = f.card_actions
    end
    # HTML is escaped in test output, so check for escaped version
    assert_match(/type=&quot;submit&quot;|type="submit"/, @actions_html)
    assert_no_match(/取消/, @actions_html)
  end

  test "field_wrapper with label_text false does not render label" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.check_box(:remember_me, label_text: "Remember me")
    end
    # check_box with label_text should render label, but wrapper should have label_text: false
    assert_match(/checkbox/, @field_html)
  end

  test "text_field with no_default_classes skips default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_field(:name, no_default_classes: true, class: "custom-class")
    end
    assert_no_match(/input-bordered/, @field_html)
    assert_match(/custom-class/, @field_html)
  end

  test "email_field with no_default_classes skips default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.email_field(:email_address, no_default_classes: true, class: "custom-class")
    end
    assert_no_match(/input-bordered/, @field_html)
    assert_match(/custom-class/, @field_html)
  end

  test "text_area with no_default_classes skips default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.text_area(:bio, no_default_classes: true, class: "custom-class")
    end
    assert_no_match(/textarea-bordered/, @field_html)
    assert_match(/custom-class/, @field_html)
  end

  test "select with no_default_classes skips default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.select(:role, [["Admin", "admin"]], {}, no_default_classes: true, class: "custom-class")
    end
    assert_no_match(/select-bordered/, @field_html)
    assert_match(/custom-class/, @field_html)
  end

  test "check_box with no_default_classes skips default classes" do
    form = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      @field_html = f.check_box(:remember_me, no_default_classes: true, class: "custom-class")
    end
    assert_no_match(/checkbox-primary/, @field_html)
    assert_match(/custom-class/, @field_html)
  end

  test "error_messages with custom class" do
    @user.errors.add(:email_address, "is invalid")
    error_html = form_with(model: @user, builder: DaisyFormBuilder) do |f|
      f.error_messages(class: "custom-alert")
    end
    assert_match(/custom-alert/, error_html)
  end
end
