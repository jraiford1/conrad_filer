require 'conrad_db'

  class DirPollingJob

    ConradDB.register_table_definition("CREATE TABLE WATCH_LIST (DIRECTORY TEXT, GLOB TEXT, INC_SUBDIR TEXT, RECURSIVE TEXT)")

    ## Class Methods ##
    
    def self.query
      "SELECT DIRECTORY, GLOB, INC_SUBDIR, POLLING_DELAY FROM POLLING_JOBS"
    end
    
    def self.all_jobs(db)
      jobs = Array.new
      db.execute(self.query) do |row|
        jobs << self.new(row)
      end
      jobs
    end
    
    
    ## Instance Methods ##
    
    def initialize(an_array)
      @rec = an_array
    end
    
    def include_subdirs?
      @rec[3] == "T"
    end

    def directory  
      @rec[1]
    end
    
    def glob
      @rec[2]
    end
    
    def perform
      # Loop over all entries in the directory and collect the files and subdirectories
    end
    
  end

