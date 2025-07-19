require "get_process_mem"

class ResourceMetricsService
  class << self
    def initialize_metrics
      @metrics = {
        solid_queue: {
          memory_usage: [],
          cpu_time: [],
          start_times: {},
          end_times: {}
        },
        async_job: {
          memory_usage: [],
          cpu_time: [],
          start_times: {},
          end_times: {}
        }
      }
    end

    def metrics
      @metrics ||= initialize_metrics
    end

    def record_start(job_type, job_id)
      job_key = job_type.to_sym
      metrics[job_key][:start_times][job_id] = {
        time: Process.clock_gettime(Process::CLOCK_MONOTONIC),
        memory: current_memory_mb,
        cpu_time: Process.times.utime + Process.times.stime
      }
    end

    def record_end(job_type, job_id)
      job_key = job_type.to_sym
      return unless metrics[job_key][:start_times][job_id]

      end_stats = {
        time: Process.clock_gettime(Process::CLOCK_MONOTONIC),
        memory: current_memory_mb,
        cpu_time: Process.times.utime + Process.times.stime
      }

      start_stats = metrics[job_key][:start_times][job_id]

      # Calculate metrics
      metrics[job_key][:memory_usage] << end_stats[:memory]
      metrics[job_key][:cpu_time] << (end_stats[:cpu_time] - start_stats[:cpu_time])

      # Store end time data
      metrics[job_key][:end_times][job_id] = end_stats
    end

    def current_memory_mb
      GetProcessMem.new.mb
    end

    def report_metrics
      puts "\n========== RESOURCE USAGE METRICS ==========\n"

      [ :solid_queue, :async_job ].each do |job_type|
        puts "\n----- #{job_type.to_s.upcase} Resource Usage -----"

        if metrics[job_type][:memory_usage].any?
          avg_memory = metrics[job_type][:memory_usage].sum / metrics[job_type][:memory_usage].size
          max_memory = metrics[job_type][:memory_usage].max
          puts "Memory Usage:"
          puts "  Average: #{avg_memory.round(2)} MB"
          puts "  Maximum: #{max_memory.round(2)} MB"
        else
          puts "Memory Usage: No data"
        end

        if metrics[job_type][:cpu_time].any?
          avg_cpu = metrics[job_type][:cpu_time].sum / metrics[job_type][:cpu_time].size
          total_cpu = metrics[job_type][:cpu_time].sum
          puts "CPU Usage:"
          puts "  Average per job: #{avg_cpu.round(4)} seconds"
          puts "  Total CPU time: #{total_cpu.round(4)} seconds"
        else
          puts "CPU Usage: No data"
        end
      end

      if metrics[:solid_queue][:memory_usage].any? && metrics[:async_job][:memory_usage].any?
        sq_avg_mem = metrics[:solid_queue][:memory_usage].sum / metrics[:solid_queue][:memory_usage].size
        aj_avg_mem = metrics[:async_job][:memory_usage].sum / metrics[:async_job][:memory_usage].size

        sq_total_cpu = metrics[:solid_queue][:cpu_time].sum
        aj_total_cpu = metrics[:async_job][:cpu_time].sum

        puts "\n----- Comparison -----"
        puts "Memory Usage: AsyncJob uses #{(aj_avg_mem / sq_avg_mem * 100 - 100).round(2)}% #{aj_avg_mem > sq_avg_mem ? 'more' : 'less'} memory than SolidQueue"
        puts "CPU Usage: AsyncJob uses #{(aj_total_cpu / sq_total_cpu * 100 - 100).round(2)}% #{aj_total_cpu > sq_total_cpu ? 'more' : 'less'} CPU time than SolidQueue"
      end

      puts "\n==========================================="
    end

    def reset_metrics
      initialize_metrics
    end
  end
end
