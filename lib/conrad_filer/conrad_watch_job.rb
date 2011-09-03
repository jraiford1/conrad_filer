require 'conrad_filer/conrad_db'
require 'inotify'

  # A watch job describes directories to monitor and includes a bitmask describing which actions to monitor
  class ConradWatchJob

    def initialize(db, a_hash)
      @db_rec = a_hash
      @bitmask = Inotify::InotifyBitmask.new(@db_rec['BITMASK'])
      @rules = Hash.new {Array.new}
      @inotify_thread = Inotify::InotifyThread.new
    end

    def id_types
      @rules.keys
    end

    def add_rule(id_type, rule)
      @rules[id_type] = @rules[id_type] << rule
    end

    def recursive?
      @db_rec['RECURSIVE'][0,1].upcase == "T"
    end

    def pathname
      @db_rec['PATHNAME']
    end

    def bitmask
      @bitmask.bitmask
    end

    def is_valid?
      @rules.size > 0
    end

    def prepare_inotify_thread
      @inotify_thread.add_watch(self.pathname, self.bitmask, self.recursive?)
      @inotify_thread.register_event(self.bitmask, &(self.method(:process_event)))
    end

    def start_inotify_thread
      self.prepare_inotify_thread
      @inotify_thread.start_thread
    end
  
    def start_inotify_loop
      self.prepare_inotify_thread
      @inotify_thread.start_loop
    end

    def process_event(notify_event, path)
      bitmask = Inotify::InotifyBitmask.new(notify_event.mask)
      puts "[ConradWatchJob::process_event] '#{path}/#{notify_event.name}' #{bitmask.as_array_of_symbols}"
      @rules.each_pair do |id_type, rules_for_id_type|
        if id_type.matches_pathname?(File.join(path,notify_event.name.to_s))
          rules_for_id_type.each do |rule|
            rule.on_watch_event(self, id_type, notify_event, path)
          end
        end
      end
    end

    #def register_event(bitmask, &block)
    #  @inotify_thread.register_event(bitmask, &block)
    #end
  end

