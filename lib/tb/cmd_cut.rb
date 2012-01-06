# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials provided
#     with the distribution.
#  3. The name of the author may not be used to endorse or promote
#     products derived from this software without specific prior
#     written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Tb::Cmd.subcommands << 'cut'

Tb::Cmd.default_option[:opt_cut_v] = nil

def (Tb::Cmd).op_cut
  op = OptionParser.new
  op.banner = "Usage: tb cut [OPTS] FIELD,... [TABLE]\n" +
    "Select columns."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('-v', 'invert match') { Tb::Cmd.opt_cut_v = true }
  op
end

def (Tb::Cmd).main_cut(argv)
  op_cut.parse!(argv)
  exit_if_help('cut')
  err('no fields given.') if argv.empty?
  fs = split_field_list_argument(argv.shift)
  argv = ['-'] if argv.empty?
  Tb::CatReader.open(argv, Tb::Cmd.opt_N) {|tblreader|
    if Tb::Cmd.opt_cut_v
      with_table_stream_output {|gen|
        first = true
        header = nil
        tblreader.each {|pairs|
          if first
            first = false
            header = tblreader.header_fixed - fs
            gen.output_header(header)
          end
          header |= pairs.map {|k, v| k } - fs
          gen << header.map {|k| pairs[k] }
        }
      }
    else
      with_table_stream_output {|gen|
        first = true
        tblreader.each {|pairs|
          if first
            first = false
            if tblreader.header_fixed
              fieldset = Tb::FieldSet.new(*tblreader.header_fixed)
              fs.each {|f|
                fieldset.index_from_field_ex(f)
              }
            end
            gen.output_header(fs)
          end
          gen << fs.map {|f| pairs[f] }
        }
      }
    end
  }
end

