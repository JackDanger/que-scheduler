require 'spec_helper'

RSpec.describe Que::Scheduler::VersionSupport do
  describe '.set_priority' do
    class TestPriority < Que::Scheduler::SchedulerJob
      Que::Scheduler::VersionSupport.set_priority(self, 3)
    end

    it 'sets the priority' do
      if described_class.zero_major?
        expect(TestPriority.instance_variable_get('@priority')).to eq(3)
      else
        expect(TestPriority.priority).to eq(3)
      end
    end
  end

  describe '.apply_retry_semantics' do
    class TestRetries < Que::Scheduler::SchedulerJob
      Que::Scheduler::VersionSupport.apply_retry_semantics(self)
    end

    it 'sets the retries' do
      if described_class.zero_major?
        expect(TestRetries.instance_variable_get('@retry_interval'))
          .to be(described_class::RETRY_PROC)
      else
        expect(TestRetries.retry_interval).to be(described_class::RETRY_PROC)
        expect(TestRetries.maximum_retry_count).to be > 10_000_000
      end
    end
  end

  describe 'RETRY_PROC' do
    it 'sets the proc' do
      expect(described_class::RETRY_PROC.call(6)).to eq(1299)
      expect(described_class::RETRY_PROC.call(7)).to eq(2404)
      expect(described_class::RETRY_PROC.call(8)).to eq(3600)
      expect(described_class::RETRY_PROC.call(9)).to eq(3600)
    end
  end

  describe '.job_attributes' do
    it 'retrieves the job attributes in a consistent manner' do
      job = Que::Scheduler::SchedulerJob.enqueue

      expected =
        if described_class.zero_major?
          hash_including(
            args: [],
            error_count: 0,
            job_class: 'Que::Scheduler::SchedulerJob',
            last_error: nil,
            priority: 0,
            queue: ''
          )
        else
          hash_including(
            args: [],
            data: {},
            error_count: 0,
            expired_at: nil,
            finished_at: nil,
            job_class: 'Que::Scheduler::SchedulerJob',
            last_error_backtrace: nil,
            last_error_message: nil,
            priority: 0,
            queue: 'default'
          )
        end
      attrs = described_class.job_attributes(job)
      expect(attrs).to match(expected)
      # Keys changed from strings to symbols with que 1.0
      # We consolidate on symbols.
      attrs.each_key do |key|
        expect(key).to be_a(Symbol)
      end
      expect(attrs.fetch(:job_id)).to be_a(Integer)
      expect(attrs.fetch(:run_at)).to be_a(Time)
    end
  end

  describe '.default_scheduler_queue' do
    it 'returns the queue name' do
      expected = described_class.zero_major? ? '' : 'default'
      expect(described_class.default_scheduler_queue).to eq(expected)
    end
  end
end
