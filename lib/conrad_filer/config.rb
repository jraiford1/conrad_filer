require 'rubygems'
require 'parseconfig'
require 'conrad_filer/watch_job'
require 'conrad_filer/id_type'
require 'conrad_filer/rule'
require 'conrad_filer/db'
require 'inotify'

module ConradFiler

  class Config
    attr_reader :cfg_filename
    attr_reader :db_filename

    # Register all tables referenced in this class so the database can be created if needed
    ConradFiler::DB.register_table_definition("CREATE TABLE WATCH_JOBS (NAME TEXT, PATHNAME TEXT, BITMASK INTEGER, RECURSIVE TEXT, ENABLED TEXT)")
    ConradFiler::DB.register_table_definition("CREATE TABLE ID_TYPES (NAME TEXT, MATCH_REGEXP TEXT, IGNORE_CASE TEXT)")
    ConradFiler::DB.register_table_definition("CREATE TABLE RULES (NAME TEXT, DIRECTORY TEXT, RECURSIVE TEXT)")
    ConradFiler::DB.register_table_definition("CREATE TABLE RULE_WATCH_JOBS (RULE TEXT, WATCH_JOB TEXT)")
    ConradFiler::DB.register_table_definition("CREATE TABLE RULE_ID_TYPES (RULE TEXT, ID_TYPE TEXT)")


    ## Register to create some data to play with when a new db is created
    bitmask = Inotify::InotifyBitmask.all_events
    bitmask.unset_flag(:in_close_nowrite)
    bitmask.unset_flag(:in_open)
    ConradFiler::DB.register_table_definition("INSERT INTO WATCH_JOBS (NAME,PATHNAME,BITMASK,RECURSIVE,ENABLED) VALUES ('WATCH_JOB','/home/jon/watch_job',#{bitmask.bitmask},'F','T')")
    ConradFiler::DB.register_table_definition("INSERT INTO ID_TYPES (NAME,MATCH_REGEXP,IGNORE_CASE) VALUES ('ID_TYPE','.\\.MP3$','T')")
    ConradFiler::DB.register_table_definition("INSERT INTO ID_TYPES (NAME,MATCH_REGEXP,IGNORE_CASE) VALUES ('ID_TYPE2','.\\.m4a$','T')")
    ConradFiler::DB.register_table_definition("INSERT INTO RULES (NAME) VALUES ('RULE')")
    ConradFiler::DB.register_table_definition("INSERT INTO RULE_WATCH_JOBS (RULE, WATCH_JOB) VALUES ('RULE', 'WATCH_JOB')")
    ConradFiler::DB.register_table_definition("INSERT INTO RULE_ID_TYPES (RULE, ID_TYPE) VALUES ('RULE', 'ID_TYPE')")
    ConradFiler::DB.register_table_definition("INSERT INTO RULE_ID_TYPES (RULE, ID_TYPE) VALUES ('RULE', 'ID_TYPE2')")


    DEFAULT_CONFIG_FILENAME = '/etc/conrad_filer.conf'
    #DEFAULT_DB_FILENAME = '/var/local/conrad_filer/conrad_filer.sdb'
    DEFAULT_DB_FILENAME = 'conrad_filer.sdb'
    #DEFAULT_LOG_FILENAME = '/var/local/conrad_filer/conrad_filer.log'
    DEFAULT_LOG_FILENAME = 'conrad_filer.log'

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
      @db = ConradFiler::DB.new(@db_filename)
      @db.open
    end

    def get_watch_jobs
      objs = Hash.new
      rows = @db.execute("SELECT * FROM WATCH_JOBS WHERE ENABLED = 'T'")
      rows.each do |row|
        obj = ConradFiler::WatchJob.new(@db, row)
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
        obj = ConradFiler::IdType.new(@db, row)
        objs[row['NAME']] = obj
      end
      objs
    end

    def get_rules
      objs = Hash.new
      @db.execute("SELECT * FROM RULES").each do |row|
        obj = ConradFiler::Rule.new(@db, row)
        row['WATCH_JOBS'] = @db.execute_as_array("SELECT WATCH_JOB FROM RULE_WATCH_JOBS WHERE RULE = #{row['NAME']}")
        row['ID_TYPES'] = @db.execute_as_array("SELECT ID_TYPE FROM RULE_ID_TYPES WHERE RULE = #{row['NAME']}")
        objs[row['NAME']] = obj
      end
      objs
    end

  end

end