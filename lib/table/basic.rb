# lib/table/basic.rb - basic fetures for table library
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

require 'pp'

class Table
  def initialize
    @free_rowids = []
    @tbl = {"_rowid"=>[]}
  end

  def pretty_print(q)
    q.object_group(self) {
      each_row {|row|
        q.breakable
        q.pp row
      }
    }
  end
  alias inspect pretty_print_inspect

  def check_rowid(rowid)
    raise IndexError, "unexpected rowid: #{rowid}" if !rowid.kind_of?(Integer) || rowid < 0
  end

  # call-seq:
  #   table.list_rowids -> [rowid1, rowid2, ...]
  def list_rowids
    @tbl["_rowid"].compact
  end

  # call-seq:
  #   table.allocate_rowid -> fresh_rowid
  def allocate_rowid
    if @free_rowids.empty?
      rowid = @tbl["_rowid"].length
      @tbl["_rowid"] << rowid
    else
      rowid = @free_rowids.pop
    end
    rowid
  end

  # call-seq:
  #   table.set_cell(rowid, field, value) -> value
  def set_cell(rowid, field, value)
    check_rowid(rowid)
    field = field.to_s
    raise ArgumentError, "can not set _rowid" if field == "_rowid"
    ary = (@tbl[field] ||= [])
    ary[rowid] = value
  end

  # call-seq:
  #   table.get_cell(rowid, field) -> value
  def get_cell(rowid, field)
    check_rowid(rowid)
    field = field.to_s
    ary = @tbl[field]
    ary ? ary[rowid] : nil
  end

  # same as set_cell(rowid, field, nil)
  def delete_cell(rowid, field)
    check_rowid(rowid)
    field = field.to_s
    raise ArgumentError, "can not delete _rowid" if field == "_rowid"
    ary = @tbl[field]
    ary[rowid] = nil
  end

  # call-seq:
  #   table.delete_row(rowid) -> {field1=>value1, ...}
  def delete_row(rowid)
    check_rowid(rowid)
    row = {}
    @tbl.each {|f, ary|
      v = ary[rowid]
      ary[rowid] = nil
      row[f] = v if !v.nil?
    }
    @free_rowids.push rowid
    row
  end

  # call-seq:
  #   table.insert({field1=>value1, ...})
  #
  def insert(row)
    rowid = allocate_rowid
    update_row(rowid, row)
    rowid
  end

  # call-seq:
  #   table1.concat(table2, table3, ...) -> table1
  def concat(*tables)
    tables.each {|t|
      t.each_row {|row|
        row.delete "_rowid"
        self.insert row
      }
    }
    self
  end

  # call-seq:
  #   table.update_row(rowid, {field1=>value1, ...}) -> nil
  def update_row(rowid, row)
    check_rowid(rowid)
    row.each {|f, v|
      f = f.to_s
      set_cell(rowid, f, v)
    }
    nil
  end

  # call-seq:
  #   table.values_at_row(rowid, field1, field2, ...) -> [value1, value2, ...]
  def values_at_row(rowid, *fields)
    check_rowid(rowid)
    fields.map {|f|
      f = f.to_s
      get_cell(rowid, f)
    }
  end

  # call-seq:
  #   table.get_row(rowid) -> {field1=>value1, ...}
  def get_row(rowid)
    result = {}
    @tbl.each {|f, ary|
      v = ary[rowid]
      next if v.nil?
      result[f] = v
    }
    result
  end

  # call-seq:
  #   table.each_rowid {|rowid| ... }
  def each_rowid
    @tbl["_rowid"].each {|rowid|
      next if rowid.nil?
      yield rowid
    }
  end

  # call-seq:
  #   table.each {|row| ... }
  #   table.each_row {|row| ... }
  def each_row
    each_rowid {|rowid|
      next if rowid.nil?
      yield get_row(rowid)
    }
  end
  alias each each_row

  # call-seq:
  #   table.each_row_values(field1, ...) {|value1, ...| ... }
  def each_row_values(*fields)
    each_rowid {|rowid|
      vs = values_at_row(rowid, *fields)
      yield vs
    }
  end

  # call-seq:
  #   table.make_hash(key_field1, key_field2, ..., value_field, :seed=>initial_seed) {|seed, value| ... } -> hash
  #
  # make_hash takes following arguments:
  # - one or more key fields
  # - value field which can be a single field name or an array of field names
  # -- a single field
  # -- an array of field names
  # -- true
  # - optional option hash which may contains:
  # -- :seed option
  #
  # make_hash takes optional block.
  #
  def make_hash(*args)
    opts = args.last.kind_of?(Hash) ? args.pop : {}
    seed_value = opts[:seed]
    value_field = args.pop
    key_fields = args
    case value_field
    when Array
      value_field_list = value_field.map {|f| f.to_s }
      gen_value = lambda {|all_values| all_values.last(value_field.length) }
    when true
      value_field_list = []
      gen_value = lambda {|all_values| true }
    else
      value_field_list = [value_field.to_s]
      gen_value = lambda {|all_values| all_values.last }
    end
    all_fields = key_fields + value_field_list
    result = {}
    each_row_values(*all_fields) {|all_values|
      value = gen_value.call(all_values)
      vs = all_values[0, key_fields.length]
      lastv = vs.pop
      h = result
      vs.each {|v|
        h[v] = {} if !h.include?(v)
        h = h[v]
      }
      if block_given?
        if !h.include?(lastv)
          h[lastv] = yield(seed_value, value)
        else
          h[lastv] = yield(h[lastv], value)
        end
      else
        if !h.include?(lastv)
          h[lastv] = value 
        else
          raise ArgumentError, "ambiguous key: #{(vs+[lastv]).map {|v| v.inspect }.join(',')}"
        end
      end
    }
    result
  end

  # call-seq:
  #   table.make_hash_array(key_field1, key_field2, ..., value_field)
  def make_hash_array(*args)
    make_hash(*args) {|seed, value| !seed ? [value] : (seed << value) }
  end

  # call-seq:
  #   table.make_hash_count(key_field1, key_field2, ...)
  def make_hash_count(*args)
    make_hash(*(args + [true])) {|seed, value| !seed ? 1 : seed+1 }
  end

  # call-seq:
  #   table.reject {|row| ... }
  def reject
    t = Table.new
    each_row {|row|
      if !yield(row)
        row.delete "_rowid"
        t.insert row
      end
    }
    t
  end
end
