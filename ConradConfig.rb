require 'rubygems'
require 'parseconfig'
require 'ConradWatchJob'
require 'ConradIdType'
require 'ConradRule'
require 'ConradDB'
require 'inotify'

  class ConradConfig
    attr_reader :cfg_filename
    attr_reader :db_filename

    # Register all tables referenced in this class so the database can be created if needed
    ConradDB.register_table_definition("CREATE TABLE WATCH_JOBS (NAME TEXT, PATHNAME TEXT, BITMASK INTEGER, RECURSIVE TEXT, ENABLED TEXT)")
    ConradDB.register_table_definition("CREATE TABLE ID_TYPES (NAME TEXT, MATCH_REGEXP TEXT, IGNORE_CASE TEXT)")
    ConradDB.register_table_definition("CREATE TABLE RULES (NAME TEXT, DIRECTORY TEXT, RECURSIVE TEXT)")
    ConradDB.register_table_definition("CREATE TABLE RULE_WATCH_JOBS (RULE TEXT, WATCH_JOB TEXT)")
    ConradDB.register_table_definition("CREATE TABLE RULE_ID_TYPES (RULE TEXT, ID_TYPE TEXT)")


    ## Register to create some data to play with when a new db is created
    bitmask = Inotify::InotifyBitmask.all_events
    bitmask.unset_flag(:in_close_nowrite)
    bitmask.unset_flag(:in_open)
    ConradDB.register_table_definition("INSERT INTO WATCH_JOBS (NAME,PATHNAME,BITMASK,RECURSIVE,ENABLED) VALUES ('WATCH_JOB','/home/jon/watch_job',#{bitmask.bitmask},'F','T')")
    ConradDB.register_table_definition("INSERT INTO ID_TYPES (NAME,MATCH_REGEXP,IGNORE_CASE) VALUES ('ID_TYPE','.\\.MP3$','T')")
    ConradDB.register_table_definition("INSERT INTO ID_TYPES (NAME,MATCH_REGEXP,IGNORE_CASE) VALUES ('ID_TYPE2','.\\.m4a$','T')")
    ConradDB.register_table_definition("INSERT INTO RULES (NAME) VALUES ('RULE')")
    ConradDB.register_table_definition("INSERT INTO RULE_WATCH_JOBS (RULE, WATCH_JOB) VALUES ('RULE', 'WATCH_JOB')")
    ConradDB.register_table_definition("INSERT INTO RULE_ID_TYPES (RULE, ID_TYPE) VALUES ('RULE', 'ID_TYPE')")
    ConradDB.register_table_definition("INSERT INTO RULE_ID_TYPES (RULE, ID_TYPE) VALUES ('RULE', 'ID_TYPE2')")


    DEFAULT_CONFIG_FILENAME = '/etc/conrad-filer.conf'
    #DEFAULT_DB_FILENAME = '/var/local/conrad-filer/conrad-filer.sdb'
    DEFAULT_DB_FILENAME = 'conrad-filer.sdb'
    #DEFAULT_LOG_FILENAME = '/var/local/conrad-filer/conrad-filer.log'
    DEFAULT_LOG_FILENAME = 'conrad-filer.log'

    def initialize(filename="")
      @cfg_filename = filename
      self.determine_file_locations
      self.open_database
    end

    def determine_file_locations
      @cfg_filename = DEFAULT_CONFIG_FILENAME if @cfg_filename.length == 0
      @file_config = ParseConfig.new(@cfg_filename)
      @db_filename = @file_config.get_value('database').to_s
      @db_filename = DEFAULT_DB_FILENAME if @db_filename.length == 0
      @log_filename = @file_config.get_value('logfile').to_s
      @log_filename = DEFAULT_LOG_FILENAME if @log_filename.length == 0
    end

    def open_database
      @db = ConradDB.new(@db_filename)
      @db.open
    end

    def get_watch_jobs
      objs = Hash.new
      rows = @db.execute("SELECT * FROM WATCH_JOBS WHERE ENABLED = 'T'")
      rows.each do |row|
        obj = ConradWatchJob.new(@db, row)
        objs[row['NAME']] = obj
      end
      objs
    end

    def disable_watch_job(watch_job_name)
      @db.execute("UPDATE WATCH_JOBS SET ENABLED = 'F' WHERE NAME = '#{watch_job_name}'")
    end

    def get_id_types
      objs = Hash.new
      @db.execute("SELECT * FROM ID_TYPES").each do |row|
        obj = ConradIdType.new(@db, row)
        objs[row['NAME']] = obj
      end
      objs
    end

    def get_rules
      objs = Hash.new
      @db.execute("SELECT * FROM RULES").each do |row|
        obj = ConradRule.new(@db, row)
        row['WATCH_JOBS'] = @db.execute_as_array("SELECT WATCH_JOB FROM RULE_WATCH_JOBS WHERE RULE = #{row['NAME']}")
        row['ID_TYPES'] = @db.execute_as_array("SELECT ID_TYPE FROM RULE_ID_TYPES WHERE RULE = #{row['NAME']}")
        objs[row['NAME']] = obj
      end
      objs
    end

  end
