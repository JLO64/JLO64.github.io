module DataSyncHelpers
  # Check if data file exists and is younger than max_age_seconds (default: 1 hour).
  # Returns true if data is fresh (skip sync), false if data is stale or missing (run sync).
  def skip_if_data_fresh?(output_path, max_age_seconds: 3600, source: nil)
    # Resolve the source path (can be a string, lambda, or instance variable)
    source_path = if source.is_a?(Proc)
                    source.call
                  elsif source
                    source
                  else
                    @site&.source
                  end

    # Resolve relative path from site source
    full_path = if output_path.start_with?('/')
                  output_path
                else
                  File.join(source_path, output_path)
                end

    unless File.exist?(full_path)
      Jekyll.logger.info "DataSync:", "#{output_path} not found — will fetch fresh data"
      return false
    end

    file_age = Time.now - File.mtime(full_path)
    if file_age < max_age_seconds
      Jekyll.logger.info "DataSync:", "#{output_path} is #{file_age.to_i}s old (< #{max_age_seconds}s threshold) — skipping sync"
      return true
    end

    false
  end
end
