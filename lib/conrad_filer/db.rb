include ObjectSpace
require 'sqlite3'

module ConradFiler

  class DB
   
    @@table_defs = Array.new
    @@table_defs << "CREATE TABLE DIR_INFO (DIR_NAME TEXT, DIR_HASH INTEGER, FULL_PATH TEXT)"

    ## Class Methods ##

    # Register the sql that will be called if the database needs to be created
    def self.register_table_definition(sql)
      @@table_defs << sql
    end

    # Finalizer definition for class instances (registered in ConradDB::open method if the database is successfully opened)
    def self.finalize_instance(db)
      proc { db.close }
    end


    ## Instance Methods ##

    # Initialize the new instance
    def initialize(filename)
      @filename = filename
    end

    # Create the configuration database
    def create
      self.delete
      @db = SQLite3::Database.new(@filename)
      @@table_defs.each do |sql|
        puts sql
        @db.execute(sql)
      end
    end
  
    # Open the configuration database
    def open
      if File.exists?(@filename)
        @db = SQLite3::Database.open(@filename)
      else
        self.create
      end
      @db.results_as_hash = true
      # Register the finalizer to make sure the db connection is closed
      ObjectSpace.define_finalizer(self, self.class.finalize_instance(@db))
      self
    end
 
    # Execute the sql
    def execute(sql)
      @db.execute(sql)
    end

    # Execute the sql as normal, but return an array from the first column of the result set
    def execute_as_array(sql)
      return_array = Array.new
      @db.results_as_hash = false
        self.execute(sql).each do |rec|
          return_array << rec[0]
        end
      @db.results_as_hash = true
      return_array
    end
  
    # Close the configuration database
    def close
      @db.close

      # Unegister all finalizers since they are no longer needed
      ObjectSpace.undefine_finalizer(self)
    end

    # Delete the configuration database
    def delete
      if File.exists?(@filename)
         File.delete(@filename)
      end
    end
 
  end

end