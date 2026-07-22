require "test_helper"
require "rake"

class PublicHolidaysTaskTest < ActiveSupport::TestCase
  class FakeSyncService
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def call(year:, country_code:)
      calls << {
        year: year,
        country_code: country_code
      }

      @result
    end
  end

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?(
      "public_holidays:sync"
    )
  end

  test "synchronizes the requested country and year" do
    service = FakeSyncService.new(
      successful_result(
        created_count: 2,
        updated_count: 1,
        unchanged_count: 8,
        deleted_count: 1
      )
    )

    stdout, stderr = with_environment(
      "YEAR" => "2027",
      "COUNTRY_CODE" => "cr"
    ) do
      with_sync_service(service) do
        capture_io { invoke_task }
      end
    end

    assert_empty stderr
    assert_equal(
      [
        {
          year: "2027",
          country_code: "CR"
        }
      ],
      service.calls
    )
    assert_includes stdout,
                    "Public holidays synchronized for CR in 2027."
    assert_includes stdout, "Created: 2"
    assert_includes stdout, "Updated: 1"
    assert_includes stdout, "Unchanged: 8"
    assert_includes stdout, "Deleted: 1"
  end

  test "uses the configured Costa Rica country and current year by default" do
    service = FakeSyncService.new(successful_result)

    with_environment(
      "YEAR" => nil,
      "COUNTRY_CODE" => nil
    ) do
      with_sync_service(service) do
        capture_io { invoke_task }
      end
    end

    assert_equal(
      [
        {
          year: Date.current.year.to_s,
          country_code: "CR"
        }
      ],
      service.calls
    )
  end

  test "exits unsuccessfully when synchronization fails" do
    service = FakeSyncService.new(
      failed_result("Unable to connect to Nager.Date")
    )
    exit_error = nil

    stdout, stderr = with_environment(
      "YEAR" => "2026",
      "COUNTRY_CODE" => "CR"
    ) do
      with_sync_service(service) do
        capture_io do
          exit_error = assert_raises(SystemExit) { invoke_task }
        end
      end
    end

    assert_empty stdout
    assert_equal 1, exit_error.status
    assert_includes(
      stderr,
      "Public holidays synchronization failed: " \
      "Unable to connect to Nager.Date"
    )
  end

  private

  def invoke_task
    task = Rake::Task["public_holidays:sync"]
    task.reenable
    task.invoke
  end

  def successful_result(
    created_count: 0,
    updated_count: 0,
    unchanged_count: 0,
    deleted_count: 0
  )
    PublicHolidays::SyncService::Result.new(
      created_count: created_count,
      updated_count: updated_count,
      unchanged_count: unchanged_count,
      deleted_count: deleted_count,
      errors: []
    )
  end

  def failed_result(message)
    PublicHolidays::SyncService::Result.new(
      created_count: 0,
      updated_count: 0,
      unchanged_count: 0,
      deleted_count: 0,
      errors: [ message ]
    )
  end

def with_sync_service(service)
  service_class = PublicHolidays::SyncService
  original_new = service_class.method(:new)

  service_class.define_singleton_method(:new) { service }

  yield
ensure
  service_class.define_singleton_method(:new) do |*args, **kwargs, &block|
    original_new.call(*args, **kwargs, &block)
  end
end

  def with_environment(values)
    previous_values = values.to_h do |name, _value|
      [ name, ENV[name] ]
    end

    values.each do |name, value|
      value.nil? ? ENV.delete(name) : ENV[name] = value
    end

    yield
  ensure
    previous_values.each do |name, value|
      value.nil? ? ENV.delete(name) : ENV[name] = value
    end
  end
end
