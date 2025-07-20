require "get_process_mem"
require "json"

class ResourceMetricsService
  # Redis keys for storing metrics
  SOLID_QUEUE_MEMORY_KEY = "solid_queue_memory_usage"
  SOLID_QUEUE_CPU_KEY = "solid_queue_cpu_time"
  SOLID_QUEUE_START_TIMES_KEY = "solid_queue_start_times"
  SOLID_QUEUE_END_TIMES_KEY = "solid_queue_end_times"
  
  ASYNC_JOB_MEMORY_KEY = "async_job_memory_usage"
  ASYNC_JOB_CPU_KEY = "async_job_cpu_time"
  ASYNC_JOB_START_TIMES_KEY = "async_job_start_times"
  ASYNC_JOB_END_TIMES_KEY = "async_job_end_times"
  
  class << self
    def initialize_metrics
      # Clear all Redis keys for metrics
      $redis.del(SOLID_QUEUE_MEMORY_KEY)
      $redis.del(SOLID_QUEUE_CPU_KEY)
      $redis.del(SOLID_QUEUE_START_TIMES_KEY)
      $redis.del(SOLID_QUEUE_END_TIMES_KEY)
      
      $redis.del(ASYNC_JOB_MEMORY_KEY)
      $redis.del(ASYNC_JOB_CPU_KEY)
      $redis.del(ASYNC_JOB_START_TIMES_KEY)
      $redis.del(ASYNC_JOB_END_TIMES_KEY)
    end

    def record_start(job_type, job_id)
      # Create start time data
      start_data = {
        time: Process.clock_gettime(Process::CLOCK_MONOTONIC),
        memory: current_memory_mb,
        cpu_time: Process.times.utime + Process.times.stime
      }
      
      # Store in Redis based on job type
      if job_type.to_sym == :solid_queue
        # Get existing start times or initialize empty hash
        start_times = $redis.get(SOLID_QUEUE_START_TIMES_KEY)
        start_times = start_times ? JSON.parse(start_times) : {}
        
        # Add new start time data
        start_times[job_id] = start_data
        
        # Save back to Redis
        $redis.set(SOLID_QUEUE_START_TIMES_KEY, start_times.to_json)
      elsif job_type.to_sym == :async_job
        # Get existing start times or initialize empty hash
        start_times = $redis.get(ASYNC_JOB_START_TIMES_KEY)
        start_times = start_times ? JSON.parse(start_times) : {}
        
        # Add new start time data
        start_times[job_id] = start_data
        
        # Save back to Redis
        $redis.set(ASYNC_JOB_START_TIMES_KEY, start_times.to_json)
      end
    end

    def record_end(job_type, job_id)
      # Get end time data
      end_stats = {
        time: Process.clock_gettime(Process::CLOCK_MONOTONIC),
        memory: current_memory_mb,
        cpu_time: Process.times.utime + Process.times.stime
      }
      
      if job_type.to_sym == :solid_queue
        # Get existing start times
        start_times_json = $redis.get(SOLID_QUEUE_START_TIMES_KEY)
        return unless start_times_json
        
        start_times = JSON.parse(start_times_json)
        return unless start_times[job_id]
        
        start_stats = start_times[job_id]
        
        # Calculate metrics
        memory_usage = $redis.get(SOLID_QUEUE_MEMORY_KEY)
        memory_usage = memory_usage ? JSON.parse(memory_usage) : []
        memory_usage << end_stats[:memory]
        $redis.set(SOLID_QUEUE_MEMORY_KEY, memory_usage.to_json)
        
        # Fix CPU time tracking
        begin
          cpu_time = $redis.get(SOLID_QUEUE_CPU_KEY)
          cpu_time = cpu_time ? JSON.parse(cpu_time) : []
          
          # Ensure values are floats
          start_cpu = start_stats[:cpu_time].to_f
          end_cpu = end_stats[:cpu_time].to_f
          cpu_diff = end_cpu - start_cpu
          
          # Log for debugging
          puts "SolidQueue CPU time diff: #{cpu_diff} (#{start_cpu} -> #{end_cpu})"
          
          # Only add positive values
          cpu_time << cpu_diff if cpu_diff > 0
          $redis.set(SOLID_QUEUE_CPU_KEY, cpu_time.to_json)
        rescue => e
          puts "Error tracking CPU time for SolidQueue: #{e.message}"
        end
        
        # Store end time data
        end_times = $redis.get(SOLID_QUEUE_END_TIMES_KEY)
        end_times = end_times ? JSON.parse(end_times) : {}
        end_times[job_id] = end_stats
        $redis.set(SOLID_QUEUE_END_TIMES_KEY, end_times.to_json)
        
      elsif job_type.to_sym == :async_job
        # Get existing start times
        start_times_json = $redis.get(ASYNC_JOB_START_TIMES_KEY)
        return unless start_times_json
        
        start_times = JSON.parse(start_times_json)
        return unless start_times[job_id]
        
        start_stats = start_times[job_id]
        
        # Calculate metrics
        memory_usage = $redis.get(ASYNC_JOB_MEMORY_KEY)
        memory_usage = memory_usage ? JSON.parse(memory_usage) : []
        memory_usage << end_stats[:memory]
        $redis.set(ASYNC_JOB_MEMORY_KEY, memory_usage.to_json)
        
        # Fix CPU time tracking
        begin
          cpu_time = $redis.get(ASYNC_JOB_CPU_KEY)
          cpu_time = cpu_time ? JSON.parse(cpu_time) : []
          
          # Ensure values are floats
          start_cpu = start_stats[:cpu_time].to_f
          end_cpu = end_stats[:cpu_time].to_f
          cpu_diff = end_cpu - start_cpu
          
          # Log for debugging
          puts "AsyncJob CPU time diff: #{cpu_diff} (#{start_cpu} -> #{end_cpu})"
          
          # Only add positive values
          cpu_time << cpu_diff if cpu_diff > 0
          $redis.set(ASYNC_JOB_CPU_KEY, cpu_time.to_json)
        rescue => e
          puts "Error tracking CPU time for AsyncJob: #{e.message}"
        end
        
        # Store end time data
        end_times = $redis.get(ASYNC_JOB_END_TIMES_KEY)
        end_times = end_times ? JSON.parse(end_times) : {}
        end_times[job_id] = end_stats
        $redis.set(ASYNC_JOB_END_TIMES_KEY, end_times.to_json)
      end
    end

    def current_memory_mb
      GetProcessMem.new.mb
    end

    def report_metrics
      puts "\n========== RESOURCE USAGE METRICS ==========\n"

      # Report SolidQueue metrics
      puts "\n----- SOLID_QUEUE Resource Usage -----"
      memory_usage_json = $redis.get(SOLID_QUEUE_MEMORY_KEY)
      cpu_time_json = $redis.get(SOLID_QUEUE_CPU_KEY)
      
      if memory_usage_json
        memory_usage = JSON.parse(memory_usage_json)
        if memory_usage.any?
          avg_memory = memory_usage.sum / memory_usage.size
          max_memory = memory_usage.max
          puts "Memory Usage:"
          puts "  Average: #{avg_memory.round(2)} MB"
          puts "  Maximum: #{max_memory.round(2)} MB"
        else
          puts "Memory Usage: No data"
        end
      else
        puts "Memory Usage: No data"
      end
      
      if cpu_time_json
        cpu_time = JSON.parse(cpu_time_json)
        if cpu_time.any?
          avg_cpu = cpu_time.sum / cpu_time.size
          total_cpu = cpu_time.sum
          puts "CPU Usage:"
          puts "  Average per job: #{avg_cpu.round(4)} seconds"
          puts "  Total CPU time: #{total_cpu.round(4)} seconds"
        else
          puts "CPU Usage: No data"
        end
      else
        puts "CPU Usage: No data"
      end

      # Report AsyncJob metrics
      puts "\n----- ASYNC_JOB Resource Usage -----"
      memory_usage_json = $redis.get(ASYNC_JOB_MEMORY_KEY)
      cpu_time_json = $redis.get(ASYNC_JOB_CPU_KEY)
      
      if memory_usage_json
        memory_usage = JSON.parse(memory_usage_json)
        if memory_usage.any?
          avg_memory = memory_usage.sum / memory_usage.size
          max_memory = memory_usage.max
          puts "Memory Usage:"
          puts "  Average: #{avg_memory.round(2)} MB"
          puts "  Maximum: #{max_memory.round(2)} MB"
        else
          puts "Memory Usage: No data"
        end
      else
        puts "Memory Usage: No data"
      end
      
      if cpu_time_json
        cpu_time = JSON.parse(cpu_time_json)
        if cpu_time.any?
          avg_cpu = cpu_time.sum / cpu_time.size
          total_cpu = cpu_time.sum
          puts "CPU Usage:"
          puts "  Average per job: #{avg_cpu.round(4)} seconds"
          puts "  Total CPU time: #{total_cpu.round(4)} seconds"
        else
          puts "CPU Usage: No data"
        end
      else
        puts "CPU Usage: No data"
      end

      # Compare metrics if both have data
      sq_memory_json = $redis.get(SOLID_QUEUE_MEMORY_KEY)
      aj_memory_json = $redis.get(ASYNC_JOB_MEMORY_KEY)
      sq_cpu_json = $redis.get(SOLID_QUEUE_CPU_KEY)
      aj_cpu_json = $redis.get(ASYNC_JOB_CPU_KEY)
      
      if sq_memory_json && aj_memory_json && sq_cpu_json && aj_cpu_json
        sq_memory = JSON.parse(sq_memory_json)
        aj_memory = JSON.parse(aj_memory_json)
        sq_cpu = JSON.parse(sq_cpu_json)
        aj_cpu = JSON.parse(aj_cpu_json)
        
        if sq_memory.any? && aj_memory.any? && sq_cpu.any? && aj_cpu.any?
          sq_avg_mem = sq_memory.sum / sq_memory.size
          aj_avg_mem = aj_memory.sum / aj_memory.size
          
          sq_total_cpu = sq_cpu.sum
          aj_total_cpu = aj_cpu.sum
          
          puts "\n----- Comparison -----"
          puts "Memory Usage: AsyncJob uses #{(aj_avg_mem / sq_avg_mem * 100 - 100).round(2)}% #{aj_avg_mem > sq_avg_mem ? 'more' : 'less'} memory than SolidQueue"
          puts "CPU Usage: AsyncJob uses #{(aj_total_cpu / sq_total_cpu * 100 - 100).round(2)}% #{aj_total_cpu > sq_total_cpu ? 'more' : 'less'} CPU time than SolidQueue"
        end
      end

      puts "\n===========================================" 
    end

    def reset_metrics
      # Just call initialize_metrics which already clears all Redis keys
      initialize_metrics
    end
  end
end
