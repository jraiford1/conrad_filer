#!/usr/bin/env ruby
require 'conrad_filer/config'
require 'inotify'

module ConradFiler
  
  Thread.abort_on_exception = true

  class CLI

    def initialize(argv)
      @file_data = Hash.new
      @file_changes = Hash.new
    end

    def run
      @config = ConradFiler::Config.new
      @watch_jobs = @config.get_watch_jobs
      @id_types = @config.get_id_types
      @rules = @config.get_rules

      # Go through each of the rules and add them to the watch jobs they are configured for
      # (note: any watch jobs that are not assigned rules will be disabled later)
      @rules.each_value do |rule|
        rule.get_watch_job_names.each do |watch_job_name|
          rule.get_id_type_names.each do |id_type_name|
            # puts "#{rule.name} #{watch_job_name} #{id_type_name}"
            watch_job = @watch_jobs[watch_job_name]
            watch_job.add_rule(@id_types[id_type_name], rule)
          end
        end
      end

      # Start up each watch job in a thread that will monitor directories. If a change is detected matching the bitmask associated
      # with the watch job, the rule will be asked to perform for each id type that matches the file associated with the event
      @watch_jobs.each_pair do |name, watch_job|
        if watch_job.is_valid?
          watch_job.start_inotify_thread
        else
          @config.disable_watch_job(name) # if watch job is enabled but nobody is referencing it, disable it so next time we don't bother including it
          @watch_jobs.delete(name)
        end
      end


      # Now that we are monitoring live updates, its time to go hunt down changes since the last time the app was run and perform the rules
      @watch_jobs.each_value do |watch_job|
        # TODO: Tell the watch job to look for changes since last run
        #watch_job.?????
      end

      # Scan the directories looking for changes since the app was last run

      #DirMonitor.all_jobs(db) do |monitor_job|
      #  @threads << Thread.new(polling_job) do |job|
      #    cur_dir = job.directory
      #    #Dir[job.].each do |filename|
      #    fs = File::Stat.new(filename)
      #  end
      #end
      #@threads.each {|thread| thread.join}

      # Create a special watch job for the configuration file and db looking for changes
      # by not spawning the thread, the app will continue running
      self.create_config_watch_job.start_loop
    end

    # create a watch job to detect if the database or config file have changed (call on_config_file_changed if this happens)
    def create_config_watch_job
      config_watch = Inotify::InotifyThread.new
      config_watch_bitmask = Inotify::InotifyBitmask.all_events
      config_watch_bitmask.set_flag(:in_move_self)
      config_watch_bitmask.set_flag(:in_delete_self)
      config_watch_bitmask.set_flag(:in_modify)
      #puts @config.cfg_filename
      #puts config_watch_bitmask.as_array_of_symbols
      config_watch.add_watch(@config.cfg_filename, config_watch_bitmask.bitmask, false)
      config_watch.add_watch(@config.db_filename, config_watch_bitmask.bitmask, false)
      config_watch.register_event(config_watch_bitmask.bitmask, &(self.method(:on_config_file_changed)))
      config_watch
    end

    # ConradFilerApp.on_config_file_changed
    # This is the callback which is called when the configuration changes
    def on_config_file_changed(notify_event, path)
      filename = path
      if filename == File.expand_path(@config.cfg_filename)
        print "config_file_changed - "
      elsif filename == File.expand_path(@config.db_filename)
        print "database updated - "
      end
      puts Inotify::InotifyBitmask.new(notify_event.mask).as_array_of_symbols
    end
  end

end
