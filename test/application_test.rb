require "test_helper"

class ApplicationTest < ActiveSupport::TestCase
  test "uses PostgreSQL for persistence" do
    assert_equal "PostgreSQL", ApplicationRecord.connection.adapter_name
  end
end
