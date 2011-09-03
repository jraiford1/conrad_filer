require 'ConradDB'
require 'inotify'

  # A rule describes an action to perform on a file that matches one of its defined id types
  class ConradRule

    attr_accessor :db_rec

    def initialize(db, a_hash)
      @db_rec = a_hash
    end

    def get_watch_job_names
      @db_rec['WATCH_JOBS']
    end

    def get_id_type_names
      @db_rec['ID_TYPES']
    end

    def name
      @db_rec['NAME']
    end

    def on_watch_event(watch_job, id_type, notify_event, path)
      bitmask = Inotify::InotifyBitmask.new(notify_event.mask)
      if notify_event.name.class == String
        pathname = File.join(path, notify_event.name)
      else
        pathname = path
      end
      puts "[ConradRule::on_watch_event] '#{pathname}' #{bitmask.as_array_of_symbols}"
    end
  end
