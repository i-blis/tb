# Copyright (C) 2011-2012 Tanaka Akira  <akr@fsij.org>
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

Tb::Cmd.subcommands << 'gsub'

Tb::Cmd.default_option[:opt_gsub_e] = nil
Tb::Cmd.default_option[:opt_gsub_f] = nil

def (Tb::Cmd).op_gsub
  op = OptionParser.new
  op.banner = "Usage: tb gsub [OPTS] REGEXP STRING [TABLE ...]\n" +
    "Substitute cells."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('-f FIELD', 'target field') {|field| Tb::Cmd.opt_gsub_f = field }
  op.def_option('-e REGEXP', 'specify regexp, possibly begins with a hyphen') {|pattern| Tb::Cmd.opt_gsub_e = pattern }
  op
end

def (Tb::Cmd).main_gsub(argv)
  op_gsub.parse!(argv)
  exit_if_help('gsub')
  if Tb::Cmd.opt_gsub_e
    re = Regexp.new(Tb::Cmd.opt_gsub_e)
  else
    err('no regexp given.') if argv.empty?
    re = Regexp.new(argv.shift)
  end
  err('no substitution given.') if argv.empty?
  repl = argv.shift
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    creader.with_cumulative_header {|header0|
      if header0
        y.set_header header0
      end
    }.each {|pairs, header|
      fs = header.dup
      fs.pop while !fs.empty? && !pairs.has_key?(fs.last)
      if Tb::Cmd.opt_gsub_f
        pairs2 = pairs.map {|f, v|
          if f == Tb::Cmd.opt_gsub_f
            v ||= ''
            [f, v.gsub(re, repl)]
          else
            [f, v]
          end
        }
      else
        pairs2 = pairs.map {|f, v|
          v ||= ''
          [f, v.gsub(re, repl)]
        }
      end
      y.yield Hash[pairs2]
    }
  }
  output_tbenum(er)
end

