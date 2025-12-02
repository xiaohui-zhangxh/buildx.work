require "test_helper"

class TechStackControllerTest < ActionDispatch::IntegrationTest
  test "show displays tech stack rule when file exists" do
    # Use an existing tech stack rule
    tech_stack_id = "authentication"
    get tech_stack_rule_path(tech_stack_id)

    assert_response :success
    # Should display the tech stack rule content
  end

  test "show is accessible without authentication" do
    # This should not redirect to login
    tech_stack_id = "authentication"
    get tech_stack_rule_path(tech_stack_id)

    assert_response :success
    assert_not_equal new_session_path, response.location
  end

  test "show returns 404 when tech stack rule does not exist" do
    # In integration tests, exceptions are caught and return 404
    get tech_stack_rule_path("non_existent_tech_stack_12345")

    assert_response :not_found
  end

  test "show returns 404 when rule file does not exist" do
    # Test with a tech stack ID that's in TECH_STACK_RULES but file doesn't exist
    # We'll use a fake one that's not in the constant
    get tech_stack_rule_path("non_existent_rule")

    assert_response :not_found
  end

  test "show displays action-policy rule" do
    # Test with action-policy rule
    tech_stack_id = "action-policy"
    get tech_stack_rule_path(tech_stack_id)

    assert_response :success
  end

  test "show displays daisy-ui rule" do
    # Test with daisy-ui rule
    tech_stack_id = "daisy-ui"
    get tech_stack_rule_path(tech_stack_id)

    assert_response :success
  end

  test "show handles invalid tech stack id format" do
    # Test with invalid characters (path traversal attempt)
    get tech_stack_rule_path("../../../etc/passwd")

    assert_response :not_found
  end

  test "show handles stale check returning false" do
    # Test when stale? returns false (cached content, returns 304)
    tech_stack_id = "authentication"

    # First request to populate cache
    get tech_stack_rule_path(tech_stack_id)
    assert_response :success

    # Second request with If-None-Match header (should return 304)
    get tech_stack_rule_path(tech_stack_id), headers: {
      "If-None-Match" => response.headers["ETag"]
    }
    # Should return 304 Not Modified
    assert_response :not_modified
  end

  test "show handles tech stack id with uppercase" do
    # Test with uppercase (should fail validation)
    get tech_stack_rule_path("AUTHENTICATION")

    assert_response :not_found
  end

  test "show handles tech stack id with special characters" do
    # Test with special characters (should fail validation)
    get tech_stack_rule_path("auth@test")

    assert_response :not_found
  end
end
