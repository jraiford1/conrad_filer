require 'conrad_db'

  # An ID Type describes files in a directory using a regular expression.  It is used by a rule to define which file types the rule applies to.
  class ConradIdType

    def initialize(db, a_hash)
      @db_rec = a_hash
    end
    
    def matches_pathname?(pathname)
      pathname =~ self.get_regexp
    end
    
    def match_regexp
      @db_rec['MATCH_REGEXP']
    end
    
    def ignore_case
      @db_rec['IGNORE_CASE'][0,1].upcase == "T"
    end
    
    def get_regexp
      return @regexp if @regexp != nil
      @regexp = Regexp.new(self.match_regexp, self.ignore_case)
    end

  end

