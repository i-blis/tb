# lib/table/tsv.rb - TSV related fetures for table library
#
# Copyright (C) 2010 Tanaka Akira  <akr@fsij.org>
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

class Table

  def Table.load_tsv(filename, *header_fields)
    Table.parse_tsv(File.read(filename), *header_fields)
  end

  def Table.parse_tsv(tsv, *header_fields)
    aa = []
    tsv.each_line {|line|
      aa << line.split(/\t/, -1)
    }
    if header_fields.empty?
      aa.shift while aa.first.all? {|elt| elt.nil? || elt == '' }
      header_fields = aa.shift
      h = Hash.new(0)
      header_fields.each {|f| h[f] += 1 }
      h.each {|f, n|
        if 1 < n
          raise ArgumentError, "ambiguous header: #{f.inspect}"
        end
      }
    end
    t = Table.new(header_fields)
    aa.each {|ary|
      h = {}
      header_fields.each_with_index {|f, i|
        h[f] = ary[i]
      }
      t.insert(h)
    }
    t
  end

  # :call-seq:
  #   generate_tsv(out='', fields=nil) {|recordids| modified_recordids }
  #   generate_tsv(out='', fields=nil)
  #
  def generate_tsv(out='', fields=nil, &block)
    if fields.nil?
      fields = @tbl.keys
    end
    recordids = list_recordids
    if block_given?
      recordids = yield(recordids)
    end
    out << tsv_join(fields)
    recordids.each {|recordid|
      out << tsv_join(get_values(recordid, *fields))
    }
    out
  end

  def tsv_join(values)
    values.map {|v| v.to_s.gsub(/[\t\r\n]/, ' ') }.join("\t")
  end
end