class RedisJobTracker
  # Keys used in Redis
  SOLID_QUEUE_TOTAL_KEY = "solid_queue_total_jobs"
  SOLID_QUEUE_COMPLETED_KEY = "solid_queue_completed_jobs"
  ASYNC_JOB_TOTAL_KEY = "async_job_total_jobs"
  ASYNC_JOB_COMPLETED_KEY = "async_job_completed_jobs"
  
  # Reset all counters for a specific job type
  def self.reset(job_type)
    if job_type == "SolidQueue"
      $redis.set(SOLID_QUEUE_TOTAL_KEY, 0)
      $redis.set(SOLID_QUEUE_COMPLETED_KEY, 0)
    elsif job_type == "AsyncJob"
      $redis.set(ASYNC_JOB_TOTAL_KEY, 0)
      $redis.set(ASYNC_JOB_COMPLETED_KEY, 0)
    end
  end
  
  # Set the total expected jobs for a job type
  def self.set_total_jobs(job_type, count)
    if job_type == "SolidQueue"
      $redis.set(SOLID_QUEUE_TOTAL_KEY, count)
    elsif job_type == "AsyncJob"
      $redis.set(ASYNC_JOB_TOTAL_KEY, count)
    end
  end
  
  # Get the total expected jobs for a job type
  def self.get_total_jobs(job_type)
    if job_type == "SolidQueue"
      $redis.get(SOLID_QUEUE_TOTAL_KEY).to_i
    elsif job_type == "AsyncJob"
      $redis.get(ASYNC_JOB_TOTAL_KEY).to_i
    else
      0
    end
  end
  
  # Increment the completed jobs counter for a job type
  def self.increment_completed(job_type)
    if job_type == "SolidQueue"
      $redis.incr(SOLID_QUEUE_COMPLETED_KEY)
    elsif job_type == "AsyncJob"
      $redis.incr(ASYNC_JOB_COMPLETED_KEY)
    end
  end
  
  # Get the completed jobs count for a job type
  def self.get_completed_count(job_type)
    if job_type == "SolidQueue"
      $redis.get(SOLID_QUEUE_COMPLETED_KEY).to_i
    elsif job_type == "AsyncJob"
      $redis.get(ASYNC_JOB_COMPLETED_KEY).to_i
    else
      0
    end
  end
end
