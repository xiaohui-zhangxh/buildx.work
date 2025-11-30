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
end
