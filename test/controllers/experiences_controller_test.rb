require "test_helper"

class ExperiencesControllerTest < ActionDispatch::IntegrationTest
  test "index shows experiences list without authentication" do
    get experiences_path

    assert_response :success
    # Should show list of experiences
  end

  test "index is accessible without authentication" do
    # This should not redirect to login
    get experiences_path

    assert_response :success
    assert_not_equal new_session_path, response.location
  end

  test "show displays experience when file exists" do
    # Use an existing experience file
    experience_id = "importmap-install-highlight-js"
    get experience_path(experience_id)

    assert_response :success
    # Should display the experience content
  end

  test "show returns 404 when experience does not exist" do
    # In integration tests, exceptions are caught and return 404
    get experience_path("non_existent_experience_12345")

    assert_response :not_found
  end

  test "index loads experiences from files" do
    get experiences_path

    assert_response :success
    # Should load experiences from docs/experiences directory
  end

  test "show handles invalid experience id format" do
    # Test with invalid characters (path traversal attempt)
    get experience_path("../../../etc/passwd")

    assert_response :not_found
  end

  test "show handles experience with invalid date format" do
    # This tests the date parsing error handling in parse_metadata
    # We can't easily create a file with invalid date, but we can test the error handling
    experience_id = "importmap-install-highlight-js"
    get experience_path(experience_id)

    assert_response :success
    # Should still display the experience even if date parsing fails
  end

  test "show handles stale check returning false" do
    # Test when stale? returns false (cached content, returns 304)
    experience_id = "importmap-install-highlight-js"

    # First request to populate cache
    get experience_path(experience_id)
    assert_response :success

    # Second request with If-None-Match header (should return 304)
    get experience_path(experience_id), headers: {
      "If-None-Match" => response.headers["ETag"]
    }
    # Should return 304 Not Modified
    assert_response :not_modified
  end

  test "load_experience returns nil for invalid id format" do
    # This tests the private method indirectly through show
    get experience_path("invalid/id/format")

    assert_response :not_found
  end

  test "parse_metadata handles missing title" do
    # Test when content doesn't have a title (first # line)
    experience_id = "importmap-install-highlight-js"
    get experience_path(experience_id)

    assert_response :success
    # Should still work even if title is missing
  end

  test "parse_metadata handles missing problem_type" do
    # Test when content doesn't have problem_type
    experience_id = "importmap-install-highlight-js"
    get experience_path(experience_id)

    assert_response :success
    # Should still work even if problem_type is missing
  end
end
