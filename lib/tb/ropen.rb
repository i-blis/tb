# lib/tb/ropen.rb - Tb::Reader.open
#
# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

class Tb::Reader
  def self.open(filename, opts={})
    io = nil
    opts = opts.dup
    case filename
    when /\Acsv:/
      io = File.open($')
      opts[:close] = io
      rawreader = Tb::CSVReader.new(io)
    when /\Atsv:/
      io = File.open($')
      opts[:close] = io
      rawreader = Tb::TSVReader.new(io)
    when /\Ap[pgbn]m:/
      io = File.open($')
      opts[:close] = io
      rawreader = Tb.pnm_stream_input(io)
    when /\.csv\z/
      io = File.open(filename)
      opts[:close] = io
      rawreader = Tb::CSVReader.new(io)
    when /\.tsv\z/
      io = File.open(filename)
      opts[:close] = io
      rawreader = Tb::TSVReader.new(io)
    when /\.p[pgbn]m\z/
      io = File.open(filename)
      opts[:close] = io
      rawreader = Tb.pnm_stream_input(io)
    else
      if filename == '-'
        rawreader = Tb::CSVReader.new(STDIN)
      elsif filename.respond_to? :to_str
        # guess table format?
        io = File.open(filename)
        opts[:close] = io
        rawreader = Tb::CSVReader.new(io)
      else
        raise ArgumentError, "unexpected filename: #{filename.inspect}"
      end
    end
    reader = self.new(rawreader, opts)
    if block_given?
      begin
        yield reader
      ensure
        reader.close
      end
    else
      reader
    end
  end
end
