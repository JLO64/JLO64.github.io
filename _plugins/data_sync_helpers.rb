module DataSyncHelpers
  # Check if a sync marker file exists and is younger than max_age_seconds (default: 1 hour).
  # Uses a gitignored .sync_<basename> marker file instead of the data file's mtime,
  # because git clone resets all file timestamps, making the data file's mtime unreliable.
  # Returns true if data is fresh (skip sync), false if stale or missing (run sync).
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

    # Use a gitignored marker file instead of the data file's mtime.
    # Git clone resets file timestamps, so the data file's mtime is meaningless.
    dir = File.dirname(full_path)
    basename = File.basename(output_path, '.*')
    marker_path = File.join(dir, ".sync_#{basename}")

    unless File.exist?(marker_path)
      Jekyll.logger.info "DataSync:", "#{output_path} — sync marker not found, will fetch fresh data"
      return false
    end

    marker_age = Time.now - File.mtime(marker_path)
    if marker_age < max_age_seconds
      Jekyll.logger.info "DataSync:", "#{output_path} — last synced #{marker_age.to_i}s ago (< #{max_age_seconds}s threshold) — skipping sync"
      return true
    end

    Jekyll.logger.info "DataSync:", "#{output_path} — last synced #{marker_age.to_i}s ago (>= #{max_age_seconds}s threshold) — will refresh"
    false
  end

  # Touch the sync marker file after a successful data sync.
  # Call this after writing the data file so subsequent builds skip the sync.
  def mark_data_synced(output_path, source: nil)
    source_path = if source.is_a?(Proc)
                    source.call
                  elsif source
                    source
                  else
                    @site&.source
                  end

    full_path = if output_path.start_with?('/')
                  output_path
                else
                  File.join(source_path, output_path)
                end

    dir = File.dirname(full_path)
    basename = File.basename(output_path, '.*')
    marker_path = File.join(dir, ".sync_#{basename}")
    FileUtils.mkdir_p(dir)
    FileUtils.touch(marker_path)
  end
end
