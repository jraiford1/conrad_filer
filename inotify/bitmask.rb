require 'find'
require 'inotify'

module Inotify

  class InotifyBitmask

    @@symbols_and_bits = {
      :in_access        =>  0,  0 => :in_access,	# File was accessed (read) (*)
      :in_modify        =>  1,  1 => :in_modify,	# File was modified (*)
      :in_attrib        =>  2,  2 => :in_attrib,	# Metadata changed (permissions, timestamps, extended attributes, etc.) (*)
      :in_close_write   =>  3,  3 => :in_close_write,	# File opened for writing was closed (*)
      :in_close_nowrite =>  4,  4 => :in_close_nowrite,	# File not opened for writing was closed (*)
      :in_open          =>  5,  5 => :in_open,		# File was opened (*)
      :in_moved_from    =>  6,  6 => :in_moved_from,	# File moved out of watched directory (*)
      :in_moved_to      =>  7,  7 => :in_moved_to,	# File moved into watched directory (*)
      :in_create        =>  8,  8 => :in_create,	# File/directory created in watched directory (*)
      :in_delete        =>  9,  9 => :in_delete,	# File/directory deleted from watched directory (*)
      :in_delete_self   => 10, 10 => :in_delete_self,	# Watched file/directory was itself deleted
      :in_move_self     => 11, 11 => :in_move_self,	# Watched file/directory was itself moved
      :in_unmount       => 13, 13 => :in_unmount,	# Backing fs was unmounted
      :in_q_overflow    => 14, 14 => :in_q_overflow,	# Event queued overflowed
      :in_ignored       => 15, 15 => :in_ignored,	# File was ignored
      :in_mask_add      => 29, 29 => :in_mask_add,	# add to the mask of an already existing watch
      :in_isdir         => 30, 30 => :in_isdir,		# event occurred against dir
      :in_oneshot       => 31, 31 => :in_oneshot	# only send event once
    }
    @@symbols_to_masks = {
      :in_access        => 0b00000000000000000000000000000001,
      :in_modify        => 0b00000000000000000000000000000010,
      :in_attrib        => 0b00000000000000000000000000000100,
      :in_close_write   => 0b00000000000000000000000000001000,
      :in_close_nowrite => 0b00000000000000000000000000010000,
      :in_open          => 0b00000000000000000000000000100000,
      :in_moved_from    => 0b00000000000000000000000001000000,
      :in_moved_to      => 0b00000000000000000000000010000000,
      :in_create        => 0b00000000000000000000000100000000,
      :in_delete        => 0b00000000000000000000001000000000,
      :in_delete_self   => 0b00000000000000000000010000000000,
      :in_move_self     => 0b00000000000000000000100000000000,
      :in_unmount       => 0b00000000000000000010000000000000,
      :in_q_overflow    => 0b00000000000000000100000000000000,
      :in_ignored       => 0b00000000000000001000000000000000,
      :in_mask_add      => 0b00100000000000000000000000000000,
      :in_isdir         => 0b01000000000000000000000000000000,
      :in_oneshot       => 0b10000000000000000000000000000000
    }

    attr_reader :bitmask
    @symbols
 
    def self.all_events
      inotify_bitmask = self.new(0b00000000000000000000111111111111)  # All standard events
    end
    def initialize(bitmask=0)
      if bitmask.class == String
        @bitmask = bitmask.to_i
      else
        @bitmask = bitmask
      end
    end
    def set_flag(a_symbol)
      @bitmask = @bitmask | @@symbols_to_masks[a_symbol]
    end
    def unset_flag(a_symbol)
      @bitmask = @bitmask & ~@@symbols_to_masks[a_symbol]
    end

    def test?(bitmask2)
      (@bitmask & bitmask2) != 0
    end
    def watch_ignored?
      self.test?(Inotify::IGNORED)
    end
    def is_directory?
      self.test?(Inotify::ISDIR)
    end
    def overflow?
      self.test?(Inotify::Q_OVERFLOW)
    end
    def unmount?
      self.test?(Inotify::UNMOUNT)
    end
    def as_array_of_symbols
      return @symbols if @symbols != nil
      @symbols = Array.new
      31.downto(0) do |i|
        if @bitmask[i] == 1
          a_symbol = @@symbols_and_bits[i]
          @symbols << a_symbol if a_symbol != nil
        end
      end
      @symbols
    end
  end
end
