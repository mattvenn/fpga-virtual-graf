from __future__ import absolute_import
from __future__ import print_function
import sys
import os
from optparse import OptionParser

# verilog parsing
import pyverilog.utils.version
from pyverilog.vparser.parser import parse
import verilog_module


def main():
    INFO = "Verilog code parser"
    VERSION = pyverilog.utils.version.VERSION
    USAGE = "Usage: python example_parser.py file ..."

    def showVersion():
        print(INFO)
        print(VERSION)
        print(USAGE)
        sys.exit()

    optparser = OptionParser()
    optparser.add_option("-v","--version",action="store_true",dest="showversion",
                         default=False,help="Show the version")
    optparser.add_option("-I","--include",dest="include",action="append",
                         default=[],help="Include path")
    optparser.add_option("-D",dest="define",action="append",
                         default=[],help="Macro Definition")
    (options, args) = optparser.parse_args()

    filelist = args
    if options.showversion:
        showVersion()

    for f in filelist:
        if not os.path.exists(f): raise IOError("file not found: " + f)

    if len(filelist) == 0:
        showVersion()

    ast, directives = parse(filelist,
                            preprocess_include=options.include,
                            preprocess_define=options.define)
    
    module = verilog_module.module()
    show(ast, module)
    with open('out.dot', 'w' ) as fh:
        fh.write(module.render("port_template.dot"))

      
def get_io_port(ch, module):
    children = ch.children()
    direction = children[0].__class__.__name__
    name = children[0].name
    type = children[1].__class__.__name__
    try:
        width = children[0].width.children()[0]
    except AttributeError:
        width = 1
    module.add_port(name, direction, type, width )

def show(ch, module):
    if(ch.__class__ == pyverilog.vparser.ast.Ioport):
        get_io_port(ch, module)
    if(ch.__class__ == pyverilog.vparser.ast.ModuleDef):
        module.set_name(ch.name)
        
    for i in ch.children():
        show(i, module)
    
if __name__ == '__main__':
    main()
